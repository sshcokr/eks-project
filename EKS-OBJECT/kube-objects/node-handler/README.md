### 2. Node Termination Handler 설치

2-1. Repo 설정

- 2-1-1. Repo 추가
  
  `helm repo add eks https://aws.github.io/eks-charts`

- 2-1-2. helm repo 업데이트

  `helm repo update`

2-2. Node Termination Handler 설치

- 2-2-1. [github](https://github.com/aws/aws-node-termination-handler/blob/main/config/helm/aws-node-termination-handler/values.yaml)에서 values.yaml 다운로드

- 2-2-2. 커스터 마이징 후 Install

  ```bash
  helm install aws-node-termination-handler eks/aws-node-termination-handler -f values.yaml \
  --namespace cluster
  ```