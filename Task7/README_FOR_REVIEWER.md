# Проверка задания 7

### GateKeeper

1. Перед проверкой убедитесь что установлен gatekeeper. Если нет, то:

```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
```

2. Применение ConstraintTemplates

```bash
kubectl apply -f gatekeeper/constraint-templates/
```

3. Применение Constraints

```bash
kubectl apply -f gatekeeper/constraints/
```

4. Создание namespace

```bash
kubectl apply -f 01-create-namespace.yaml
```

5. Проверка работы

Запустите скрипты проверки:

```bash
./verify/verify-admission.sh
./verify/validate-security.sh
```