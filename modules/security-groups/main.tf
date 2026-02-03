#######################################################
# Default Security Group
#######################################################

resource "aws_default_security_group" "default" {
  vpc_id = var.vpc_id

  ingress = []
  egress  = []
}

#######################################################
# Redis
#######################################################

resource "aws_security_group" "redis" {
  count       = var.create_redis_sg ? 1 : 0
  name        = "Redis"
  description = "Allow access to redis"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "Redis"
  }, var.tags)
}
# tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group_rule" "redis-vpc" {
  count             = var.create_redis_sg ? 1 : 0
  type              = "ingress"
  from_port         = 6168
  to_port           = 6168
  protocol          = "tcp"
  security_group_id = aws_security_group.redis[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow Redis traffic from VPC"
}

resource "aws_security_group_rule" "redis-backups" {
  count             = var.create_redis_sg && var.backup_private_ip != "" ? 1 : 0
  type              = "ingress"
  from_port         = 6169
  to_port           = 6169
  protocol          = "tcp"
  security_group_id = aws_security_group.redis[count.index].id
  cidr_blocks       = ["${var.backup_private_ip}/32"]
  description       = "Allow Redis backup traffic"
}

resource "aws_security_group_rule" "redis-vpn" {
  count                    = var.create_redis_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 6169
  to_port                  = 6169
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redis[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow Redis traffic from VPN"
}

resource "aws_security_group_rule" "reporting-redis-in" {
  count             = var.create_redis_sg && var.reporting_cidr != "" ? 1 : 0
  type              = "ingress"
  from_port         = 6169
  to_port           = 6169
  protocol          = "tcp"
  security_group_id = aws_security_group.redis[count.index].id
  cidr_blocks       = [var.reporting_cidr]
  description       = "Allow Redis traffic from reporting CIDR"
}

#######################################################
# MQTT
#######################################################

resource "aws_security_group" "mqtt" {
  count       = var.create_mqtt_sg ? 1 : 0
  name        = "MQTT"
  description = "Allow access to MQTT"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "MQTT"
  }, var.tags)
}

# tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group_rule" "mqtt-vpc" {
  count             = var.create_mqtt_sg ? 1 : 0
  type              = "ingress"
  from_port         = 2616
  to_port           = 2616
  protocol          = "tcp"
  security_group_id = aws_security_group.mqtt[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow MQTT traffic from VPC"
}

resource "aws_security_group_rule" "mqtt-vpn" {
  count                    = var.create_mqtt_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 1616
  to_port                  = 1616
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mqtt[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow MQTT traffic from VPN"
}

resource "aws_security_group_rule" "reporting-mqtt-in" {
  count             = var.create_mqtt_sg && var.reporting_cidr != "" ? 1 : 0
  type              = "ingress"
  from_port         = 1616
  to_port           = 1616
  protocol          = "tcp"
  security_group_id = aws_security_group.mqtt[count.index].id
  cidr_blocks       = [var.reporting_cidr]
  description       = "Allow MQTT traffic from reporting CIDR"
}


#######################################################
# Elephants
#######################################################

resource "aws_security_group" "elephants" {
  count       = var.create_elephants_sg ? 1 : 0
  name        = "Elephants"
  description = "Allow access to elephants"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "Elephants"
  }, var.tags)
}

# tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group_rule" "elephants-in" {
  count             = var.create_elephants_sg ? 1 : 0
  type              = "ingress"
  from_port         = 43616
  to_port           = 43616
  protocol          = "tcp"
  security_group_id = aws_security_group.elephants[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow Elephants traffic from VPC"
}
# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "elephants-out" {
  count             = var.create_elephants_sg ? 1 : 0
  type              = "egress"
  from_port         = 43616
  to_port           = 43616
  protocol          = "tcp"
  security_group_id = aws_security_group.elephants[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow Elephants traffic to VPC"
}

resource "aws_security_group_rule" "reporting-elephant-in" {
  count             = var.create_elephants_sg && var.reporting_cidr != "" ? 1 : 0
  type              = "ingress"
  from_port         = 43616
  to_port           = 43616
  protocol          = "tcp"
  security_group_id = aws_security_group.elephants[count.index].id
  cidr_blocks       = [var.reporting_cidr]
  description       = "Allow Elephants traffic from reporting CIDR"
}

#######################################################
# NGINX
#######################################################
resource "aws_security_group" "nginx" {
  count       = var.create_nginx_sg ? 1 : 0
  name        = "Nginx"
  description = "Allow access to Nginx"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "Nginx"
  }, var.tags)
}

resource "aws_security_group_rule" "nginx-alb" {
  count                    = var.create_nginx_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.nginx[count.index].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description              = "Allow HTTP traffic from ALB to Nginx"
}

#######################################################
# Registration Server
#######################################################

resource "aws_security_group" "registration_server" {
  count       = var.create_registration_server_sg ? 1 : 0
  name        = "Registration Server"
  description = "Allow access to Registration Server"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "Registration Server"
  }, var.tags)
}

resource "aws_security_group_rule" "registration_server_alb" {
  count                    = var.create_registration_server_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 56433
  to_port                  = 56433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.registration_server[count.index].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description              = "Allow traffic from ALB to Registration Server"
}

#######################################################
# SSH
#######################################################

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "ssh" {
  count       = var.create_ssh_sg ? 1 : 0
  name        = "SSH"
  description = "Allow access to SSH"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic to anywhere"
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic to anywhere"
  }

  tags = merge({
    Name = "SSH"
  }, var.tags)
}

resource "aws_security_group_rule" "ssh_from_vpn" {
  count                    = var.create_ssh_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ssh[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow SSH traffic from VPN"
}

resource "aws_security_group_rule" "ssh_from_cidr" {
  count                    = var.create_ssh_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ssh[count.index].id
  cidr_blocks              = ["10.26.0.0/16"]
  description              = "Allow SSH traffic from CIDR block"
}


#######################################################
# API
#######################################################

#tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "api" {
  count       = var.create_api_sg ? 1 : 0
  name        = "API"
  description = "Allow access to API"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow MongoDB traffic within VPC"
  }

  egress {
    from_port   = 6168
    to_port     = 6168
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow Redis traffic within VPC"
  }
  egress {
    from_port   = 2616
    to_port     = 2616
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow MQTT traffic within VPC"
  }
  egress {
    from_port   = 43616
    to_port     = 43616
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow Elephants traffic within VPC"
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow RDS traffic within VPC"
  }

  tags = merge({
    Name = "API"
  }, var.tags)
}

resource "aws_security_group_rule" "api-alb" {
  count                    = var.create_api_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 21899
  to_port                  = 21899
  protocol                 = "tcp"
  security_group_id        = aws_security_group.api[count.index].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description              = "Allow traffic from ALB to API"
}


#######################################################
# ALB
#######################################################
#tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group" "alb" {
  count       = var.create_alb_sg ? 1 : 0
  name        = "ALB"
  description = "Allow access to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow HTTP traffic from anywhere"
  }

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr
  # Note: Allowing ingress from the public internet is necessary for the ALB to receive traffic from the internet.
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow HTTPS traffic from anywhere"
  }

  tags = merge({
    Name = "ALB"
  }, var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "alb-api" {
  count                    = var.create_alb_sg && var.create_api_sg ? 1 : 0
  type                     = "egress"
  from_port                = 21899
  to_port                  = 21899
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb[count.index].id
  source_security_group_id = aws_security_group.api[count.index].id
  description              = "Allow traffic from ALB to API"
}

resource "aws_security_group_rule" "alb-registration" {
  count                    = var.create_alb_sg && var.create_registration_server_sg ? 1 : 0
  type                     = "egress"
  from_port                = 56433
  to_port                  = 56433
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb[count.index].id
  source_security_group_id = aws_security_group.registration_server[count.index].id
  description              = "Allow traffic from ALB to Registration Server"
}

resource "aws_security_group_rule" "alb-files" {
  count                    = var.create_alb_sg && var.create_nginx_sg ? 1 : 0
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb[count.index].id
  source_security_group_id = aws_security_group.nginx[count.index].id
  description              = "Allow traffic from ALB to Nginx"
}

#######################################################
# Backups
#######################################################

resource "aws_security_group" "backups" {
  count       = var.redis_private_ip != "" ? 1 : 0
  name        = "Backups"
  description = "Allow access to Backups"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 6169
    to_port     = 6169
    protocol    = "tcp"
    cidr_blocks = var.redis_private_ip != "" && var.redis_private_ip != "false" ? ["${var.redis_private_ip}/32"] : []
    description = "Allow Redis backup traffic"
  }

  tags = merge({
    Name = "Backups"
  }, var.tags)
}

#######################################################
# VPN
#######################################################

# tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group" "vpn" {
  count       = var.create_vpn_sg ? 1 : 0
  name        = "VPN"
  description = "Allow access to VPN"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from anywhere"
  }
}


resource "aws_security_group_rule" "vpn-redis" {
  count                    = var.create_vpn_sg && var.create_redis_sg ? 1 : 0
  type                     = "egress"
  from_port                = 6169
  to_port                  = 6169
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpn[count.index].id
  source_security_group_id = aws_security_group.redis[count.index].id
  description              = "Allow Redis traffic from VPN"
}

resource "aws_security_group_rule" "vpn-redis-ssl" {
  count                    = var.create_vpn_sg && var.create_redis_sg ? 1 : 0
  type                     = "egress"
  from_port                = 6168
  to_port                  = 6168
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpn[count.index].id
  source_security_group_id = aws_security_group.redis[count.index].id
  description              = "Allow Redis SSL traffic from VPN"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "vpn-ssh" {
  count             = var.create_vpn_sg ? 1 : 0
  type              = "egress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.vpn[count.index].id
  description       = "Allow SSH traffic from VPN"
}

resource "aws_security_group_rule" "vpn-mqtt" {
  count                    = var.create_vpn_sg && var.create_mqtt_sg ? 1 : 0
  type                     = "egress"
  from_port                = 1616
  to_port                  = 1616
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpn[count.index].id
  source_security_group_id = aws_security_group.mqtt[count.index].id
  description              = "Allow MQTT traffic from VPN"
}

resource "aws_security_group_rule" "vpn-mqtts" {
  count                    = var.create_vpn_sg && var.create_mqtt_sg ? 1 : 0
  type                     = "egress"
  from_port                = 2616
  to_port                  = 2616
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpn[count.index].id
  source_security_group_id = aws_security_group.mqtt[count.index].id
  description              = "Allow MQTT SSL traffic from VPN"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "vpn-postgres" {
  count             = var.create_vpn_sg ? 1 : 0
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.vpn[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow Postgres traffic from VPN"
}

resource "aws_security_group_rule" "vpn-opensearch" {
  count                    = var.create_vpn_sg && var.create_opensearch_sg ? 1 : 0
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpn[count.index].id
  source_security_group_id = aws_security_group.opensearch[count.index].id
  description              = "Allow OpenSearch traffic from VPN"
}

resource "aws_security_group_rule" "vpn-ocg" {
  count                    = var.create_ocg_sg ? 1 : 0
  type                     = "egress"
  from_port                = 3389
  to_port                  = 3389
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpn[count.index].id
  source_security_group_id = aws_security_group.ocg_windows[count.index].id
  description              = "Allow OCG traffic from VPN"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "vpn-internal-https" {
	count             = var.create_vpn_sg ? 1 : 0
	type              = "egress"
	from_port         = 443
	to_port           = 443
	protocol          = "tcp"
	security_group_id = aws_security_group.vpn[count.index].id
	cidr_blocks       = [var.vpc_cidr]
	description       = "Allow HTTPS traffic from VPN to VPC"
}
# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "vpn-internal-http" {
	count             = var.create_vpn_sg ? 1 : 0
	type              = "egress"
	from_port         = 80
	to_port           = 80
	protocol          = "tcp"
	security_group_id = aws_security_group.vpn[count.index].id
	cidr_blocks       = [var.vpc_cidr]
	description       = "Allow HTTP traffic from VPN to VPC"
}

#######################################################
# OpenSearch
#######################################################

resource "aws_security_group" "opensearch" {
  count       = var.create_opensearch_sg ? 1 : 0
  name        = "OpenSearch"
  description = "Allow access to OpenSearch"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "OpenSearch"
  }, var.tags)
}

resource "aws_security_group_rule" "opensearch-vpn-ingress-opensearch-port" {
  count                    = var.create_opensearch_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 9200
  to_port                  = 9200
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opensearch[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow OpenSearch traffic from VPN"
}

resource "aws_security_group_rule" "opensearch-vpn-ingress-https-port" {
  count                    = var.create_opensearch_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opensearch[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow HTTPS traffic from VPN to OpenSearch"
}

resource "aws_security_group_rule" "opensearch-vpn-ingress-http-port" {
  count                    = var.create_opensearch_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opensearch[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow HTTP traffic from VPN to OpenSearch"
}

# tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group_rule" "opensearch-vpc-ingress" {
  count             = var.create_opensearch_sg ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.opensearch[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow HTTPS traffic from VPC to OpenSearch"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "opensearch-egress" {
  count             = var.create_opensearch_sg ? 1 : 0
  type              = "egress"
  from_port         = -1
  to_port           = -1
  protocol          = -1
  security_group_id = aws_security_group.opensearch[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from OpenSearch"
}

#######################################################
# Mongo Out
#######################################################

resource "aws_security_group" "backend-services" {
  count       = var.create_backend_services_sg ? 1 : 0
  name        = "Backend Services"
  description = "Allow access to backend services"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "Backend Services"
  }, var.tags)
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "backend-services-mongo" {
  count             = var.create_backend_services_sg ? 1 : 0
  type              = "egress"
  from_port         = 27017
  to_port           = 27017
  protocol          = "tcp"
  security_group_id = aws_security_group.backend-services[count.index].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow MongoDB traffic from Backend Services"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "backend-services-mqtt" {
  count             = var.create_backend_services_sg ? 1 : 0
  type              = "egress"
  from_port         = 2616
  to_port           = 2616
  protocol          = "tcp"
  security_group_id = aws_security_group.backend-services[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow MQTT traffic from Backend Services"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "backend-services-redis" {
  count             = var.create_backend_services_sg ? 1 : 0
  type              = "egress"
  from_port         = 6168
  to_port           = 6168
  protocol          = "tcp"
  security_group_id = aws_security_group.backend-services[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow Redis traffic from Backend Services"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "backend-services-elephants" {
  count             = var.create_backend_services_sg ? 1 : 0
  type              = "egress"
  from_port         = 43616
  to_port           = 43616
  protocol          = "tcp"
  security_group_id = aws_security_group.backend-services[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow Elephants traffic from Backend Services"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "backend-services-rds" {
  count             = var.create_backend_services_sg ? 1 : 0
  type              = "egress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.backend-services[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow RDS traffic from Backend Services"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "backend-services-redis-backups" {
  count             = var.create_backend_services_sg ? 1 : 0
  type              = "egress"
  from_port         = 6169
  to_port           = 6169
  protocol          = "tcp"
  security_group_id = aws_security_group.backend-services[count.index].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow Redis backup traffic from Backend Services"
}

#######################################################
# Lambda VPC Security Group
#######################################################

resource "aws_security_group" "lambda_sg" {
  count       = var.create_lambda_sg ? 1 : 0
  name        = "Lambda VPC"
  description = "Allow access to Lambda function"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "Lambda VPC"
  }, var.tags)
}

# tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group_rule" "lambda_sg_ingress_http" {
  count             = var.create_lambda_sg ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP traffic to Lambda"
}

# tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group_rule" "lambda_sg_ingress_https" {
  count             = var.create_lambda_sg ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.lambda_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS traffic to Lambda"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "lambda_sg_egress" {
  count             = var.create_lambda_sg ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.lambda_sg[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from Lambda"
}


#######################################################
# Create Jenkins & Jenkins Agents Security Group
####################################################### 


resource "aws_security_group" "jenkins_sg" {
  count       = var.create_jenkins_sg ? 1 : 0
  name        = "jenkins-security-group"
  description = "Allow access to Jenkins and agents"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "Shared-Service-Account VPC"
  }, var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "jenkins_sg_ingress_http" {
  count             = var.create_jenkins_sg ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_sg[0].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description       = "Allow HTTP traffic from ALB to Jenkins"
}

resource "aws_security_group_rule" "jenkins_sg_ingress_https" {
  count             = var.create_jenkins_sg ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_sg[0].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description       = "Allow HTTPS traffic from ALB to Jenkins"
}

resource "aws_security_group_rule" "jenkins_sg_ingress_ldap" {
  count             = var.create_jenkins_sg ? 1 : 0
  type              = "ingress"
  from_port         = 389
  to_port           = 389
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_sg[0].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description       = "Allow LDAP traffic from ALB to Jenkins"
}

resource "aws_security_group_rule" "jenkins_sg_ingress_custom" {
  count             = var.create_jenkins_sg ? 1 : 0
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_sg[0].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description       = "Allow custom traffic from ALB to Jenkins"
}

resource "aws_security_group_rule" "jenkins_sg_ingress_ssh" {
  count             = var.create_jenkins_sg ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.jenkins_sg[0].id
  cidr_blocks       = ["10.21.19.5/32"]
  description       = "Allow SSH traffic to Jenkins"
}

# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group_rule" "jenkins_sg_egress_all" {
  count             = var.create_jenkins_sg ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.jenkins_sg[0].id
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow all outbound traffic from Jenkins"
}

#######################################################
# Create OCG API & OCG Windows Security Group
####################################################### 


resource "aws_security_group" "ocg_api" {
  count       = var.create_ocg_sg ? 1 : 0
  name        = "ocg-api"
  description = "Allow access to OCG API"
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_security_group" "ocg_alb" {
  count       = var.create_ocg_sg ? 1 : 0
  name        = "ocg-alb"
  description = "Allow access to OCG ALB"
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_security_group" "ocg_windows" {
  count       = var.create_ocg_sg ? 1 : 0
  name        = "ocg-windows"
  description = "Allow access to OCG Windows"
  vpc_id      = var.vpc_id

  tags = var.tags
}

resource "aws_security_group_rule" "ocg_api_node" {
  count                    = var.create_ocg_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 21234
  to_port                  = 21234
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ocg_api[count.index].id
  source_security_group_id = aws_security_group.ocg_alb[count.index].id
  description              = "Allow OCG API node traffic from OCG ALB"
}

resource "aws_security_group_rule" "ocg_windows_rdp" {
  count                    = var.create_ocg_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 3389
  to_port                  = 3389
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ocg_windows[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow RDP traffic from VPN to OCG Windows"
}

resource "aws_security_group_rule" "ocg_windows_ingress_ssh" {
  count             = var.create_ocg_sg ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.ocg_windows[0].id
  cidr_blocks       = [var.reporting_cidr]
  description       = "Allow SSH traffic from reporting CIDR to OCG Windows"
}

resource "aws_security_group_rule" "ocg_alb_ingress_http" {
  count             = var.create_ocg_sg ? 1 : 0
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.ocg_alb[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP traffic from anywhere to OCG ALB"
}

resource "aws_security_group_rule" "ocg_alb_ingress_https" {
  count             = var.create_ocg_sg ? 1 : 0
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ocg_alb[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS traffic from anywhere to OCG ALB"
}

resource "aws_security_group_rule" "ocg_alb_egress_all" {
  count             = var.create_ocg_sg ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ocg_alb[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from OCG ALB"
}

resource "aws_security_group_rule" "ocg_api_egress_all" {
  count             = var.create_ocg_sg ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ocg_api[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from OCG API"
}

resource "aws_security_group_rule" "ocg_windows_egress_all" {
  count             = var.create_ocg_sg ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ocg_windows[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic from OCG Windows"
}

#######################################################
# Create OpenLDAP Security Group
#######################################################

resource "aws_security_group" "openldap" {
  count       = var.create_openldap_sg ? 1 : 0
  name        = "openldap"
  description = "Allow access to OpenLDAP"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.21.0.0/16"]
    description = "Allow all outbound traffic within VPC"
  }

  tags = var.tags
}

resource "aws_security_group_rule" "openldap_ingress_https" {
  count                    = var.create_openldap_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.openldap[0].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description              = "Allow HTTPS traffic from ALB to OpenLDAP"
}

resource "aws_security_group_rule" "openldap_ingress_http" {
  count                    = var.create_openldap_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.openldap[0].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description              = "Allow HTTP traffic from ALB to OpenLDAP"
}

resource "aws_security_group_rule" "openldap_ingress_ldap" {
  count                    = var.create_openldap_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 389
  to_port                  = 389
  protocol                 = "tcp"
  security_group_id        = aws_security_group.openldap[0].id
  source_security_group_id = aws_security_group.alb[count.index].id
  description              = "Allow LDAP traffic from ALB to OpenLDAP"
}


#######################################################
# JENKINS ALB SECURITY GROUP
#######################################################

#tfsec:ignore:aws-ec2-no-public-ingress-sgr
resource "aws_security_group" "jenkins-alb" {
  count       = var.create_alb_sg ? 1 : 0
  name        = "ALB-Jenkins"
  description = "Allow access to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow HTTPS traffic from anywhere"
  }

  tags = merge({
    Name = "ALB"
  }, var.tags)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "jenkins_alb_http_vpn" {
  count                    = var.create_alb_sg && var.create_vpn_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins-alb[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow HTTP traffic from VPN"
}

resource "aws_security_group_rule" "jenkins_alb_https_vpn" {
  count                    = var.create_alb_sg && var.create_vpn_sg ? 1 : 0
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins-alb[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow HTTPS traffic from VPN"
}

resource "aws_security_group_rule" "jenkins_alb_custom_vpn" {
  count                    = var.create_alb_sg && length(aws_security_group.vpn) > 0 ? 1 : 0
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.jenkins-alb[count.index].id
  source_security_group_id = aws_security_group.vpn[count.index].id
  description              = "Allow custom traffic from VPN"
}


#######################################################
# EKS Security Groups
#######################################################

resource "aws_security_group" "eks_cluster" {
  count       = var.create_eks_cluster_sg ? 1 : 0
  name        = "EKS-Cluster"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = "EKS-Cluster"
  }, var.tags)
}

resource "aws_security_group" "eks_nodes" {
  count       = var.create_eks_nodes_sg ? 1 : 0
  name        = "EKS-Nodes"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  tags = merge({
    Name =  "EKS-Nodes"
  }, var.tags)
}

# Cluster to node communication
resource "aws_security_group_rule" "cluster_inbound_https" {
  count                    = var.create_eks_cluster_sg && var.create_eks_nodes_sg ? 1 : 0
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster[0].id
  source_security_group_id = aws_security_group.eks_nodes[0].id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_inbound_http" {
  count                    = var.create_eks_cluster_sg && var.create_eks_nodes_sg ? 1 : 0
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster[0].id
  source_security_group_id = aws_security_group.eks_nodes[0].id
  to_port                  = 80
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_outbound" {
  count                    = var.create_eks_cluster_sg && var.create_eks_nodes_sg ? 1 : 0
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster[0].id
  source_security_group_id = aws_security_group.eks_nodes[0].id
  type                     = "egress"
}

# Node to cluster communication
resource "aws_security_group_rule" "nodes_cluster_outbound" {
  count                    = var.create_eks_nodes_sg && var.create_eks_cluster_sg ? 1 : 0
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes[0].id
  source_security_group_id = aws_security_group.eks_cluster[0].id
  to_port                  = 443
  type                     = "egress"
}

# Node to node communication
resource "aws_security_group_rule" "nodes_internal" {
  count             = var.create_eks_nodes_sg ? 1 : 0
  description       = "Allow nodes to communicate with each other"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes[0].id
  self              = true
  to_port           = 65535
  type              = "ingress"
}

# Optional: Allow SSH access to nodes from VPN
resource "aws_security_group_rule" "nodes_ssh_vpn" {
  count                    = var.create_eks_nodes_sg && var.create_vpn_sg ? 1 : 0
  description              = "Allow SSH access from VPN"
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes[0].id
  source_security_group_id = aws_security_group.vpn[0].id
  to_port                  = 22
  type                     = "ingress"
}

# Optional: Allow node egress to internet
resource "aws_security_group_rule" "nodes_egress_internet" {
  count             = var.create_eks_nodes_sg ? 1 : 0
  description       = "Allow nodes to access internet"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_nodes[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  to_port           = 0
  type              = "egress"
}