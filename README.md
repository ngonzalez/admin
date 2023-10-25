# admin
![logo](https://user-images.githubusercontent.com/26479/113612862-aaadd080-9650-11eb-83db-7a3103293c3c.png)

#### create namespace, deployment and service

⚠️ Coredns

```shell
kubectl apply -f configmap/coredns.yaml
```

⚠️ Admin user

```shell
kubectl apply -f service-account/admin-user.yaml
kubectl apply -f service-account/cluster-admin.yaml
```

⚠️ Generate token

```shell
kubectl -n kubernetes-dashboard create token admin-user
```

⚠️ Namespace

```shell
kubectl apply -f namespace/development.yaml
```

⚠️ Deployment

```shell
kubectl apply -f deploy/demodb.yaml
kubectl apply -f deploy/demoredis.yaml
kubectl apply -f deploy/demoappbackend.yaml
```

⚠️ Service

```shell
kubectl apply -f service/demodb.yaml
kubectl apply -f service/demoredis.yaml
kubectl apply -f service/demoappbackend.yaml
```
