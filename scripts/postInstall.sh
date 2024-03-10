#set env vars
set -o allexport; source .env; set +o allexport;

#wait until the server is ready
echo "Waiting for software to be ready ..."
sleep 200s;

  ######## SYSADMIN ########

docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -t -c "UPDATE tb_user SET email='admin@${DOMAIN}' WHERE email='sysadmin@thingsboard.org';"
EOF

login=$(curl https://${DOMAIN}/api/auth/login \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'pragma: no-cache' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
  --data-raw '{"username":"admin@'${DOMAIN}'","password":"sysadmin"}')

access_token=$(echo $login | jq -r '.token' )

curl https://${DOMAIN}/api/auth/changePassword \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'pragma: no-cache' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
  -H 'x-authorization: Bearer '${access_token}'' \
  --data-raw '{"currentPassword":"sysadmin","newPassword":"'${ADMIN_PASSWORD}'"}'


  ######## TENANT ########

docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -t -c "UPDATE tb_user SET email='${ADMIN_EMAIL}' WHERE email='tenant@thingsboard.org';"
EOF

login=$(curl https://${DOMAIN}/api/auth/login \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'pragma: no-cache' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
  --data-raw '{"username":"'${ADMIN_EMAIL}'","password":"tenant"}')

access_token=$(echo $login | jq -r '.token' )


curl https://${DOMAIN}/api/auth/changePassword \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: fr-FR,fr;q=0.9,en-US;q=0.8,en;q=0.7,he;q=0.6,zh-CN;q=0.5,zh;q=0.4,ja;q=0.3' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'pragma: no-cache' \
  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36' \
  -H 'x-authorization: Bearer '${access_token}'' \
  --data-raw '{"currentPassword":"tenant","newPassword":"'${ADMIN_PASSWORD}'"}'


  ######## HTTPS ########

https_id=$(docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -t -c "SELECT id
FROM admin_settings
WHERE json_value::jsonb->'coap' IS NOT NULL;"
EOF
)

https_id=$(echo "$https_id" | tr -d '[:space:]')

docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -t -c "UPDATE admin_settings
SET json_value = '{\"http\":{\"enabled\":false,\"host\":\"\",\"port\":8080},\"https\":{\"enabled\":true,\"host\":\"${DOMAIN}\",\"port\":443},\"mqtt\":{\"enabled\":true,\"host\":\"\",\"port\":1883},\"mqtts\":{\"enabled\":false,\"host\":\"\",\"port\":8883},\"coap\":{\"enabled\":true,\"host\":\"\",\"port\":5683},\"coaps\":{\"enabled\":false,\"host\":\"\",\"port\":5684}}'::jsonb
WHERE id = '${https_id}'"
EOF


  ######## SMTP ########

smtp_id=$(docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -t -c "SELECT id
FROM admin_settings
WHERE json_value::jsonb->>'mailFrom' = 'ThingsBoard <sysadmin@localhost.localdomain>';"
EOF
)

smtp_id=$(echo "$smtp_id" | tr -d '[:space:]')

docker-compose exec -T mytb bash <<EOF
    psql -U thingsboard -d thingsboard -t -c "UPDATE admin_settings
SET json_value = '{\"mailFrom\":\"ThingsBoard <${MAIL_FROM}>\",\"smtpProtocol\":\"smtp\",\"smtpHost\":\"172.17.0.1\",\"smtpPort\":\"25\",\"timeout\":\"10000\",\"enableTls\":false,\"username\":\"\",\"password\":\"\",\"tlsVersion\":\"TLSv1.2\",\"enableProxy\":false,\"showChangePassword\":false}'::jsonb
WHERE id = '${smtp_id}'"
EOF
