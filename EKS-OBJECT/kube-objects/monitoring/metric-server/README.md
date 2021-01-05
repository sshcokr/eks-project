---
Deploy metric-server
---
### 1. Metrics-server 설치

- 대부분의 모니터링 도구에 필요한 메트릭 서버이다. 필수로 설치하자.

1-1. Repo 설정

- 1-1-1. Repo 추가

  `helm repo add stable https://charts.helm.sh/stable`

- 1-1-2. Repo 업데이트

  `helm repo update`

1-2. Metrics-server 배포

- 1-2-1. [github](https://github.com/helm/charts/blob/master/stable/metrics-server/values.yaml)
에서 values.yaml 다운로드

- 1-2-2. 커스터 마이징 후 Install

  ```bash
  helm install metrics-server stable/metrics-server -f values.yaml \
  --namespace monitoring
  ```

1-3. 확인

- 1-3-1. node의 cpu, memory, disk 확인

  `kubectl top node`

- 1-3-2. pod들 의 cpu, memory, disk 확인

  `kubectl top pod`