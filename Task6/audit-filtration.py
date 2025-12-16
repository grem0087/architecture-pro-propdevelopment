#!/usr/bin/env python3

import json
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
AUDIT_LOG_FILE = SCRIPT_DIR / "audit.log"
AUDIT_EXTRACT_FILE = SCRIPT_DIR / "audit-extract.json"


def load_audit_log(file_path):
    events = []
    try:
        with open(file_path, 'r') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                try:
                    event = json.loads(line)
                    events.append(event)
                except json.JSONDecodeError as e:
                    print(f"Не удалось разобрать строку {line_num}: {e}", file=sys.stderr)
    except FileNotFoundError:
        print(f"Файл {file_path} не найден. Пытаюсь получить audit.log из контейнера...")

        import subprocess
        result = subprocess.run(
            ['docker', 'ps', '--filter', 'name=audit-cluster-control-plane', '--format', '{{.ID}}'],
            capture_output=True, text=True
        )
        container_id = result.stdout.strip().split('\n')[0] if result.stdout.strip() else None

        if not container_id:
            print("Контейнер audit-cluster-control-plane не найден. Дальнейшая работа невозможна.", file=sys.stderr)
            sys.exit(1)

        with open(file_path, 'w') as out:
            subprocess.run(
                ['docker', 'exec', container_id, 'cat', '/var/log/audit/audit.log'],
                stdout=out
            )

        print("Лог успешно скопирован. Повторяю загрузку.")
        return load_audit_log(file_path)

    return events


def is_suspicious(event):
    object_ref = event.get('objectRef', {})
    verb = event.get('verb', '')
    user = event.get('user', {})
    username = user.get('username', '')
    request_object = event.get('requestObject', {})
    request_uri = event.get('requestURI', '')

    # 1. Доступ к секретам
    if object_ref.get('resource') == 'secrets' and verb in ['get', 'list', 'create']:
        if not username.startswith('system:'):
            return True, "Доступ к secrets не системным пользователем"

    # 2. Привилегированные поды
    if object_ref.get('resource') == 'pods' and verb in ['create', 'update', 'patch']:
        containers = request_object.get('spec', {}).get('containers', [])
        for container in containers:
            if container.get('securityContext', {}).get('privileged') is True:
                return True, "Создание привилегированного пода"

    # 3. Использование kubectl exec в чужом поде
    if verb == 'create' and object_ref.get('subresource') == 'exec':
        return True, "Использование kubectl exec"

    # 4. Создание RoleBinding с правами cluster-admin
    if object_ref.get('resource') == 'rolebindings':
        role_ref = request_object.get('roleRef', {})
        if role_ref.get('name') == 'cluster-admin':
            return True, "RoleBinding с cluster-admin"
        if verb in ['create', 'update', 'patch']:
            return True, "Создание или изменение RoleBinding"

    # 5. Действия, связанные с audit-policy
    if 'audit-policy' in request_uri.lower() or 'audit-policy' in str(event).lower():
        return True, "Действие с audit-policy"

    # 6. monitoring / secure-ops
    if 'monitoring' in username.lower() or 'secure-ops' in request_uri.lower():
        return True, "Операция monitoring/secure-ops"

    # 7. Подозрительные имена ресурсов
    suspicious_names = ['privileged-pod', 'escalate-binding', 'attacker-pod', 'suspicious-binding']
    resource_name = object_ref.get('name', '')
    if any(name in resource_name.lower() for name in suspicious_names):
        return True, f"Подозрительное имя ресурса: {resource_name}"

    return False, None


def filter_suspicious_events(events):
    """Возвращает список подозрительных событий."""
    suspicious = []
    seen = set()

    for event in events:
        audit_id = event.get('auditID', '')
        is_susp, reason = is_suspicious(event)

        if is_susp and audit_id not in seen:
            seen.add(audit_id)
            event['_suspicious_reason'] = reason
            suspicious.append(event)

    return suspicious


def main():
    print("Загружаю журнал audit.log...")
    events = load_audit_log(AUDIT_LOG_FILE)
    print(f"Событий загружено: {len(events)}")

    print("Ищу подозрительные события...")
    suspicious = filter_suspicious_events(events)

    suspicious.sort(key=lambda x: x.get('requestReceivedTimestamp', ''))

    print(f"Подозрительных событий найдено: {len(suspicious)}")

    if suspicious:
        print("Статистика по типам событий:")
        stats = {}
        for event in suspicious:
            r = event['_suspicious_reason']
            stats[r] = stats.get(r, 0) + 1

        for reason, count in sorted(stats.items(), key=lambda x: -x[1]):
            print(f"  {reason}: {count}")

    print(f"Сохраняю результаты в {AUDIT_EXTRACT_FILE}...")
    with open(AUDIT_EXTRACT_FILE, 'w') as f:
        json.dump(suspicious, f, indent=2, ensure_ascii=False)

    print("Готово.")


if __name__ == '__main__':
    main()