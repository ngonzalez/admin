# admin

![Webinar_K8S101_K8slogo-1](https://user-images.githubusercontent.com/26479/113612862-aaadd080-9650-11eb-83db-7a3103293c3c.png)

#### create namespace, deployment and service
```
kubectl apply -f namespaces/$NAMESPACE.yaml
kubectl apply -f deploy/$CLUSTER_NAME.yaml
kubectl apply -f service/$CLUSTER_NAME.yaml
kubectl apply -f ingress/$CLUSTER_NAME.yaml
```

#### get informations
```
kubectl get configmaps -A -o wide
kubectl get deployments -A -o wide
kubectl get daemonsets -A -o wide
kubectl get no -A -o wide
kubectl get po -A -o wide
kubectl get svc -A -o wide
kubectl get endpoints -A -o wide
kubectl get ing -A -o wide
```

#### detailed informations
```
kubectl -n $NAMESPACE describe deployments
kubectl -n $NAMESPACE describe nodes
kubectl -n $NAMESPACE describe pods
kubectl -n $NAMESPACE describe services
kubectl -n $NAMESPACE describe ing
```

kubectl patch svc app-loadbalancer -n k8s -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.17.0.100"]}}'
kubectl patch svc database-loadbalancer -n k8s -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.17.0.101"]}}'
kubectl patch svc nginx-ingress -n nginx-ingress -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.17.0.102"]}}'
