#!/usr/bin/env bash
# =====================================================================
# Blockcast BEACON — Installer/Manager (RU/EN), per official guide
# Docs:  https://docs.blockcast.network/main/getting-started/how-do-i-participate-in-the-network/beacon/start-running-your-beacon-today
# Repo:  https://github.com/Blockcast/beacon-docker-compose
# Target: Ubuntu/Debian (needs sudo for installs)
# Version: 2.2.0
# =====================================================================
set -Eeuo pipefail

# -----------------------------
# Colors / UI
# -----------------------------
cG=$'\033[0;32m'; cC=$'\033[0;36m'; cB=$'\033[0;34m'; cR=$'\033[0;31m'
cY=$'\033[1;33m'; cM=$'\033[1;35m'; c0=$'\033[0m'; cBold=$'\033[1m'; cDim=$'\033[2m'

ok()   { echo -e "${cG}[OK]${c0} ${*}"; }
info() { echo -e "${cC}[INFO]${c0} ${*}"; }
warn() { echo -e "${cY}[WARN]${c0} ${*}"; }
err()  { echo -e "${cR}[ERROR]${c0} ${*}"; }
hr()   { echo -e "${cDim}────────────────────────────────────────────────────────${c0}"; }

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
SCRIPT_VERSION="2.2.0"
REPO_RAW_YML="https://raw.githubusercontent.com/Blockcast/beacon-docker-compose/refs/heads/main/docker-compose.yml"

COMPOSE_HOME="$HOME/.blockcast/compose"
COMPOSE_FILE="$COMPOSE_HOME/docker-compose.yml"
OVERRIDE_FILE="$COMPOSE_HOME/docker-compose.override.yml"

# Порт на хосте -> порт в контейнере (TLS-фронт beacond слушает 8080)
HOST_PORT="${HOST_PORT:-8443}"
CONTAINER_PORT="8080"

# Старый путь (для авто-миграции, если ранее использовали ~/blockcast)
OLD_DIR="$HOME/blockcast"

# Ключи
KEY_DIR="$HOME/.blockcast/certs"
KEY_FILE="$KEY_DIR/gw_challenge.key"
LEGACY_KEY="$KEY_DIR/gateway.key"
BACKUP_DIR="$HOME/blockcast/backup"

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
      need_root)             echo "Some steps need sudo/root." ;;
      fixing)                echo "Fixing APT repos (cross-arch) and installing base deps..." ;;
      deps_done)             echo "Base deps installed." ;;
      docker)                echo "Installing Docker Engine + compose plugin..." ;;
      docker_ok)             echo "Docker ready." ;;
      ufw)                   echo "Configuring UFW (firewall)..." ;;
      ufw_ok)                echo "Firewall rules applied." ;;
      ask_port)              echo "Enter public port for blockcastd (default 8443 -> container 8080):" ;;
      fetch)                 echo "Preparing compose directory and fetching official compose..." ;;
      compose_home_ready)    echo "Compose directory is ready:" ;;
      repo_ok)               echo "Fetched docker-compose.yml from official repo." ;;
      repo_fail)             echo "Failed to fetch docker-compose.yml from official repo." ;;
      migrated_old)          echo "Found old compose in ~/blockcast, migrating to ~/.blockcast/compose..." ;;
      override_write)        echo "Writing override to publish ${HOST_PORT}:${CONTAINER_PORT} on 'blockcastd'..." ;;
      override_ok)           echo "Override file written." ;;
      override_skip_wt)      echo "No 'watchtower' service in base compose, skipping ports cleanup for it." ;;
      validate)              echo "Validating compose (base + override)..." ;;
      compose_invalid)       echo "Compose validation failed. Check the printed config and fix errors above." ;;
      conflicts)             echo "Removing old containers with conflicting names..." ;;
      port_conflicts)        echo "Removing containers publishing port ${HOST_PORT}..." ;;
      start)                 echo "Starting services (docker compose up -d)..." ;;
      started)               echo "Services started." ;;
      restart)               echo "Restarting services (force-recreate)..." ;;
      restarted)             echo "Services restarted." ;;
      logs)                  echo "Following logs (Ctrl+C to stop)..." ;;
      status)                echo "Docker status:" ;;
      reg)                   echo "Running 'docker compose exec blockcastd blockcastd init'..." ;;
      reg_hwid)              echo "Hardware ID:" ;;
      reg_ck)                echo "Challenge Key:" ;;
      reg_url)               echo "Registration URL:" ;;
      loc_hint)              echo "Your IP geolocation (city/region/country/loc):" ;;
      backup)                echo "Backing up private key..." ;;
      backup_done)           echo "Key backed up to:" ;;
      backup_miss)           echo "Key file not found. Run registration first." ;;
      remove)                echo "Full removal (containers/images/folders). Type 'yes' to confirm:" ;;
      removed)               echo "Blockcast removed (keys kept)." ;;
      dir_missing)           echo "Directory not found:" ;;
      press)                 echo "Press Enter to return to menu..." ;;
      # menu items
      menu)                  echo "Blockcast BEACON — installer & manager" ;;
      m1) echo "Install deps (APT fix) and Docker" ;;
      m2) echo "Configure firewall (UFW) and open port" ;;
      m3) echo "Fetch official compose (into ~/.blockcast/compose) and write override" ;;
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
      need_root)             echo "Некоторые шаги требуют sudo/root." ;;
      fixing)                echo "Чиню APT-репозитории (кросс-арх) и устанавливаю базовые зависимости..." ;;
      deps_done)             echo "Базовые зависимости установлены." ;;
      docker)                echo "Ставлю Docker Engine + compose-плагин..." ;;
      docker_ok)             echo "Docker готов." ;;
      ufw)                   echo "Настраиваю UFW (фаервол)..." ;;
      ufw_ok)                echo "Правила фаервола применены." ;;
      ask_port)              echo "Введите внешний порт для blockcastd (по умолчанию 8443 -> контейнер 8080):" ;;
      fetch)                 echo "Готовлю каталог compose и скачиваю официальный compose..." ;;
      compose_home_ready)    echo "Каталог compose готов:" ;;
      repo_ok)               echo "Получен docker-compose.yml из официального репозитория." ;;
      repo_fail)             echo "Не удалось получить docker-compose.yml из официального репозитория." ;;
      migrated_old)          echo "Найден старый compose в ~/blockcast — мигрирую в ~/.blockcast/compose..." ;;
      override_write)        echo "Записываю override для публикации ${HOST_PORT}:${CONTAINER_PORT} у 'blockcastd'..." ;;
      override_ok)           echo "Override-файл записан." ;;
      override_skip_wt)      echo "Сервиса 'watchtower' нет в базовом compose — пропускаю чистку его портов." ;;
      validate)              echo "Проверяю конфигурацию (base + override)..." ;;
      compose_invalid)       echo "Валидация compose не прошла. Проверьте напечатанный конфиг и исправьте ошибки." ;;
      conflicts)             echo "Удаляю контейнеры с конфликтующими именами..." ;;
      port_conflicts)        echo "Удаляю контейнеры, публикующие порт ${HOST_PORT}..." ;;
      start)                 echo "Запускаю сервисы (docker compose up -d)..." ;;
      started)               echo "Сервисы запущены." ;;
      restart)               echo "Перезапускаю сервисы (force-recreate)..." ;;
      restarted)             echo "Сервисы перезапущены." ;;
      logs)                  echo "Показываю логи (Ctrl+C для выхода)..." ;;
      status)                echo "Статус Docker:" ;;
      reg)                   echo "Выполняю 'docker compose exec blockcastd blockcastd init'..." ;;
      reg_hwid)              echo "Hardware ID:" ;;
      reg_ck)                echo "Challenge Key:" ;;
      reg_url)               echo "Ссылка для регистрации:" ;;
      loc_hint)              echo "Геолокация по IP (city/region/country/loc):" ;;
      backup)                echo "Делаю бэкап приватного ключа..." ;;
      backup_done)           echo "Ключ сохранён в:" ;;
      backup_miss)           echo "Файл ключа не найден. Сначала выполните регистрацию." ;;
      remove)                echo "Полное удаление (контейнеры/образы/папки). Введите 'yes' для подтверждения:" ;;
      removed)               echo "Blockcast удалён (ключи сохранены)." ;;
      dir_missing)           echo "Каталог не найден:" ;;
      press)                 echo "Нажмите Enter для возврата в меню..." ;;
      # пункты меню
      menu)                  echo "Blockcast BEACON — установщик и менеджер" ;;
      m1) echo "Установить зависимости (APT fix) и Docker" ;;
      m2) echo "Настроить фаервол (UFW) и открыть порт" ;;
      m3) echo "Загрузить официальный compose (в ~/.blockcast/compose) и написать override" ;;
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
get_codename(){
  if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -cs
  else
    . /etc/os-release 2>/dev/null || true
    echo "${UBUNTU_CODENAME:-jammy}"
  fi
}
fix_apt_repos(){
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

  add_archive_amd64(){
    cat <<EOF
deb [arch=amd64] http://archive.ubuntu.com/ubuntu ${codename} main restricted universe multiverse
deb [arch=amd64] http://archive.ubuntu.com/ubuntu ${codename}-updates main restricted universe multiverse
deb [arch=amd64] http://archive.ubuntu.com/ubuntu ${codename}-backports main restricted universe multiverse
deb [arch=amd64] http://security.ubuntu.com/ubuntu ${codename}-security main restricted universe multiverse
EOF
  }
  add_ports_arm64(){
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
# Compose fetch / override / validate
# -----------------------------
ensure_compose_home(){
  info "$(tr fetch)"; hr
  mkdir -p "$COMPOSE_HOME"
  ok "$(tr compose_home_ready) $COMPOSE_HOME"

  # migrate old layout if present
  if [[ -f "$OLD_DIR/docker-compose.yml" && ! -f "$COMPOSE_FILE" ]]; then
    info "$(tr migrated_old)"
    mv "$OLD_DIR/docker-compose.yml" "$COMPOSE_FILE"
  fi

  # fetch base compose if absent
  if [[ ! -f "$COMPOSE_FILE" ]]; then
    if curl -fsSL "$REPO_RAW_YML" -o "$COMPOSE_FILE"; then
      ok "$(tr repo_ok)"
    else
      err "$(tr repo_fail)"
      exit 1
    fi
  else
    ok "$(tr repo_ok)"
  fi
}

write_override(){
  # ask port (once here or when changing)
  read -rp "${cBold}$(tr ask_port)${c0} [${HOST_PORT}] " _ans
  HOST_PORT="${_ans:-$HOST_PORT}"

  info "$(tr override_write)"
  # check if watchtower exists in base compose
  local has_wt=0
  if grep -qE '^[[:space:]]*watchtower:' "$COMPOSE_FILE"; then has_wt=1; fi

  cat > "$OVERRIDE_FILE" <<EOF
services:
  blockcastd:
    ports:
      - "${HOST_PORT}:${CONTAINER_PORT}"
EOF

  if [[ "$has_wt" -eq 1 ]]; then
    # ensure watchtower has no published ports
    cat >> "$OVERRIDE_FILE" <<'EOF'
  watchtower:
    ports: []
EOF
  else
    info "$(tr override_skip_wt)"
  fi

  ok "$(tr override_ok)"
}

validate_compose(){
  info "$(tr validate)"
  if ! (cd "$COMPOSE_HOME" && docker compose -f "$COMPOSE_FILE" -f "$OVERRIDE_FILE" config >/dev/null 2>&1); then
    (cd "$COMPOSE_HOME" && docker compose -f "$COMPOSE_FILE" -f "$OVERRIDE_FILE" config || true)
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

  info "$(tr port_conflicts)"
  docker ps --filter "publish=${HOST_PORT}" -q | xargs -r docker rm -f || true
}
start_services(){
  [[ -d "$COMPOSE_HOME" ]] || { err "$(tr dir_missing) $COMPOSE_HOME"; return 1; }
  conflicts_cleanup
  setup_ufw
  info "$(tr start)"
  (cd "$COMPOSE_HOME" && docker compose up -d)
  ok "$(tr started)"
}
restart_services(){
  [[ -d "$COMPOSE_HOME" ]] || { err "$(tr dir_missing) $COMPOSE_HOME"; return 1; }
  setup_ufw
  info "$(tr restart)"
  (cd "$COMPOSE_HOME" && docker compose up -d --force-recreate)
  ok "$(tr restarted)"
}
show_logs(){
  [[ -d "$COMPOSE_HOME" ]] || { err "$(tr dir_missing) $COMPOSE_HOME"; return 1; }
  info "$(tr logs)"
  (cd "$COMPOSE_HOME" && docker compose logs -fn 500)
}
show_status(){
  [[ -d "$COMPOSE_HOME" ]] || { err "$(tr dir_missing) $COMPOSE_HOME"; return 1; }
  echo "$(tr status)"
  (cd "$COMPOSE_HOME" && docker compose ps -a)
}

# -----------------------------
# Registration (blockcastd init)
# -----------------------------
register_beacon(){
  [[ -d "$COMPOSE_HOME" ]] || { err "$(tr dir_missing) $COMPOSE_HOME"; return 1; }
  info "$(tr reg)"
  local j; j=$(curl -s https://ipinfo.io || true)
  if [[ -n "$j" ]]; then
    echo "$(tr loc_hint)"
    echo "$j" | jq '.city, .region, .country, .loc' || echo "$j"
  fi
  local TMP; TMP=$(mktemp)
  set +e
  (cd "$COMPOSE_HOME" && docker compose exec blockcastd blockcastd init) | tee "$TMP"
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
  echo "${cDim}Важно: сохраните приватный ключ (${KEY_FILE} или ${LEGACY_KEY}).${c0}"
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
    err "$(tr backup_miss)"; return 1
  fi
}

# -----------------------------
# Change port (rewrite override + restart)
# -----------------------------
change_port(){
  [[ -d "$COMPOSE_HOME" ]] || { err "$(tr dir_missing) $COMPOSE_HOME"; return 1; }
  write_override
  validate_compose
  restart_services
}

# -----------------------------
# Full removal
# -----------------------------
remove_all(){
  # Полное «сносит всё». Сначала обычное подтверждение:
  read -rp "$(tr remove) " CONF
  [[ "$CONF" == "yes" ]] || { warn "Canceled."; return 0; }

  set +e

  # 1) Гасим стек в обоих возможных местах и удаляем «осиротевшее»
  (cd "$COMPOSE_HOME" 2>/dev/null && docker compose down -v --remove-orphans) || true
  (cd "$OLD_DIR"      2>/dev/null && docker compose down -v --remove-orphans) || true

  # 2) Явные имена контейнеров из стека
  docker rm -f blockcastd control_proxy beacond watchtower 2>/dev/null || true

  # 3) Удаляем всё, что собрано docker compose для проектов по именам каталогов
  #    Обычно это 'compose' (для ~/.blockcast/compose) и 'blockcast' (для ~/blockcast)
  for prj in "$(basename "$COMPOSE_HOME")" "blockcast"; do
    docker ps -a      --filter "label=com.docker.compose.project=${prj}" -q | xargs -r docker rm -f || true
    docker network ls --filter "label=com.docker.compose.project=${prj}" -q | xargs -r docker network rm || true
    docker volume ls  --filter "label=com.docker.compose.project=${prj}" -q | xargs -r docker volume rm -f || true
    # На всякий случай: некоторые образы тоже могут нести compose-лейбл
    docker images     --filter "label=com.docker.compose.project=${prj}" -q | xargs -r docker rmi -f || true
  done

  # 4) Удаляем контейнеры, которые держат нужный порт на хосте (обычно 8443)
  for p in "${HOST_PORT}" 8443; do
    docker ps --filter "publish=${p}" -q | xargs -r docker rm -f || true
  done

  # 5) Добиваем известные сети (если остались без лейблов)
  docker network rm compose_default 2>/dev/null || true
  docker network rm blockcast_default 2>/dev/null || true

  # 6) Образы Blockcast и Watchtower/Updater
  docker images 'blockcast/*' -q                | xargs -r docker rmi -f || true
  docker images 'blockcast/blockcastd-updater' -q | xargs -r docker rmi -f || true
  docker images 'containrrr/watchtower' -q      | xargs -r docker rmi -f || true

  # 7) Чистим каталоги compose (новый и старый макеты)
  rm -rf "$COMPOSE_HOME" "$OLD_DIR"

  set -e

  # 8) Отдельным подтверждением — удаление всей ~/.blockcast (КЛЮЧИ БУДУТ УТЕРЯНЫ!)
  read -rp "Also delete ~/.blockcast (this WILL delete keys; you may need to re-register)? Type 'DELETE' to confirm: " DELK
  if [[ "$DELK" == "DELETE" ]]; then
    rm -rf "$HOME/.blockcast"
    if [[ "$LANG" == "en" ]]; then
      ok "Blockcast removed (including keys)."
    else
      ok "Blockcast удалён (включая ключи)."
    fi
  else
    ok "$(tr removed)"  # «Blockcast removed (keys kept).»
  fi

  # 9) Финальная проверка, что порт свободен
  if docker ps --filter "publish=${HOST_PORT}" -q | grep -q .; then
    warn "Port ${HOST_PORT} is still published by some container."
  fi
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
      3) ensure_compose_home; write_override; validate_compose ;;
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
