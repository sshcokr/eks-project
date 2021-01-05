### 1. Nginx-Ingress-Controller 설치

1-1. Repo 설정

- 1-1-1. Repo 추가

  `helm add repo ingress-nginx https://kubernetes.github.io/ingress-nginx`

- 1-1-2. helm repo 업데이트

1-2. Nginx-Ingress-Controller 설치

- 1-2-1. [github](https://github.com/kubernetes/ingress-nginx/blob/master/charts/ingress-nginx/values.yaml)에서 values.yaml 다운로드

- 1-2-2. 커스터 마이징 후 Deploy

  ```bash
  helm install ingress-nginx ingress-nginx/ingress-nginx -f values.yaml -- namespace nginx
  ```

1-3. Deploy 확인

- 1-3-1. 확인

  ```bash
  $ kubectl get pod -n nginx
  -------------------------------
  NAME                                        READY   STATUS    RESTARTS   AGE
  ingress-nginx-controller-777d688cbf-w5ldh   1/1     Running   0          172m
  ```