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
/*
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
*/

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
  security_groups = ["terraform_w3"]
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
		echo "PublicIp: ${aws_instance.ami_base.public_ip}" > info.txt
		echo "PrivateIp: ${aws_instance.ami_base.public_ip}" >> info.txt
		echo "InstanceId: ${aws_instance.ami_base.id}" >> info.txt

		Ami=$(aws ec2 create-image --instance-id ${aws_instance.ami_base.id} --name "TestAmiImageTerra${aws_instance.ami_base.id}")
		echo $Ami | python -c "import json,sys;obj=json.load(sys.stdin);print obj['ImageId'];"
		echo $Ami > result.json

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


