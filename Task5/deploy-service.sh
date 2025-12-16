#!/bin/bash

echo "Deploy..."

kubectl create namespace my-namespace --dry-run=client -o yaml | kubectl apply -f -

kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80 -n my-namespace
kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80 -n my-namespace
kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80 -n my-namespace
kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80 -n my-namespace

echo "Waiting..."
kubectl wait --for=condition=Ready pod -l role=front-end -n my-namespace --timeout=60s
kubectl wait --for=condition=Ready pod -l role=back-end-api -n my-namespace --timeout=60s
kubectl wait --for=condition=Ready pod -l role=admin-front-end -n my-namespace --timeout=60s
kubectl wait --for=condition=Ready pod -l role=admin-back-end-api -n my-namespace --timeout=60s