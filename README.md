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
kubectl -n $NAMESPACE get deployments -o wide
kubectl -n $NAMESPACE get nodes -o wide
kubectl -n $NAMESPACE get pods -o wide
kubectl -n $NAMESPACE get services -o wide
kubectl -n $NAMESPACE get endpoints -o wide
```

#### detailed informations
```
kubectl -n $NAMESPACE describe deployments
kubectl -n $NAMESPACE describe nodes
kubectl -n $NAMESPACE describe pods
kubectl -n $NAMESPACE describe services
```

See also: [cluster.md](https://github.com/ngonzalez/admin/blob/main/cluster.md)
