---
Deploy grafana
---
### 3. Grafana 설치

3-1. Repo 설정

- 3-1-1. Grafana Repo 추가

  `helm repo add grafana https://grafana.github.io/helm-charts`

- 3-1-2. Repo 업데이트

  `helm repo update`

3-2. Grafana 배포

- 3-2-1. [github](https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml)
에서 values.yaml 다운로드

- 3-2-2. 커스터 마이징 후 Install

  ```bash
  helm install grafana grafana/grafana -f values.yaml \
  --namespace monitoring
  ```

3-3. 접속 확인

- 3-3-1. Pod의 주소 노출

  ```bash
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 3000
  ```

- 3-3-2. admin 초기 패스워드 확인

  ```bash
  kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
  ```
