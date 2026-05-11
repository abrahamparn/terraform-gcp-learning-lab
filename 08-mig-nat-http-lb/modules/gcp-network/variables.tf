variable "environment" {
  description = "Environment name used for resrouce naming."
  type        = string
}

variable "region" {
  description = "Default google cloud region for regional resoruces."
  type        = string
}

variable "network_name" {
  description = "Base name of the VPC network."
  type        = string
}

variable "subnets" {
  description = "Map of subnets to create inside the VPC"
  type = map(object({
    cidr_range = string
    region     = optional(string)

  }))

}

variable "firewall_rules" {
  description = "Map of ingress firewall rules to create."
  type = map(object({
    description   = optional(string)
    source_ranges = list(string)
    target_tags   = optional(list(string), [])
    allow = list(object({
      protocol = string
      ports    = optional(list(string))
    }))
  }))

  default = {}
}