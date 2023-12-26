# data "local_file" "subnet_ids_file" {
#   filename = "/home/divagar/vpc-subnets-module/cidr/ouptut.json"
# }

# locals {
#   subnet_ids = jsondecode(data.local_file.subnet_ids_file.content)["subnet_ids"]
# }

