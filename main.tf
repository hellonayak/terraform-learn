provider "aws" {
    region = "ap-south-1"
 
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip {}
variable instance_type {}
# variable public_key_location {}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_block     
    tags = {
        Name: "${var.env_prefix}-vpc"  //prefix variable names glued together
    }
}

resource "aws_subnet" "myapp-subnet-1" {  
    vpc_id = aws_vpc.myapp-vpc.id   
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
     tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

/*resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id  //vpc id reference

    route{  //each route will have their own block
        cidr_block = "0.0.0.0/0" //anywhere
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name : "${var.env_prefix}-rtb"
    }
}*/

resource"aws_internet_gateway" "myapp-igw" {  //interacts with internet with vpc
    vpc_id = aws_vpc.myapp-vpc.id
     tags = {
        Name : "${var.env_prefix}-igw"
    }
}


resource "aws_default_route_table" "main-rtb" { //we dont need a vpc id because we r using main
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id //we get the main rtb id like this
   
   route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.myapp-igw.id
   }
   tags = {
        Name : "${var.env_prefix}-main-rtb"
    } 
}


resource "aws_default_security_group" "default-sg" {
    vpc_id = aws_vpc.myapp-vpc.id  //associate sg with vpc
    ingress { //for incoming traffic
        from_port = 22
        to_port = 22 //we can also configure a range of ports here
        protocol = "tcp"
        cidr_blocks = [var.my_ip] //ip adres range or list of ip address, who is allowed to access thi sport
        //if the ip is dynamic you can declare as env variable
    
    
    }
    ingress { 
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    
    
    }
    egress { //outgoing
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
        prefix_list_ids = [] //for allowing access to vpc end points
    }
    tags = {
        Name = "${var.env_prefix}-default-sg"
    }
    
}

# data "aws_ami" "latest-amazon-linux-image"{
#     most_recent = true 
#     owners = ["amazon"]  //we can hv multiple owners here , also can have my own images
# }

# output "aws_ami_id" {
#     value = data.aws_ami.latest-amazon-linux-image.id
# }

output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}



resource "aws_key_pair" "ssh-key" {
  key_name   = "server-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDY1GiCvmlcq9ITBDcLbtweHraVbckuCni0YAUTPY/ab357MXhbMUUs/XUnccFrd9q4wqEWWwyJoJyqIbE56Xr6YB02+jz9+R7Qgc3xSg+RKfwlxCJQtw02xqVQfuIuD83P+Tb+uy+bycb6UrfBIlx5t9ponu5qBvG70N7hjEGWyI0u/qK9ijjAoQOCScyqFQ/9WLrd7qjl38Y3bI1VRvTN4QDKNg2d7ZcofhAHFTo6R3pRZrBTV2BUwlZr/0n7qb8P6tXdOuHNmifeFjp9maDRb8Gu0r3o8f+vrpm/LaxpQ0/5D+mLHWFdLZiTIKmS3ajyXugNibOIbeO6ky93TP8iO66hgJLThCcevYrq0pC+adSGJ8d/ePY3y7vQm8WPacvYRAS7yBoD7eAs9uV5XUymwWcE2Sr5KyQAaQfLBhR8xwAdmTUdnygSUfzBu1U+NHTEzJNso3Jas8dCU0uAhvQNaMlZncslPrbRNRbts+gGXzfPH131UdEzrOylaH7GWyc= Dibya@DESKTOP-IK9C0D1"
  }

resource "aws_instance" "myapp-server" {
    ami = "ami-0d81306eddc614a45"
    instance_type = var.instance_type

    //above two arguements are required, below are optional, if we dont specify them ec2 will do it in default

    //configure to gets in the subnet id..and to end up in our vpc
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.default-sg.id]  //this is used as list
    availability_zone = var.avail_zone
    
    associate_public_ip_address = true //we will be able to access this from browser
    key_name = aws_key_pair.ssh-key.key_name //associate the key here

    user_data = file("entry-script.sh")




    tags = {
        Name = "${var.env_prefix}-server"

    }

}




