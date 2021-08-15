# admin

⚠️ Please follow these links for the changes related to ___app___ and ___db___ clusters:
 * https://github.com/ngonzalez/admin/tree/app
 * https://github.com/ngonzalez/admin/tree/db

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
```

#### detailed informations
```
kubectl -n $NAMESPACE describe deployments
kubectl -n $NAMESPACE describe nodes
kubectl -n $NAMESPACE describe pods
kubectl -n $NAMESPACE describe services
```

📎 See also: [docker-instructions.md](https://github.com/ngonzalez/docker-instructions)
