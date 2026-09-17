#!/usr/bin/env bash
set -Eeuo pipefail

# ==========================================================
# SKN HOSTING — VIP ELITE ALL-IN-ONE INSTALLER
# Inspired by colorful terminal dashboards; original SKN UI.
# ==========================================================

PTERO_INSTALLER_URL="https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer/master/install.sh"
PTERODACTYL_DIR="/var/www/pterodactyl"

ESC=$'\033'
RESET="${ESC}[0m"
BOLD="${ESC}[1m"
RED="${ESC}[1;38;5;196m"
GREEN="${ESC}[1;38;5;82m"
GOLD="${ESC}[1;38;5;220m"
CYAN="${ESC}[1;38;5;51m"
PINK="${ESC}[1;38;5;201m"
VIOLET="${ESC}[1;38;5;135m"
NEON="${ESC}[1;38;5;198m"
WHITE="${ESC}[1;38;5;255m"
GRAY="${ESC}[0;38;5;244m"

require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo -e "${RED}✗ Run this installer as root.${RESET}"
    echo -e "${GRAY}Example: sudo -i${RESET}"
    exit 1
  fi
}

ensure_base_tools() {
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y curl wget ca-certificates git unzip zip lsb-release >/dev/null 2>&1 || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y curl wget ca-certificates git unzip zip >/dev/null 2>&1 || true
  elif command -v yum >/dev/null 2>&1; then
    yum install -y curl wget ca-certificates git unzip zip >/dev/null 2>&1 || true
  fi
}

pause() {
  echo
  read -r -p "  Press Enter to continue..." _
}

clear_screen() { clear 2>/dev/null || true; }

spinner() {
  local pid="$1" msg="$2" frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r%s%s %s%s' "$CYAN" "${frames:i++%${#frames}:1}" "$msg" "$RESET"
    sleep 0.10
  done
  printf '\r\033[K'
}

run_animated() {
  local msg="$1"; shift
  "$@" >/tmp/skn-action.log 2>&1 &
  local pid=$!
  spinner "$pid" "$msg"
  if wait "$pid"; then
    echo -e "${GREEN}✓ ${msg}${RESET}"
    return 0
  fi
  echo -e "${RED}✗ ${msg} failed${RESET}"
  tail -n 18 /tmp/skn-action.log 2>/dev/null || true
  return 1
}

header() {
  clear_screen
  local uptime disk ram
  uptime="$(uptime -p 2>/dev/null || echo 'unknown')"
  disk="$(df -h / 2>/dev/null | awk 'NR==2{print $3 "/" $2}' || echo '?')"
  ram="$(free -h 2>/dev/null | awk '/Mem:/{print $3 "/" $2}' || echo '?')"
  echo -e "${VIOLET}┌──────────────────────────────────────────────────────────────────────────────┐${RESET}"
  printf "${VIOLET}│${RESET} ${GRAY} %s    %s    %s${RESET}                                                   ${VIOLET}│${RESET}\n" "$uptime" "$disk" "$ram"
  echo -e "${VIOLET}│${RESET}                                                                              ${VIOLET}│${RESET}"
  echo -e "${PINK}│   ███████╗██╗  ██╗███╗   ██╗    ██╗  ██╗ ██████╗ ███████╗████████╗        ${VIOLET}│${RESET}"
  echo -e "${PINK}│   ██╔════╝██║ ██╔╝████╗  ██║    ██║  ██║██╔═══██╗██╔════╝╚══██╔══╝        ${VIOLET}│${RESET}"
  echo -e "${PINK}│   ███████╗█████╔╝ ██╔██╗ ██║    ███████║██║   ██║███████╗   ██║           ${VIOLET}│${RESET}"
  echo -e "${PINK}│   ╚════██║██╔═██╗ ██║╚██╗██║    ██╔══██║██║   ██║╚════██║   ██║           ${VIOLET}│${RESET}"
  echo -e "${PINK}│   ███████║██║  ██╗██║ ╚████║    ██║  ██║╚██████╔╝███████║   ██║           ${VIOLET}│${RESET}"
  echo -e "${PINK}│   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝    ╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝           ${VIOLET}│${RESET}"
  echo -e "${VIOLET}│                                                                              │${RESET}"
  printf "${VIOLET}│${RESET} ${GOLD}${BOLD}                    POWERED BY SKYLER NODES${RESET}                          ${VIOLET}│${RESET}\n"
  printf "${VIOLET}│${RESET} ${CYAN}${BOLD}                         MADE BY ZYREN${RESET}                               ${VIOLET}│${RESET}\n"
  echo -e "${VIOLET}└──────────────────────────────────────────────────────────────────────────────┘${RESET}"
}

system_status() {
  local cpu ram disk net
  cpu="$(LC_ALL=C top -bn1 2>/dev/null | awk '/Cpu\(s\)/{print int(100-$8); exit}' || echo 0)"
  ram="$(free -m 2>/dev/null | awk '/Mem:/{if ($2) printf "%d", ($3/$2)*100; else print 0}' || echo 0)"
  disk="$(df -P / 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}' || echo 0)"
  if curl -fsS --max-time 3 https://github.com >/dev/null 2>&1; then
    net="${GREEN}● CONNECTED${RESET}"
  else
    net="${RED}● OFFLINE${RESET}"
  fi
  echo -e "${CYAN}  ◉ SYSTEM STATUS${RESET}"
  echo -e "${GRAY}    CPU Usage: ${WHITE}${cpu}%${RESET}    ${GRAY}RAM Usage: ${WHITE}${ram}%${RESET}    ${GRAY}Network: ${net}${RESET}"
}

menu() {
  header
  echo
  system_status
  echo
  echo -e "${WHITE}${BOLD}   DEPLOYMENT & SERVICES${RESET}"
  echo -e "${GRAY}    ├─ [1] Panel             ├─ [5] Themes${RESET}"
  echo -e "${GRAY}    ├─ [2] Wings             ├─ [6] System${RESET}"
  echo -e "${GRAY}    ├─ [3] Toolbox           ├─ [7] Container${RESET}"
  echo -e "${GRAY}    └─ [4] Extras            └─ [8] New Module${RESET}"
  echo
  echo -e "${WHITE}${BOLD}   MAINTENANCE & TOOLS${RESET}"
  echo -e "${GRAY}    └─ [9] Diagnostics${RESET}"
  echo
  echo -e "${VIOLET}  ──────────────────────────────────────────────────────────────────────────${RESET}"
  printf "${GOLD}${BOLD}  ➜ Enter Option (0-9): ${RESET}"
  read -r MENU_OPTION
}

panel_menu() {
  while true; do
    header
    echo
    echo -e "${CYAN}${BOLD}  🛰️  SERVER PANEL MANAGER v15.0${RESET}"
    echo -e "${GRAY}  SYSTEM STATUS${RESET}"
    printf "  ├─ Uptime : %s\n" "$(uptime -p 2>/dev/null | sed 's/^up //' || echo 'unknown')"
    printf "  └─ Load   : %s\n" "$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo '0.00')"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${RESET}"
    echo -e "${WHITE}${BOLD}    AVAILABLE DEPLOYMENTS${RESET}"
    echo -e "${CYAN}  ┌──────────────────────────┬──────────────────────────┐${RESET}"
    printf "${CYAN}  │${RESET} [1] Ptero               ${CYAN}│${RESET} [5] Paymenter           ${CYAN}│${RESET}\n"
    printf "${CYAN}  │${RESET} [2] JexPanel             ${CYAN}│${RESET} [6] FeatherPanel        ${CYAN}│${RESET}\n"
    printf "${CYAN}  │${RESET} [3] Reviactyl            ${CYAN}│${RESET} [7] Mythicaldash         ${CYAN}│${RESET}\n"
    printf "${CYAN}  │${RESET} [4] CtrlPanel            ${CYAN}│${RESET} [8] Mythicaldashv3       ${CYAN}│${RESET}\n"
    printf "${CYAN}  │${RESET} [0] Exit                 ${CYAN}│${RESET}                          ${CYAN}│${RESET}\n"
    echo -e "${CYAN}  └──────────────────────────┴──────────────────────────┘${RESET}"
    echo
    printf "${GOLD}${BOLD}  λ Select Module [1-8]: ${RESET}"
    read -r x
    case "$x" in
      1) ptero_manager ;;
      2) jexactyl_manager ;;
      3) reviactyl_manager ;;
      4) ctrlpanel_manager ;;
      5) paymenter_manager ;;
      6) feather_manager ;;
      7) mythicaldash_manager ;;
      8) mythicaldash_v3_manager ;;
      0) return ;;
      *) echo -e "${RED}✗ Invalid module.${RESET}"; sleep 1 ;;
    esac
  done
}

skn_panel_config() {
  mkdir -p /etc/skn-hosting
  local f=/etc/skn-hosting/panel.conf
  if [[ -f "$f" ]]; then return 0; fi
  clear_screen
  echo -e "${CYAN}${BOLD}SKN HOSTING — FIRST TIME PANEL SETUP${RESET}"
  echo
  read -r -p "  Panel domain (e.g. panel.example.com): " SKN_DOMAIN
  read -r -p "  Admin email: " SKN_EMAIL
  read -r -p "  Timezone [Asia/Kolkata]: " SKN_TZ
  SKN_TZ="${SKN_TZ:-Asia/Kolkata}"
  cat > "$f" <<EOF
SKN_DOMAIN=$(printf '%q' "$SKN_DOMAIN")
SKN_EMAIL=$(printf '%q' "$SKN_EMAIL")
SKN_TZ=$(printf '%q' "$SKN_TZ")
EOF
  chmod 600 "$f"
  echo -e "${GREEN}✓ Details saved. Future panel actions will reuse them.${RESET}"
  sleep 1
}

load_panel_config() {
  skn_panel_config
  # shellcheck disable=SC1091
  source /etc/skn-hosting/panel.conf
}

panel_loading() {
  local name="$1"
  echo
  echo -e "${CYAN}  ➜ Executing ${name} Routine...${RESET}"
  local i
  for i in {1..16}; do
    printf '\r  %s[%02d/16] Preparing %s...%s' "$GRAY" "$i" "$name" "$RESET"
    sleep 0.06
  done
  printf '\r\033[K'
}

panel_shell_menu() {
  local name="$1" install_fn="$2" user_fn="$3" update_fn="$4" domain_fn="$5" uninstall_fn="$6"
  while true; do
    clear_screen
    panel_status "$name"
    echo
    echo -e "${WHITE}${BOLD}  ┌───────────────────────────────────────────────────────┐${RESET}"
    printf "${WHITE}  │${RESET}  %-52s${WHITE}│${RESET}\n" "${name} MANAGER"
    echo -e "${WHITE}  ├───────────────────────────────────────────────────────┤${RESET}"
    printf "${WHITE}  │${RESET}  [1] Install       :: (Fresh Install)                ${WHITE}│${RESET}\n"
    printf "${WHITE}  │${RESET}  [2] Admin/User    :: (Initial Account)              ${WHITE}│${RESET}\n"
    printf "${WHITE}  │${RESET}  [3] Update        :: (Latest Release)               ${WHITE}│${RESET}\n"
    printf "${WHITE}  │${RESET}  [4] Domain/SSL    :: (Domain / SSL)                 ${WHITE}│${RESET}\n"
    printf "${WHITE}  │${RESET}  [5] Uninstall     :: (Remove Panel Data)            ${WHITE}│${RESET}\n"
    printf "${WHITE}  │${RESET}  [6] phpMyAdmin    :: (Database Tool)                ${WHITE}│${RESET}\n"
    printf "${WHITE}  │${RESET}  [0] Exit          :: (Back to Panel Manager)        ${WHITE}│${RESET}\n"
    echo -e "${WHITE}  └───────────────────────────────────────────────────────┘${RESET}"
    echo
    printf "${GOLD}${BOLD}  ➜ Select ${name} Option [0-6]: ${RESET}"
    read -r x
    case "$x" in
      1) panel_loading "$name"; load_panel_config; "$install_fn"; pause ;;
      2) panel_loading "$name"; load_panel_config; "$user_fn"; pause ;;
      3) panel_loading "$name"; "$update_fn"; pause ;;
      4) panel_loading "$name"; load_panel_config; "$domain_fn"; pause ;;
      5) panel_loading "$name"; "$uninstall_fn"; pause ;;
      6) panel_loading "phpMyAdmin"; phpmyadmin_tools ;;
      0) return ;;
      *) echo -e "${RED}✗ Invalid option.${RESET}"; sleep 1 ;;
    esac
  done
}

panel_status() {
  local name="$1" path=""
  case "$name" in
    Pterodactyl) path="$PTERODACTYL_DIR";;
    Jexactyl) path="/var/www/jexactyl";;
    Reviactyl) path="/var/www/reviactyl";;
    CtrlPanel) path="/var/www/ctrlpanel";;
    Paymenter) path="/var/www/paymenter";;
    FeatherPanel) path="/opt/featherpanel";;
    MythicalDash|MythicalDashV3) path="/var/www/mythicaldash";;
  esac
  local status="NOT INSTALLED ✘"
  [[ -n "$path" && -d "$path" ]] && status="INSTALLED ✓"
  echo -e "${CYAN}${BOLD}  ${name} MANAGER${RESET}"
  echo -e "${WHITE}  ┌───────────────────────────────────────────────────────┐${RESET}"
  printf "${WHITE}  │${RESET} PANEL STATUS: %-39s${WHITE}│${RESET}\n" "$status"
  echo -e "${WHITE}  └───────────────────────────────────────────────────────┘${RESET}"
}

ptero_manager() { panel_shell_menu "Pterodactyl" install_panel ptero_user_menu update_panel ptero_domain ptero_uninstall; }

install_panel() {
  require_debian || return 1
  load_panel_config
  if [[ -z "${SKN_DOMAIN:-}" || -z "${SKN_EMAIL:-}" ]]; then
    echo -e "${RED}Panel domain/email are required.${RESET}"
    return 1
  fi
  echo -e "${CYAN}Installing Pterodactyl with the saved SKN details...${RESET}"
  echo -e "${GRAY}Domain: ${SKN_DOMAIN} | Email: ${SKN_EMAIL} | TZ: ${SKN_TZ}${RESET}"
  PANEL_DOMAIN="$SKN_DOMAIN" LE_EMAIL="$SKN_EMAIL" TIMEZONE="$SKN_TZ" NO_WINGS=1 \
    bash <(curl -fsSL https://raw.githubusercontent.com/2hoch1/pterodactyl-installer/main/get.sh) --yes
}

update_panel() {
  if [[ ! -d "$PTERODACTYL_DIR" ]]; then
    echo -e "${RED}Pterodactyl is not installed.${RESET}"
    return 1
  fi
  echo -e "${CYAN}Running the current Pterodactyl installer/update routine...${RESET}"
  load_panel_config
  PANEL_DOMAIN="$SKN_DOMAIN" LE_EMAIL="$SKN_EMAIL" TIMEZONE="$SKN_TZ" NO_WINGS=1 \
    bash <(curl -fsSL https://raw.githubusercontent.com/2hoch1/pterodactyl-installer/main/get.sh) --yes
}

ptero_do
# ---- SKN built-in utility routines ----
database_tools() {
  require_debian || return 1
  apt-get update -y
  apt-get install -y mariadb-server mariadb-client
  systemctl enable --now mariadb
  echo -e "${GREEN}✓ MariaDB is installed and running.${RESET}"
}
redis_tools() {
  require_debian || return 1
  apt-get update -y
  apt-get install -y redis-server
  systemctl enable --now redis-server
  echo -e "${GREEN}✓ Redis is installed and running.${RESET}"
}
docker_tools() {
  require_debian || return 1
  if command -v docker >/dev/null 2>&1; then
    docker --version
    systemctl enable --now docker 2>/dev/null || true
  else
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker
  fi
}
php_tools() {
  require_debian || return 1
  apt-get update -y
  apt-get install -y php-cli php-fpm php-mysql php-curl php-mbstring php-xml php-zip php-gd php-bcmath unzip
  if ! command -v composer >/dev/null 2>&1; then
    curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f /tmp/composer-setup.php
  fi
  php -v | head -n 1
  composer --version
}
node_tools() {
  require_debian || return 1
  apt-get update -y
  apt-get install -y nodejs npm
  node --version
  npm --version
}
phpmyadmin_tools() {
  require_debian || return 1
  echo -e "${CYAN}phpMyAdmin setup${RESET}"
  apt-get update -y
  apt-get install -y phpmyadmin
  echo -e "${GREEN}✓ phpMyAdmin package installed. Configure your web server before production use.${RESET}"
}
blueprint_tools() {
  if [[ -d "$PTERODACTYL_DIR" ]]; then
    echo -e "${CYAN}Blueprint is available for the installed Pterodactyl panel.${RESET}"
    echo "Panel: $PTERODACTYL_DIR"
    echo "Install the Blueprint release matching your Pterodactyl version before applying themes/extensions."
  else
    echo -e "${GRAY}Pterodactyl is not installed yet.${RESET}"
  fi
}
os_manager() {
  echo "OS: $(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Linux}")"
  echo "Kernel: $(uname -r)"
  echo "Architecture: $(uname -m)"
}
service_manager() {
  echo "Key services:"
  for svc in nginx docker mariadb redis-server wings pteroq; do
    if systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
      printf '  %-12s %s\n' "$svc" "$(systemctl is-active "$svc" 2>/dev/null || true)"
    fi
  done
}
network_tools() {
  echo "Hostname: $(hostname)"
  echo "IPv4: $(hostname -I 2>/dev/null | awk '{print $1}')"
  command -v ip >/dev/null && ip -brief addr || true
}
firewall_tools() {
  if command -v ufw >/dev/null 2>&1; then
    ufw status verbose
  else
    echo "UFW is not installed."
  fi
}
storage_tools() {
  df -hT
}
logs_tools() {
  echo "Recent system log entries:"
  journalctl -n 25 --no-pager 2>/dev/null || true
}

main() {
  load_panel_config
  echo -e "${CYAN}Pterodactyl Domain / SSL${RESET}"
  echo "Saved domain : ${SKN_DOMAIN}"
  echo "Saved email  : ${SKN_EMAIL}"
  echo "Timezone     : ${SKN_TZ}"
  echo
  echo "The saved values are reused for future Pterodactyl routines."
}

jexactyl_manager() { panel_shell_menu "Jexactyl" install_jexactyl_skn jexactyl_user update_jexactyl_skn jexactyl_domain jexactyl_uninstall; }
reviactyl_manager() { panel_shell_menu "Reviactyl" install_reviactyl_skn reviactyl_user update_reviactyl_skn reviactyl_domain reviactyl_uninstall; }
ctrlpanel_manager() { panel_shell_menu "CtrlPanel" install_ctrlpanel_skn ctrlpanel_user update_ctrlpanel_skn ctrlpanel_domain ctrlpanel_uninstall; }
paymenter_manager() { panel_shell_menu "Paymenter" install_paymenter_skn paymenter_user update_paymenter_skn paymenter_domain paymenter_uninstall; }
feather_manager() { panel_shell_menu "FeatherPanel" install_feather_skn feather_user update_feather_skn feather_domain feather_uninstall; }
mythicaldash_manager() { panel_shell_menu "MythicalDash" install_mythicaldash_skn mythical_user update_mythicaldash_skn mythical_domain mythical_uninstall; }
mythicaldash_v3_manager() { panel_shell_menu "MythicalDashV3" install_mythicaldash_v3_skn mythical_v3_user update_mythicaldash_v3_skn mythical_v3_domain mythical_v3_uninstall; }

ptero_user_menu() {
  load_panel_config
  echo -e "${CYAN}Pterodactyl user/admin setup${RESET}"
  echo "The official installer will handle account creation/configuration."
  echo "Admin email: $SKN_EMAIL"
  [[ -d "$PTERODACTYL_DIR" ]] && echo "Panel path: $PTERODACTYL_DIR"
}
wings_menu() { while true; do clear_screen; echo -e "${CYAN}${BOLD}WINGS MANAGER${RESET}"; echo "[1] Install Wings"; echo "[2] Update Wings"; echo "[3] Config"; echo "[0] Back"; read -r -p "➜ Wings option: " x; case "$x" in 1) panel_loading "Wings"; install_wings; pause;; 2) panel_loading "Wings"; update_wings; pause;; 3) node_config;; 0) return;; *) echo "Invalid option.";; esac; done; }
install_wings() {
  require_debian || return 1
  echo -e "${CYAN}Installing Pterodactyl Wings...${RESET}"
  bash <(curl -fsSL https://raw.githubusercontent.com/thexento/pterodactyl-installer/main/install.sh) wings
}
update_wings() {
  if command -v wings >/dev/null 2>&1; then
    echo -e "${CYAN}Updating Wings...${RESET}"
  else
    echo -e "${YELLOW:-$GOLD}Wings is not installed; starting installation.${RESET}"
  fi
  install_wings
}

toolbox_menu() { while true; do clear_screen; echo -e "${GOLD}${BOLD}TOOLBOX${RESET}"; echo "[1] MariaDB"; echo "[2] Redis"; echo "[3] Docker"; echo "[4] PHP/Composer"; echo "[5] Node.js"; echo "[6] phpMyAdmin"; echo "[0] Back"; read -r -p "➜ Toolbox option: " x; case "$x" in 1) database_tools;; 2) redis_tools;; 3) docker_tools;; 4) php_tools;; 5) node_tools;; 6) phpmyadmin_tools;; 0) return;; *) echo "Invalid option.";; esac; done; }
extras_menu() { while true; do clear_screen; echo -e "${CYAN}${BOLD}EXTRAS${RESET}"; echo "[1] System Information"; echo "[2] Diagnostics"; echo "[3] Logs"; echo "[0] Back"; read -r -p "➜ Extras option: " x; case "$x" in 1) system_information;; 2) diagnostics;; 3) logs_tools;; 0) return;; *) echo "Invalid option.";; esac; done; }
themes_menu() { while true; do clear_screen; echo -e "${VIOLET}${BOLD}THEMES${RESET}"; echo "[1] Blueprint"; echo "[0] Back"; read -r -p "➜ Theme option: " x; case "$x" in 1) blueprint_tools;; 0) return;; *) echo "Invalid option.";; esac; done; }
system_menu() { while true; do clear_screen; echo -e "${PINK}${BOLD}SYSTEM${RESET}"; echo "[1] OS"; echo "[2] Services"; echo "[3] Network"; echo "[4] Firewall"; echo "[5] Storage"; echo "[0] Back"; read -r -p "➜ System option: " x; case "$x" in 1) os_manager;; 2) service_manager;; 3) network_tools;; 4) firewall_tools;; 5) storage_tools;; 0) return;; *) echo "Invalid option.";; esac; done; }
container_menu() { docker_tools; }
new_module_menu() { clear_screen; echo -e "${CYAN}${BOLD}NEW MODULE${RESET}"; echo "Reserved for future SKN HOSTING modules."; pause; }

ptero_uninstall() { echo -e "${RED}Pterodactyl uninstall is destructive.${RESET}"; read -r -p "Type REMOVE-PTERO to confirm: " c; [[ "$c" == "REMOVE-PTERO" ]] || return; rm -rf "$PTERODACTYL_DIR" /etc/pterodactyl; systemctl disable --now pteroq 2>/dev/null || true; echo "Pterodactyl files removed."; }

install_jexactyl_skn() {
  require_debian
  apt-get update -y; apt-get install -y curl git unzip nginx mariadb-server redis-server php8.3 php8.3-{cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} || return 1
  command -v composer >/dev/null 2>&1 || curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
  mkdir -p /var/www/jexactyl; cd /var/www/jexactyl
  [[ -f panel.tar.gz ]] || curl -Lo panel.tar.gz https://github.com/jexactyl/jexactyl/releases/latest/download/panel.tar.gz
  tar -xzf panel.tar.gz
  cp -n .env.example .env
  composer install --no-dev --optimize-autoloader --no-interaction
  php artisan key:generate --force
  php artisan migrate --seed --force
  chown -R www-data:www-data /var/www/jexactyl
  echo "Jexactyl installed. Configure the URL/database using the panel's installer/config before production use."
}
jexactyl_user(){ echo "Jexactyl initial admin is created through its supported setup flow after installation."; }
update_jexactyl_skn(){ [[ -d /var/www/jexactyl ]] || { echo "Jexactyl not installed."; return 1; }; cd /var/www/jexactyl; php artisan down || true; curl -L https://github.com/jexactyl/jexactyl/releases/latest/download/panel.tar.gz | tar -xz; composer install --no-dev --optimize-autoloader --no-interaction; php artisan migrate --force; php artisan optimize:clear; php artisan up || true; }
jexactyl_domain(){ echo "Jexactyl domain: ${SKN_DOMAIN:-not configured}"; echo "Set APP_URL in /var/www/jexactyl/.env and configure Nginx/SSL for the domain."; }
jexactyl_uninstall(){ read -r -p "Type REMOVE-JEXACTYL to confirm: " c; [[ "$c" == "REMOVE-JEXACTYL" ]] || return; rm -rf /var/www/jexactyl; rm -f /etc/nginx/sites-enabled/jexactyl.conf /etc/nginx/sites-available/jexactyl.conf; systemctl reload nginx 2>/dev/null || true; }

install_reviactyl_skn() { require_debian; apt-get update -y; apt-get install -y curl git unzip nginx mariadb-server redis-server php8.3 php8.3-{cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} || return 1; command -v composer >/dev/null 2>&1 || curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; mkdir -p /var/www/reviactyl; cd /var/www/reviactyl; curl -Lo panel.tar.gz https://github.com/reviactyl/panel/releases/latest/download/panel.tar.gz; tar -xzf panel.tar.gz; chmod -R 755 storage bootstrap/cache; cp -n .env.example .env; composer install --no-dev --optimize-autoloader --no-interaction; php artisan key:generate --force; php artisan migrate --seed --force; chown -R www-data:www-data /var/www/reviactyl; echo "Reviactyl files installed; finish its supported web installer/configuration."; }
reviactyl_user(){ echo "Reviactyl admin/user setup is completed through the panel's supported setup flow."; }
update_reviactyl_skn(){ [[ -d /var/www/reviactyl ]] || { echo "Reviactyl not installed."; return 1; }; cd /var/www/reviactyl; curl -L https://github.com/reviactyl/panel/releases/latest/download/panel.tar.gz | tar -xz; composer install --no-dev --optimize-autoloader --no-interaction; php artisan migrate --force; php artisan optimize:clear; }
reviactyl_domain(){ echo "Reviactyl domain: ${SKN_DOMAIN:-not configured}"; echo "Configure APP_URL and Nginx/SSL for the saved domain."; }
reviactyl_uninstall(){ read -r -p "Type REMOVE-REVIACTYL to confirm: " c; [[ "$c" == "REMOVE-REVIACTYL" ]] || return; rm -rf /var/www/reviactyl; rm -f /etc/nginx/sites-enabled/reviactyl.conf /etc/nginx/sites-available/reviactyl.conf; systemctl reload nginx 2>/dev/null || true; }

install_ctrlpanel_skn() { require_debian; apt-get update -y; apt-get install -y software-properties-common curl ca-certificates gnupg git nginx mariadb-server redis-server php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} || return 1; command -v composer >/dev/null 2>&1 || curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; mkdir -p /var/www/ctrlpanel; cd /var/www/ctrlpanel; if [[ ! -d .git ]]; then git clone https://github.com/Ctrlpanel-gg/panel.git ./; fi; COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader; php artisan storage:link; chmod -R 755 storage bootstrap/cache; chown -R www-data:www-data /var/www/ctrlpanel; echo "CtrlPanel installed. Open its /installer route after configuring its database and Nginx domain."; }
ctrlpanel_user(){ echo "CtrlPanel account setup is completed through its /installer route."; }
update_ctrlpanel_skn(){ [[ -d /var/www/ctrlpanel ]] || { echo "CtrlPanel not installed."; return 1; }; cd /var/www/ctrlpanel; git pull --ff-only; COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader; php artisan migrate --force 2>/dev/null || true; php artisan optimize:clear; }
ctrlpanel_domain(){ echo "CtrlPanel domain: ${SKN_DOMAIN:-not configured}"; echo "Use the official CtrlPanel Nginx/SSL configuration for this domain."; }
ctrlpanel_uninstall(){ read -r -p "Type REMOVE-CTRLPANEL to confirm: " c; [[ "$c" == "REMOVE-CTRLPANEL" ]] || return; rm -rf /var/www/ctrlpanel; rm -f /etc/nginx/sites-enabled/ctrlpanel.conf /etc/nginx/sites-available/ctrlpanel.conf; systemctl reload nginx 2>/dev/null || true; }

install_paymenter_skn() { require_debian; apt-get update -y; apt-get install -y software-properties-common curl apt-transport-https ca-certificates gnupg nginx mariadb-server redis-server git unzip php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} || return 1; mkdir -p /var/www/paymenter; cd /var/www/paymenter; curl -Lo paymenter.tar.gz https://github.com/paymenter/paymenter/releases/latest/download/paymenter.tar.gz; tar -xzf paymenter.tar.gz; chmod -R 755 storage bootstrap/cache; cp -n .env.example .env; php artisan key:generate --force; php artisan storage:link; php artisan migrate --force --seed; php artisan db:seed --class=CustomPropertySeeder; chown -R www-data:www-data /var/www/paymenter; echo "Paymenter installed. Run 'php artisan app:init' in /var/www/paymenter for the saved application setup."; }
paymenter_user(){ [[ -d /var/www/paymenter ]] && (cd /var/www/paymenter && php artisan app:user:create) || echo "Paymenter not installed."; }
update_paymenter_skn(){ [[ -d /var/www/paymenter ]] || { echo "Paymenter not installed."; return 1; }; cd /var/www/paymenter; php artisan app:upgrade; }
paymenter_domain(){ echo "Paymenter domain: ${SKN_DOMAIN:-not configured}"; echo "Configure .env APP_URL and Nginx/SSL using the official Paymenter webserver guide."; }
paymenter_uninstall(){ read -r -p "Type REMOVE-PAYMENTER to confirm: " c; [[ "$c" == "REMOVE-PAYMENTER" ]] || return; systemctl disable --now paymenter.service 2>/dev/null || true; rm -rf /var/www/paymenter; rm -f /etc/nginx/sites-enabled/paymenter.conf /etc/nginx/sites-available/paymenter.conf; systemctl reload nginx 2>/dev/null || true; }

install_feather_skn(){ panel_loading "FeatherPanel installer"; curl -sSL https://get.featherpanel.com/installer.sh | bash; }
feather_user(){ echo "FeatherPanel account/setup is handled by its official installer and web interface."; }
update_feather_skn(){ echo "Run the latest official FeatherPanel installer/update procedure; the vendor installer manages current components."; curl -sSL https://get.featherpanel.com/installer.sh | bash; }
feather_domain(){ echo "FeatherPanel domain: ${SKN_DOMAIN:-not configured}"; echo "Configure the domain/SSL according to the installed FeatherPanel version."; }
feather_uninstall(){ read -r -p "Type REMOVE-FEATHER to confirm: " c; [[ "$c" == "REMOVE-FEATHER" ]] || return; rm -rf /opt/featherpanel; echo "FeatherPanel files under /opt/featherpanel removed if present."; }

install_mythicaldash_skn(){ require_debian; apt-get update -y; apt-get install -y curl git unzip nginx mariadb-server redis-server php8.3 php8.3-{cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} || return 1; command -v composer >/dev/null 2>&1 || curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; mkdir -p /var/www/mythicaldash; cd /var/www/mythicaldash; git clone --depth 1 https://github.com/MythicalLTD/MythicalDash.git . 2>/dev/null || git pull --ff-only; echo "MythicalDash source downloaded. Follow the current MythicalSystems v3 installation wizard for final DB/web configuration."; }
mythical_user(){ echo "MythicalDash admin setup is completed through the supported installation wizard."; }
update_mythicaldash_skn(){ [[ -d /var/www/mythicaldash/.git ]] || { echo "MythicalDash not installed."; return 1; }; cd /var/www/mythicaldash; git pull --ff-only; }
mythical_domain(){ echo "MythicalDash domain: ${SKN_DOMAIN:-not configured}"; echo "Configure its web server/SSL according to the current MythicalSystems v3 docs."; }
mythical_uninstall(){ read -r -p "Type REMOVE-MYTHICAL to confirm: " c; [[ "$c" == "REMOVE-MYTHICAL" ]] || return; rm -rf /var/www/mythicaldash; }
install_mythicaldash_v3_skn(){ install_mythicaldash_skn; }
mythical_v3_user(){ mythical_user; }
update_mythicaldash_v3_skn(){ update_mythicaldash_skn; }
mythical_v3_domain(){ mythical_domain; }
mythical_v3_uninstall(){ mythical_uninstall; }

require_debian() { command -v apt-get >/dev/null 2>&1 || { echo -e "${RED}This routine currently requires Debian/Ubuntu (apt).${RESET}"; return 1; }; }

panel_config() {
  echo -e "${WHITE}PANEL CONFIGURATION${RESET}"
  [[ -f "$PTERODACTYL_DIR/.env" ]] && {
    echo "Panel .env exists: $PTERODACTYL_DIR/.env"
    echo "Use your preferred editor to change it."
  } || echo "Panel .env not found."
  pause
}

node_config() {
  echo -e "${WHITE}NODE CONFIGURATION${RESET}"
  [[ -f "/etc/pterodactyl/config.yml" ]] && {
    echo "Wings config: /etc/pterodactyl/config.yml"
  } || echo "Wings config not found."
  pause
}

system_information() {
  header
  echo
  echo -e "${CYAN}${BOLD}SYSTEM INFORMATION${RESET}"
  echo
  echo "Hostname : $(hostname)"
  echo "OS       : $(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Linux}")"
  echo "Kernel   : $(uname -r)"
  echo "Arch     : $(uname -m)"
  echo "Uptime   : $(uptime -p 2>/dev/null || true)"
  echo "CPU      : $(nproc 2>/dev/null || echo '?') cores"
  echo "Memory   : $(free -h 2>/dev/null | awk '/Mem:/{print $2}')"
  echo "Disk     : $(df -h / 2>/dev/null | awk 'NR==2{print $2}')"
  pause
}

diagnostics() {
  echo -e "${CYAN}${BOLD}SKN DIAGNOSTICS${RESET}"
  echo
  command -v curl >/dev/null && echo -e "${GREEN}✓ curl${RESET}" || echo -e "${RED}✗ curl${RESET}"
  command -v php >/dev/null && echo -e "${GREEN}✓ php${RESET}" || echo -e "${RED}✗ php${RESET}"
  command -v composer >/dev/null && echo -e "${GREEN}✓ composer${RESET}" || echo -e "${GRAY}• composer missing${RESET}"
  command -v docker >/dev/null && echo -e "${GREEN}✓ docker${RESET}" || echo -e "${GRAY}• docker missing${RESET}"
  systemctl is-active --quiet wings && echo -e "${GREEN}✓ wings active${RESET}" || echo -e "${GRAY}• wings inactive${RESET}"
  systemctl is-active --quiet nginx && echo -e "${GREEN}✓ nginx active${RESET}" || echo -e "${GRAY}• nginx inactive${RESET}"
  pause
}


# ---- SKN built-in utility routines ----
database_tools() {
  require_debian || return 1
  apt-get update -y
  apt-get install -y mariadb-server mariadb-client
  systemctl enable --now mariadb
  echo -e "${GREEN}✓ MariaDB is installed and running.${RESET}"
}
redis_tools() {
  require_debian || return 1
  apt-get update -y
  apt-get install -y redis-server
  systemctl enable --now redis-server
  echo -e "${GREEN}✓ Redis is installed and running.${RESET}"
}
docker_tools() {
  require_debian || return 1
  if command -v docker >/dev/null 2>&1; then
    docker --version
    systemctl enable --now docker 2>/dev/null || true
  else
    apt-get update -y
    apt-get install -y docker.io
    systemctl enable --now docker
  fi
}
php_tools() {
  require_debian || return 1
  apt-get update -y
  apt-get install -y php-cli php-fpm php-mysql php-curl php-mbstring php-xml php-zip php-gd php-bcmath unzip
  if ! command -v composer >/dev/null 2>&1; then
    curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f /tmp/composer-setup.php
  fi
  php -v | head -n 1
  composer --version
}
node_tools() {
  require_debian || return 1
  apt-get update -y
  apt-get install -y nodejs npm
  node --version
  npm --version
}
phpmyadmin_tools() {
  require_debian || return 1
  echo -e "${CYAN}phpMyAdmin setup${RESET}"
  apt-get update -y
  apt-get install -y phpmyadmin
  echo -e "${GREEN}✓ phpMyAdmin package installed. Configure your web server before production use.${RESET}"
}
blueprint_tools() {
  if [[ -d "$PTERODACTYL_DIR" ]]; then
    echo -e "${CYAN}Blueprint is available for the installed Pterodactyl panel.${RESET}"
    echo "Panel: $PTERODACTYL_DIR"
    echo "Install the Blueprint release matching your Pterodactyl version before applying themes/extensions."
  else
    echo -e "${GRAY}Pterodactyl is not installed yet.${RESET}"
  fi
}
os_manager() {
  echo "OS: $(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Linux}")"
  echo "Kernel: $(uname -r)"
  echo "Architecture: $(uname -m)"
}
service_manager() {
  echo "Key services:"
  for svc in nginx docker mariadb redis-server wings pteroq; do
    if systemctl list-unit-files "$svc.service" >/dev/null 2>&1; then
      printf '  %-12s %s\n' "$svc" "$(systemctl is-active "$svc" 2>/dev/null || true)"
    fi
  done
}
network_tools() {
  echo "Hostname: $(hostname)"
  echo "IPv4: $(hostname -I 2>/dev/null | awk '{print $1}')"
  command -v ip >/dev/null && ip -brief addr || true
}
firewall_tools() {
  if command -v ufw >/dev/null 2>&1; then
    ufw status verbose
  else
    echo "UFW is not installed."
  fi
}
storage_tools() {
  df -hT
}
logs_tools() {
  echo "Recent system log entries:"
  journalctl -n 25 --no-pager 2>/dev/null || true
}

main() {
  printf "\033]0;SKN HOSTING — VIP ELITE\007" 2>/dev/null || true
  require_root
  ensure_base_tools

  while true; do
    menu
    option="$MENU_OPTION"
    case "$option" in
      1) panel_menu ;;
      2) wings_menu ;;
      3) toolbox_menu ;;
      4) extras_menu ;;
      5) themes_menu ;;
      6) system_menu ;;
      7) container_menu ;;
      8) new_module_menu ;;
      9) extras_menu ;;
      0) clear_screen; echo -e "${GREEN}SKN HOSTING installer closed safely.${RESET}"; exit 0 ;;
      *) echo -e "${RED}✗ Invalid option.${RESET}"; sleep 1 ;;
    esac
  done
}

main "$@"
