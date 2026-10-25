# installmultizapofc

Instalador do Multizap (Whaticket) para Ubuntu 20.04, 22.04 e 24.04, em VPS ou no WSL do Windows.

## O que é instalado

Node.js 20, PM2, PostgreSQL, Docker (Redis), Nginx e Certbot (SSL).

## Instalação na VPS

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/GilmarInfodrog/installmultizapofc-main.git
cd installmultizapofc-main
sudo chmod +x install_primaria install_instancia
sudo ./install_primaria
```

- Use `install_primaria` na primeira instalação da VPS.
- Use `install_instancia` para adicionar, atualizar, bloquear ou remover empresas.

Os domínios do frontend e do backend precisam apontar para o IP da VPS antes da instalação, senão o Certbot não gera o SSL.

## Testando no WSL

O instalador detecta o WSL sozinho e então:

- não configura SSL (as URLs ficam com `http://`);
- funciona com ou sem systemd.

Para usar o systemd no WSL (recomendado), crie o arquivo `/etc/wsl.conf` com:

```
[boot]
systemd=true
```

Depois rode `wsl --shutdown` no PowerShell e abra o Ubuntu de novo.

Como domínio, use nomes terminados em `.localhost`, por exemplo `app.localhost` (frontend) e `api.localhost` (backend). No Windows, abra `http://app.localhost` no navegador.

## Senhas

O arquivo `config` é criado na primeira execução e guarda as senhas. Ele **não** deve ser enviado ao GitHub (já está no `.gitignore`).
