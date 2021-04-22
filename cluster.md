# cluster

#### minikube
```
brew install minikube
```

```
minikube config set driver hyperkit
```

```
ssh docker@$(minikube ip) -i $HOME/.minikube/machines/minikube/id_rsa -v
```

```
minikube start
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
```shell
export PROJECT_NAME='project'
export SERVICE_ACCOUNT='service-account@project.iam.gserviceaccount.com'
export KEY_FILE="$HOME/.key.json"
export REGION='europe-north1' 		# gcloud compute regions list
export ZONE='europe-north1-c' 		# gcloud compute zones list
export MACHINE_TYPE='n1-standard-8' 	# gcloud compute machine-types list --zones=$ZONE
```

```
gcloud components update
```

```
gcloud auth login --no-launch-browser
```

```
gcloud config set project $PROJECT_NAME
```

```
gcloud config set account $SERVICE_ACCOUNT
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
