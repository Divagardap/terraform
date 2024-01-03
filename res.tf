############ VARIABLES #############
variable "students" {
  type = list(string)
  default = []
}
variable "batch_name" {
  type = string
  default = ""
}
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type = string
  default = ""
}
variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"
  type = string
  default = ""
}
variable "region" {
  description = "AWS region"
  type = string
  default = ""
}
variable "instance_type" {
  description = "AWS instance"
  type = string
  default = ""  
}
variable "volume_size" {
  description = "AWS volume"
  type = number
}
############ USER RESOURCES ################
resource "aws_iam_user" "users" {
  count = length(var.students)
  name = var.students[count.index]
}

resource "aws_iam_group" "group" {
  name = var.batch_name
}


resource "aws_iam_user_group_membership" "groups_membership" {
  count = length(var.students)
  user  = aws_iam_user.users[count.index].name
  groups = [aws_iam_group.group.name]
}
resource "aws_iam_user_login_profile" "login_profile" {
  count = length(var.students)
  user = aws_iam_user.users[count.index].name
}

output "user_credentials" {
  value = [
    for idx in range(length(aws_iam_user_login_profile.login_profile)) : {
      username = aws_iam_user.users[idx].name
      password = aws_iam_user_login_profile.login_profile[idx].password      
      id = aws_iam_user.users[idx].arn != null ? split(":", aws_iam_user.users[idx].arn)[4] : null
    }
  ]
}
resource "aws_iam_user_policy_attachment" "ec2actions" {
  count      = length(var.students)
  user       = var.students[count.index]
  policy_arn = aws_iam_policy.ec2actions.arn
}
resource "aws_iam_policy" "ec2actions" {
  name = "ec2_vpc_attach_policy"
  # user = aws_iam_user.users[count.index].name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ec2:RunInstances",
          "ec2:Describe*",
          "ec2:GetConsole*",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:AssociateRouteTable",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolume*",
          "ec2:AttachNetworkInterface",
          "ec2:DetachNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:ModifyInstanceAttribute",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair",
          "ec2:DescribeKeyPairs"
        ],
        Resource = "*"
      }
    ]
  })
}

########### local script to exec cidr ###########
resource "null_resource" "execute_script" {
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "bash calc.sh > output.txt"
  }
}
data "local_file" "script_output" {
  depends_on = [null_resource.execute_script]
  filename = "./output.txt"
}
output "cidr_output" {
  value = data.local_file.script_output.content
}

################# vpc and subnet

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
  map_public_ip_on_launch = true
  tags = {
    Name = "MySubnet" 

  }
}
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "myigw"
  }
}
resource "aws_route_table" "myroute" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
  tags = {
    Name = "mypubroute"
  }
}
resource "aws_route_table_association" "rt_associate" {
    subnet_id = aws_subnet.main_subnet.id
    route_table_id = aws_route_table.myroute.id
}

output "vpc_arn" {
  value = aws_vpc.main.arn
}

output "subnet_arn" {
  value = aws_subnet.main_subnet.arn
}

############# POLICY ################

resource "aws_iam_user_policy_attachment" "example_attachment" {
  count      = length(var.students)
  user       = var.students[count.index]
  policy_arn = aws_iam_policy.custom_policy2.arn
}
resource "aws_iam_policy" "custom_policy2" {
  name        = "Customregolicy"
  description = "Custom IAM policy for EC2 operations"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid     = "region",
        Effect  = "Deny",
        Action  = "ec2:*",
        Resource = "*",
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.region
          }
        }
      }
    ] 
  })
}
resource "aws_iam_user_policy_attachment" "policy_attachment3" {
  count      = length(var.students)
  user       = var.students[count.index]
  policy_arn = aws_iam_policy.t2microdeny.arn
}
resource "aws_iam_policy" "t2microdeny" {
  name        = "InstanceTypeDenyPolicy"
  description = "IAM policy to deny RunInstances if the instance type is not t2.micro"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid"       = "sizeandinstancelimit",
        "Effect"    = "Deny",
        "Action"    = "ec2:RunInstances",
        "Resource"  = "arn:aws:ec2:${var.region}:*:instance/*",
        "Condition" = {
          "ForAnyValue:StringNotLike" = {
            "ec2:InstanceType" = var.instance_type
          }
        }
      }
    ]
  })
}
resource "aws_iam_user_policy_attachment" "volume_size" {
  count      = length(var.students)
  user       = var.students[count.index]
  policy_arn = aws_iam_policy.volume_sizede.arn
}
resource "aws_iam_policy" "volume_sizede" {
  name        = "VolumeSizeDenyPolicy"
  description = "IAM policy to deny RunInstances if the volume size is greater than 10"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Sid"       = "volumesize",
        "Effect"    = "Deny",
        "Action"    = "ec2:RunInstances",
        "Resource"  = "arn:aws:ec2:${var.region}:*:volume/*",
        "Condition" = {
          "NumericGreaterThan" = {
            "ec2:VolumeSize" = var.volume_size
          }
        }
      }
    ]
  })
}
resource "aws_iam_user_policy_attachment" "attachment2" {
  count      = length(var.students)
  user       = var.students[count.index]
  policy_arn = aws_iam_policy.restricted_ec2_policy.arn
}
resource "aws_iam_policy" "restricted_ec2_policy" {
  name        = "RestrictedEC2Policy"
  description = "Allows running and describing EC2 instances only within a specific VPC and subnet."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect"   = "Deny",
        "Action"   = ["ec2:RunInstances"],
        "Resource" = ["*"],
        "Condition" = {
          "ForAnyValue:StringNotLike" = {
            "ec2:Vpc"    = aws_vpc.main.arn,
            "ec2:Subnet" = aws_subnet.main_subnet.arn
          }
        }
      }
    ]
  })
}
  