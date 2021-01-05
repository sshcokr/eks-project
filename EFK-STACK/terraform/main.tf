############   Local Variable  ######################
# 로컬변수입니다. 클러스터의 이름과 배스천 호스트에 접속가능한 IP대역을 설정해주세요.
locals {
  cluster_name = "seunghyeon-eks"
  region       = "ap-northeast-2"
  bastion-con-ip = ["0.0.0.0/0"]
}

###################  Create VPC   ###################
module "vpc" {
  source = "git::https://github.com/SeungHyeonShin/terraform.git//modules/eks-vpc?ref=v1.3.0"

  aws_vpc_cidr        = "192.168.0.0/16"
  aws_private_subnets = ["192.168.1.0/24", "192.168.2.0/24"]
  aws_public_subnets  = ["192.168.11.0/24", "192.168.12.0/24"]
  aws_region          = local.region
  aws_azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  aws_default_name    = "seunghyeon"
  global_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

###################  Create EKS   ###################
# EKS 클러스터를 프로비저닝합니다.
# 비용절감을 위해 On-Demand 노드 하나, Spot-Instance 노드 하나로 구성합니다.
module "eks" {
  source          = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v13.2.1"
  cluster_name    = local.cluster_name
  vpc_id          = module.vpc.aws_vpc_id
  subnets         = module.vpc.private_subnets
  cluster_version = "1.18"
  manage_aws_auth = false

  # EKS Cluster의 보안그룹을 추가시킴
  worker_security_group_id = module.eks.cluster_security_group_id

# This is Important to Use K8S Objects Module's config_path
  write_kubeconfig = true
  config_output_path = pathexpand("~/.kube/kubeconfig_${local.cluster_name}")

  node_groups = [
    {
      name                = "on-demand-1"
      instance_type       = "t3.medium"
      asg_max_size        = 3
      key_name            = aws_key_pair.shin-eks.key_name
      kubelet_extra_args  = "--node-labels=spot=false"
      suspended_processes = ["AZRebalance"]
      additional_tags     = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
      }

      source_security_group_ids = [
        aws_security_group.seunghyeon-bastion-sg.id
      ]
    }
  ]

  worker_groups_launch_template = [
    {
      name                    = "spot-1"
      override_instance_types = ["t3.medium", "t3a.medium"]
      spot_instance_pools     = 5
      asg_max_size            = 5
      asg_desired_capacity    = 1
      key_name                = aws_key_pair.shin-eks.key_name
      kubelet_extra_args      = "--node-labels=node.kubernetes.io/lifecycle=spot"

      # EKS Cluster의 보안그룹을 추가시킴
      additional_security_group_ids = [module.eks.cluster_primary_security_group_id]
      additional_tags = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
      }

      source_security_group_ids = [
        aws_security_group.seunghyeon-bastion-sg.id
      ]
    }
  ]
}



############ Upload  Key Pair ##############
resource "aws_key_pair" "shin-eks" {
  key_name = "shin-eks"
  public_key = file("~/.ssh/project/shin-eks.pub")
}

resource "aws_key_pair" "shin-eks-bastion" {
  key_name = "shin-eks-bastion"
  public_key = file("~/.ssh/project/shin-eks-bastion.pub")
}

############   Create Bastion Host   ################
resource "aws_security_group" "seunghyeon-bastion-sg" {
  name = "seunghyeon-bastion"
  vpc_id = module.vpc.aws_vpc_id

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = local.bastion-con-ip
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "seunghyeon-EKS-bastion-sg"
  }
}
resource "aws_instance" "bastion" {
  ami = "ami-027ce4ce0590e3c98"
  instance_type = "t2.micro"
  subnet_id = element(module.vpc.public_subnets, 0)
  key_name = aws_key_pair.shin-eks-bastion.key_name
  vpc_security_group_ids = [
    aws_security_group.seunghyeon-bastion-sg.id
  ]

  tags = {
    "Name" = "seunghyeon-EKS-bastionHost"
  }
}

