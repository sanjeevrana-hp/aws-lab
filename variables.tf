variable "instance_web" {
  type    = string
  default = "t2.large"
}

variable "instance_app" {
  type    = string
  default = "t2.micro"
}

variable "web_count" {
  type    = number
  default = 1
}

variable "app_count" {
  type    = number
  default = 1
}