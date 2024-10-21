#RUOLO LAMBDA dynamoDB_lambda
resource "aws_iam_role" "lambda_dynamo_role" {
  name = "${var.project_name}-${var.env}-lambda_dynamo_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

#POLICY LAMBDA dynamoDB_lambda
resource "aws_iam_policy" "lambda_dynamo_policy" {
  name = "${var.project_name}-${var.env}-lambda-dynamo-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "errorLambdasPolicy",
    "Statement" : [
         {
            "Effect": "Allow",
            "Action": [
                "dynamodb:Scan",
                "dynamodb:PutItem"
            ],
            "Resource": aws_dynamodb_table.thesis-dynamo-table.arn
        },
      {
        "Sid" : "AllowEventBridgePutEvents",
        "Effect" : "Allow",
        "Action" : "events:PutEvents",
        "Resource" : [
          "arn:aws:events:eu-west-1:523753954008:*"

        ]
      },
      {
        "Sid" : "AllowCloudWatchLogging",
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
            ],
        "Resource": [
          "arn:aws:logs:eu-west-1:523753954008:log-group:/aws/lambda/${var.project_name}-${var.env}-dynamoDB_lambda:*"
            ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_dynamoDB_allarm_attachment" {
  role       = aws_iam_role.lambda_dynamo_role.name
  policy_arn = aws_iam_policy.lambda_dynamo_policy.arn
}


#------------------------------------------------------------------------------------------

#RUOLO LAMBDA lambda_error_triggered
resource "aws_iam_role" "lambda_error_role" {
  name = "${var.project_name}-${var.env}-lambda_error_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

#POLICY LAMBDA lambda_error_triggered
resource "aws_iam_policy" "lambda_error_policy" {
  name = "${var.project_name}-${var.env}-lambda-error-policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "errorLambdasPolicy",
    "Statement" : [
                {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:eu-west-1:523753954008:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-1:523753954008:log-group:/aws/lambda/${var.project_name}-${var.env}-message_and_error_triggered_lambda:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:DescribeLogStreams",
                "logs:FilterLogEvents",
                "logs:GetLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-west-1:523753954008:log-group:/aws/lambda/${var.project_name}-${var.env}-dynamoDB_lambda:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "sns:Publish",
            "Resource": aws_sns_topic.error_topic.arn
      },
      {
            "Sid": "LambdaGetFunctionPermission",
            "Effect": "Allow",
            "Action": "lambda:GetFunction",
            "Resource": [
                "arn:aws:lambda:eu-west-1:523753954008:function:${var.project_name}-${var.env}-dynamoDB_lambda"
            ]
        },
        {
            "Action": [
                "bedrock:Retrieve",
                "bedrock:InvokeModel"
            ],
            "Effect": "Allow",
            "Resource": [
                aws_bedrockagent_knowledge_base.bedrockKB.arn,
                "arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude-3-5-sonnet-20240620-v1:0"
            ]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_error_policy_attachment" {
  role       =  aws_iam_role.lambda_error_role.name
  policy_arn = aws_iam_policy.lambda_error_policy.arn
}

#--------------------------------------------------------------------------------------------

# BEDROCK  Role
resource "aws_iam_role" "thesis_knowledge_base_role" {
  name = "${var.project_name}-${var.env}-thesis-knowledge-base-role"
  provider = aws.another_region
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "bedrock.amazonaws.com"  # Bedrock come servizio
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  depends_on = [
    aws_opensearchserverless_collection.opensearch_collection
  ]
}

resource "aws_iam_policy" "thesis_knowledge_base_policy" {
  name     = "${var.project_name}-${var.env}-thesis-knowledge-base-policy"
  provider = aws.another_region
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
            "Sid": "BedrockInvokeModelStatement",
            "Effect": "Allow",
            "Action": [
                "bedrock:InvokeModel"
            ],
            "Resource": [
                "arn:aws:bedrock:us-west-2::foundation-model/amazon.titan-embed-text-v1"
            ]
        },
        {
            "Sid": "S3GetObjectStatement",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetObject",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                 aws_s3_bucket.thesis_knowledge_base_bucket.arn,
                 "${aws_s3_bucket.thesis_knowledge_base_bucket.arn}/*"
            ],
            "Condition": {
                "StringEquals": {
                    "aws:ResourceAccount": [
                        "523753954008"
                    ]
                }
            }
        },
        {
            "Sid": "OpenSearchServerlessAPIAccessAllStatement",
            "Effect": "Allow",
            "Action": [
                "aoss:APIAccessAll"
            ],
            "Resource": [
                aws_opensearchserverless_collection.opensearch_collection.arn
            ]
        },
        {
            "Sid" : "OpenSearchServiceAccess",
            "Effect" : "Allow",
            "Action" : [
                        "aoss:CreateCollection",
                        "aoss:DeleteCollection",
                        "aoss:UpdateCollection",
                        "aoss:ListCollections",
                        "aoss:BatchGetCollection",
                        "aoss:CreateAccessPolicy",
                        "aoss:CreateSecurityPolicy",
                        "aoss:GetAccessPolicy",
                        "aoss:UpdateAccessPolicy",
                        "aoss:DeleteAccessPolicy",
                        "aoss:ListAccessPolicies",
                        "aoss:GetSecurityPolicy",
                        "aoss:DeleteAccessPolicy",
                        "aoss:CreateIndex",
                        "aoss:DeleteIndex",
                        "aoss:UpdateIndex",
                        "aoss:DescribeIndex",
                        "aoss:DescribeCollection",
                        "aoss:ListIndices",
                        "aoss:WriteDocument",
                        "aoss:ReadDocument"
                    ],
            "Resource" : [
            aws_opensearchserverless_collection.opensearch_collection.arn
            ]
        },
        {
        "Sid": "BedrockDataSourceAccess",  # Nuovo blocco per i permessi di Bedrock DataSource
        "Effect": "Allow",
        "Action": [
          "bedrock:CreateDataSource",
          "bedrock:ListDataSources",
          "bedrock:GetDataSource",
          "bedrock:UpdateDataSource",
          "bedrock:DeleteDataSource"
        ],
        "Resource": "*"
      },
      {
        "Sid": "BedrockIngestionJobAccess", 
        "Effect": "Allow",
        "Action": [
          "bedrock:StartIngestionJob",
          "bedrock:ListIngestionJobs",
          "bedrock:GetIngestionJob",
          "bedrock:StopIngestionJob"
        ],
        "Resource": "*"
      }
    ]
  })
}


# Attaching the policy to the role
resource "aws_iam_role_policy_attachment" "thesis_knowledge_policy_attachment" {
  role       = aws_iam_role.thesis_knowledge_base_role.name
  policy_arn = aws_iam_policy.thesis_knowledge_base_policy.arn
}

#------------------------------------------------------------------------------------------