---
Deploy Jenkins
---
### 2. Jenkins 설치 (Helm)

2-1. Helm 설치

- 2-1-1. Stable Repo 추가

  `helm repo add jenkins https://charts.jenkins.io`

- 2-1-2. helm repo 업데이트

  `helm repo update`

2-2. Jenkins 설치

- 2-2-1. [github](https://github.com/jenkinsci/helm-charts/blob/main/charts/jenkins/values.yaml)
에서 values.yaml 다운로드

  - [Customizing Values](https://github.com/jenkinsci/helm-charts/blob/main/charts/jenkins/VALUES_SUMMARY.md)

- 2-2-2. 커스터마이징 후 Deploy

  ```
  helm install jenkins stable/jenkins -f values.yaml \
  --set persistence.existingClaim=false \
  --set master.serviceType=LoadBalancer \
  --namespace cicd
  ```

2-3. 접속 확인

- 2-3-1. admin 초기 패스워드 확인

  ```bash
  printf $(kubectl get secret --namespace cicd jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
  ```

- 2-3-2. 접속 URL 확인

  - Private Subnet에 Jenkins를 Deploy 했으므로 LoadBalancer의 Type을 확인해야한다.

  `kubectl get svc -n cicd`

- 2-3-3. 접속 확인