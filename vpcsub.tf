resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "MyVPC"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "${var.subnet_cidr_block}${replace(data.local_file.script_output.content, "\n", "")}"
  availability_zone = "${var.region}a" 

  tags = {
    Name = "MySubnet"
  }
}