// provider
provider "aws" {
  region = "${var.aws_region}"
}

// ssh
resource "aws_key_pair" "default" {
  key_name   = "vpctestkeypair"
  public_key = "${file("${var.key_path}")}"
}

// vpc
resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "ibtjw-service-test-vpc"
  }
}

// public subnet
resource "aws_subnet" "public-subnet" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.public_subnet_cidr}"
  availability_zone = "us-east-1a"

  tags {
    Name = "public subnet"
  }
}

// private subnet
resource "aws_subnet" "private-subnet" {
  vpc_id            = "${aws_vpc.default.id}"
  cidr_block        = "${var.private_subnet_cidr}"
  availability_zone = "us-east-1b"

  tags {
    Name = "private subnet"
  }
}

// internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "ibtjw-service-test-vpc-igw"
  }
}

// route table
resource "aws_route_table" "public-rt" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "public subnet rt"
  }
}

// assign route table to public subnet
resource "aws_route_table_association" "public-rt" {
  subnet_id      = "${aws_subnet.public-subnet.id}"
  route_table_id = "${aws_route_table.public-rt.id}"
}

// security group for public subnet
resource "aws_security_group" "sg_pub" {
  name        = "ibtjw-service-test-vpc"
  description = "allow incoming http and ssh traffic"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "public sg"
  }
}

// security group for private subnet
resource "aws_security_group" "sg_private" {
  name        = "ibtjw-service-test-vpc"
  description = "allow traffic from public subnet"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.public_subnet_cidr}"]
  }

  vpc_id = "${aws_vpc.default.id}"

  tags {
    Name = "private sg"
  }
}

// webserver in public sub
resource "aws_instance" "pub" {
  ami                         = "${var.ami}"
  instance_type               = "t1.micro"
  key_name                    = "${aws_key_pair.default.id}"
  subnet_id                   = "${aws_subnet.public-subnet.id}"
  vpc_security_group_ids      = ["${aws_security_group.sg_pub.id}"]
  associate_public_ip_address = true
  source_dest_check           = false

  // user_data = "${file("install.sh")}"

  tags {
    Name = "pub"
  }
}

// db in private sub
resource "aws_instance" "priv" {
  ami                    = "${var.ami}"
  instance_type          = "t1.micro"
  key_name               = "${aws_key_pair.default.id}"
  subnet_id              = "${aws_subnet.private-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.sg_private.id}"]
  source_dest_check      = false

  tags {
    Name = "private"
  }
}
