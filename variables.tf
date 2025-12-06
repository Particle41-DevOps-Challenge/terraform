variable "project" {
    type = string
    default = "Particle41"
  
}

variable "cidr_block" {
    default = "10.0.0.0/16"
  
}

variable "vpc_tags" {
    type = map(string)
    default = {}  
}

variable "igw_tags" {
    type = map(string)
    default = {}
  
}

variable "public_subnet_cidrs" {
    default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
    default = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "public_subnet_tags" {
    type = map(string)
    default = {}
}

variable "private_subnet_tags" {
    type = map(string)
    default = {}
}

variable "eip_tags" {
    type = map(string)
    default = {}  
}

variable "nat_gatewway_tags" {
    type = map(string)
    default = {}  
}

variable "public_route_table_tags" {
    type = map(string)
    default = {}  
}

variable "private_route_table_tags" {
    type = map(string)
    default = {}  
}
