# Encryption Policy
resource "aws_opensearchserverless_security_policy" "collection_encryption_policy" {
  name     = "${var.project_name}-${var.env}-oc-policy"
  type     = "encryption"
  provider = aws.another_region

  policy = jsonencode({
    "Rules" = [
      {
        "Resource" = [
          "collection/${var.project_name}-${var.env}-osc"
        ],
        "ResourceType" = "collection"
      }
    ],
    "AWSOwnedKey" = true
  })
}


# Network Policy
resource "aws_opensearchserverless_security_policy" "collection_network_policy" {
  name     = "${var.project_name}-${var.env}-oc-net-policy"
  type     = "network"
  provider = aws.another_region

  policy = jsonencode([
    {
      "Description" = "Public access for ${var.project_name}-${var.env} collection",
      "Rules" = [
        {
          "ResourceType" = "dashboard",
          "Resource" = [
            "collection/${var.project_name}-${var.env}-osc"
          ]
        },
        {
          "ResourceType" = "collection",
          "Resource" = [
            "collection/${var.project_name}-${var.env}-osc"
          ]
        }
      ],
      "AllowFromPublic" = true
    }
  ])
}


# OpenSearch Serverless Collection
resource "aws_opensearchserverless_collection" "opensearch_collection" {
  name               = "${var.project_name}-${var.env}-osc"
  description        = "OpenSearch Serverless collection for ${var.project_name} ${var.env} environment"
  type               = "VECTORSEARCH"
  provider           = aws.another_region
  standby_replicas   = "DISABLED"

  depends_on = [
    aws_opensearchserverless_security_policy.collection_encryption_policy,
    aws_opensearchserverless_security_policy.collection_network_policy
  ]
}


# Data Access Policy
resource "aws_opensearchserverless_access_policy" "collection_data_access_policy" {
  name        = "${var.project_name}-${var.env}-oc-data-policy"
  type        = "data"
  description = "Data access policy"
  provider    = aws.another_region

  policy = jsonencode([
    {
      "Description": "Data access policy for ${var.project_name}-${var.env}",
      "Rules": [
        {
          "ResourceType": "collection",
          "Resource": [
            "collection/${var.project_name}-${var.env}-osc"
          ],
          "Permission": [
            "aoss:DescribeCollectionItems",
            "aoss:CreateCollectionItems",
            "aoss:UpdateCollectionItems",
            "aoss:DeleteCollectionItems"
          ]
        },
        {
          "ResourceType": "index",
          "Resource": [
            "index/${var.project_name}-${var.env}-osc/*"
          ],
          "Permission": [
            "aoss:UpdateIndex",
            "aoss:DescribeIndex",
            "aoss:ReadDocument",
            "aoss:WriteDocument",
            "aoss:CreateIndex",
            "aoss:DeleteIndex"
          ]
        }
      ],
      "Principal": [
        "${data.aws_caller_identity.current.arn}",
        "${aws_iam_role.thesis_knowledge_base_role.arn}"
      ]
    }
  ])

  depends_on = [aws_opensearchserverless_collection.opensearch_collection,
  aws_iam_role.thesis_knowledge_base_role
  ]
}


# Get current caller identity
data "aws_caller_identity" "current" {}


# OpenSearch Index
resource "opensearch_index" "opensearch_collection_index" {
  name                           = "bedrock-knowledge-base-index"
  number_of_shards               = "2"
  number_of_replicas             = "0"
  provider                       = opensearch
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = <<-EOF
    {
      "properties": {
        "bedrock-knowledge-base-default-vector": {
          "type": "knn_vector",
          "dimension": 1536,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": false
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text",
          "index": true
        }
      }
    }
  EOF

  force_destroy = true

  lifecycle {
    ignore_changes = [ mappings ]
  }
  depends_on                     = [aws_opensearchserverless_collection.opensearch_collection]

}