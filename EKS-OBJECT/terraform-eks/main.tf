###################  Create VPC   ###################
module "vpc" {
  source = "git::https://github.com/SeungHyeonShin/terraform.git//modules/eks-vpc?ref=v1.2.0"

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
module "eks" {
  source          = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v12.1.0"
  cluster_name    = local.cluster_name
  vpc_id          = module.vpc.aws_vpc_id
  subnets         = module.vpc.private_subnets
  cluster_version = "1.18"

  # This is Important to Use K8S Objects Module's config_path
  write_kubeconfig = true
  config_output_path = pathexpand("~/.kube/kubeconfig_${local.cluster_name}")

  node_groups = [
    {
      name                = "on-demand-1"
      instance_type       = "m4.large"
      asg_max_size        = 3
      key_name         = aws_key_pair.seunghyeon-eks.key_name
      kubelet_extra_args  = "--node-labels=spot=false"
      suspended_processes = ["AZRebalance"]
      additional_tags = {
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
      override_instance_types = ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]
      spot_instance_pools     = 5
      asg_max_size            = 5
      asg_desired_capacity    = 1
      key_name         = aws_key_pair.seunghyeon-eks.key_name
      kubelet_extra_args      = "--node-labels=node.kubernetes.io/lifecycle=spot"
      additional_tags = {
        "k8s.io/cluster-autoscaler/enabled" = "true"
      }

      source_security_group_ids = [
        aws_security_group.seunghyeon-bastion-sg.id
      ]
    }
  ]
  manage_aws_auth = false
}

############   Create Bastion Host   ################
resource "aws_security_group" "seunghyeon-bastion-sg" {
  name = "seunghyeon-bastion"
  vpc_id = module.vpc.aws_vpc_id

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = var.my-ip-address
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
  key_name = aws_key_pair.seunghyeon-bastion.id
  vpc_security_group_ids = [
    aws_security_group.seunghyeon-bastion-sg.id
  ]

  tags = {
    "Name" = "seunghyeon-EKS-bastionHost"
  }
}

############   Local Variable  ######################
locals {
  cluster_name = "seunghyeon-eks-cluster"
  region       = "ap-northeast-2"
}

############   K8S Objects Modules ###################
module "k8s" {
  source = "git::https://github.com/SeungHyeonShin/k8s-terraform-modules.git//kube-object?ref=v1.1.0"
  config_path = "~/.kube/kubeconfig_${local.cluster_name}"

  node-handler-path = "../kube-objects/node-handler/values.yaml"
  jenkins-path = "../kube-objects/cicd/jenkins/values.yaml"
  argo-path = "../kube-objects/cicd/argo/values.yaml"
  nginx-path = "../kube-objects/nginx-controller/values.yaml"
  metric-path = "../kube-objects/monitoring/metric-server/values.yaml"
  prometheus-path = "../kube-objects/monitoring/prometheus/values.yaml"
  grafana-path = "../kube-objects/monitoring/grafana/values.yaml"
}