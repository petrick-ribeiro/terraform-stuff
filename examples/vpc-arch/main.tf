# Creates a VPC.
resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      "Name" = "main-vpc"
    }
}

# Creates a Internet Gateway.
resource "aws_internet_gateway" "main_igw" {
    vpc_id = aws_vpc.main_vpc.id

    tags = {
      "Name" = "main-internet-gw"
    }
}

# Generates a Elastic IP address.
resource "aws_eip" "main_ng_eip_1" {
    vpc =true
}

resource "aws_eip" "main_ng_eip_2" {
    vpc =true
}

# Creates NAT Gateways in differents AZs.
# us-east-1a
resource "aws_nat_gateway" "main_ng_1" {
    allocation_id = aws_eip.main_ng_eip_1.id
    subnet_id = aws_subnet.public_subnet-1.id

    tags = {
      "Name" = "main-nat-gw-1a"
    }

    depends_on = [
      aws_internet_gateway.main_igw
    ]
}

# us-east-1b
resource "aws_nat_gateway" "main_ng_2" {
    allocation_id = aws_eip.main_ng_eip_2.id
    subnet_id = aws_subnet.public_subnet-2.id

    tags = {
      "Name" = "main-nat-gw-1b"
    }

    depends_on = [
      aws_internet_gateway.main_igw
    ]
}

# Create public subnets in differents AZs.
resource "aws_subnet" "public_subnet-1" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"

    tags = {
      "Name" = "main-public-subnet-1a"
    }
}

resource "aws_subnet" "public_subnet-2" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1b"

    tags = {
      "Name" = "main-public-subnet-1b"
    }
}

# Creates private subnets in differents AZs
resource "aws_subnet" "private_subnet-1" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1a"

    tags = {
      "Name" = "main-private-subnet-1a"
    }
}

resource "aws_subnet" "private_subnet-2" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "us-east-1b"

    tags = {
      "Name" = "main-private-subnet-1b"
    }
}

# Creates a association between the public subnet and the public route table.
resource "aws_route_table_association" "public_subnet_1_association" {
    subnet_id = aws_subnet.public_subnet-1.id
    route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_2_association" {
    subnet_id = aws_subnet.public_subnet-2.id
    route_table_id = aws_route_table.public_route_table.id
}

# Creates a public route table.
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main_igw.id
    }

    tags = {
      "Name" = "main-public-rt"
    }
}

# Creates a association between the private subnet and the private route table.
resource "aws_route_table_association" "private_subnet_association_1" {
    subnet_id = aws_subnet.private_subnet-1.id
    route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table_association" "private_subnet_association_2" {
    subnet_id = aws_subnet.private_subnet-2.id
    route_table_id = aws_route_table.private_route_table_2.id
}

# Creates a private route table.
# Points to the NAT Gateway in us-east-1a
resource "aws_route_table" "private_route_table_1" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main_ng_1.id
    }

    tags = {
      "Name" = "main-private-rt-1a",
    }
}

# Points to the NAT Gateway in us-east-1b
resource "aws_route_table" "private_route_table_2" {
    vpc_id = aws_vpc.main_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main_ng_2.id
    }

    tags = {
      "Name" = "main-private-rt-1b",
    }
}