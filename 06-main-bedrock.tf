# S3 Bucket resource (example, if not already defined)
resource "aws_s3_bucket" "thesis_knowledge_base_bucket" {
    provider = aws.another_region
    bucket = "${var.project_name}-${var.env}-thesis-kb-bucket"
}


variable "pdf_directory" {
  type    = string
  default = "./kb_files"
}

locals {
  pdf_files = fileset(var.pdf_directory, "*.pdf")
}


resource "aws_s3_object" "my_pdf_objects" {
  provider = aws.another_region
  for_each = local.pdf_files

  bucket = aws_s3_bucket.thesis_knowledge_base_bucket.bucket
  key    = each.value
  source = "${var.pdf_directory}/${each.value}"              
}


resource "aws_bedrockagent_data_source" "data_source" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.bedrockKB.id
  provider = aws.another_region
  name              =  "${var.project_name}-${var.env}-data_source"
  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.thesis_knowledge_base_bucket.arn
    }
  }
    depends_on = [
    aws_bedrockagent_knowledge_base.bedrockKB
  ]
}


resource "aws_bedrockagent_knowledge_base" "bedrockKB" {
  name     = "${var.project_name}-${var.env}-bedrockKB"
  role_arn = aws_iam_role.thesis_knowledge_base_role.arn
  provider = aws.another_region
  knowledge_base_configuration {
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:us-west-2::foundation-model/amazon.titan-embed-text-v1"
    }
    type = "VECTOR"
  }
  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.opensearch_collection.arn
      vector_index_name = opensearch_index.opensearch_collection_index.name
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }
  depends_on = [
   aws_iam_role_policy_attachment.thesis_knowledge_policy_attachment,
    aws_opensearchserverless_collection.opensearch_collection,
    aws_opensearchserverless_access_policy.collection_data_access_policy,
    aws_opensearchserverless_security_policy.collection_network_policy
  ]
}


resource "null_resource" "kb_ingestion" {
  triggers = merge(
    {for key,obj in  aws_s3_object.my_pdf_objects : key => obj.checksum_sha256 },

    {datasource_id = aws_bedrockagent_data_source.data_source.id}
  )

  provisioner "local-exec" {
    command = <<-EOF
      aws bedrock-agent start-ingestion-job \
        --data-source-id ${split(",",aws_bedrockagent_data_source.data_source.id)[0]} \
        --knowledge-base-id ${aws_bedrockagent_knowledge_base.bedrockKB.id} \
        --region us-west-2 \
        --profile storm-roma-lab \
        --debug
    EOF
  }

  depends_on = [
    aws_bedrockagent_knowledge_base.bedrockKB,
    aws_bedrockagent_data_source.data_source
  ]
}