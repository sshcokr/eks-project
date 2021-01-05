---
Deploy prometheus
---
### 2. Prometheus 설치

2-1. Repo 설정

- 2-1-1. Repo 추가

  `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`

- 2-1-2. Repo 업데이트

  `helm repo update`

2-2. Prometheus 배포

- 2-2-1. [github](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml)
에서 values.yaml 다운로드

- 2-2-2. 커스터 마이징 후 Install

  ```bash
  helm install prometheus prometheus-community/prometheus -f values.yaml \
  --namespace monitoring
  ```

2-3. 접속 확인

- 2-3-1. Pod의 주소 노출

  ```bash
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}")

  kubectl --namespace monitoring port-forward $POD_NAME 9090
  ```