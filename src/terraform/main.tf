provider "aws" {
  profile = "terraform-operator"
  region = "eu-central-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

output "AZs" {
  value = data.aws_availability_zones.available.names
  description = "list of AWS availability Zones within my region"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.10.0"
  # insert the 21 required variables here
  name = "vpc-awesome"
  cidr = "10.0.0.0/16"
  azs = data.aws_availability_zones.available.names
  public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_dns_support = true # useful for the Ingress
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/awesome" = "shared"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.22.0"
  
  # insert the 7 required variables here
  cluster_name = "awesome"
  cluster_version = "1.21"
  subnets = module.vpc.public_subnets
  vpc_id = module.vpc.vpc_id
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  map_users = var.map_users

  # worker nodes
  worker_groups_launch_template = [
    {
      name                 = "worker-group-1"
      instance_type        = "t2.micro"
      asg_min_size         = 2
      asg_desired_capacity = 2
      asg_max_size         = 5
      autoscaling_enabled  = true
      public_ip            = true
    }
  ]
}
