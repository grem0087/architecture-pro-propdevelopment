#!/bin/bash

echo "=== Тестирование Pod Security Admission ==="
echo ""

echo "1. Тестирование privileged pod..."
kubectl apply -f insecure-manifests/01-privileged-pod.yaml 2>&1 | grep -E "admission denied|created"

echo ""
echo "2. Тестирование hostPath pod..."
kubectl apply -f insecure-manifests/02-hostpath-pod.yaml 2>&1 | grep -E "admission denied|created"

echo ""
echo "3. Тестирование root user pod..."
kubectl apply -f insecure-manifests/03-root-user-pod.yaml 2>&1 | grep -E "admission denied|created"

echo ""
echo "4. Тестирование secure pods..."
for file in secure-manifests/*.yaml; do
    echo "Creating $(basename $file)..."
    kubectl apply -f $file 2>&1 | grep -E "created|unchanged"
done

echo ""
echo "=== Созданные поды в audit-zone ==="
kubectl get pods -n audit-zone