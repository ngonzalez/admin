# admin
![Webinar_K8S101_K8slogo-1](https://user-images.githubusercontent.com/26479/113612862-aaadd080-9650-11eb-83db-7a3103293c3c.png)

#### create namespace, deployment and service

⚠️ Coredns

```
kubectl apply -f configmap/coredns.yaml
```

⚠️ Admin user

```
kubectl apply -f service-account/admin-user.yaml
kubectl apply -f service-account/cluster-admin.yaml
```

⚠️ Generate token

```
kubectl -n kubernetes-dashboard create token admin-user
```
