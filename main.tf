# Create a new instance EC2 for minecraft server
provider "aws" {
  region = "${var.aws-region}"
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"] # Canonical
}

resource "aws_key_pair" "deployer" {
  key_name = "deployer-key"
  public_key      = "${file("../admin_rsa.pub")}"
}

resource "aws_instance" "web" {
  ami           = "${data.aws_ami.amazon-linux-2.id}"
  instance_type = "${var.instance-type}"
  key_name = "${aws_key_pair.deployer.key_name}"

  tags = {
    Name = "minecraft-server"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y java",
      "mkdir ~/minecraft"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("../admin_rsa")}"
    }
  }

  provisioner "file" {
    source      = "files/"
    destination = "~/minecraft"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("../admin_rsa")}"
      timeout = "10m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x ~/minecraft/server.jar",
      "cd ~/minecraft",
      "screen -dmS minecraft java -server -Xmx512M -Xms512M -jar server.jar",
      "sleep 1",
      "echo OK"
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = "${file("../admin_rsa")}"
      timeout = "10m"
    }
  }
}
