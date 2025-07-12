variable "subnet_ids" {
  description = "List of subnet IDs for ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for ALB"
  type        = string
}
variable "instance_a_id" {
  description = "instance a id"
  type        = string
}

