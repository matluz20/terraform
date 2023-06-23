#variables

variable "AWS_REGION" {    
    default = "eu-west-3"
}

variable "profile" {    
    default = "sbx"
}

#define avaibilite zones
variable "azs" {
  type    = string
  default = "eu-west-1a"
}

#public network
variable "public_subnets" {
  type    = string
  default = "10.0.1.0/24"
}

#private network
variable "private_subnets" {
  type    = string
  default = "10.0.101.0/24"
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             