output "dynamodb_table_name" {
  value = aws_dynamodb_table.thesis-dynamo-table.name
}
output "data_source_id" {
  value = aws_bedrockagent_data_source.data_source.id
}
output "s3_objects" {
  value = [for obj in aws_s3_object.my_pdf_objects : obj.key]
}