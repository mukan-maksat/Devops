#!/bin/bash
set -euo pipefail

echo "Предпросмотр изменений (buckets):"
mc admin policy list myminio | jq -r '.[].name' > /tmp/current_policies
for bucket in $(yq e '.buckets[].name' buckets.yaml); do
  if ! mc ls myminio/$bucket >/dev/null 2>&1; then
    echo " [+] Будет создан бакет: $bucket"
  fi
done

echo -e "\nПредпросмотр изменений (users):"
mc admin user list myminio | awk '{print $2}' > /tmp/current_users
for user in $(yq e '.users[].access_key' users.yaml); do
  if ! grep -q "^$user$" /tmp/current_users; then
    echo " [+] Будет создан пользователь: $user"
  fi
done
