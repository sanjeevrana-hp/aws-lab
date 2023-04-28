###### Generating Random username/password ##########
# Creating two random password for username and Password
resource "random_pet" "username" {
  length = 2
}
resource "random_string" "password" {
  length  = 20
  special = false
}


# RSA key of size 4096 bits
resource "tls_private_key" "rsa-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "KeyPair" {
  key_name   = "${random_pet.username.id}-KeyPair"
  public_key = tls_private_key.rsa-key.public_key_openssh
  tags       = local.common_tags
}

resource "local_file" "KeyPair_File" {
  content         = tls_private_key.rsa-key.private_key_pem
  filename        = "mykey-pair"
  file_permission = "0400"
}

resource "aws_instance" "webserver" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_web
  count                  = var.web_count
  key_name               = "${random_pet.username.id}-KeyPair"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = ["${aws_security_group.allow_traffic.id}"]
  security_groups        = ["${aws_security_group.allow_traffic.id}"]
  root_block_device {
    volume_size           = "30"
    delete_on_termination = "true"
  }
  tags = {
    Name           = "webserver_${count.index}"
  }
}

resource "aws_instance" "appserver" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_app
  count                  = var.app_count
  key_name               = "${random_pet.username.id}-KeyPair"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = ["${aws_security_group.allow_traffic.id}"]
  security_groups        = ["${aws_security_group.allow_traffic.id}"]
  root_block_device {
    volume_size           = "30"
    delete_on_termination = "true"
  }
  tags = {
    Name           = "appserver_${count.index}"
  }
}