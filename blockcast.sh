#!/usr/bin/env bash
# =====================================================================
#  Blockcast Node — RU/EN interactive installer/runner (Docker-based)
#  Target: Ubuntu/Debian (apt). Requires sudo privileges for installs.
#  Version: 1.0.2
# =====================================================================
set -Eeuo pipefail

# -----------------------------
# Branding / Logo
# -----------------------------
display_logo() {
  cat <<'EOF'
 _   _           _  _____      
| \ | |         | ||____ |     
|  \| | ___   __| |    / /_ __ 
| . ` |/ _ \ / _` |    \ \ '__|
| |\  | (_) | (_| |.___/ / |   
\_| \_/\___/ \__,_|\____/|_|
          Blockcast
 Канал: https://t.me/NodesN3R
EOF
}

# -----------------------------
# Colors
# -----------------------------
clrGreen=$'\033[0;32m'
clrCyan=$'\033[0;36m'
clrBlue=$'\033[0;34m'
clrRed=$'\033[0;31m'
clrYellow=$'\033[1;33m'
clrMag=$'\033[1;35m'
clrReset=$'\033[0m'
clrBold=$'\033[1m'
clrDim=$'\033[2m'

ok()    { echo -e "${clrGreen}[OK]${clrReset} ${*:-}"; }
info()  { echo -e "${clrCyan}[INFO]${clrReset} ${*:-}"; }
warn()  { echo -e "${clrYellow}[WARN]${clrReset} ${*:-}"; }
err()   { echo -e "${clrRed}[ERROR]${clrReset} ${*:-}"; }
hr()    { echo -e "${clrDim}────────────────────────────────────────────────────────${clrReset}"; }

# -----------------------------
# Config
# -----------------------------
SCRIPT_NAME="BlockcastNode"
SCRIPT_VERSION="1.0.2"

BC_DIR="$HOME/blockcast"
ENV_FILE="$BC_DIR/.env"
COMPOSE_FILE="$BC_DIR/docker-compose.yml"
REPO_URL="https://github.com/0xmoei/blockcast"

# Defaults
PROXY_PORT="8443"      # external port
ALT_PORT="8080"        # legacy port in some readme examples
IMAGE_REPO="blockcast/cdn_gateway_go"
IMAGE_TAG="stable"

# -----------------------------
# Language (RU/EN)
# -----------------------------
LANG_CHOICE="ru"
choose_language() {
  clear; display_logo
  echo -e "\n${clrBold}${clrMag}Select language / Выберите язык${clrReset}"
  echo -e "${clrDim}1) Русский${clrReset}"
  echo -e "${clrDim}2) English${clrReset}"
  read -rp "> " ans
  case "${ans:-}" in
    2) LANG_CHOICE="en" ;;
    *) LANG_CHOICE="ru" ;;
  esac
}

tr() {
  local k="${1-}"; [[ -z "$k" ]] && return 0
  case "$LANG_CHOICE" in
    en)
      case "$k" in
        root_enabled) echo "• Root Access Enabled ✔" ;;
        updating) echo "Updating packages..." ;;
        installing_deps) echo "Installing base dependencies..." ;;
        deps_done) echo "Base dependencies installed" ;;
        docker_setup) echo "Installing Docker (engine + compose plugin)..." ;;
        docker_done) echo "Docker installed" ;;
        ufw_setup) echo "Configuring firewall (UFW)..." ;;
        ufw_warn_enable) echo "UFW will be enabled; ensure SSH (22) is allowed to avoid lockout." ;;
        ufw_done) echo "Firewall rules applied" ;;
        make_dir) echo "Creating ./blockcast directory and fetching upstream compose" ;;
        ask_port) echo "Enter listening port for Blockcast proxy (8443 recommended; 8080 legacy):" ;;
        env_saved) echo ".env saved" ;;
        compose_saved) echo "docker-compose.yml saved" ;;
        compose_from_repo) echo "Pulled upstream compose from repo" ;;
        compose_patched) echo "Patched compose with your port" ;;
        starting) echo "Starting Blockcast (docker compose up -d)..." ;;
        started) echo "Blockcast started" ;;
        restarting) echo "Restarting Blockcast..." ;;
        restarted) echo "Blockcast restarted" ;;
        logs_hint) echo "Showing live logs (last 1000 lines). Ctrl+C to stop." ;;
        menu_title) echo "Blockcast Node — Installer & Manager" ;;
        m1_bootstrap) echo "One-click setup: deps, Docker, UFW" ;;
        m2_create) echo "Create ./blockcast and prepare compose" ;;
        m3_start) echo "Start node" ;;
        m4_restart) echo "Restart node" ;;
        m5_logs) echo "Follow logs" ;;
        m6_register) echo "Registration helper (blockcastd init)" ;;
        m7_status) echo "Show docker status" ;;
        m8_remove) echo "Remove node (FULL)" ;;
        m9_lang) echo "Change language / Сменить язык" ;;
        m10_exit) echo "Exit" ;;
        press_enter) echo "Press Enter to return to menu..." ;;
        need_root_warn) echo "Some steps require sudo/root. You'll be prompted when needed." ;;
        docker_missing) echo "Docker is not available. Please run the one-click setup first." ;;
        remove_confirm) echo "This will stop containers, remove volumes, images and delete data. Type 'yes' to confirm:" ;;
        keep_env_q) echo "Keep .env as backup? [Y/n]:" ;;
        backup_saved) echo "Backup saved to" ;;
        removed_ok) echo "Blockcast completely removed" ;;
        cancelled) echo "Cancelled" ;;
        dir_missing) echo "Directory not found" ;;
        compose_missing) echo "docker-compose.yml not found" ;;
        reg_hint) echo "Running 'docker compose exec blockcastd blockcastd init'..." ;;
        reg_url) echo "Registration URL:" ;;
        city_hint) echo "Your detected location (city/region/country/loc):" ;;
      esac ;;
    *)
      case "$k" in
        root_enabled) echo "• Root Access Enabled ✔" ;;
        updating) echo "Обновляю пакеты..." ;;
        installing_deps) echo "Устанавливаю базовые зависимости..." ;;
        deps_done) echo "Базовые зависимости установлены" ;;
        docker_setup) echo "Устанавливаю Docker (движок + compose-плагин)..." ;;
        docker_done) echo "Docker установлен" ;;
        ufw_setup) echo "Настраиваю firewall (UFW)..." ;;
        ufw_warn_enable) echo "Будет включён UFW; проверьте, что SSH (22) разрешён." ;;
        ufw_done) echo "Правила файрвола применены" ;;
        make_dir) echo "Создаю ./blockcast и подтягиваю compose из репозитория" ;;
        ask_port) echo "Введите порт для прокси Blockcast (рекомендуем 8443; 8080 — старый вариант):" ;;
        env_saved) echo ".env сохранён" ;;
        compose_saved) echo "docker-compose.yml сохранён" ;;
        compose_from_repo) echo "Забрал compose из репозитория" ;;
        compose_patched) echo "Порт в compose обновлён" ;;
        starting) echo "Запускаю Blockcast (docker compose up -d)..." ;;
        started) echo "Нода запущена" ;;
        restarting) echo "Перезапускаю Blockcast..." ;;
        restarted) echo "Нода перезапущена" ;;
        logs_hint) echo "Показываю логи (последние 1000 строк). Ctrl+C для выхода." ;;
        menu_title) echo "Blockcast Node — установщик и менеджер" ;;
        m1_bootstrap) echo "Установка утилит, Docker и UFW" ;;
        m2_create) echo "Подготовить каталог и compose" ;;
        m3_start) echo "Запустить ноду" ;;
        m4_restart) echo "Перезапустить ноду" ;;
        m5_logs) echo "Смотреть логи" ;;
        m6_register) echo "Регистрация (blockcastd init)" ;;
        m7_status) echo "Статус контейнеров" ;;
        m8_remove) echo "Удалить ноду (полностью)" ;;
        m9_lang) echo "Сменить язык / Change language" ;;
        m10_exit) echo "Выход" ;;
        press_enter) echo "Нажмите Enter для возврата в меню..." ;;
        need_root_warn) echo "Некоторые шаги требуют sudo/root. Права попросят по ходу." ;;
        docker_missing) echo "Docker недоступен. Сначала выполните быструю установку." ;;
        remove_confirm) echo "Будут удалены контейнеры, образы и данные. Введите 'yes' для подтверждения:" ;;
        keep_env_q) echo "Сохранить .env в бэкап? [Y/n]:" ;;
        backup_saved) echo "Бэкап сохранён по пути" ;;
        removed_ok) echo "Blockcast полностью удалён" ;;
        cancelled) echo "Отменено" ;;
        dir_missing) echo "Каталог не найден" ;;
        compose_missing) echo "Файл docker-compose.yml не найден" ;;
        reg_hint) echo "Выполняю 'docker compose exec blockcastd blockcastd init'..." ;;
        reg_url) echo "Ссылка для регистрации:" ;;
        city_hint) echo "Определённая геолокация (city/region/country/loc):" ;;
      esac ;;
  esac
}

# -----------------------------
# Helpers
# -----------------------------
need_sudo() {
  if [[ $(id -u) -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
    err "sudo не найден. Запустите под root или установите sudo."; exit 1
  fi
}
run() {
  if [[ $(id -u) -ne 0 ]]; then sudo bash -lc "$*"; else bash -lc "$*"; fi
}

# -----------------------------
# Update & base deps
# -----------------------------
update_and_deps() {
  echo "$(tr root_enabled)"
  info "$(tr updating)"; run "apt-get update && apt-get upgrade -y"
  info "$(tr installing_deps)"
  run "apt-get install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip ufw screen gawk"
  ok "$(tr deps_done)"
}

# -----------------------------
# Docker install
# -----------------------------
install_docker() {
  info "$(tr docker_setup)"; need_sudo
  if ! command -v docker >/dev/null 2>&1; then
    run "apt-get update && apt-get install -y docker.io"
  fi
  if ! docker compose version >/dev/null 2>&1; then
    run "apt-get install -y docker-compose-plugin"
  fi
  run "systemctl enable --now docker" || true
  docker --version || true
  docker compose version || true
  ok "$(tr docker_done)"
}

# -----------------------------
# Firewall (UFW)
# -----------------------------
setup_firewall() {
  info "$(tr ufw_setup)"; need_sudo
  echo "$(tr ufw_warn_enable)"
  run "apt-get install -y ufw > /dev/null 2>&1 || true"
  run "ufw allow 22"; run "ufw allow ssh"
  run "ufw allow ${PROXY_PORT}" || true
  if [[ "$ALT_PORT" != "$PROXY_PORT" ]]; then run "ufw allow ${ALT_PORT}" || true; fi
  yes | run ufw enable || true
  run ufw reload || true
  ok "$(tr ufw_done)"
}

# -----------------------------
# Bootstrap
# -----------------------------
bootstrap_setup() {
  update_and_deps
  install_docker
  setup_firewall
}

# -----------------------------
# Create dir, fetch compose, set port
# -----------------------------
create_dir_and_compose() {
  info "$(tr make_dir)"; hr
  mkdir -p "$BC_DIR"; cd "$BC_DIR"

  local PORT_IN
  PORT_IN="$PROXY_PORT"
  read -rp "${clrBold}$(tr ask_port)${clrReset} [${PORT_IN}] " ans
  PORT_IN="${ans:-${PORT_IN}}"
  PROXY_PORT="$PORT_IN"

  cat > "$ENV_FILE" <<EOF
PROXY_PORT=${PROXY_PORT}
ALT_PORT=${ALT_PORT}
IMAGE_REPO=${IMAGE_REPO}
IMAGE_TAG=${IMAGE_TAG}
EOF
  ok "$(tr env_saved)"; hr

  # Fetch upstream compose
  if command -v git >/dev/null 2>&1; then
    rm -rf "$BC_DIR/.tmp_repo" 2>/dev/null || true
    mkdir -p "$BC_DIR/.tmp_repo"
    git clone --depth=1 "$REPO_URL" "$BC_DIR/.tmp_repo" >/dev/null 2>&1 || true
    if [[ -f "$BC_DIR/.tmp_repo/docker-compose.yml" ]]; then
      cp "$BC_DIR/.tmp_repo/docker-compose.yml" "$COMPOSE_FILE"
      ok "$(tr compose_from_repo)"
    fi
    rm -rf "$BC_DIR/.tmp_repo" 2>/dev/null || true
  fi

  # Fallback compose if repo wasn't available
  if [[ ! -f "$COMPOSE_FILE" ]]; then
    cat > "$COMPOSE_FILE" <<YAML
services:
  blockcastd:
    image: ${IMAGE_REPO}:${IMAGE_TAG}
    container_name: blockcastd
    restart: unless-stopped
    command: ["/usr/bin/blockcastd"]
  beacond:
    image: ${IMAGE_REPO}:${IMAGE_TAG}
    container_name: beacond
    restart: unless-stopped
    command: ["/usr/bin/beacond"]
  control_proxy:
    image: ${IMAGE_REPO}:${IMAGE_TAG}
    container_name: control_proxy
    restart: unless-stopped
    command: ["/usr/bin/control_proxy"]
    ports:
      - "${PROXY_PORT}:${PROXY_PORT}"
YAML
    ok "$(tr compose_saved)"
  fi

  # Patch common port mappings if present
  if [[ -f "$COMPOSE_FILE" ]]; then
    sed -i \
      -e "s/\"8080:8080\"/\"${PROXY_PORT}:8080\"/g" \
      -e "s/\"8443:8443\"/\"${PROXY_PORT}:8443\"/g" \
      -e "s/'8080:8080'/'${PROXY_PORT}:8080'/g" \
      -e "s/'8443:8443'/'${PROXY_PORT}:8443'/g" \
      "$COMPOSE_FILE" || true
    ok "$(tr compose_patched)"
  fi
}

# -----------------------------
# Start / Restart / Logs / Status
# -----------------------------
start_node() {
  if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then err "$(tr docker_missing)"; return 1; fi
  cd "$BC_DIR"; info "$(tr starting)"; docker compose up -d; ok "$(tr started)"
}
restart_node() {
  if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then err "$(tr docker_missing)"; return 1; fi
  cd "$BC_DIR" || { err "$(tr dir_missing)"; return 1; }
  info "$(tr restarting)"; docker compose up -d --force-recreate; ok "$(tr restarted)"
}
show_logs() {
  if ! command -v docker >/dev/null 2>&1; then err "$(tr docker_missing)"; return 1; fi
  cd "$BC_DIR"; info "$(tr logs_hint)"; docker compose logs -fn 1000
}
show_status() {
  if ! command -v docker >/dev/null 2>&1; then err "$(tr docker_missing)"; return 1; fi
  cd "$BC_DIR"; docker compose ps -a
}

# -----------------------------
# Registration helper
# -----------------------------
register_node() {
  if ! command -v docker >/dev/null 2>&1; then err "$(tr docker_missing)"; return 1; fi
  cd "$BC_DIR" || { err "$(tr dir_missing)"; return 1; }
  info "$(tr reg_hint)"
  local loc_json
  loc_json=$(curl -s https://ipinfo.io || true)
  if [[ -n "$loc_json" ]]; then
    echo "$(tr city_hint)"
    echo "$loc_json" | jq '.city, .region, .country, .loc' || echo "$loc_json"
  fi
  local TMP
  TMP=$(mktemp)
  set +e
  docker compose exec blockcastd blockcastd init | tee "$TMP"
  local ec=$?
  set -e
  local URL
  URL=$(grep -Eo 'https?://[^ ]+' "$TMP" | head -n1 || true)
  rm -f "$TMP"
  if [[ -n "$URL" ]]; then
    printf "%s %b%s%b\n" "$(tr reg_url)" "$clrBlue" "$URL" "$clrReset"
  fi
  return $ec
}

# -----------------------------
# Remove all
# -----------------------------
remove_node() {
  if [[ ! -d "$BC_DIR" ]] && ! docker ps -a --format '{{.Names}}' | grep -q '^blockcastd$'; then
    warn "$(tr dir_missing): $BC_DIR"; return 0
  fi
  read -rp "$(tr remove_confirm) " CONF
  if [[ "$CONF" != "yes" ]]; then warn "$(tr cancelled)"; return 0; fi
  if command -v docker >/dev/null 2>&1; then
    (cd "$BC_DIR" 2>/dev/null && docker compose down -v --remove-orphans) || true
  fi
  if [[ -f "$ENV_FILE" ]]; then
    read -rp "$(tr keep_env_q) " KEEP
    if [[ -z "$KEEP" || "$KEEP" =~ ^[Yy]$ ]]; then
      local TS
      TS="$(date +%Y%m%d_%H%M%S)"
      cp "$ENV_FILE" "$HOME/blockcast.env.$TS.bak" && ok "$(tr backup_saved) $HOME/blockcast.env.$TS.bak"
    fi
  fi
  if command -v docker >/dev/null 2>&1; then
    info "Removing blockcast images..."
    local IMG_IDS
    IMG_IDS=$(docker images --format '{{.Repository}} {{.ID}}' | awk -v repo="$IMAGE_REPO" '$1==repo{print $2}') || true
    if [[ -n "${IMG_IDS:-}" ]]; then docker rmi -f ${IMG_IDS} || true; fi
  fi
  rm -rf "$BC_DIR"; ok "$(tr removed_ok)"
}

# -----------------------------
# Main menu (renumbered without options 8 and 9)
# -----------------------------
main_menu() {
  choose_language
  info "$(tr need_root_warn)" || true
  while true; do
    clear; display_logo; hr
    echo -e "${clrBold}${clrMag}$(tr menu_title)${clrReset} ${clrDim}(v${SCRIPT_VERSION})${clrReset}\n"
    echo -e "${clrGreen}1)${clrReset} $(tr m1_bootstrap)"
    echo -e "${clrGreen}2)${clrReset} $(tr m2_create)"
    echo -e "${clrGreen}3)${clrReset} $(tr m3_start)"
    echo -e "${clrGreen}4)${clrReset} $(tr m4_restart)"
    echo -e "${clrGreen}5)${clrReset} $(tr m5_logs)"
    echo -e "${clrGreen}6)${clrReset} $(tr m6_register)"
    echo -e "${clrGreen}7)${clrReset} $(tr m7_status)"
    echo -e "${clrGreen}8)${clrReset} $(tr m8_remove)"
    echo -e "${clrGreen}9)${clrReset} $(tr m9_lang)"
    echo -e "${clrGreen}10)${clrReset} $(tr m10_exit)"
    hr
    read -rp "> " choice
    case "${choice:-}" in
      1) bootstrap_setup ;;
      2) create_dir_and_compose ;;
      3) start_node ;;
      4) restart_node ;;
      5) show_logs ;;
      6) register_node ;;
      7) show_status ;;
      8) remove_node ;;
      9) choose_language ;;
      10) exit 0 ;;
      *) ;;
    esac
    echo -e "\n$(tr press_enter)"; read -r
  done
}

main_menu
