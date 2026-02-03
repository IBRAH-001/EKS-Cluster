data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  public_subnet_name_prefix  = "Public Subnet"
  private_subnet_name_prefix = "Private Subnet"
  internet_gateway_suffix    = "Internet Gateway"
  nat_gateway_suffix         = "NAT Gateway"
  public_route_table_suffix  = "Public Routing"
  private_route_table_suffix = "Private Routing"
  #flow_logs_bucket_name      = "team4tech-dev-${lower(var.name)}-vpc-flow-logs"
  private_acl_name = "${var.name} Private ACL"
  public_acl_name  = "${var.name} Public ACL"

  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.azs) : 0
}


########################################
# VPC
########################################

resource "aws_vpc" "main" {
  cidr_block                       = var.cidr
  enable_dns_support               = var.enable_dns_hostnames
  enable_dns_hostnames             = var.enable_dns_hostnames
  assign_generated_ipv6_cidr_block = var.enable_public_ipv6

  tags = merge({
    Name = var.name
  }, var.tags)
}

########################################
# Subnets 
########################################

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnets, count.index)
  ipv6_cidr_block         = var.enable_public_ipv6 ? cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index) : null
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = false

 tags = merge({
    Name = "${local.public_subnet_name_prefix} ${count.index + 1}"
  }, 
  var.tags,
  var.enable_eks_support ? {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                       = "1"
  } : {},
  var.eks_public_subnet_tags)
}


resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnets, count.index)
  availability_zone = element(var.azs, count.index)

  tags = merge({
    Name = "${local.private_subnet_name_prefix} ${count.index + 1}"
  }, 
  var.tags,
  var.enable_eks_support ? {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"              = "1"
  } : {},
  var.eks_private_subnet_tags)
}

########################################
# Internet Gateway
########################################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name = "${var.name} ${local.internet_gateway_suffix}"
  }, var.tags)
}

########################################
# NAT Gateway
########################################

resource "aws_eip" "nat" {
  # checkov:skip=CKV2_AWS_19 : EIP is attached to NAT gateway (required for private subnet internet access), not EC2 instance
  count = local.nat_gateway_count

  tags = merge({
    Name = "${var.name} ${local.nat_gateway_suffix}"
  }, var.tags)
}

resource "aws_nat_gateway" "nat" {
  count         = local.nat_gateway_count
  subnet_id     = element(aws_subnet.public_subnets[*].id, var.single_nat_gateway ? 0 : count.index)
  allocation_id = element(aws_eip.nat[*].id, var.single_nat_gateway ? 0 : count.index)

  tags = merge({
    Name = "${var.name} ${local.nat_gateway_suffix}"
  }, var.tags)
}

########################################
# Route Tables
########################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name = "${var.name} ${local.public_route_table_suffix}"
  }, var.tags)
}

resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route" "public_igw_v6" {
  count                       = var.enable_public_ipv6 ? 1 : 0
  route_table_id              = aws_route_table.public.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.gw.id
}

resource "aws_route_table" "private" {
  count  = local.nat_gateway_count
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name = "${var.name} ${local.private_route_table_suffix}"
  }, var.tags)
}

resource "aws_route" "private" {
  count                  = local.nat_gateway_count
  route_table_id         = element(aws_route_table.private[*].id, count.index)
  nat_gateway_id         = element(aws_nat_gateway.nat[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
}

########################################
# Route Table Associations
########################################

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = element(aws_route_table.private[*].id, var.single_nat_gateway ? 0 : count.index)
}

########################################
# VPC Flow Logs Log Destination S3
########################################

#resource "aws_s3_bucket" "vpc_flow_logs" {
#bucket = local.flow_logs_bucket_name
#force_destroy = true
#}

#resource "aws_s3_bucket_ownership_controls" "vpc_flow_logs" {
#bucket = aws_s3_bucket.vpc_flow_logs.id
#rule {
#object_ownership = "BucketOwnerPreferred"
#}
#}

#resource "aws_s3_bucket_acl" "vpc_flow_logs" {
#depends_on = [aws_s3_bucket_ownership_controls.vpc_flow_logs]

#bucket = aws_s3_bucket.vpc_flow_logs.id
#acl    = "private"
#}



resource "aws_flow_log" "vpc_flow_logs" {
  count                = var.centralized_vpc_flow_logs_bucket_arn != "" ? 1 : 0
  log_destination      = var.centralized_vpc_flow_logs_bucket_arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
}

###################################################
# VPC Flow Logs Log Destination CloudWatch Log Group
###################################################

# Create a KMS key
resource "aws_kms_key" "vpc_flow_logs" {
  description = "KMS key for VPC Flow Logs"
  enable_key_rotation = true
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Id": "key-default-1",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow CloudWatch Logs use of the key",
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.${data.aws_region.current.name}.amazonaws.com"
      },
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Create a CloudWatch Log Group with KMS encryption
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_cloudwatch_log_group ? 1 : 0
  name              = var.name
  retention_in_days = var.log_retention_days
  kms_key_id        = aws_kms_key.vpc_flow_logs.arn
}

resource "aws_flow_log" "vpc_flow_logs_cloudwatch" {
  count          = var.cloudwatch_log_group_arn != "" && var.vpc_flow_logs_role_arn != "" ? 1 : 0
  log_destination          = var.cloudwatch_log_group_arn
  traffic_type             = "ALL"
  max_aggregation_interval = var.max_aggregation_interval
  vpc_id                   = aws_vpc.main.id
  iam_role_arn             = var.vpc_flow_logs_role_arn
}

########################################
# Network ACL
########################################

resource "aws_network_acl" "private" {
  # checkov:skip=CKV2_AWS_1 : NACL is associated with subnets via aws_network_acl_association resource
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name : local.private_acl_name
  }, var.tags)
}

# tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "private_local" {
  # checkov:skip=CKV_AWS_352 : NACL rule allows local VPC communication (required for VPC internal traffic)
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  rule_action    = "allow"
  protocol       = -1
  egress         = false
  from_port      = 0
  to_port        = 0
  cidr_block     = var.cidr
}

# tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "private_ephemeral" {
  # checkov:skip=CKV_AWS_231 : Ephemeral port range is required for return traffic (standard NACL configuration)
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  rule_action    = "allow"
  protocol       = "tcp"
  egress         = false
  from_port      = 1024
  to_port        = 65535
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_http_out" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  rule_action    = "allow"
  protocol       = "tcp"
  egress         = true
  from_port      = 80
  to_port        = 80
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_https_out" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 110
  rule_action    = "allow"
  protocol       = "tcp"
  egress         = true
  from_port      = 443
  to_port        = 443
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_out_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 120
  rule_action    = "allow"
  protocol       = -1
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = var.cidr
}

resource "aws_network_acl_rule" "private_out_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 130
  rule_action    = "allow"
  protocol       = "tcp"
  egress         = true
  from_port      = 1024
  to_port        = 65535
  cidr_block     = "0.0.0.0/0"
}

# Allow all traffic from VPN VPC to private subnets (ingress)
# Required for cross-VPC communication between EKS cluster and main production VPC
#tfsec:ignore:aws-ec2-no-excessive-port-access
resource "aws_network_acl_rule" "private_vpn_all_in" {
  # checkov:skip=CKV_AWS_352 : NACL allows all protocols to enable full cross-VPC communication between EKS and production VPC
  network_acl_id = aws_network_acl.private.id
  rule_number    = 170
  rule_action    = "allow"
  protocol       = "-1"
  egress         = false
  from_port      = 0
  to_port        = 0
  cidr_block     = "10.26.0.0/16"
}

# Allow all traffic from private subnets to VPN VPC (egress)
# Required for cross-VPC communication between EKS cluster and main production VPC
#tfsec:ignore:aws-ec2-no-excessive-port-access
resource "aws_network_acl_rule" "private_vpn_all_out" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 180
  rule_action    = "allow"
  protocol       = "-1"
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = "10.26.0.0/16"
}

resource "aws_network_acl" "public" {
  # checkov:skip=CKV2_AWS_1 : NACL is associated with subnets via aws_network_acl_association resource
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name : local.public_acl_name
  }, var.tags)
}
# tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_local" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  rule_action    = "allow"
  protocol       = "tcp"
  egress         = false
  from_port      = 22
  to_port        = 22
  cidr_block     = var.cidr
}

# tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 110
  rule_action    = "allow"
  protocol       = "tcp"
  egress         = false
  from_port      = 80
  to_port        = 80
  cidr_block     = "0.0.0.0/0"
}


# Allowing ingress from public internet on port 443 for HTTPS access due to application requirements.
# This is necessary to ensure that customers can access the application securely over HTTPS.
# Additional security measures, such as an application firewall, are in place to protect the application.
# tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 120
  rule_action    = "allow"
  protocol       = "tcp"
  egress         = false
  from_port      = 443
  to_port        = 443
  cidr_block     = "0.0.0.0/0"
}

# tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_http_v6" {
  count           = var.enable_public_ipv6 ? 1 : 0
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 220
  rule_action     = "allow"
  protocol        = "tcp"
  egress          = false
  from_port       = 80
  to_port         = 80
  ipv6_cidr_block = "::/0"
}

# tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_https_v6" {
  count           = var.enable_public_ipv6 ? 1 : 0
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 140
  rule_action     = "allow"
  protocol        = "tcp"
  egress          = false
  from_port       = 443
  to_port         = 443
  ipv6_cidr_block = "::/0"
}

# tfsec:ignore:aws-ec2-no-public-ingress-acl
resource "aws_network_acl_rule" "public_ephemeral" {
  # checkov:skip=CKV_AWS_231 : Ephemeral port range is required for return traffic (standard NACL configuration)
  network_acl_id = aws_network_acl.public.id
  rule_number    = 130
  rule_action    = "allow"
  protocol       = "tcp"
  egress         = false
  from_port      = 1024
  to_port        = 65535
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_out_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  rule_action    = "allow"
  protocol       = -1
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_out_v6_all" {
  network_acl_id  = aws_network_acl.public.id
  rule_number     = 200
  rule_action     = "allow"
  protocol        = -1
  egress          = true
  from_port       = 0
  to_port         = 0
  ipv6_cidr_block = "::/0"
}

# Allow all traffic from VPN VPC to public subnets (ingress)
# Required for cross-VPC communication between EKS cluster and main production VPC
#tfsec:ignore:aws-ec2-no-excessive-port-access
resource "aws_network_acl_rule" "public_vpn_all_in" {
  # checkov:skip=CKV_AWS_352 : NACL allows all protocols to enable full cross-VPC communication between EKS and production VPC
  network_acl_id = aws_network_acl.public.id
  rule_number    = 170
  rule_action    = "allow"
  protocol       = "-1"
  egress         = false
  from_port      = 0
  to_port        = 0
  cidr_block     = "10.26.0.0/16"
}

# Allow all traffic from public subnets to VPN VPC (egress)
# Required for cross-VPC communication between EKS cluster and main production VPC
#tfsec:ignore:aws-ec2-no-excessive-port-access
resource "aws_network_acl_rule" "public_vpn_all_out" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 180
  rule_action    = "allow"
  protocol       = "-1"
  egress         = true
  from_port      = 0
  to_port        = 0
  cidr_block     = "10.26.0.0/16"
}


resource "aws_network_acl_association" "private" {
  count          = length(aws_subnet.private_subnets)
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private_subnets[count.index].id
}

resource "aws_network_acl_association" "public" {
  count          = length(aws_subnet.public_subnets)
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public_subnets[count.index].id
}

########################################
# Default Security Group
########################################

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main.id

  ingress = []
  egress  = []
}

########################################
# VPC Endpoints for ECR (Required for EKS nodes in private subnets)
########################################

# Security group for VPC endpoints
resource "aws_security_group" "vpc_endpoints" {
  count       = var.enable_ecr_vpc_endpoints ? 1 : 0
  name        = "${var.name}-vpc-endpoints-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.name}-vpc-endpoints-sg"
  }, var.tags)
}

# ECR Docker API endpoint (Interface endpoint)
resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.enable_ecr_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids           = aws_subnet.private_subnets[*].id
  security_group_ids   = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled  = true

  tags = merge({
    Name = "${var.name}-ecr-dkr-endpoint"
  }, var.tags)
}

# ECR API endpoint (Interface endpoint)
resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.enable_ecr_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids           = aws_subnet.private_subnets[*].id
  security_group_ids   = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled  = true

  tags = merge({
    Name = "${var.name}-ecr-api-endpoint"
  }, var.tags)
}

# S3 Gateway endpoint (for pulling image layers - free)
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_ecr_vpc_endpoints ? 1 : 0
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge({
    Name = "${var.name}-s3-endpoint"
  }, var.tags)
}