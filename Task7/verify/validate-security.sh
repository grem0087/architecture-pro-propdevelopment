#!/bin/bash

echo "=== проверка конфигурации безопасности==="
echo ""

echo "1. Проверка namespace labels:"
kubectl get namespace audit-zone -o jsonpath='{.metadata.labels}' | jq .
echo ""

echo "2. Проверка настроек Gatekeeper:"
kubectl get constraints -A
echo ""

echo "3. Проверка ConstraintTemplates:"
kubectl get constrainttemplates
echo ""

echo "4. Проверка безопасности контекста под:"
kubectl get pods -n audit-zone -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.runAsNonRoot}{"\t"}{.spec.containers[*].securityContext.privileged}{"\n"}{end}'

echo ""
echo "5. Тестирование Gatekeeper:"
cat <<EOF | kubectl apply -f - 2>&1 | grep -E "denied|created"
apiVersion: v1
kind: Pod
metadata:
  name: test-violation
  namespace: audit-zone
spec:
  containers:
  - name: test
    image: nginx
    securityContext:
      privileged: true
EOF