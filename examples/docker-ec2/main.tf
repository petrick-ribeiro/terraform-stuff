# Define Network Settings
resource "aws_vpc" "foobar_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

resource "aws_subnet" "foobar_public_subnet" {
  vpc_id                  = aws_vpc.foobar_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev_public"
  }
}

resource "aws_internet_gateway" "foobar_gw" {
  vpc_id = aws_vpc.foobar_vpc.id

  tags = {
    Name = "dev_igw"
  }
}

resource "aws_route_table" "foobar_public_rt" {
  vpc_id = aws_vpc.foobar_vpc.id

  tags = {
    Name = "dev_public_rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.foobar_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.foobar_gw.id
}

resource "aws_route_table_association" "foobar_public_assoc" {
  subnet_id      = aws_subnet.foobar_public_subnet.id
  route_table_id = aws_route_table.foobar_public_rt.id
}

resource "aws_security_group" "foobar_sg" {
  name        = "dev_sg"
  description = "dev security group"
  vpc_id      = aws_vpc.foobar_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define SSH Authentication
resource "aws_key_pair" "foobar_auth" {
  key_name   = "terraform-key"
  public_key = file("~/.ssh/terraform-key.pub") # SSH Public Key Path
}

# Create EC2 Instance
resource "aws_instance" "dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.foobar_auth.id
  vpc_security_group_ids = [aws_security_group.foobar_sg.id]
  subnet_id              = aws_subnet.foobar_public_subnet.id
  user_data              = file("init.tpl") # Provide initial configuration

  root_block_device {
    volume_size = 10
  }

  provisioner "local-exec" { # Setting the SSH Configuration
    command = templatefile("ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/terraform-key"
    })
    interpreter = ["bash", "-c"]
  }

  tags = {
    Name = "dev-node"
  }
}
