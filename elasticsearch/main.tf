terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.50.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 0.15, > 0.12"
}

#### Backend ###
## S3
################
terraform {
   backend "s3" {
     bucket          = "cloudgeeksca-backend-terraform"
     key             = "env/dev/cloudgeeks-dev.tfstate"
     region          = "us-east-1"
    # dynamodb_table = "cloudgeeksca-dev-terraform-backend-state-lock"
  }
}



# aws s3api create-bucket --bucket cloudgeeksca-backend-terraform --region us-east-1

# aws s3api put-bucket-versioning --bucket cloudgeeksca-backend-terraform --versioning-configuration Status=Enabled


#####
# Vpc
#####
module "vpc" {
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version = "3.18.0"

  name = "cloudgeeks-vpc"

  cidr             = "10.60.0.0/16"
  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.60.0.0/23", "10.60.2.0/23", "10.60.4.0/23"]
  public_subnets   = ["10.60.100.0/23", "10.60.102.0/24", "10.60.104.0/24"]
  database_subnets = ["10.60.200.0/24", "10.60.201.0/24", "10.60.202.0/24"]


  map_public_ip_on_launch = true
  enable_nat_gateway      = true
  single_nat_gateway      = true
  one_nat_gateway_per_az  = false

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false
  create_database_nat_gateway_route      = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}




##############
# EC2 Key Pair
##############
module "ec2-keypair" {
  source     = "./modules/aws-ec2-keypair"
  key-name   = "cloudgeeks"
  public-key = file("./modules/secrets/cloudgeeks.pub")
}


####################################
# SG RDS SecurityGroups - DBSecGroup
####################################
module "rds-sg" {
  source = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  name   = "DBSecGroup"
  vpc_id = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [

    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = 6
      description              = "Application Security Group Allowed"
      source_security_group_id = [module.ec2-sg-appsecgroup.security_group_id][0]
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = 6
      description = "All OutBound Allowed"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = 17
      description = "All OutBound Allowed"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}



# Allowed traffic from Application Load Balancer
module "ec2-sg-appsecgroup" {
  source = "registry.terraform.io/terraform-aws-modules/security-group/aws"
  name   = "AppSecGroup"
  vpc_id = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [

    {
      from_port                = 9200
      to_port                  = 9200
      protocol                 = 6
      description              = "Backend ALB Allowed"
      source_security_group_id = [module.backend-alb-sg.this_security_group_id][0]
    },
    {
      from_port                = 9300
      to_port                  = 9300
      protocol                 = 6
      description              = "Backend ALB Allowed Service Discovery"
      source_security_group_id = [module.backend-alb-sg.this_security_group_id][0]
    },
    {
      from_port                = 9200
      to_port                  = 9200
      protocol                 = 6
      description              = "Self Allowed for ElasticSearch"
      source_security_group_id = [module.ec2-sg-appsecgroup.security_group_id][0]
    },
    {
      from_port                = 9300
      to_port                  = 9300
      protocol                 = 6
      description              = "Self Allowed Service Discovery"
      source_security_group_id = [module.ec2-sg-appsecgroup.security_group_id][0]
    },
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = 6
      description              = "Backend ALB Allowed"
      source_security_group_id = [module.backend-alb-sg.this_security_group_id][0]
    },
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = 6
      description              = "Self Allowed"
      source_security_group_id = [module.ec2-sg-appsecgroup.security_group_id][0]
    },
    {
      from_port                = 443
      to_port                  = 443
      protocol                 = 6
      description              = "Backend ALB Allowed"
      source_security_group_id = [module.backend-alb-sg.this_security_group_id][0]
    }

  ]
  number_of_computed_ingress_with_source_security_group_id = 6
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = 6
      description = "All OutBound Allowed"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = 17
      description = "All OutBound Allowed"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

}




######################
# EC2 Instance Profile
######################
module "iam-instance-profile" {
  source                        = "./modules/aws-instance-profile"
  aws_iam_instance_profile_name = "elasticsearch"
  aws_iam_role_name             = "elasticsearch"
  # Custom policy attachment / Customer Managed policy
  custom-policy-name = "cloudgeeks-policy"
}





######################
# Private Hosted Zone  # Important: Note ---> Must update the USERDATA with PRIVATE HOSTED ID
######################
resource "aws_route53_zone" "cloudgeeks-private-hosted-zone" {
  name = "cloudgeeks.tk"
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  lifecycle {
    ignore_changes = [vpc]
  }
}

######################################
# Route53 Private Hosted Zone Entries
######################################

#################################
# ElasticSearch Cluster End Point
#################################
resource "aws_route53_record" "elastic-search-cluster-end-point" {
  zone_id = aws_route53_zone.cloudgeeks-private-hosted-zone.id
  name    = "elasticsearch-cluster"
  type    = "A"

  alias {
    name                   = module.alb-backend-elasticsearch.aws-alb-dns-name
    zone_id                = module.alb-backend-elasticsearch.aws-alb-hosted-zone-id
    evaluate_target_health = true
  }

  depends_on = [module.alb-backend-elasticsearch.aws-alb-dns-name]
}

###############################
# ElasticSearch Docker Cluster
###############################
# https://www.elastic.co/guide/en/elasticsearch/reference/current/high-availability-cluster-small-clusters.html      

# ENDPOINT='https://elasticsearch-cluster.cloudgeeks.tk'
      
# ENDPOINT='http://elasticsearch-node1.cloudgeeks.tk:9200'

# export ENDPOINT

# curl -X GET "${ENDPOINT}/_cluster/health?pretty"

# curl -X GET "${ENDPOINT}/_cat"

# curl -X GET "${ENDPOINT}/_cat/nodes?v"

# curl -X GET "${ENDPOINT}/_cat/indices?v"
      
################      
# Authentication
################     
# curl --user elastic:'cloudgeeks' -X GET "${ENDPOINT}/_cluster/health?pretty"

# curl  --user elastic:'cloudgeeks' -X GET "${ENDPOINT}/_cat"

# curl  --user elastic:'cloudgeeks' -X GET "${ENDPOINT}/_cat/nodes?v"

# curl  --user elastic:'cloudgeeks' -X GET "${ENDPOINT}/_cat/indices?v"      

############
# MetricBeat
############
# curl -X GET "${ENDPOINT}/_cat/indices"

# elasticsearch-cluster.cloudgeeks.tk	Alias dualstack.internal-backend-alb-elasticsearch-qa-397640293.us-east-1.elb.amazonaws.com.

# elasticsearch-node1.cloudgeeks.tk	A	Simple	-

# elasticsearch-node2.cloudgeeks.tk	A	Simple	-

# elasticsearch-node3.cloudgeeks.tk	A	Simple	-

# ES Health Checks

# curl -X GET "localhost:9200/_cluster/health?pretty"

# curl -X GET "elasticsearch-cluster.cloudgeeks.tk/_cluster/health?pretty"

#####################################################
# BackEnd Application Load Balancer for ElasticSearch
######################################################

module "alb-backend-elasticsearch" {
  source                           = "./modules/aws-alb"
  alb-name                         = "Backend-Alb-ElasticSearch"
  internal                         = true
  alb-sg                           = module.backend-alb-sg.this_security_group_id
  alb-subnets                      = module.vpc.private_subnets
  alb-tag                          = "Backend-Alb-ElasticSearch"
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = true
  enable_http2                     = true
}


##################################################
# BackEnd Application Load Balancer Security Group
##################################################

module "backend-alb-sg" {
  source              = "./modules/aws-sg-dynamic-ipv4"
  security-group-name = "BackEnd-Alb-Sg"
  vpc-id              = module.vpc.vpc_id
  sg-description      = "Backend Application Load Balancer Security Group dev Environment"

  sg_ingress = {

    "internal-cidr-port-80" = {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["10.60.0.0/16"]
    },
    "internal-cidr-port-443" = {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["10.60.0.0/16"]
    },
    "backend-alb-openvpn-allowed" = {
      port        = 0
      protocol    = "-1"
      cidr_blocks = ["10.60.0.0/16"]
    }

  }

}




#######################
# Target Group Default
#######################
resource "aws_lb_target_group" "backend_default-elasticsearch-tg" {
  name     = "backend-default-elasticsearch-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}


##################################
# Target Group ElasticSearch Nodes
##################################
resource "aws_lb_target_group" "elastic-search-nodes" {
  name = "elastic-search-nodes"
  #  target_type  = "ip"
  port     = 9200
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  ##############
  # Health Check
  ##############
  health_check {
    interval = "30"
    path     = "/"
    #  port                = "80"  ---> default traffic-port
    protocol            = "HTTP"
    timeout             = "25"
    healthy_threshold   = "2"
    unhealthy_threshold = "3"
    matcher             = "200"
  }

  deregistration_delay = "360"
}




################
# HTTP Listeners
################
resource "aws_lb_listener" "backend_alb_elasticsearch_http" {
  load_balancer_arn = module.alb-backend-elasticsearch.aws-alb-arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


#################
# HTTPS Listeners
#################
resource "aws_lb_listener" "https" {
  load_balancer_arn                   = module.alb-backend-elasticsearch.aws-alb-arn
  port                                = "443"
  protocol                            = "HTTPS"
  ssl_policy                          = "ELBSecurityPolicy-2016-08"
  # DNS Verified ACM ARN Required
  certificate_arn                     = "arn:aws:acm:us-east-1:611812404044:certificate/067e6a91-0c95-4282-b640-060c1b48ce5a"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_default-elasticsearch-tg.arn
  }
}


#####################
# Https Listener Rule
#####################
resource "aws_alb_listener_rule" "https-listener" {
  listener_arn = aws_lb_listener.https.arn
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.elastic-search-nodes.arn
  }
  condition {
    host_header {
      values = ["elasticsearch-cluster.cloudgeeks.tk"]
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  priority = 1
}

  
######################
# Cloudwatch Log Group
######################
resource "aws_cloudwatch_log_group" "aws-cloudwatch-log-group-cloudgeeks" {
  name = "elasticsearch"
  tags = {
    Environment = "dev"
    Application = "ElasticSearch Cluster"
  }

}
