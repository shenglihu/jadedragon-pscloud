# DB
# 修改docker
grep 10.14.0.5 -rl /etc/docker | xargs sed -i "s/10.14.0.5/10.10.10.1/g"
vim /FILESTORE/SYSTEM/jdg-db.yaml
docker-compose -f /FILESTORE/SYSTEM/jdg-db.yaml down
docker-compose -f /FILESTORE/SYSTEM/jdg-db.yaml up --force-recreate -d 

systemctl restart docker
docker restart jdg-db
docker restart share-redis

