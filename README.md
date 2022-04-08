# admin
![Webinar_K8S101_K8slogo-1](https://user-images.githubusercontent.com/26479/113612862-aaadd080-9650-11eb-83db-7a3103293c3c.png)

#### create namespace, deployment and service

⚠️ Common

```
kubectl apply -f namespaces/k8s.yaml
```

⚠️ Storage

```
kubectl apply -f storage/storage-class.yaml
kubectl apply -f storage/persistent-volume.yaml
kubectl apply -f storage/persistent-volume-claim.yaml
```

⚠️ Database service

```
kubectl apply -f deploy/database.yaml
kubectl apply -f service/database.yaml
```

⚠️ App service

```
kubectl apply -f deploy/app.yaml
kubectl apply -f service/app.yaml
```

#### kubectl get informations

```
kubectl get configmaps -A -o wide
kubectl get daemonsets -A -o wide
kubectl get endpoints -A -o wide
kubectl get deployments -A -o wide
```

```
kubectl get no -A -o wide
kubectl get po -A -o wide
kubectl get svc -A -o wide
```
