#!/data/data/com.termux/files/usr/bin/bash
# Bootstrap do Termux: SSH + Git + ferramentas para migração via Tailscale
set -euo pipefail

echo "==> Atualizando pacotes"
pkg update -y
apt-get -y -o Dpkg::Options::=--force-confnew upgrade

echo "==> Instalando pacotes"
pkg install -y openssh git rsync curl procps termux-auth

echo "==> Preparando ~/.ssh"
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
touch "$HOME/.ssh/authorized_keys"
chmod 600 "$HOME/.ssh/authorized_keys"

# Senha só é necessária para o primeiro login (depois use ssh-copy-id)
if [ ! -s "$HOME/.ssh/authorized_keys" ]; then
  echo "==> Defina uma senha para o primeiro login SSH"
  passwd
fi

# Acesso a /sdcard (~/storage); abre o diálogo do Android se ainda não houver
[ -d "$HOME/storage" ] || termux-setup-storage || true

echo "==> Configurando início automático do sshd"
if ! grep -q 'pgrep -x sshd' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'EOF'

# inicia o sshd ao abrir o Termux
pgrep -x sshd >/dev/null || sshd
EOF
fi

echo "==> Iniciando sshd"
pgrep -x sshd >/dev/null || sshd

# Impede o Android de suspender o Termux durante a migração
termux-wake-lock || true

# IP do Tailscale (best effort; o Android às vezes bloqueia essa leitura)
TS_IP="$( (ifconfig 2>/dev/null || ip -4 addr 2>/dev/null) \
  | grep -oE '100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.[0-9]+\.[0-9]+' | head -n1 || true)"

echo
echo "================ PRONTO ================"
echo "Usuário : $(whoami)  (o sshd do Termux aceita qualquer nome)"
echo "Porta   : 8022"
echo "IP TS   : ${TS_IP:-não detectado — veja no app do Tailscale}"
echo
echo "Fingerprint da chave do host:"
ssh-keygen -lf "$PREFIX/etc/ssh/ssh_host_ed25519_key.pub" || true
echo
echo "No computador:"
echo "  ssh -p 8022 ${TS_IP:-<ip-ou-nome-tailscale>}"
echo "  ssh-copy-id -p 8022 ${TS_IP:-<ip-ou-nome-tailscale>}"
echo "========================================"
