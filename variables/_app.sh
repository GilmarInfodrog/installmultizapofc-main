#!/bin/bash
#
# Variables to be used for background styling.

# app variables

jwt_secret=$(openssl rand -base64 32)
jwt_refresh_secret=$(openssl rand -base64 32)

db_pass=$(openssl rand -base64 32)

db_user=$(openssl rand -base64 32)
db_name=$(openssl rand -base64 32)

deploy_email=deploy@deploy.com

# versao do Node.js instalada (LTS)
node_version=20

# detecta se esta rodando dentro do WSL (Windows)
if grep -qi microsoft /proc/version 2>/dev/null; then
  is_wsl=true
else
  is_wsl=false
fi

# no WSL nao ha dominio publico, entao o SSL (certbot) e ignorado e usamos http
if [[ "${is_wsl}" == "true" ]]; then
  url_scheme=http
  proxy_port=80
else
  url_scheme=https
  proxy_port=443
fi
