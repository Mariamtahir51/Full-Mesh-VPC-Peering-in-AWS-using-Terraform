variable "region"{
    default = "eu-central-1"
}

variable "primary_region" {
  default = "eu-central-1"
}

variable "secondary_region" {
  default = "us-east-1"
}

variable "tertiary_region" {
  default = "eu-north-1"
}

variable "primary_key_name" {
  default = "vpc_peering_east"
}

variable "secondary_key_name" {
  default = "vpc_peering_west"
}

variable "tertiary_key_name" {
  default = "vpc_peering_north"
}

variable "primary_vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "tertiary_vpc_cidr" {
  default = "10.2.0.0/16"
}

variable "primary_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "secondary_subnet_cidr" {
  default = "10.1.1.0/24"
}

variable "tertiary_subnet_cidr" {
  default = "10.2.1.0/24"
}

variable "allow_from_anywhere_cidr" {
    default = "0.0.0.0/0"
}

variable "aws_availability_zones" {
  default = ["eu-central-1a", "us-east-1a", "eu-north-1a"]
}