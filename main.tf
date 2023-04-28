# Creating a local variable for generating randomness
locals {
  name  = "terraform-deploy"
  app   = "test-application"
  tstmp = formatdate("DD-MMM-YYYY:hh-mm", timestamp())
}

locals {
  common_tags = {
    Name = local.name
    App  = local.app
    Time = local.tstmp
  }
}


# VPC Creation
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  tags       = local.common_tags
}

# Security Group Creation
resource "aws_security_group" "allow_traffic" {
  name        = "terraform_allow_traffic"
  description = "Allow Ingress/Egress traffic"
  vpc_id      = aws_vpc.myvpc.id
  dynamic "ingress" {
    for_each = [22, 80, 8080, 443, 9090, 9000]
    iterator = port
    content {
      description = "Allow traffic from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags = local.common_tags

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

# Subnet Creation
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  tags       = local.common_tags
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags                    = local.common_tags
}

# InternetGateway Creation
resource "aws_internet_gateway" "mygw" {
  vpc_id = aws_vpc.myvpc.id
  tags   = local.common_tags
}

# Route_table creation & association
resource "aws_route_table" "pub_route_table" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygw.id
  }
  tags = local.common_tags
}

resource "aws_route_table_association" "route_table_ass" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.pub_route_table.id
}

#Dynamo table creation
resource "aws_dynamodb_table" "state_locking" {
  hash_key = "LockID"
  name     = "dynamodb-state-locking"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name           = "dynamodb-locking-table"
    DateOfCreation = local.tstmp
  }
}

#S3 bucket creation, acl & versioning
resource "aws_s3_bucket" "mys3_bucket" {
  bucket = "${random_pet.username.id}-bucket-2023"
  tags = {
    Name = "My_bucket"
  }
}

resource "aws_s3_bucket_acl" "mys3_bucket_acl" {
  bucket = aws_s3_bucket.mys3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "mys3_bucket_versioning" {
  bucket = aws_s3_bucket.mys3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}