#!/bin/bash
echo "Rollback не требуется — MinIO не поддерживает удаление бакетов с объектами"
echo "При необходимости можно удалить пользователей:"
mc admin user list myminio
