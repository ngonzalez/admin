# cluster

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
minikube ssh
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
