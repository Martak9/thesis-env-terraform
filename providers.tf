provider "aws" {
    profile = "storm-roma-lab"
    region = var.region

  default_tags {
    # This configuration combines some "default" tags with optionally provided additional tags
    tags = merge(
      var.default_tags,
      {
        Owner       = var.owner,
        environment = var.env
        application = var.project_name
    })
  }
}


provider "aws" {
    profile = "storm-roma-lab"
    alias  = "another_region"
    region = "us-west-2"
    default_tags {
        tags = merge(
        var.default_tags,
        {
            Owner       = var.owner,
            environment = var.env
            application = var.project_name
        })
    }
}


terraform {
  required_providers {
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "~> 2.0"  # Use the latest 2.x version
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Use the latest 5.x version, adjust as needed
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"  # Puoi specificare una versione appropriata
    }
  }
}


provider "opensearch" {
  url                 = aws_opensearchserverless_collection.opensearch_collection.collection_endpoint
  aws_region          = "us-west-2"  # Make sure this matches your AWS provider region
  healthcheck         = false
  aws_profile         = "storm-roma-lab"
}

provider "archive" {}