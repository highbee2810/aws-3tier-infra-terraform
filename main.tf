module "network" {
  source                 = "./modules/vpc"
  vpc_cidr               = var.vpc_cidr_block
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  database_subnet_cidrs  = var.database_subnet_cidrs
  project_name           = var.project_name
  aws_region             = var.aws_region
}

module "web_sg" {
  source      = "./modules/security-group"
  name        = "web-tier-sg"
  description = "Security group for web tier instances"
  vpc_id      = module.network.vpc_id
  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  project_name = var.project_name
}

module "app_sg" {
  source      = "./modules/security-group"
  name        = "app-tier-sg"
  description = "Security group for application tier instances"
  vpc_id      = module.network.vpc_id
  ingress_rules = [
    {
      from_port       = 8080
      to_port         = 8080
      protocol        = "tcp"
      security_groups = [module.web_sg.id]
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["YOUR_TRUSTED_IP_CIDR/32"]
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  project_name = var.project_name
}

module "db_sg" {
  source      = "./modules/security-group"
  name        = "db-tier-sg"
  description = "Security group for database tier instances"
  vpc_id      = module.network.vpc_id
  ingress_rules = [
    {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [module.app_sg.id]
    }
  ]
  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  project_name = var.project_name
}

resource "aws_instance" "web_tier" {
  count                   = 2
  ami                     = var.ami_id
  instance_type           = var.instance_type_web
  subnet_id               = element(module.network.public_subnet_ids, count.index)
  vpc_security_group_ids  = [module.web_sg.id]
  key_name                = var.key_pair_name

  tags = {
    Name        = "${var.project_name}-Web-${count.index + 1}"
    Environment = var.project_name
    Tier        = "Web"
  }
}

resource "aws_instance" "app_tier" {
  count                   = 2
  ami                     = var.ami_id
  instance_type           = var.instance_type_app
  subnet_id               = element(module.network.private_subnet_ids, count.index)
  vpc_security_group_ids  = [module.app_sg.id]
  key_name                = var.key_pair_name

  tags = {
    Name        = "${var.project_name}-App-${count.index + 1}"
    Environment = var.project_name
    Tier        = "App"
  }
}

resource "aws_instance" "db_tier" {
  count                   = 1
  ami                     = var.ami_id
  instance_type           = var.instance_type_db
  subnet_id               = element(module.network.database_subnet_ids, 0)
  vpc_security_group_ids  = [module.db_sg.id]
  key_name                = var.key_pair_name

  tags = {
    Name        = "${var.project_name}-DB-1"
    Environment = var.project_name
    Tier        = "Database"
  }
}

resource "aws_network_acl" "public_nacl" {
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.public_subnet_ids

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-Public-NACL"
  }
}

resource "aws_network_acl" "private_nacl" {
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = module.network.public_subnet_cidrs[0]
    from_port  = 8080
    to_port    = 8080
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-Private-NACL"
  }
}

resource "aws_network_acl" "database_nacl" {
  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.database_subnet_ids

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = module.network.private_subnet_cidrs[0]
    from_port  = 3306
    to_port    = 3306
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-Database-NACL"
  }
}
