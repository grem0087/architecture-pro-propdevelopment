#!/bin/bash

# Скрипт для создания пользователей

set -e

# Создаем директорию для сертификатов
mkdir -p ./crt/usrs

# Функция для создания сертификата пользователя
create_cert() {
    local username=$1
    local group=$2
    
    echo "Создание сертификата для пользователя: $username"
    
    openssl genrsa -out ./crt/usrs/${username}.key 2048
    
    openssl req -new -key ./crt/usrs/${username}.key -out ./crt/usrs/${username}.csr -subj "/CN=${username}/O=${group}"
    
    openssl x509 -req -in ./crt/usrs/${username}.csr -CA ~/.minikube/ca.crt -CAkey ~/.minikube/ca.key -CAcreateserial -out ./crt/usrs/${username}.crt -days 365
    
    kubectl config set-credentials ${username} --client-certificate=./crt/usrs/${username}.crt --client-key=./crt/usrs/${username}.key --embed-certs=true
    
    echo "Конфигурирование серт. для  $username выполнено успешно"
}

# Создаем пользователей для каждой группы

echo "=== Создание администраторов кластера ==="
create_cert "admin1" "k8s-admins"
create_cert "admin2" "k8s-admins"

echo "=== Создание DevOps ==="
create_cert "devops1" "devops"
create_cert "devops2" "devops"
create_cert "devops3" "devops"

echo "=== Создание разработчиков ==="
create_cert "dev1" "developer"
create_cert "dev2" "developer"
create_cert "dev3" "developer"

echo "=== Создание лидов ==="
create_cert "lead1" "maintainer"
create_cert "lead2" "maintainer"

echo "=== Создание контекстов для пользователей ==="

# Создаем контексты для каждого пользователя
for user in admin1 admin2 devops1 devops2 dev1 dev2 dev3 lead1 lead2; do
    kubectl config set-context ${user}-context --cluster=minikube --user=${user}
done

echo "=== Создание пользователей завершено ==="