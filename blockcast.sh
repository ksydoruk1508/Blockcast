#!/usr/bin/env bash
# =====================================================================
# Blockcast BEACON — Installer/Manager (RU/EN), per official guide
# Docs: https://docs.blockcast.network/main/getting-started/how-do-i-participate-in-the-network/beacon/start-running-your-beacon-today
# Repo: https://github.com/Blockcast/beacon-docker-compose
# Target: Ubuntu/Debian. Requires sudo for installs.
# Version: 2.1.0
# =====================================================================
set -Eeuo pipefail

# -----------------------------
# Colors / UI
# -----------------------------
cG=$'\033[0;32m'
cC=$'\033[0;36m'
cB=$'\033[0;34m'
cR=$'\033[0;31m'
cY=$'\033[1;33m'
cM=$'\033[1;35m'
c0=$'\033[0m'
cBold=$'\033[1m'
cDim=$'\033[2m'

ok(){   echo -e "${cG}[OK]${c0} ${*}"; }
info(){ echo -e "${cC}[INFO]${c0} ${*}"; }
warn(){ echo -e "${cY}[WARN]${c0} ${*}"; }
err(){  echo -e "${cR}[ERROR]${c0} ${*}"; }
hr(){   echo -e "${cDim}────────────────────────────────────────────────────────${c0}"; }

logo(){ cat <<'EOF'
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
# Paths / Config
# -----------------------------
SCRIPT_VERSION="2.1.0"
REPO_URL="https://github.com/Blockcast/beacon-docker-compose"

BC_DIR="$HOME/blockcast"
ENV_FILE="$BC_DIR/.env"
COMPOSE_FILE="$BC_DIR/docker-compose.yml"

# По вашему требованию видим 0.0.0.0:8443->8080/tcp у blockcastd
HOST_PORT="${HOST_PORT:-8443}"
CONTAINER_PORT="8080"

# Ключи
KEY_DIR="$HOME/.blockcast/certs"
KEY_FILE="$KEY_DIR/gw_challenge.key"
LEGACY_KEY="$KEY_DIR/gateway.key"
BACKUP_DIR="$BC_DIR/backup"

# -----------------------------
# Language (RU/EN)
# -----------------------------
LANG="ru"
choose_lang(){
  clear; logo
  echo -e "\n${cBold}${cM}Select language / Выберите язык${c0}"
  echo "1) Русский"
  echo "2) English"
  read -rp "> " a
  case "${a:-}" in
    2) LANG="en" ;;
    *) LANG="ru" ;;
  esac
}
tr(){
  local k="${1:-}"; [[ -z "$k" ]] && return 0
  if [[ "$LANG" == "en" ]]; then
    case "$k" in
      need_root) echo "Some steps need sudo/root." ;;
      fixing) echo "Fixing APT repos (cross-arch) and installing base deps..." ;;
      deps_done) echo "Base deps installed." ;;
      docker) echo "Installing Docker Engine + compose plugin..." ;;
      docker_ok) echo "Docker ready." ;;
      ufw) echo "Configuring UFW (firewall)..." ;;
      ufw_ok) echo "Firewall rules applied." ;;
      ask_port) echo "Enter public port to expose on blockcastd (default 8443 -> container 8080):" ;;
      fetch) echo "Preparing folder and fetching official compose..." ;;
      repo_ok) echo "Fetched docker-compose.yml from official repo." ;;
      patch_ports) echo "Ensuring ${HOST_PORT}:${CONTAINER_PORT} published on service 'blockcastd'..." ;;
      remove_watchtower_port) echo "Removing accidental port mapping from 'watchtower'..." ;;
      start) echo "Starting services (docker compose up -d)..." ;;
      started) echo "Services started." ;;
      restart) echo "Restarting services..." ;;
      restarted) echo "Services restarted." ;;
      logs) echo "Following logs (Ctrl+C to stop)..." ;;
      reg) echo "Running 'docker compose exec blockcastd blockcastd init'..." ;;
      reg_hwid) echo "Hardware ID:" ;;
      reg_ck) echo "Challenge Key:" ;;
      reg_url) echo "Registration URL:" ;;
      loc_hint) echo "Your IP geolocation (city/region/country/loc):" ;;
      backup) echo "Backing up private key..." ;;
      backup_done) echo "Key backed up to:" ;;
      backup_miss) echo "Key file not found. Run registration first." ;;
      status) echo "Docker status:" ;;
      change_port) echo "Changing published port and recreating containers..." ;;
      remove) echo "Full removal (containers/images/folder). Type 'yes' to confirm:" ;;
      removed) echo "Blockcast removed (keys kept)." ;;
      menu) echo "Blockcast BEACON — installer & manager" ;;
      press) echo "Press Enter to return to menu..." ;;
      compose_invalid) echo "docker-compose.yml failed to validate. Check syntax above." ;;
      conflicts) echo "Removing old containers with conflicting names..." ;;
      compose_missing) echo "docker-compose.yml not found in the official repo." ;;
      dir_missing) echo "Directory not found:" ;;
      svc_blockcastd_missing) echo "Service 'blockcastd' not found — skipping port patch." ;;

      # menu items
      m1) echo "Install deps (APT fix) and Docker" ;;
      m2) echo "Configure firewall (UFW) and open port" ;;
      m3) echo "Fetch official compose and patch ports" ;;
      m4) echo "Start (docker compose up -d)" ;;
      m5) echo "Restart (force-recreate)" ;;
      m6) echo "Registration (blockcastd init)" ;;
      m7) echo "Logs (follow)" ;;
      m8) echo "Containers status" ;;
      m9) echo "Backup private key" ;;
      m10) echo "Change published port and restart" ;;
      m11) echo "Full removal (keep keys)" ;;
      m12) echo "Change language" ;;
      m13) echo "Exit" ;;
    esac
  else
    case "$k" in
      need_root) echo "Некоторые шаги требуют sudo/root." ;;
      fixing) echo "Чиню APT-репозитории (кросс-арх) и устанавливаю базовые зависимости..." ;;
      deps_done) echo "Базовые зависимости установлены." ;;
      docker) echo "Ставлю Docker Engine + compose-плагин..." ;;
      docker_ok) echo "Docker готов." ;;
      ufw) echo "Настраиваю UFW (фаервол)..." ;;
      ufw_ok) echo "Правила фаервола применены." ;;
      ask_port) echo "Введите внешний порт, публикуемый у blockcastd (по умолчанию 8443 -> контейнер 8080):" ;;
      fetch) echo "Готовлю каталог и забираю официальный compose..." ;;
      repo_ok) echo "Получен docker-compose.yml из официального репозитория." ;;
      patch_ports) echo "Гарантирую публикацию ${HOST_PORT}:${CONTAINER_PORT} у сервиса 'blockcastd'..." ;;
      remove_watchtower_port) echo "Убираю лишний проброс порта из 'watchtower'..." ;;
      start) echo "Запускаю сервисы (docker compose up -d)..." ;;
      started) echo "Сервисы запущены." ;;
      restart) echo "Перезапускаю сервисы..." ;;
      restarted) echo "Сервисы перезапущены." ;;
      logs) echo "Показываю логи (Ctrl+C для выхода)..." ;;
      reg) echo "Выполняю 'docker compose exec blockcastd blockcastd init'..." ;;
      reg_hwid) echo "Hardware ID:" ;;
      reg_ck) echo "Challenge Key:" ;;
      reg_url) echo "Ссылка для регистрации:" ;;
      loc_hint) echo "Геолокация по IP (city/region/country/loc):" ;;
      backup) echo "Делаю бэкап приватного ключа..." ;;
      backup_done) echo "Ключ сохранён в:" ;;
      backup_miss) echo "Файл ключа не найден. Сначала выполните регистрацию." ;;
      status) echo "Статус Docker:" ;;
      change_port) echo "Меняю публикуемый порт и пересоздаю контейнеры..." ;;
      remove) echo "Полное удаление (контейнеры/образы/папка). Введите 'yes' для подтверждения:" ;;
      removed) echo "Blockcast удалён (ключи сохранены)." ;;
      menu) echo "Blockcast BEACON — установщик и менеджер" ;;
      press) echo "Нажмите Enter для возврата в меню..." ;;
      compose_invalid) echo "docker-compose.yml не валиден. Проверьте синтаксис выше." ;;
      conflicts) echo "Удаляю старые контейнеры с конфликтующими именами..." ;;
      compose_missing) echo "В официальном репозитории не найден docker-compose.yml." ;;
      dir_missing) echo "Каталог не найден:" ;;
      svc_blockcastd_missing) echo "Сервис 'blockcastd' не найден — пропуск патча портов." ;;

      # пункты меню
      m1) echo "Установить зависимости (APT fix) и Docker" ;;
      m2) echo "Настроить фаервол (UFW) и открыть порт" ;;
      m3) echo "Загрузить официальный compose и пропатчить порты" ;;
      m4) echo "Запустить (docker compose up -d)" ;;
      m5) echo "Перезапустить (force-recreate)" ;;
      m6) echo "Регистрация (blockcastd init)" ;;
      m7) echo "Логи (follow)" ;;
      m8) echo "Статус контейнеров" ;;
      m9) echo "Бэкап приватного ключа" ;;
      m10) echo "Изменить публикуемый порт и перезапустить" ;;
      m11) echo "Полное удаление (ключи сохраняются)" ;;
      m12) echo "Сменить язык / Change language" ;;
      m13) echo "Выход" ;;
    esac
  fi
}

need_sudo(){
  if [[ $(id -u) -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
    err "sudo не найден. Запустите под root или установите sudo."
    exit 1
  fi
}
run(){ if [[ $(id -u) -ne 0 ]]; then sudo bash -lc "$*"; else bash -lc "$*"; fi; }

# -----------------------------
# APT: cross-arch repo fix + deps
# -----------------------------
get_codename() {
  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -cs
  else
    . /etc/os-release 2>/dev/null || true
    echo "${UBUNTU_CODENAME:-jammy}"
  fi
}
fix_apt_repos() {
  local host_arch foreign arches codename
  host_arch="$(dpkg --print-architecture)"
  foreign="$(dpkg --print-foreign-architectures || true)"
  codename="$(get_codename)"

  arches="$host_arch"
  if grep -qw "amd64" <<<"$foreign"; then arches="$arches amd64"; fi
  if grep -qw "arm64" <<<"$foreign"; then arches="$arches arm64"; fi

  info "APT: host=${host_arch}; foreign=${foreign:-none}; codename=${codename}"
  run "bash -lc 'cat > /etc/apt/sources.list <<EOF
# --- Managed by Blockcast installer ---
EOF'"

  add_archive_amd64() {
    cat <<EOF
deb [arch=amd64] http://archive.ubuntu.com/ubuntu ${codename} main restricted universe multiverse
deb [arch=amd64] http://archive.ubuntu.com/ubuntu ${codename}-updates main restricted universe multiverse
deb [arch=amd64] http://archive.ubuntu.com/ubuntu ${codename}-backports main restricted universe multiverse
deb [arch=amd64] http://security.ubuntu.com/ubuntu ${codename}-security main restricted universe multiverse
EOF
  }
  add_ports_arm64() {
    cat <<EOF
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports ${codename} main restricted universe multiverse
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports ${codename}-updates main restricted universe multiverse
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports ${codename}-backports main restricted universe multiverse
deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports ${codename}-security main restricted universe multiverse
EOF
  }

  if grep -qw "amd64" <<<"$arches"; then add_archive_amd64 | run "cat >> /etc/apt/sources.list"; fi
  if grep -qw "arm64" <<<"$arches"; then add_ports_arm64  | run "cat >> /etc/apt/sources.list"; fi

  run "rm -rf /var/lib/apt/lists/*"
  run "apt-get clean"
  run "apt-get -o Acquire::Retries=3 update"
}
install_deps(){
  info "$(tr fixing)"
  fix_apt_repos
  run "apt-get install -y curl git jq ufw ca-certificates gnupg lsb-release"
  ok "$(tr deps_done)"
}

# -----------------------------
# Docker + UFW
# -----------------------------
install_docker(){
  info "$(tr docker)"; need_sudo
  if ! command -v docker >/dev/null 2>&1; then
    run "apt-get install -y docker.io"
  fi
  if ! docker compose version >/dev/null 2>&1; then
    run "apt-get install -y docker-compose-plugin"
  fi
  run "systemctl enable --now docker" || true
  docker --version || true
  docker compose version || true
  ok "$(tr docker_ok)"
}
setup_ufw(){
  info "$(tr ufw)"; need_sudo
  run "apt-get install -y ufw >/dev/null 2>&1 || true"
  run "ufw allow 22 >/dev/null 2>&1 || true"
  run "ufw allow ssh >/dev/null 2>&1 || true"
  run "ufw allow ${HOST_PORT}/tcp >/dev/null 2>&1 || true"
  yes | run ufw enable || true
  run ufw reload || true
  ok "$(tr ufw_ok)"
}

# -----------------------------
# Compose fetch / patch
# -----------------------------
fetch_compose(){
  info "$(tr fetch)"; hr
  mkdir -p "$BC_DIR"; cd "$BC_DIR"
  rm -rf "$BC_DIR/.tmp_repo" 2>/dev/null || true
  git clone --depth 1 "$REPO_URL" "$BC_DIR/.tmp_repo" >/dev/null 2>&1 || true
  if [[ -f "$BC_DIR/.tmp_repo/docker-compose.yml" ]]; then
    cp "$BC_DIR/.tmp_repo/docker-compose.yml" "$COMPOSE_FILE"
    ok "$(tr repo_ok)"
  else
    err "Не найден docker-compose.yml в официальном репозитории."
    exit 1
  fi
  rm -rf "$BC_DIR/.tmp_repo" || true

  read -rp "${cBold}$(tr ask_port)${c0} [${HOST_PORT}] " ans
  HOST_PORT="${ans:-$HOST_PORT}"

  cat > "$ENV_FILE" <<EOF
HOST_PORT=${HOST_PORT}
CONTAINER_PORT=${CONTAINER_PORT}
EOF

  info "$(tr patch_ports)"

  # 1) если у blockcastd нет секции ports — добавим
  if grep -qE '^[[:space:]]*blockcastd:' "$COMPOSE_FILE"; then
    if ! awk '/^[[:space:]]*blockcastd:/{f=1} f && /^[[:space:]]*ports:/{p=1} f && /^[^[:space:]]/{f=0} END{exit !(p)}' "$COMPOSE_FILE"; then
      # вставить ports сразу после 'blockcastd:'
      awk '
        BEGIN{ins=0}
        /^[[:space:]]*blockcastd:/ && ins==0 {print; print "    ports:\n      - \"'"${HOST_PORT}"':'"${CONTAINER_PORT}"'\""; ins=1; next}
        {print}
      ' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp" && mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"
    else
      # есть ports — убедимся, что есть строка "*:8080"
      if ! awk -v cp="$CONTAINER_PORT" '/^\s*blockcastd:/{f=1} f && /^\s*ports:/{p=1}
           f&&p&&/^\s*[^- ]/{f=0;p=0}
           f&&p&&/-\s*".*:'"$CONTAINER_PORT"'"/{found=1}
           END{exit !(found)}' "$COMPOSE_FILE"; then
        awk '/^\s*blockcastd:/{f=1} f&&/^\s*ports:/{p=1}
             f&&p&&/^\s*[^- ]/{f=0;p=0}
             {print}
             f&&p&&!done&&/^\s*ports:/{print "      - \"'"${HOST_PORT}"':'"${CONTAINER_PORT}"'\""; done=1}
            ' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp" && mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"
      fi
      # заменить существующее Х:8080 на наш HOST_PORT:8080
      sed -i -E "s/(-\s*\")([0-9]+)(:${CONTAINER_PORT}\")/\\1${HOST_PORT}\\3/g" "$COMPOSE_FILE"
    fi
  else
    warn "Сервис 'blockcastd' не найден — пропуск патча портов."
  fi

  # 2) убрать возможный проброс порта у watchtower (8443:8080) — чтобы не путать
  if awk '/^\s*watchtower:/{f=1} f&&/^\s*ports:/{p=1} f&&p&&/^\s*[^- ]/{f=0;p=0} f&&p&&/-\s*".*:8080"/{exit 0} END{exit 1}' "$COMPOSE_FILE"; then
    info "$(tr remove_watchtower_port)"
    # удаляем строки вида  - "xxxx:8080" в секции watchtower->ports
    awk '
      /^\s*watchtower:/{f=1}
      f && /^\s*ports:/{p=1}
      f && p && /^\s*[^- ]/{f=0; p=0}
      { 
        if (f && p && $0 ~ /- *".*:8080"/) next; 
        print 
      }
    ' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp" && mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"
  fi

  # Валидация compose
  if ! docker compose -f "$COMPOSE_FILE" config >/dev/null 2>&1; then
    docker compose -f "$COMPOSE_FILE" config || true
    err "$(tr compose_invalid)"
    exit 1
  fi
}

# -----------------------------
# Start / Restart / Logs / Status
# -----------------------------
conflicts_cleanup(){
  info "$(tr conflicts)"
  docker rm -f blockcastd control_proxy beacond watchtower 2>/dev/null || true
}
start_services(){
  cd "$BC_DIR" || { err "Каталог не найден: $BC_DIR"; return 1; }
  conflicts_cleanup
  info "$(tr start)"
  docker compose up -d
  ok "$(tr started)"
}
restart_services(){
  cd "$BC_DIR" || { err "Каталог не найден: $BC_DIR"; return 1; }
  info "$(tr restart)"
  docker compose up -d --force-recreate
  ok "$(tr restarted)"
}
show_logs(){
  cd "$BC_DIR" || { err "Каталог не найден: $BC_DIR"; return 1; }
  info "$(tr logs)"
  docker compose logs -fn 500
}
show_status(){
  cd "$BC_DIR" || { err "Каталог не найден: $BC_DIR"; return 1; }
  echo "$(tr status)"
  docker compose ps -a
}

# -----------------------------
# Registration (blockcastd init)
# -----------------------------
register_beacon(){
  cd "$BC_DIR" || { err "Каталог не найден: $BC_DIR"; return 1; }
  info "$(tr reg)"
  local j; j=$(curl -s https://ipinfo.io || true)
  if [[ -n "$j" ]]; then
    echo "$(tr loc_hint)"
    echo "$j" | jq '.city, .region, .country, .loc' || echo "$j"
  fi
  local TMP; TMP=$(mktemp)
  set +e
  docker compose exec blockcastd blockcastd init | tee "$TMP"
  local ec=$?
  set -e
  local HWID CK URL
  HWID=$(grep -E '^Hardware ID:' -A1 "$TMP" | tail -n1 | tr -d '\r\n' || true)
  CK=$(grep -E '^Challenge Key:' -A1 "$TMP" | tail -n1 | tr -d '\r\n' || true)
  URL=$(grep -Eo 'https?://[^ ]+' "$TMP" | head -n1 || true)
  rm -f "$TMP"

  [[ -n "$HWID" ]] && printf "%b%s%b %s\n" "$cBold" "$(tr reg_hwid)" "$c0" "$HWID"
  [[ -n "$CK"   ]] && printf "%b%s%b %s\n" "$cBold" "$(tr reg_ck)"   "$c0" "$CK"
  [[ -n "$URL"  ]] && printf "%b%s%b %b%s%b\n" "$cBold" "$(tr reg_url)" "$c0" "$cB" "$URL" "$c0"

  echo
  echo "${cDim}Важно: сохраните приватный ключ устройства (${KEY_FILE} или ${LEGACY_KEY}).${c0}"
  return $ec
}

# -----------------------------
# Backup private key
# -----------------------------
backup_key(){
  echo "$(tr backup)"
  mkdir -p "$BACKUP_DIR"
  local ts; ts=$(date +%Y%m%d_%H%M%S)
  if [[ -f "$KEY_FILE" ]]; then
    cp -f "$KEY_FILE" "$BACKUP_DIR/gw_challenge.key.$ts"
    chmod 600 "$BACKUP_DIR/gw_challenge.key.$ts" || true
    ok "$(tr backup_done) $BACKUP_DIR/gw_challenge.key.$ts"
  elif [[ -f "$LEGACY_KEY" ]]; then
    cp -f "$LEGACY_KEY" "$BACKUP_DIR/gateway.key.$ts"
    chmod 600 "$BACKUP_DIR/gateway.key.$ts" || true
    ok "$(tr backup_done) $BACKUP_DIR/gateway.key.$ts"
  else
    err "$(tr backup_miss)"
    return 1
  fi
}

# -----------------------------
# Change port (repatch + restart)
# -----------------------------
change_port(){
  cd "$BC_DIR" || { err "Каталог не найден: $BC_DIR"; return 1; }
  read -rp "${cBold}$(tr ask_port)${c0} [${HOST_PORT}] " ans
  HOST_PORT="${ans:-$HOST_PORT}"
  sed -i -E "s/^HOST_PORT=.*/HOST_PORT=${HOST_PORT}/" "$ENV_FILE" 2>/dev/null || true

  info "$(tr patch_ports)"
  if grep -qE '^[[:space:]]*blockcastd:' "$COMPOSE_FILE"; then
    # если нет ports — добавим
    if ! awk '/^[[:space:]]*blockcastd:/{f=1} f && /^[[:space:]]*ports:/{p=1} f && /^[^[:space:]]/{f=0} END{exit !(p)}' "$COMPOSE_FILE"; then
      awk '
        BEGIN{ins=0}
        /^[[:space:]]*blockcastd:/ && ins==0 {print; print "    ports:\n      - \"'"${HOST_PORT}"':'"${CONTAINER_PORT}"'\""; ins=1; next}
        {print}
      ' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp" && mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"
    else
      # заменить существующую публикацию на новый HOST_PORT
      sed -i -E "s/(-\s*\")([0-9]+)(:${CONTAINER_PORT}\")/\\1${HOST_PORT}\\3/g" "$COMPOSE_FILE"
      # если вдруг отсутствовала строка — добавим
      if ! grep -qE "^[[:space:]]*-[[:space:]]*\"${HOST_PORT}:${CONTAINER_PORT}\"" "$COMPOSE_FILE"; then
        awk '/^\s*blockcastd:/{f=1} f&&/^\s*ports:/{p=1}
             f&&p&&/^\s*[^- ]/{f=0;p=0}
             {print}
             f&&p&&!done&&/^\s*ports:/{print "      - \"'"${HOST_PORT}"':'"${CONTAINER_PORT}"'\""; done=1}
            ' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp" && mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"
      fi
    fi
  else
    warn "Сервис 'blockcastd' не найден — пропуск патча портов."
  fi

  # убрать публикацию у watchtower, если есть
  if awk '/^\s*watchtower:/{f=1} f&&/^\s*ports:/{p=1} f&&p&&/^\s*[^- ]/{f=0;p=0} f&&p&&/-\s*".*:8080"/{exit 0} END{exit 1}' "$COMPOSE_FILE"; then
    info "$(tr remove_watchtower_port)"
    awk '
      /^\s*watchtower:/{f=1}
      f && /^\s*ports:/{p=1}
      f && p && /^\s*[^- ]/{f=0; p=0}
      { if (f && p && $0 ~ /- *".*:8080"/) next; print }
    ' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp" && mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"
  fi

  setup_ufw
  restart_services
}

# -----------------------------
# Full removal
# -----------------------------
remove_all(){
  read -rp "$(tr remove) " CONF
  [[ "$CONF" == "yes" ]] || { warn "Отменено."; return 0; }
  (cd "$BC_DIR" 2>/dev/null && docker compose down -v --remove-orphans) || true
  docker rm -f blockcastd control_proxy beacond watchtower 2>/dev/null || true
  docker images 'blockcast/cdn_gateway_go' -q | xargs -r docker rmi -f
  rm -rf "$BC_DIR"
  ok "$(tr removed)"
}

# -----------------------------
# Menu
# -----------------------------
main_menu(){
  choose_lang
  info "$(tr need_root)"; hr
  while true; do
    clear; logo; hr
    echo -e "${cBold}${cM}$(tr menu)${c0} ${cDim}(v${SCRIPT_VERSION})${c0}\n"
    echo "1)  $(tr m1)"
    echo "2)  $(tr m2)"
    echo "3)  $(tr m3)"
    echo "4)  $(tr m4)"
    echo "5)  $(tr m5)"
    echo "6)  $(tr m6)"
    echo "7)  $(tr m7)"
    echo "8)  $(tr m8)"
    echo "9)  $(tr m9)"
    echo "10) $(tr m10)"
    echo "11) $(tr m11)"
    echo "12) $(tr m12)"
    echo "13) $(tr m13)"
    hr
    read -rp "> " ch
    case "${ch:-}" in
      1) install_deps; install_docker ;;
      2) setup_ufw ;;
      3) fetch_compose ;;
      4) start_services ;;
      5) restart_services ;;
      6) register_beacon ;;
      7) show_logs ;;
      8) show_status ;;
      9) backup_key ;;
      10) change_port ;;
      11) remove_all ;;
      12) choose_lang ;;
      13) exit 0 ;;
      *) ;;
    esac
    echo -e "\n$(tr press)"; read -r
  done
}

main_menu
