# kubernetes
export NAMESPACE='hebe'
export CLUSTER_NAME='app'

# gcp
export PROJECT_NAME='project'
export SERVICE_ACCOUNT='service-account@project.iam.gserviceaccount.com'
export KEY_FILE="$HOME/.key.json"
export REGION='europe-north1' # gcloud compute regions list
export ZONE='europe-north1-c' # gcloud compute zones list
export MACHINE_TYPE='n1-standard-8' # gcloud compute machine-types list --zones=$ZONE
