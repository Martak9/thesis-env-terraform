resource "aws_dynamodb_table" "thesis-dynamo-table" {
  name           = "thesis-dynamo-table"  # Nome tabella
  hash_key       = "WorkName"  # Chiave primaria

  attribute {
    name = "WorkName"
    type = "S" 
  }

  attribute {
    name = "Author"
    type = "S" 
  }
  billing_mode    = "PROVISIONED"
  read_capacity   = 1
  write_capacity  = 1

  global_secondary_index {
    name               = "AuthorIndex"  # Nome dell'indice
    hash_key           = "Author"  # Chiave secondaria
    projection_type    = "ALL"  # Proiettare tutti gli attributi

    read_capacity      = 1  # Capacità di lettura per il GSI
    write_capacity     = 1  # Capacità di scrittura per il GSI
  }
  
}


resource "aws_dynamodb_table_item" "item1" {
  table_name = aws_dynamodb_table.thesis-dynamo-table.name

  hash_key   = "WorkName"

  item = <<EOT
  {
    "WorkName": {"S": "Se questo è un uomo"},
    "Author": {"S": "Primo Levi"}
  }
  EOT
}


resource "aws_dynamodb_table_item" "item2" {
  table_name = aws_dynamodb_table.thesis-dynamo-table.name

  hash_key   = "WorkName"

  item = <<EOT
  {
    "WorkName": {"S": "Il Fu Mattia Pascal"},
    "Author": {"S": "Luigi Pirandello"}
  }
  EOT
}