variable "aws_region" {
  description = "vpc region"
  default = "us-east-1"
}

variable "vpc_cidr" {
  description = "cidr for vpc"
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "cidr for the public subnet"
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "cidr for the private subnet"
  default = "10.0.2.0/24"
}

variable "ami" {
  description = "ami for ec2"
  default = "ami-4fffc834"
}

variable "key_path" {
  description = "ssh public keypath"
  default = "/Users/tj/.ssh/id_rsa.pub"
}