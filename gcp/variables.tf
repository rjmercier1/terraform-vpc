variable "region" {
  type    = string
  default = "us-east1"
}
variable "project" {
  type = string
}
variable "network" {
  type = string
}
variable "user" {
  type = string
}
variable "email" {
  type = string
}
variable "privatekeypath" {
  type    = string
  default = "keypair"
}
variable "publickeypath" {
  type    = string
  default = "keypair.pub"
}
