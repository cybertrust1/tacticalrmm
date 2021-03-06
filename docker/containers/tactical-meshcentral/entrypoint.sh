#!/usr/bin/env bash

set -e

: "${MESH_USER:=meshcentral}"
: "${MESH_PASS:=meshcentralpass}"
: "${MONGODB_USER:=mongouser}"
: "${MONGODB_PASSWORD:=mongopass}"
: "${MONGODB_HOST:=tactical-mongodb}"
: "${MONGODB_PORT:=27017}"
: "${NGINX_HOST_IP:=172.20.0.20}"

mkdir -p /home/node/app/meshcentral-data
mkdir -p ${TACTICAL_DIR}/tmp

mesh_config="$(cat << EOF
{
  "settings": {
    "mongodb": "mongodb://${MONGODB_USER}:${MONGODB_PASSWORD}@${MONGODB_HOST}:${MONGODB_PORT}",
    "Cert": "${MESH_HOST}",
    "TLSOffload": "${NGINX_HOST_IP}",
    "RedirPort": 80,
    "WANonly": true,
    "Minify": 1,
    "Port": 443,
    "AllowLoginToken": true,
    "AllowFraming": true,
    "_AgentPing": 60,
    "AgentPong": 300,
    "AllowHighQualityDesktop": true,
    "MaxInvalidLogin": {
      "time": 5,
      "count": 5,
      "coolofftime": 30
    }
  },
  "domains": {
    "": {
      "Title": "Tactical RMM",
      "Title2": "TacticalRMM",
      "NewAccounts": false,
      "mstsc": true,
      "GeoLocation": true,
      "CertUrl": "https://${NGINX_HOST_IP}:443",
      "httpheaders": {
        "Strict-Transport-Security": "max-age=360000",
        "_x-frame-options": "sameorigin",
        "Content-Security-Policy": "default-src 'none'; script-src 'self' 'unsafe-inline'; connect-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; frame-src 'self'; media-src 'self'"
      }
    }
  }
}
EOF
)"

echo "${mesh_config}" > /home/node/app/meshcentral-data/config.json

node node_modules/meshcentral --createaccount ${MESH_USER} --pass ${MESH_PASS} --email example@example.com
node node_modules/meshcentral --adminaccount ${MESH_USER}

if [ ! -f "${TACTICAL_DIR}/tmp/mesh_token" ]; then
    node node_modules/meshcentral --logintokenkey > ${TACTICAL_DIR}/tmp/mesh_token
fi

# start mesh
node node_modules/meshcentral
