variable "AWS_REGION" {    
    default = "us-west-1"
}

variable "AMI" {
    type = map

    default = {
        us-west-1 = "ami-0fc6c1dea61cc5971"
    }
}

variable "PUBLIC_KEY_PATH" {
    default = "test-keypair.pub"
}

variable "PRIVATE_KEY_PATH" {
    default = "test-keypair"
}

variable "EC2_USER" {
    default = "ubuntu"
}
