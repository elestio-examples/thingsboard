#set env vars
set -o allexport; source .env; set +o allexport;

mkdir -p ./mytb-data
mkdir -p ./mytb-logs

chown -R 799:799 ./mytb-data
chown -R 799:799 ./mytb-logs