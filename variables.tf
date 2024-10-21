variable "env" {
  description = "Environment name or identifier."
  default     = "env"
}


variable "project_name" {
  default = "thesis"
}


variable "region" {
  description = "The region where resources will be deployed"
  default     = "eu-west-1"
}


variable "default_tags" {
  type    = map(string)
  default = {}
}


variable "owner" {
  type    = string
  default = "m.paciotti@reply.it"
}