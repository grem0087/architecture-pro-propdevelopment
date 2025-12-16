#!/bin/bash

# Скрипт привязки пользователей к ролям

set -e

echo "=== Создание ClusterRoleBindings для adm1 и adm2 ==="

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: k8s-admins-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: k8s-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: admin1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: admin2
EOF

echo "=== Создание ClusterRoleBindings для devops1 и devops2 ==="

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: devops-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: devops
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: devops1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: devops2
EOF

echo "=== Создание RoleBindings для лидов ==="

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: maintainer-binding
  namespace: development
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: maintainer
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: lead1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: lead2
EOF

echo "=== Создание RoleBindings для разработчиков ==="

kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-binding
  namespace: development
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: developer
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev1
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: dev2
EOF

echo "=== Создание привязок завершено ==="
