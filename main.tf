/*
variable "vpc_cidr" {
  description = "CIDR for VPC"
  default     = "0.0.0.0/0"
}

resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
}
*/

variable "admin_password" {
  description = "Windows Administrator password to login as."
  default     = "DevOps2016"
}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
  default     = "gocd"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-2"
}



provider "aws" {
  region = "${var.aws_region}"
}




# Default security group to access the instances via w3web over HTTP and HTTPS
resource "aws_security_group" "w3web" {
  name        = "terraform_w3"
  description = "Used in the terraform"

  # w3web access from anywhere
  ingress {
	from_port = 22
	to_port = 22
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
	from_port = 80
	to_port = 80
	protocol = "tcp"
	cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_instance" "gocd" {
  instance_id = "i-0261a2d5712b2d3f3"
  
  filter {
    name   = "tag:Name"
    values = ["gocd"]
  }
}

resource "aws_instance" "ami_base" {
  ami           = "ami-4191b524"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.w3web.name}"]
  tags {
    Name = "TF_Linux"
  }
  
  user_data = <<HEREDOC
	  #!/bin/bash
	  sudo su
	  echo 'root:DevOps2016' | chpasswd
	HEREDOC
	
	provisioner "file" {
  		source      = "/etc/ssh/gocd.pem"
  		destination = "~/gocd.pem"

	  connection {
    		type	=	"ssh"
		user	=	"ec2-user"
		private_key = "${file("/etc/ssh/gocd.pem")}"
  	  }
	}


	provisioner "remote-exec" {
		connection {
			type	=	"ssh"
			user	=	"ec2-user"
			private_key = "${file("/etc/ssh/gocd.pem")}"
		}

		inline = [
		  "sudo yum update -y",
		  "sudo yum install -y git",
		  "sudo yum install -y httpd24",
		  "sudo service httpd start",
		  "sudo chkconfig httpd on",
		  "sudo sh -c 'echo \"Hello World<br>Jello<br>yellow\" > /var/www/html/index.html'"
		]
	  }
  
  provisioner "local-exec" {
    command = <<EOT
		echo ${aws_instance.ami_base.private_ip} >> info.txt
		echo ${aws_instance.ami_base.public_ip} >> info.txt
		echo "Waiting ec2 Running" >> info.txt
		aws ec2 wait instance-running --instance-ids ${aws_instance.ami_base.id} >> info.txt
		echo "Waiting ec2 status-ok" >> info.txt
		aws ec2 wait instance-status-ok --instance-ids ${aws_instance.ami_base.id} >> info.txt

		echo "Done"
	EOT
  }
  
}

output "public_ip" {
  value = "${aws_instance.ami_base.public_ip}"
}

output "private_ip" {
  value = "${aws_instance.ami_base.private_ip}"
}


