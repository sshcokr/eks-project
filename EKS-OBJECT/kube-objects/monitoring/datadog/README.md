---
Deploy Datadog
---
### 0. 선행사항

- [Datadog](https://www.datadoghq.com/) 회원가입

    ⇒ 회원가입 후 나오는 API Key 필요

### 1. Installing Agent

- 1-1. `monitoring` 네임스페이스 추가

  `kubectl create ns monitoring`

1-2. Repo 설정

- 1-2-1. 관련 Repo 추가

  `helm repo add datadog https://helm.datadoghq.com`

- 1-2-2. Repo Update

  `helm repo update`

1-3. Datadog Agent 배포

- 1-3-1. [github](https://github.com/DataDog/helm-charts/blob/master/charts/datadog/values.yaml)
에서 values.yaml 복사

- 1-3-2. 배포 시 자신의 API-KEY 넣고 Deploy

  - API-KEY는 Datadog 사이트에서 확인가능

  ```bash
  helm install datadog -f values.yaml --set datadog.site='[datadoghq.com](http://datadoghq.com/)' --set datadog.apiKey=<DATADOG-API-KEY> datadog/datadog
  ```