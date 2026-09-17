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

vps_menu() {
  header
  echo
  system_status
  echo
  echo -e "${VIOLET}╭──────────────────────────────────────────────────────────────────────────────╮${RESET}"
  echo -e "${VIOLET}│${RESET} ${CYAN}${BOLD}  DEPLOYMENT & SERVICES${RESET}                                                 ${VIOLET}│${RESET}"
  printf "${VIOLET}│${RESET}    ${GREEN}[1]${RESET} Panel               ${PINK}[5]${RESET} Themes                                      ${VIOLET}│\\n"
  printf "${VIOLET}│${RESET}    ${GREEN}[2]${RESET} Wings               ${PINK}[6]${RESET} System                                      ${VIOLET}│\\n"
  printf "${VIOLET}│${RESET}    ${GOLD}[3]${RESET} Toolbox             ${PINK}[7]${RESET} Container                                   ${VIOLET}│\\n"
  printf "${VIOLET}│${RESET}    ${GOLD}[4]${RESET} Extras              ${PINK}[8]${RESET} New Module                                  ${VIOLET}│\\n"
  printf "${VIOLET}│${RESET}                                                                              ${VIOLET}│\\n"
  echo -e "${VIOLET}│${RESET} ${WHITE}${BOLD}   MAINTENANCE & TOOLS${RESET}                                                  ${VIOLET}│${RESET}"
  printf "${VIOLET}│${RESET}    ${RED}[9]${RESET} Shutdown                                                                    ${VIOLET}│\\n"
  echo -e "${VIOLET}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
  printf "${VIOLET}│${RESET} ${GRAY}  ➜ Enter Option (0-9):${RESET}                                                  ${VIOLET}│\\n"
  printf "${VIOLET}╰──────────────────────────────────────────────────────────────────────────────╯${RESET}\\n"
  # Keep the cursor/input prompt on the same logical menu line; no external root@ prompt.
  printf "${GOLD}${BOLD}➜ Enter Option (0-9): ${RESET}"
  read -r MENU_OPTION
}

fetch_upstream() {
  if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}curl is required but could not be installed automatically.${RESET}"
    return 1
  fi
  echo -e "${CYAN}Downloading Pterodactyl installer...${RESET}"
  if ! curl -fL --retry 3 --connect-timeout 10 "$PTERO_INSTALLER_URL" -o /tmp/skn-pterodactyl-upstream.sh; then
    echo -e "${RED}✗ Download failed. Check DNS/network access.${RESET}"
    return 1
  fi
  if ! grep -q "Pterodactyl" /tmp/skn-pterodactyl-upstream.sh 2>/dev/null; then
    echo -e "${RED}✗ Downloaded installer could not be verified.${RESET}"
    return 1
  fi
  chmod +x /tmp/skn-pterodactyl-upstream.sh
}

install_panel() {
  fetch_upstream || return 1
  bash /tmp/skn-pterodactyl-upstream.sh panel
}
install_wings() {
  fetch_upstream || return 1
  bash /tmp/skn-pterodactyl-upstream.sh wings
}
install_both() {
  fetch_upstream || return 1
  bash /tmp/skn-pterodactyl-upstream.sh panel || return 1
  bash /tmp/skn-pterodactyl-upstream.sh wings
}

update_panel() {
  [[ -d "$PTERODACTYL_DIR" ]] || { echo -e "${RED}Panel directory not found.${RESET}"; return 1; }
  cd "$PTERODACTYL_DIR"
  php artisan down || true
  git fetch --all --tags
  git pull --ff-only
  composer install --no-dev --optimize-autoloader
  php artisan migrate --seed --force
  php artisan view:clear
  php artisan config:clear
  php artisan cache:clear
  php artisan queue:restart || true
  php artisan up
}

update_wings() {
  systemctl stop wings 2>/dev/null || true
  local arch url
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) url="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64" ;;
    aarch64|arm64) url="https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_arm64" ;;
    *) echo -e "${RED}Unsupported architecture: $arch${RESET}"; return 1 ;;
  esac
  install -d /usr/local/bin /etc/pterodactyl
  curl -fsSL "$url" -o /usr/local/bin/wings
  chmod +x /usr/local/bin/wings
  systemctl daemon-reload
  systemctl enable wings >/dev/null 2>&1 || true
  systemctl start wings
}

service_manager() {
  echo -e "${CYAN}SERVICE MANAGER${RESET}"
  echo "[1] Status"
  echo "[2] Start"
  echo "[3] Stop"
  echo "[4] Restart"
  echo "[5] Enable at boot"
  echo "[0] Back"
  read -r -p "➜ Service option: " x
  case "$x" in
    1) systemctl --no-pager --full status nginx pteroq wings docker mariadb redis-server 2>&1 || true ;;
    2) systemctl start nginx pteroq wings docker mariadb redis-server 2>&1 || true ;;
    3) systemctl stop nginx pteroq wings docker mariadb redis-server 2>&1 || true ;;
    4) systemctl daemon-reload; systemctl restart nginx pteroq wings docker mariadb redis-server 2>&1 || true ;;
    5) systemctl enable nginx pteroq wings docker mariadb redis-server 2>&1 || true ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

database_tools() {
  echo -e "${GOLD}DATABASE MANAGER${RESET}"
  echo "[1] Install MariaDB"
  echo "[2] MariaDB status"
  echo "[3] Restart MariaDB"
  echo "[4] Secure installation helper"
  echo "[0] Back"
  read -r -p "➜ Database option: " x
  case "$x" in
    1) apt-get update -y && apt-get install -y mariadb-server ;;
    2) systemctl --no-pager --full status mariadb 2>&1 || true ;;
    3) systemctl restart mariadb ;;
    4) mysql_secure_installation ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

redis_tools() {
  echo -e "${PINK}REDIS MANAGER${RESET}"
  echo "[1] Install Redis"
  echo "[2] Status"
  echo "[3] Restart"
  echo "[0] Back"
  read -r -p "➜ Redis option: " x
  case "$x" in
    1) apt-get update -y && apt-get install -y redis-server ;;
    2) systemctl --no-pager --full status redis-server 2>&1 || true ;;
    3) systemctl restart redis-server ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

docker_tools() {
  echo -e "${CYAN}DOCKER MANAGER${RESET}"
  echo "[1] Install Docker"
  echo "[2] Status"
  echo "[3] Containers"
  echo "[4] Images"
  echo "[5] Restart Docker"
  echo "[0] Back"
  read -r -p "➜ Docker option: " x
  case "$x" in
    1) curl -fsSL https://get.docker.com | sh; systemctl enable --now docker ;;
    2) systemctl --no-pager --full status docker 2>&1 || true ;;
    3) docker ps -a ;;
    4) docker images ;;
    5) systemctl restart docker ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

network_tools() {
  echo -e "${NEON}NETWORK MANAGER${RESET}"
  echo "[1] Listening ports"
  echo "[2] IP addresses"
  echo "[3] Routes"
  echo "[4] DNS"
  echo "[5] Restart networking"
  echo "[0] Back"
  read -r -p "➜ Network option: " x
  case "$x" in
    1) ss -tulpn ;;
    2) ip -br addr ;;
    3) ip route ;;
    4) resolvectl status 2>/dev/null || cat /etc/resolv.conf ;;
    5) systemctl restart systemd-networkd 2>/dev/null || true ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

firewall_tools() {
  echo -e "${RED}FIREWALL MANAGER${RESET}"
  echo "[1] UFW status"
  echo "[2] UFW allow SSH"
  echo "[3] UFW allow HTTP/HTTPS"
  echo "[4] Enable UFW"
  echo "[5] Disable UFW"
  echo "[0] Back"
  read -r -p "➜ Firewall option: " x
  case "$x" in
    1) ufw status verbose 2>&1 || true ;;
    2) ufw allow OpenSSH ;;
    3) ufw allow 80/tcp; ufw allow 443/tcp ;;
    4) ufw --force enable ;;
    5) ufw disable ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

storage_tools() {
  echo -e "${GOLD}STORAGE MANAGER${RESET}"
  echo "[1] Disk usage"
  echo "[2] Block devices"
  echo "[3] Mounts"
  echo "[4] Inode usage"
  echo "[0] Back"
  read -r -p "➜ Storage option: " x
  case "$x" in
    1) df -h ;;
    2) lsblk ;;
    3) findmnt ;;
    4) df -ih ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

system_tools() {
  echo -e "${PINK}SYSTEM MANAGER${RESET}"
  echo "[1] Update packages"
  echo "[2] Memory"
  echo "[3] CPU info"
  echo "[4] Kernel"
  echo "[5] Processes"
  echo "[0] Back"
  read -r -p "➜ System option: " x
  case "$x" in
    1) apt-get update && apt-get upgrade -y ;;
    2) free -h ;;
    3) lscpu ;;
    4) uname -a ;;
    5) ps aux --sort=-%cpu | head -n 25 ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

logs_tools() {
  echo -e "${PINK}LOG VIEWER${RESET}"
  echo "[1] Wings"
  echo "[2] Panel queue"
  echo "[3] Nginx"
  echo "[4] System"
  echo "[0] Back"
  read -r -p "➜ Log option: " x
  case "$x" in
    1) journalctl -u wings -n 80 --no-pager 2>&1 || true ;;
    2) journalctl -u pteroq -n 80 --no-pager 2>&1 || true ;;
    3) tail -n 80 /var/log/nginx/error.log 2>&1 || true ;;
    4) journalctl -n 80 --no-pager 2>&1 || true ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

os_manager() {
  echo -e "${CYAN}OS MANAGER${RESET}"
  echo "[1] OS release"
  echo "[2] Package update"
  echo "[3] Reboot"
  echo "[0] Back"
  read -r -p "➜ OS option: " x
  case "$x" in
    1) cat /etc/os-release ;;
    2) apt-get update && apt-get upgrade -y ;;
    3) read -r -p "Type REBOOT to confirm: " c; [[ "$c" == REBOOT ]] && reboot ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

blueprint_tools() {
  echo -e "${VIOLET}BLUEPRINT / THEME MANAGER${RESET}"
  echo "[1] Install Blueprint"
  echo "[2] Run Blueprint CLI"
  echo "[3] Remove Blueprint"
  echo "[0] Back"
  read -r -p "➜ Blueprint option: " x
  case "$x" in
    1)
      [[ -d "$PTERODACTYL_DIR" ]] || { echo "Install Panel first."; pause; return; }
      apt-get update -y && apt-get install -y ca-certificates curl git gnupg unzip wget zip nodejs npm
      cd "$PTERODACTYL_DIR"
      wget -q "https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip" -O release.zip
      unzip -o release.zip
      printf '%s\n' 'WEBUSER="www-data";' 'OWNERSHIP="www-data:www-data";' 'USERSHELL="/bin/bash";' > .blueprintrc
      chmod +x blueprint.sh
      bash blueprint.sh
      ;;
    2) command -v blueprint >/dev/null 2>&1 && blueprint || echo "Blueprint is not installed." ;;
    3) [[ -x "$PTERODACTYL_DIR/blueprint.sh" ]] && bash "$PTERODACTYL_DIR/blueprint.sh" -remove || echo "Blueprint not installed." ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

php_tools() {
  echo -e "${CYAN}PHP / COMPOSER${RESET}"
  echo "[1] Install PHP packages"
  echo "[2] Composer version"
  echo "[3] Install Composer"
  echo "[0] Back"
  read -r -p "➜ PHP option: " x
  case "$x" in
    1) apt-get update -y && apt-get install -y php8.3 php8.3-cli php8.3-gd php8.3-mysql php8.3-mbstring php8.3-bcmath php8.3-xml php8.3-curl php8.3-zip ;;
    2) composer --version 2>&1 || true ;;
    3) curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

node_tools() {
  echo -e "${GREEN}NODE.JS MANAGER${RESET}"
  echo "[1] Install Node.js 22"
  echo "[2] Node version"
  echo "[3] npm version"
  echo "[0] Back"
  read -r -p "➜ Node option: " x
  case "$x" in
    1) curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs ;;
    2) node --version 2>&1 || true ;;
    3) npm --version 2>&1 || true ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

phpmyadmin_tools() {
  echo -e "${GREEN}phpMyAdmin${RESET}"
  echo "[1] Install phpMyAdmin"
  echo "[2] Check package"
  echo "[0] Back"
  read -r -p "➜ phpMyAdmin option: " x
  case "$x" in
    1) apt-get update -y && apt-get install -y phpmyadmin ;;
    2) dpkg -s phpmyadmin 2>&1 || true ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

queue_restart() {
  systemctl restart pteroq 2>/dev/null || true
  echo -e "${GREEN}✓ Panel queue restarted.${RESET}"
  pause
}

cache_clear() {
  [[ -d "$PTERODACTYL_DIR" ]] || { echo "Panel directory not found."; pause; return; }
  cd "$PTERODACTYL_DIR"
  php artisan optimize:clear
  echo -e "${GREEN}✓ Panel cache cleared.${RESET}"
  pause
}

vps_vm_manager() {
  echo -e "${WHITE}${BOLD}VPS / VM MANAGER${RESET}"
  echo "[1] Proxmox status"
  echo "[2] Incus status"
  echo "[3] Libvirt status"
  echo "[4] Virtualization info"
  echo "[0] Back"
  read -r -p "➜ VPS/VM option: " x
  case "$x" in
    1) command -v pvesh >/dev/null && pvesh get /cluster/status || echo "Proxmox tools not detected." ;;
    2) command -v incus >/dev/null && incus list || echo "Incus not detected." ;;
    3) command -v virsh >/dev/null && virsh list --all || echo "Libvirt not detected." ;;
    4) systemd-detect-virt || true ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  pause
}

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
