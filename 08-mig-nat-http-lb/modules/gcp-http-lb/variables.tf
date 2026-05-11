variable "environment" {
  description = "Environment name used for resource naming."
  type        = string
}

variable "lb_name" {
  description = "Base name for the HTTP load balancer."
  type        = string
}

variable "backend_instance_group" {
  description = "Instance group URL used as backend."
  type        = string
}

variable "health_check_self_link" {
  description = "Health check self-link for the backend service."
  type        = string
}

variable "app_port" {
  description = "Application port served by the backend."
  type        = number
}