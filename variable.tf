variable "region" {
  type = string
}
variable "main_cidr" {}
variable "privateSubApne1a_cidr" {}
variable "publicSubApne1a_cidr" {}
variable "privateSubApne1c_cidr" {}
variable "publicSubApne1c_cidr" {}
variable "project_name" {}
variable "ecs_service_count" {}
variable "dbusername" {}
variable "dbpassword" {}
variable "database" {}
variable "roleAdm" {}
variable "DBCRED" {}
variable "task_families_name" {
  type    = list(string)
  default = ["app1", "app2", "app3"] #change this accordingly
}

variable "db_img_name" {
  type    = string
  default = "hldbpostgres"
}
