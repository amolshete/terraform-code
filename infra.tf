# variable "region" {
#     type = string
#     default = "ap-south-1"
# }



terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "terrafome-stage-mgmt-474378"
    key    = "mydir/terraform_state_file"
    region = "ap-south-1"
  }

}


provider "aws" {
  region = var.region
}



# resource "aws_instance" "web" {
#   ami           = "ami-05295b6e6c790593e"
#   instance_type = "t2.micro"
#   key_name = "linux-demo-111"
#   tags = {
#     Name = "HelloWorld-1"
#   }
# }

# resource "aws_instance" "coit_instance_2" {
#   ami           = "ami-09298640a92b2d12c"
#   instance_type = "t2.micro"
#   key_name = "linux-demo-111"

#   tags = {
#     Name = "demo machine"
#     owner= "Amol Shete"
#   }
# }

# resource "aws_eip" "test_eip" {
#   instance = aws_instance.coit_instance_2.id
# }


#creating the vpc
resource "aws_vpc" "demo_vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "demo-vpc"
  }
}

#creating the subnets

resource "aws_subnet" "demo_subnet-1a" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.10.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Demo-subnet-1a"
  }
}

resource "aws_subnet" "demo_subnet-1b" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Demo-subnet-1b"
  }
}


resource "aws_subnet" "demo_subnet-1c" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "Demo-subnet-1c"
  }
}

#creating the ec2 machines
resource "aws_instance" "demo_instance-1" {
  ami           = "ami-01dc3b2554a2c65b3"
  instance_type = "t2.micro"
  key_name = aws_key_pair.terraform-demo-key.id
  subnet_id = aws_subnet.demo_subnet-1a.id
  associate_public_ip_address = "true"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  user_data = filebase64("userdata.sh")

  tags = {
    Name = "demo machine"
    owner= "Amol Shete"
  }
}


resource "aws_instance" "demo_instance-2" {
  ami           = "ami-01dc3b2554a2c65b3"
  instance_type = "t2.micro"
  key_name = aws_key_pair.terraform-demo-key.id
  subnet_id = aws_subnet.demo_subnet-1b.id
  #associate_public_ip_address = "true"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "demo machine 2"
    owner= "Amol Shete"
  }
}

#create the key pair
resource "aws_key_pair" "terraform-demo-key" {
  key_name   = "terraform-demo-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC0+HrfMh25OlQOHNWKQsk02UkCaeejAklO0uOf3Z1QGAX+kLbiQQQ9p9ib16Pa7fhnb/GVjlfxU1hN9LzLRl+OjJvnQ1Owj/Khzmd+93v9qBb4DhuTyDUWEUkMHGlquVy1GyZeo+rcbLKNoouSc6F7eWALixTvlNMNBBnPNXjaKm9GFY0xRUDuAUbUzmlfoSANBqZRLW3v3UG+72wcl5ATBI+GPwv1EV3uKwG0rXJObHHYef/pHVex2eFzoxkQnuuv4s/8N0lc8ddoycu+p4vkHqSgJhyqMz4SOBOuIUFuVCValBGjKO468HvAfGuLBi0+JdHSOyhvYZVJJyp+X075dN0fuDXoJxgRvI9pJ4wlxyxYj1wk81L/5Zwq/wOWm9Y8QPheAMRes8e2T1m7vB3uXYosgBr7g6xf7gyIf0lesTfj+FYZLiophfBX2wTKijF4Mr6nXXvQTVgl1n/AlNAQYqinhGK8YsA3L0Z14xB+/BZNcuGfKhKCL4L4dNj+Y20= Amol@DESKTOP-2MVQBON"
}

#create securtiy group
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.demo_vpc.id

  tags = {
    Name = "allow_traffic_for_demo_instance"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_80" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


#create IGW

resource "aws_internet_gateway" "demo_IGW" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "Demo_IGW"
  }
}

#create public RT

resource "aws_route_table" "Public_demo_RT" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_IGW.id
  }

  tags = {
    Name = "Public_RT"
  }
}

resource "aws_route_table_association" "RT_association_1" {
  subnet_id      = aws_subnet.demo_subnet-1a.id
  route_table_id = aws_route_table.Public_demo_RT.id
}


resource "aws_route_table_association" "RT_association_2" {
  subnet_id      = aws_subnet.demo_subnet-1b.id
  route_table_id = aws_route_table.Public_demo_RT.id
}


resource "aws_route_table" "Private_demo_RT" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "Private_RT"
  }
}

resource "aws_route_table_association" "RT_association_3" {
  subnet_id      = aws_subnet.demo_subnet-1c.id
  route_table_id = aws_route_table.Private_demo_RT.id
}


#create the target group

resource "aws_lb_target_group" "apache_target_group" {
  name     = "tf-example-apache2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo_vpc.id
}

resource "aws_lb_target_group_attachment" "apache_target_group_attach_1" {
  target_group_arn = aws_lb_target_group.apache_target_group.arn
  target_id        = aws_instance.demo_instance-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "apache_target_group_attach_2" {
  target_group_arn = aws_lb_target_group.apache_target_group.arn
  target_id        = aws_instance.demo_instance-2.id
  port             = 80
}

#create Listener

resource "aws_lb_listener" "demo_lb_listener" {
  load_balancer_arn = aws_lb.apache_LB.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apache_target_group.arn
  }
}

#create LB

resource "aws_lb" "apache_LB" {
  name               = "apache-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.demo_subnet-1a.id, aws_subnet.demo_subnet-1b.id]

  tags = {
    Environment = "production"
  }
}


#Creating the launch template

resource "aws_launch_template" "demo_launch_template" {

  name = "demo-launch-template"
  image_id = "ami-01dc3b2554a2c65b3"
  instance_type = "t2.micro"
  key_name = aws_key_pair.terraform-demo-key.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "demo_instance_by_LT"
    }
  }

  tags = {
    Name = "demo machine 2"
    owner= "Amol Shete"
  }

  user_data = filebase64("userdata.sh")
}

#create ASG

resource "aws_autoscaling_group" "bar" {
  name = "demo"  
  vpc_zone_identifier = [aws_subnet.demo_subnet-1a.id, aws_subnet.demo_subnet-1b.id]
  desired_capacity   = 2
  max_size           = 5
  min_size           = 2
  target_group_arns = [aws_lb_target_group.apache_target_group_2.arn]

  launch_template {
    id      = aws_launch_template.demo_launch_template.id
    version = "$Latest"
  }
}

#creta ALB with ASG

resource "aws_lb" "apache_LB_2" {
  name               = "apache-LB-2"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_ssh.id]
  subnets            = [aws_subnet.demo_subnet-1a.id, aws_subnet.demo_subnet-1b.id]

  tags = {
    Environment = "production"
  }
}

#create Listener

resource "aws_lb_listener" "demo_lb_listener_2" {
  load_balancer_arn = aws_lb.apache_LB_2.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apache_target_group_2.arn
  }
}


#create the target group

resource "aws_lb_target_group" "apache_target_group_2" {
  name     = "tf-apache2-2"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo_vpc.id
}

