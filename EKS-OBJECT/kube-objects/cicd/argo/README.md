---
Deploy ArgoCD
---
### 1. Argo 설치 (Helm)

1-1. Argo 설치

- 1-1-1. argo Repo 추가

  `helm repo add argo https://argoproj.github.io/argo-helm`

- 1-1-2. helm repo 업데이트

  `helm repo update`

- 1-1-3. [github](https://github.com/argoproj/argo-helm/blob/master/charts/argo-cd/values.yaml)
에서 value.yml 다운로드

- 1-1-4. 커스터 마이징 후 Install

    ```bash
    helm install argo argo/argo-cd -f values.yaml \
    --namespace cicd
    ```
1-2. 접속 확인

- 1-2-1. admin 초기 패스워드 확인

  - admin의 초기 비밀번호는 생성된 argo pod의 이름이다.

    ```bash
    kubectl get pods -n cicd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
    ```

- 1-2-2. 접속 URL 확인

  - Private Subnet에 Argo를 Deploy 했으므로 LoadBalancer의 Type을 확인해야한다.

    `kubectl get svc -n cicd`
