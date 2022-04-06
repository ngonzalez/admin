# admin
![Webinar_K8S101_K8slogo-1](https://user-images.githubusercontent.com/26479/113612862-aaadd080-9650-11eb-83db-7a3103293c3c.png)

#### create namespace, deployment and service

⚠️ Common

```
kubectl apply -f namespaces/k8s.yaml
```

⚠️ Database service

```
kubectl apply -f deploy/database.yaml
kubectl apply -f service/database.yaml
```

⚠️ Backend service

```
kubectl apply -f deploy/backend.yaml
kubectl apply -f service/backend.yaml
```

⚠️ Frontend service

```
kubectl apply -f deploy/frontend.yaml
kubectl apply -f service/frontend.yaml
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
