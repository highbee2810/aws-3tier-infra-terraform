# Terraform Resources for 3-Tier AWS Infrastructure
### Infrastructure Overview
This project provisions a secure 3-tier architecture on AWS:
- Web tier in public subnet
- App and DB tier in private subnets
- Remote backend with S3 & DynamoDB
- Security enforced via SGs and NACLs

### How to Deploy
```bash
terraform init
terraform plan
terraform apply

## This document explains the purpose and role of each AWS resource provisioned by the Terraform configuration for a secure 3-tier application architecture and how to implement it.
**Core Networking Resources**
*aws_vpc**  
**Purpose:** Creates an isolated Virtual Private Cloud (VPC) in AWS for launching resources.  
**Role in 3-Tier Architecture:** Defines the main network space (10.0.0.0/16) for all subnets and components.

**aws_subnet**  
**Purpose:** Divides a VPC into public or private subnets.  
**Role in 3-Tier Architecture:**  
- **Public Subnets:** Host Web Tier EC2 instances and NAT Gateway with direct internet access.  
- **Private Subnets:** Host Application Tier EC2 instances, using NAT Gateway for internet access.  
- **Database Subnets:** Host Database Tier EC2 instances, also using NAT Gateway.

**aws_internet_gateway (aws_igw)**  
**Purpose:** Connects the VPC to the internet.  
**Role in 3-Tier Architecture:** Targets internet-bound traffic for public subnets.

**aws_eip (Elastic IP)**  
**Purpose:** A static public IPv4 address allocated to your AWS account.  
**Role in 3-Tier Architecture:** Provides a stable IP for the NAT Gateway.

**aws_nat_gateway (aws_nat_gw)**  
**Purpose:** Allows internet access for private subnet instances.  
**Role in 3-Tier Architecture:** Deployed in a public subnet to enable outbound access for private application and database instances.

**aws_route_table**  
**Purpose:** Contains routing rules for network traffic.  
**Role in 3-Tier Architecture:**  
- **Public Route Table:** Directs internet-bound traffic to the Internet Gateway.  
- **Private Route Table:** Directs traffic to the NAT Gateway for private subnets.  
- **Database Route Table:** Directs traffic to the NAT Gateway for database subnets.

**aws_route**  
**Purpose:** Defines a specific traffic path in a route table.  
**Role in 3-Tier Architecture:**  
- Public subnets route to the Internet Gateway.  
- Private and database subnets route to the NAT Gateway.

**aws_route_table_association**  
**Purpose:** Links a subnet to a route table.  
**Role in 3-Tier Architecture:** Connects each subnet to its respective route table for correct traffic routing.

**Compute and Security Resources**
**AWS Instance (aws_instance)**  
**Purpose:** Represents an Amazon EC2 instance, which is a virtual server in AWS.

**Role in 3-Tier Architecture:**

- **Web Tier EC2:** Hosts the public web application components.
  
- **Application Tier EC2:** Hosts business logic and application servers within private subnets.
  
- **Database Tier EC2:** Hosts the database server in dedicated subnets.

---

**AWS Security Group (aws_security_group or aws_sg)**  
**Purpose:** Acts as a virtual firewall for EC2 instances, controlling inbound and outbound traffic. Security groups are stateful, allowing outbound return traffic automatically.

**Role in 3-Tier Architecture:** 

- **Web Tier SG:** Allows inbound HTTP/HTTPS from the internet and SSH from trusted IPs, with outbound traffic to the Application Tier SG.

- **Application Tier SG:** Allows inbound traffic from the Web Tier SG on specific ports and outbound traffic to the Database Tier SG and the internet (via NAT Gateway).

- **Database Tier SG:** Allows inbound traffic from the Application Tier SG on specific database ports and outbound traffic to the internet (via NAT Gateway).

---

**AWS Network ACL (aws_network_acl or aws_nacl)**  
**Purpose:** An optional stateless firewall for controlling subnet traffic. Requires rules for both inbound and outbound traffic.

**Role in 3-Tier Architecture:** Adds a broader security layer at the subnet level, allowing specific IP blocks, and complements security groups.

---

**Data Sources**  
**Data Source:** `data "aws_availability_zones"`  
**Purpose:** Retrieves information about available AWS Availability Zones (AZs) in a specified region.

**Role in 3-Tier Architecture:** Distributes subnets across multiple AZs for high availability and fault tolerance.

---

## This documentation summarizes the Terraform resources for building a secure 3-tier infrastructure on AWS.##
## step by step implementation guide  
**step-one: Create a GitHub repository**
Name it something like aws-3tier-infra-terraform
Initialize with a README.md, .gitignore for Terraform, and optionally a license.
**2. Clone repo locally**
```
git clone https://github.com/yourusername/aws-3tier-infra-terraform.git
cd aws-3tier-infra-terraform
```
** Define Folder Structure**
![alt text](<images/Screenshot (378).png>)
**Step 3: Create Terraform Modules**
1. VPC Module
Provision:
VPC
Public & private subnets 
Route tables and associations
```
#modules/vpc/main.tf
resource "aws_vpc" "three_tier_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name        = "${var.project_name}-VPC"
    Environment = var.project_name
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name        = "${var.project_name}-IGW"
    Environment = var.project_name
  }
}

resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"
  tags = {
    Name        = "${var.project_name}-NAT-EIP-${count.index + 1}"
    Environment = var.project_name
  }
}

resource "aws_nat_gateway" "this" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(aws_subnet.public.*.id, count.index)
  tags = {
    Name        = "${var.project_name}-NAT-GW-${count.index + 1}"
    Environment = var.project_name
  }
  depends_on = [aws_internet_gateway.this]
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.three_tier_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-Public-${data.aws_availability_zones.available.names[count.index]}"
    Environment = var.project_name
    Tier        = "Public"
  }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-Private-${data.aws_availability_zones.available.names[count.index]}"
    Environment = var.project_name
    Tier        = "Private"
  }
}

resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.three_tier_vpc.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.project_name}-DB-${data.aws_availability_zones.available.names[count.index]}"
    Environment = var.project_name
    Tier        = "Database"
  }
}

resource "aws_route_table" "public" {
  count  = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name        = "${var.project_name}-Public-RT-${count.index + 1}"
    Environment = var.project_name
  }
}

resource "aws_route" "public_internet_access" {
  count                  = length(var.public_subnet_cidrs)
  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[count.index].id
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name        = "${var.project_name}-Private-RT-${count.index + 1}"
    Environment = var.project_name
  }
}

resource "aws_route" "private_nat_access" {
  count                  = length(var.private_subnet_cidrs)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table" "database" {
  count  = length(var.database_subnet_cidrs)
  vpc_id = aws_vpc.three_tier_vpc.id
  tags = {
    Name        = "${var.project_name}-DB-RT-${count.index + 1}"
    Environment = var.project_name
  }
}

resource "aws_route" "database_nat_access" {
  count                  = length(var.database_subnet_cidrs)
  route_table_id         = aws_route_table.database[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = element(aws_subnet.database.*.id, count.index)
  route_table_id = aws_route_table.database[count.index].id
}

data "aws_availability_zones" "available" {
  state = "available"
}
```
```
# modules/vpc/variables.tf
variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}
variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}
variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
}
variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets."
  type        = list(string)
}
variable "project_name" {
  description = "Project name for tagging."
  type        = string
}
variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
}
```
```
#modules/vpc/outputs.tf
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.three_tier_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets."
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets."
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_ids" {
  description = "IDs of the database subnets."
  value       = aws_subnet.database[*].id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways."
  value       = aws_nat_gateway.this[*].id
}
```
### Security Module
Security Groups:

Web SG: allow HTTP/HTTPS from Internet

App SG: allow traffic from Web SG

DB SG: allow traffic from App SG

NACLs for extra layer (stateless rules)

```
# modules/security-group/main.tf
resource "aws_security_group" "this" {
  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = lookup(egress.value, "cidr_blocks", null)
    }
  }

  tags = {
    Name        = var.name
    Environment = var.project_name
  }
}
```
```
# modules/security-group/outputs.tf
output "id" {
  description = "The ID of the security group."
  value       = aws_security_group.this.id
}
```
```
# modules/security-group/variables.tf
variable "name" {
  description = "The name of the security group."
  type        = string
}
variable "description" {
  description = "A description for the security group."
  type        = string
  default     = "Managed by Terraform"
}
variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}
variable "ingress_rules" {
  description = "List of ingress rules."
  type = list(object({
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string))
    security_groups = optional(list(string))
  }))
  default = []
}
variable "egress_rules" {
  description = "List of egress rules."
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = optional(list(string))
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
variable "project_name" {
  description = "Project name for tagging."
  type        = string
}
```
## The Ec2 instances are created root in main.tf.

```
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
```
```
# 3-tier-infra-aws/outputs.tf
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.network.public_subnet_ids
}

output "web_tier_public_ips" {
  description = "Public IPs of the web tier instances."
  value       = aws_instance.web_tier[*].public_ip 
}
```
## The S3 bucket and dynamoDB used in storing and locking the terraform state are provisioned manually on the console
```
# 3-tier-infra-aws/outputs.tf
output "vpc_id" {
  description = "The ID of the created VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.network.public_subnet_ids
}

output "web_tier_public_ips" {
  description = "Public IPs of the web tier instances."
  value       = aws_instance.web_tier[*].public_ip 
}
```
