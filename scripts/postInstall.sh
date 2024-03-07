#set env vars
set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 120s;

docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -t -c "UPDATE tb_user SET email='admin@${DOMAIN}' WHERE email='sysadmin@thingsboard.org';"
EOF


target=$(docker-compose port mytb 9090)

login=$(curl http://${target}/api/auth/login \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'pragma: no-cache' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
  --data-raw '{"username":"admin@'${DOMAIN}'","password":"sysadmin"}')

access_token=$(echo $login | jq -r '.token' )


  curl http://${target}/api/auth/changePassword \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'pragma: no-cache' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
  -H 'x-authorization: Bearer '${access_token}'' \
  --data-raw '{"currentPassword":"sysadmin","newPassword":"'${ADMIN_PASSWORD}'"}'



  ###################################


docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -t -c "UPDATE tb_user SET email='${ADMIN_EMAIL}' WHERE email='tenant@thingsboard.org';"
EOF

login=$(curl http://${target}/api/auth/login \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'pragma: no-cache' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
  --data-raw '{"username":"'${ADMIN_EMAIL}'","password":"tenant"}')

access_token=$(echo $login | jq -r '.token' )


  curl http://${target}/api/auth/changePassword \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'pragma: no-cache' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
  -H 'x-authorization: Bearer '${access_token}'' \
  --data-raw '{"currentPassword":"tenant","newPassword":"'${ADMIN_PASSWORD}'"}'

  docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -t -c "DELETE FROM tb_user WHERE email IN ('customerA@thingsboard.org', 'customerB@thingsboard.org', 'customerC@thingsboard.org', 'customer@thingsboard.org');"
EOF

docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -c "TRUNCATE TABLE customer;"
EOF