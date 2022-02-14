provider "aws" {
  region = "${var.AWS_REGION}"
}

resource "aws_vpc" "prod-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = "true" #gives you an internal domain name
    enable_dns_hostnames = "true" #gives you an internal host name
    enable_classiclink = "false"
    instance_tenancy = "default"    
    
    tags = {
        Name = "prod-vpc"
    }
}

resource "aws_instance" "nat" {
    ami = "${lookup(var.AMI, var.AWS_REGION)}"
    instance_type = "t4g.nano"

    # VPC
    subnet_id = "${aws_subnet.prod-subnet-public-1.id}"

    # Security Group
    vpc_security_group_ids = ["${aws_security_group.public-sg.id}"]

    # the Public SSH key
    key_name = "${aws_key_pair.test-keypair.id}"

    # Allow nat host to route for subnet
    # 
    provisioner "remote-exec" {
        inline = [
            "sudo iptables ! -o lo -t nat -A POSTROUTING -j MASQUERADE",
            "sudo sh -c 'iptables-save > /etc/iptables.rules'",

            "sudo sh -c 'echo #\\!/bin/sh > /etc/network/if-pre-up.d/iptablesrestore'",
            "sudo sh -c 'echo iptables-restore /etc/iptables.rules >> /etc/network/if-pre-up.d/iptablesrestore'",
            "sudo sh -c 'echo exit 0 >> /etc/network/if-pre-up.d/iptablesrestore'",
            "sudh chmod +x /etc/network/if-pre-up.d/iptablesrestore",

            "sudo sh -c 'echo #!/bin/sh > /etc/network/if-pre-up.d/iptablesrestore'",
            "sudo sh -c 'echo net.ipv4.ip_forward=1 > /etc/sysctl.d/20-ipv4_forward.conf'",
            "sudo sysctl net.ipv4.ip_forward=1"
        ]
    }
    provisioner "local-exec" {
        command = "aws ec2 modify-instance-attribute --no-source-dest-check --instance-id ${self.id}"
    }

    connection {
        user = "${var.EC2_USER}"
        host = "${self.public_ip}"
        private_key = "${file("${var.PRIVATE_KEY_PATH}")}"
    }
}

resource "aws_instance" "worker" {
    ami = "${lookup(var.AMI, var.AWS_REGION)}"
    instance_type = "t4g.nano"

    # VPC
    subnet_id = "${aws_subnet.prod-subnet-private-1.id}"

    # Security Group
    vpc_security_group_ids = ["${aws_security_group.private-sg.id}"]

    # the Public SSH key
    key_name = "${aws_key_pair.test-keypair.id}"

    connection {
        user = "${var.EC2_USER}"
        private_key = "${file("${var.PRIVATE_KEY_PATH}")}"
    }
}

// Sends your public key to the instance
resource "aws_key_pair" "test-keypair" {
    key_name = "test-keypair"
    public_key = "${file(var.PUBLIC_KEY_PATH)}"
}
