# EKS 클러스터 생성 후 K8S 필수 오브젝트 생성
EKS 클러스터를 Terraform으로 생성 후 필수 K8S 오브젝트들을 Terraforming후 모듈로 가져와서 바로 오브젝트들을 배치합니다.

## EKS Cluster Setting
---
EKS를 생성 시 두 가지 종류의 그룹이 있는데 바로 worker_group과 node_group입니다.
이 두가지의 차이점은 관리의 차이점입니다. worker_group으로 생성하게 되면 사용자가 워커노드를 관리를 하게 되지만 반면 node_group으로 생성하게 되면 aws_managed로 ASG가 생성이 되고 해당 ASG에는 워커노드인 EC2가 생성이 되게 됩니다. 

aws_managed라고 해서 추가비용이 있거나 하진 않고 따로 프로비저닝한 AWS 리소스에 대해서만 비용을 지불하면 됩니다. (EC2, EBS, 기타 AWS인프라 ...)
따라서 저는 관리의 용의성을 위해 `node_groups`으로 eks 클러스터를 생성하였습니다. `worker_groups`로 생성하고 싶다면 [github](https://github.com/terraform-aws-modules/terraform-aws-eks)를 참조하여 커스터마이징 하시면 됩니다.

  - node_group에 대한 자세한 내용은 [amazon 공식 docs](https://docs.aws.amazon.com/eks/latest/userguide/managed-node-groups.html)를 참조 바랍니다.

또한 비용을 줄이기 위해 Spot Instance를 사용합니다. Spot Instance 설정은 eks 모듈 공식 [github](https://github.com/terraform-aws-modules/terraform-aws-eks)에서 설정을 참조하였고 2개의 인스턴스가 생성이 됩니다. 1개는 On-Demand, 나머지 1개는 Spot Instance입니다.
그러다가 부하가 많아지면 최대 8개의 워커노드가 생성이 됩니다.
  - On-Demand: m4.large
    - asg_max_size: 3
  - Spot-1: ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]
    - asg_max_size: 5

# Issue (20.11.04) 
- K8S Module
  - 현재 `terraform apply` 명령어로 코드를 실행 시키면 K8S Module은 프로비저닝이 안되는 에러가 발생한다. 물론 한번 더 apply를 하면 정상적으로 작동하긴 하지만 apply 한번에 모든 리소스를 생성하고 싶은 욕구가 안채워져서 이 부분은 해결방법을 찾아서 업데이트 하겠다.

### Usage example
```
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
      kubelet_extra_args  = "--node-labels=spot=false"
      suspended_processes = ["AZRebalance"]

      tags = {
        "Key" = "Name"
        "Value" = "Worker-Node_On-Demand"
      }
    }
  ]
  worker_groups_launch_template = [
    {
      name                    = "spot-1"
      override_instance_types = ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]
      spot_instance_pools     = 5
      asg_max_size            = 5
      asg_desired_capacity    = 1
      kubelet_extra_args      = "--node-labels=node.kubernetes.io/lifecycle=spot"
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
```

**terraform apply**
```
terraform init
terraform apply
    #k8s 모듈에서 에러발생 후 다시 
terraform apply
```

**terraform destroy**
```
terraform destroy -target module.k8s 
    #k8s 모듈을 선제적으로 지워줘야 한다.
terraform destroy
```

### Next Steps
- Nat Instance 생성
  - 현재 VPC 모듈로 VPC를 구성하는데 AWS Managed인 Nat Gateway로 Nat를 사용하게 된다. 하지만 이 방법으로 구성하게 되면 비용적인 이슈가 발생한다. (비싼걸로 알고 있음) 따라서 Bastion Host에 Nat기능을 추가하여 Bastion Host를 Nat Gateway처럼 사용하게 하려고 [해당링크](https://blog.2dal.com/2018/12/31/nat-gateway-to-nat-instance/)를 참조해서 버전업을 하려고 함. 
- Spot Instance에 대한 테스트
  - 현재 Node Termination Handler를 설치를 하게끔 하였지만 이게 실제로 동작을 하는지는 미지수이다. 확실하게 테스팅을 하여서 정상적으로 동작이 하는지 테스팅할 예정이다.
- 비용 테스트
  - 현재 워커그룹을 On-Demand 하나, Spot Instance 하나로 구성하였는데 Spot Instance로 실습을 해본것은 처음이라서 이게 실제로 얼마나 비용절감이 되는지도 모르겠고 Spot Instance는 실제 인스턴스의 소유자가 요청을 하면 다시 회수가 된다고 알고 있는데 이게 어떻게 돌아가는지 직접 눈으로 확인해보고 싶다.
  
  
[![HitCount](http://hits.dwyl.com/SeungHyeonShin/eks-project.svg)](http://hits.dwyl.com/SeungHyeonShin/eks-project)
