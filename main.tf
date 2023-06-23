#variables are provided by vars.tf

# Configure the AWS Provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}



provider "aws" {
 profile ="${var.profile}"
 region = "${var.AWS_REGION}"
}

#create ssh key
resource "aws_key_pair" "matondo_ssh_key" {
  key_name   = "matondo_ssh_key"
  public_key = file("/Users/mluzolo/.ssh/id_ed25519.pub")
}




#create vpc
resource "aws_vpc" "main" {
 cidr_block = "10.0.0.0/16"
 
 tags = {
   Name = "Project terraform_Matondo"
 }
}

#Create Internet Gateway 
 resource "aws_internet_gateway" "IGW" {    
    vpc_id =  aws_vpc.main.id  
                
 }

#create subnets  ---------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------

#Public Subnets
resource "aws_subnet" "publicsubnets" {  
vpc_id            = aws_vpc.main.id  
cidr_block        = "${var.public_subnets}"
availability_zone = var.azs


  tags = {
  Name = "Public_matondo"
}          
}


#Private Subnet                   
resource "aws_subnet" "privatesubnets" {
  vpc_id      =  aws_vpc.main.id
  cidr_block  = "${var.private_subnets}"  

  tags = {
  Name = "Private_matondo"
}         
}


#create route table  -----------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
#Public route table
resource "aws_route_table" "public_route" {   
  vpc_id = aws_vpc.main.id
  route {
  cidr_block = "0.0.0.0/0"             
  gateway_id = aws_internet_gateway.IGW.id 
  }
}

#Private route table
 resource "aws_route_table" "private_route" {    
   vpc_id = aws_vpc.main.id
   route {
   cidr_block = "0.0.0.0/0"             
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }
 }

#association route table subnet (public)
 resource "aws_route_table_association" "public_association" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.public_route.id
 }


 #association route table subnet (private)
 resource "aws_route_table_association" "private_association" {
    subnet_id = aws_subnet.privatesubnets.id
    route_table_id = aws_route_table.private_route.id
 }


#create nat gateway
resource "aws_eip" "natIP" {
   vpc   = true
 }

 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.natIP.id
   subnet_id = aws_subnet.publicsubnets.id
 }


#create security group  --------------------------------------------------------------------
#-------------------------------------------------------------------------------------------

#bastion security group 
resource "aws_security_group" "bastion" {
  name        = "bastion"
  description = "allow * connection"

  vpc_id = aws_vpc.main.id 

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



#apps security group
resource "aws_security_group" "apps" {
  name        = "apps"
  description = "allow ssh connection from bastion"

  vpc_id = aws_vpc.main.id 

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_subnets]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}





#create ec2 instance --------------------------------------------------------------------
#----------------------------------------------------------------------------------------

#bastion instance 
resource "aws_instance" "matondo_bastion" {
    ami = "ami-00021ee291bc62064"
    instance_type = "t2.micro"
    key_name      = aws_key_pair.matondo_ssh_key.key_name
    ebs_optimized = false
    monitoring = false
    tags = {
    Name = "matondo_bastion"
    subnet_id  =  aws_subnet.publicsubnets.id
    vpc_security_group_ids = aws_security_group.bastion.id
  }

    root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }
    
}


#internal instance 
resource "aws_instance" "matondo_internal" {
    ami = "ami-00021ee291bc62064"
    instance_type = "t2.micro"
    key_name      = aws_key_pair.matondo_ssh_key.key_name
    ebs_optimized = false
    monitoring = false
    tags = {
    Name = "matondo_internal"
    subnet_id  =  aws_subnet.publicsubnets.id
    vpc_security_group_ids = aws_security_group.apps.id
    public_ip = false
  }

    root_block_device {
    volume_type           = "gp2"
    volume_size           = 8
    delete_on_termination = true
  }
    
}
