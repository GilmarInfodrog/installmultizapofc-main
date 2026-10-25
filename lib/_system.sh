#!/bin/bash
# 
# system management

#######################################
# checks if systemd is running (WSL may not have it)
# Arguments:
#   None
#######################################
has_systemd() {
  [[ -d /run/systemd/system ]]
}

#######################################
# enables and starts a service, with or without systemd
# Arguments:
#   service name
#######################################
start_service() {
  if has_systemd; then
    sudo systemctl enable --now "$1"
  else
    sudo service "$1" start
  fi
}

#######################################
# installs only the apt packages that exist in this
# Ubuntu version (names change between releases)
# Arguments:
#   package names
#######################################
apt_install_available() {
  local available=()
  local pkg
  for pkg in "$@"; do
    if apt-cache policy "$pkg" 2>/dev/null | grep -q "Candidate: [^(]"; then
      available+=("$pkg")
    fi
  done
  sudo apt-get install -y "${available[@]}"
}

#######################################
# creates user
# Arguments:
#   None
#######################################
system_create_user() {
  print_banner
  printf "${WHITE} 💻 Agora, vamos criar o usuário para a instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # aspas simples: o hash SHA-512 contem "$" e nao pode ser expandido
  deploy_hash=$(openssl passwd -6 "${mysql_root_password}")

  sudo su - root <<EOF
  useradd -m -p '${deploy_hash}' -s /bin/bash -G sudo deploy
  usermod -aG sudo deploy
EOF

  sleep 2
}

#######################################
# clones repostories using git
# Arguments:
#   None
#######################################
system_git_clone() {
  print_banner
  printf "${WHITE} 💻 Fazendo download do código Whaticket...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

  sudo su - deploy <<EOF
  git clone ${link_git} /home/deploy/${instancia_add}/
EOF

  sleep 2
}

#######################################
# updates system
# Arguments:
#   None
#######################################
system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos atualizar o sistema Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo apt-get update -y
  sudo apt-get upgrade -y
  sudo apt-get install -y curl wget git unzip ca-certificates gnupg lsb-release fontconfig locales

  sleep 2
}



#######################################
# delete system
# Arguments:
#   None
#######################################
deletar_tudo() {
  print_banner
  printf "${WHITE} 💻 Vamos deletar o Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  docker container rm redis-${empresa_delete} --force
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_delete}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_delete}-backend
  
  sleep 2

  sudo su - postgres
  dropuser ${empresa_delete}
  dropdb ${empresa_delete}
  exit
EOF

sleep 2

sudo su - deploy <<EOF
 rm -rf /home/deploy/${empresa_delete}
 pm2 delete ${empresa_delete}-frontend ${empresa_delete}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Remoção da Instancia/Empresa ${empresa_delete} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

}

#######################################
# bloquear system
# Arguments:
#   None
#######################################
configurar_bloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos bloquear o Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 stop ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Bloqueio da Instancia/Empresa ${empresa_bloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}


#######################################
# desbloquear system
# Arguments:
#   None
#######################################
configurar_desbloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos Desbloquear o Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 start ${empresa_desbloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Desbloqueio da Instancia/Empresa ${empresa_desbloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# alter dominio system
# Arguments:
#   None
#######################################
configurar_dominio() {
  print_banner
  printf "${WHITE} 💻 Vamos Alterar os Dominios do Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

sleep 2

  sudo su - root <<EOF
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-enabled/${empresa_dominio}-backend  
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-frontend
  cd && rm -rf /etc/nginx/sites-available/${empresa_dominio}-backend
EOF

sleep 2

  sudo su - deploy <<EOF
  cd && cd /home/deploy/${empresa_dominio}/frontend
  sed -i "1c\REACT_APP_BACKEND_URL=${url_scheme}://${alter_backend_url}" .env
  cd && cd /home/deploy/${empresa_dominio}/backend
  sed -i "2c\BACKEND_URL=${url_scheme}://${alter_backend_url}" .env
  sed -i "3c\FRONTEND_URL=${url_scheme}://${alter_frontend_url}" .env
EOF

sleep 2
   
   backend_hostname=$(echo "${alter_backend_url#*://}")

 sudo su - root <<EOF
  cat > /etc/nginx/sites-available/${empresa_dominio}-backend << 'END'
server {
  server_name $backend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_backend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -sf /etc/nginx/sites-available/${empresa_dominio}-backend /etc/nginx/sites-enabled
EOF

sleep 2

frontend_hostname=$(echo "${alter_frontend_url#*://}")

sudo su - root << EOF
cat > /etc/nginx/sites-available/${empresa_dominio}-frontend << 'END'
server {
  server_name $frontend_hostname;
  location / {
    proxy_pass http://127.0.0.1:${alter_frontend_port};
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END
ln -sf /etc/nginx/sites-available/${empresa_dominio}-frontend /etc/nginx/sites-enabled
EOF

 sleep 2

 sudo su - root <<EOF
  service nginx restart
EOF

  sleep 2

  if [[ "${is_wsl}" != "true" ]]; then
    backend_domain=$(echo "${alter_backend_url#*://}")
    frontend_domain=$(echo "${alter_frontend_url#*://}")

    sudo certbot -m $deploy_email \
            --nginx \
            --agree-tos \
            --non-interactive \
            --domains $backend_domain,$frontend_domain
  fi

  sleep 2

  print_banner
  printf "${WHITE} 💻 Alteração de dominio da Instancia/Empresa ${empresa_dominio} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# installs node
# Arguments:
#   None
#######################################
system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nodejs...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  curl -fsSL https://deb.nodesource.com/setup_${node_version}.x | sudo -E bash -
  sudo apt-get install -y nodejs
  sleep 2
  sudo apt-get install -y postgresql
  start_service postgresql
  sleep 2
  if has_systemd; then
    sudo timedatectl set-timezone America/Sao_Paulo
  else
    sudo ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
  fi

  sleep 2
}
#######################################
# installs docker
# Arguments:
#   None
#######################################
system_docker_install() {
  print_banner
  printf "${WHITE} 💻 Instalando docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo apt-get install -y docker.io
  start_service docker

  sleep 2
}

#######################################
# Ask for file location containing
# multiple URL for streaming.
# Globals:
#   WHITE
#   GRAY_LIGHT
#   BATCH_DIR
#   PROJECT_ROOT
# Arguments:
#   None
#######################################
system_puppeteer_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando puppeteer dependencies...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # os nomes com "t64" sao do Ubuntu 24.04; os sem sao do 20.04/22.04
  apt_install_available libxshmfence-dev libgbm-dev wget unzip fontconfig locales \
                        libasound2t64 libasound2 libatk1.0-0t64 libatk1.0-0 libc6 \
                        libcairo2 libcups2t64 libcups2 libdbus-1-3 libexpat1 libfontconfig1 \
                        libgcc-s1 libgdk-pixbuf-2.0-0 libgdk-pixbuf2.0-0 libglib2.0-0t64 libglib2.0-0 \
                        libgtk-3-0t64 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 \
                        libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 \
                        libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 \
                        libxtst6 ca-certificates fonts-liberation libnss3 lsb-release xdg-utils

  sleep 2
}

#######################################
# installs pm2
# Arguments:
#   None
#######################################
system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando pm2...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo npm install -g pm2

  sleep 2
}

#######################################
# installs certbot
# Arguments:
#   None
#######################################
system_certbot_install() {
  print_banner
  printf "${WHITE} 💻 Instalando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  if [[ "${is_wsl}" == "true" ]]; then
    printf "${WHITE} 💻 WSL detectado: certbot ignorado (sem domínio público)${GRAY_LIGHT}\n"
  else
    sudo apt-get install -y certbot python3-certbot-nginx
  fi

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_nginx_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo apt-get install -y nginx
  sudo rm -f /etc/nginx/sites-enabled/default
  start_service nginx

  sleep 2
}

#######################################
# restarts nginx
# Arguments:
#   None
#######################################
system_nginx_restart() {
  print_banner
  printf "${WHITE} 💻 reiniciando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  service nginx restart
EOF

  sleep 2
}

#######################################
# setup for nginx.conf
# Arguments:
#   None
#######################################
system_nginx_conf() {
  print_banner
  printf "${WHITE} 💻 configurando nginx...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - root << EOF

cat > /etc/nginx/conf.d/deploy.conf << 'END'
client_max_body_size 100M;
END

EOF

  sleep 2
}

#######################################
# installs nginx
# Arguments:
#   None
#######################################
system_certbot_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando certbot...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  if [[ "${is_wsl}" == "true" ]]; then
    printf "${WHITE} 💻 WSL detectado: SSL ignorado, acesse por http://${GRAY_LIGHT}\n"
    return
  fi

  backend_domain=$(echo "${backend_url#*://}")
  frontend_domain=$(echo "${frontend_url#*://}")

  sudo certbot -m $deploy_email \
          --nginx \
          --agree-tos \
          --non-interactive \
          --domains $backend_domain,$frontend_domain

  sleep 2
}
