#!/bin/bash

app_external_ip=`cd ../terraform/stage && terraform output app_external_ip`
db_external_ip=`cd ../terraform/stage && terraform output db_external_ip`

cat << EOF > ./inventory.json
{
  "_meta": {
    "hostvars": { }
  },
  "app": {
    "hosts": [ "${app_external_ip}" ]
  },
  "db": {
    "hosts": [ "${db_external_ip}" ]
  }
}
EOF
