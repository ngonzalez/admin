# admin

![Webinar_K8S101_K8slogo-1](https://user-images.githubusercontent.com/26479/113612862-aaadd080-9650-11eb-83db-7a3103293c3c.png)

#### create namespace, deployment and service
```
kubectl apply -f namespaces/$NAMESPACE.yaml
kubectl apply -f deploy/$CLUSTER_NAME.yaml
kubectl apply -f service/$CLUSTER_NAME.yaml
```

#### get informations
```
kubectl -n $NAMESPACE get deployments -A -o wide
kubectl -n $NAMESPACE get no -A -o wide
kubectl -n $NAMESPACE get po -A -o wide
kubectl -n $NAMESPACE get svc -A -o wide
kubectl -n $NAMESPACE get endpoints -A -o wide
```

#### detailed informations
```
kubectl -n $NAMESPACE describe deployments
kubectl -n $NAMESPACE describe nodes
kubectl -n $NAMESPACE describe pods
kubectl -n $NAMESPACE describe services
```
