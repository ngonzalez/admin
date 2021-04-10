# admin

![Webinar_K8S101_K8slogo-1](https://user-images.githubusercontent.com/26479/113612862-aaadd080-9650-11eb-83db-7a3103293c3c.png)

#### minikube
```
brew install minikube
```

```
minikube dashboard
```

```
minikube tunnel
```

```
kubectl proxy --port=8080 &
```

#### gcloud
```
gcloud components update
```

```
gcloud auth login --no-launch-browser
```

```
gcloud config set account $SERVICE_ACCOUNT
```

```
gcloud config set project $PROJECT_NAME
```

#### create cluster
```
gcloud container clusters create $CLUSTER_NAME \
	--zone $ZONE \
	--machine-type $MACHINE_TYPE \
	--num-nodes 1
```

#### get credentials
```
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_NAME
```

#### list addresses for LoadBalancer
```
gcloud compute addresses list $CLUSTER_NAME
```

#### create address for LoadBalancer
```
gcloud compute addresses create $CLUSTER_NAME --region $REGION
```

#### create namespace, deployment and service
```
kubectl apply -f namespace.yaml
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

#### ssh into pod
```
gcloud compute ssh --zone $ZONE <NODE> --project $PROJECT_NAME --container=<POD>
```

```
ssh -J <GCLOUD_USER>@<NODE_EXTERNAL_IP> <USER>@<POD_IP>
```

```
ssh -o ProxyCommand='ssh -W %h:%p <GCLOUD_USER>@<NODE_EXTERNAL_IP>' <USER>@<POD_IP>
```
