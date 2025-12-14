#!/bin/bash

echo "Поиск доступа к secrets"
jq 'select(.objectRef.resource=="secrets" and .verb=="get")' ./audit.log > audit-extract.json

echo "Поиск привилегированных подов"
jq 'select(.verb=="create" and .objectRef.subresource=="exec")' ./audit.log >> audit-extract.json

echo "Поиск kubectl exec команд" 
jq 'select(.objectRef.resource=="pods" and .requestObject.spec.containers[].securityContext.privileged==true)' ./audit.log >> audit-extract.json

echo "Объединение результатов"
grep -i 'audit-policy' audit.log ./audit.log >> audit-extract.json