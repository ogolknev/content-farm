#!/bin/bash
set -e

echo "Настройка директории /data/io..."
mkdir -p /data/io || { echo "Ошибка: не удалось создать /data/io"; exit 1; }
if ! id -u n8n >/dev/null 2>&1; then
  echo "Ошибка: пользователь n8n не существует в контейнере"
  exit 1
fi
chown -R n8n:n8n /data/io || { echo "Ошибка: не удалось назначить владельца n8n для /data/io"; exit 1; }
chmod -R 777 /data/io || { echo "Ошибка: не удалось установить права 755 для /data/io"; exit 1; }
echo "Директория /data/io настроена успешно."

# Импорт всех workflow из /data/n8n_workflows (если есть)
# -L флаг: следует symlink'ам и обрабатывает реальные файлы
if [ -d /data/n8n_workflows ]; then
  echo "Импорт workflow из /data/n8n_workflows..."
  chown -R n8n:n8n /data/n8n_workflows || true
  find -L /data/n8n_workflows -maxdepth 1 -name "*.json" -type f | while read wf; do
    [ -f "$wf" ] || continue
    echo "Импорт: $wf"
    su -s /bin/bash n8n -c "n8n import:workflow --separate --input '$wf'" || true
  done
fi

# Передаём управление следующей команде
exec su -c "exec $@" n8n
