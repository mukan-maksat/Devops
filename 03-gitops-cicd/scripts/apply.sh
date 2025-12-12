#!/usr/bash
set -euo pipefail

# Buckets
for bucket in $(yq e '.buckets[].name' buckets.yaml); do
  mc mb myminio/$bucket 2>/dev/null || echo "Бакет $bucket уже существует"
done

# Versioning & locking
yq e '.buckets[] | [.name, .versioning, .locking] | @tsv' buckets.yaml | while IFS=$'\t' read name ver lock; do
  [ "$ver" = "true" ] && mc version enable myminio/$name
  [ "$lock" = "true" ] && mc retention set --default governance 30d myminio/$name
done

# Policies
for bucket in $(yq e '.buckets[].name' buckets.yaml); do
  policy=$(yq e ".buckets[] | select(.name == \"$bucket\") .policy" buckets.yaml)
  [ "$policy" = "public" ] && mc anonymous set download myminio/$bucket
done

# Users
for row in $(yq e -o=json '.users[]' users.yaml); do
  access=$(echo $row | jq -r '.access_key')
  secret=$(echo $row | jq -r '.secret_key' | vault kv get -field=password -format=json kv/minio/users)
  policy=$(echo $row | jq -r '.policy')
  
  mc admin user add myminio $access $secret 2>/dev/null || echo "Пользователь $access уже есть"
  mc admin policy attach myminio $policy --user $access
done

# Сохраняем хэш последнего применения
sha256sum buckets.yaml users.yaml > .last-applied-hash
