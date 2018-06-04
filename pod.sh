#!/bin/bash

export PROJECT_ID="$(gcloud config get-value project -q)"
gcloud config set compute/zone us-central1-b

CLUSTER_NAME="jupyter"
GIT_REGISTRY="https://github.com/denisdevel/jupyter-googledrive"

if [[ -z $1 || -z $2 ]]; then
        echo "use pod.sh <project name> run update delete"
        exit 1
else
        case "$2" in
        "run")
                echo "starting new pod $1"
                rm -rf $1
                git clone $GIT_REGISTRY
                cd $1/
                docker build -t gcr.io/${PROJECT_ID}/$1:latest .
                gcloud docker -- push gcr.io/${PROJECT_ID}/$1:latest
                gcloud container clusters get-credentials $CLUSTER_NAME
                kubectl run $1 --image=gcr.io/${PROJECT_ID}/$1:latest --port 8888
                kubectl expose deployment $1 --type=LoadBalancer --port 8888 --target-port 8888
        ;;
        "update")
                echo "updating pod $1 image"
                cd $1/
                git fetch
                docker build -t gcr.io/${PROJECT_ID}/$1:latest .
                gcloud docker -- push gcr.io/${PROJECT_ID}/$1:latest
                gcloud container clusters get-credentials $CLUSTER_NAME
                kubectl set image deployment/$1 $1=$1:latest
        ;;
        "delete")
                echo "deleting $1 deployment"
                kubectl delete deployment $1
        ;;
        *)
                echo "Unknown parameter. Use run or update"
        ;;
        esac
fi
