#!/usr/bin/env bash
set -Eeuo pipefail

# SKN HOSTING - Pterodactyl All-in-One Installer
# Independent wrapper around the maintained pterodactyl-installer project.
# No Nobita code is copied into this script.

PTERO_INSTALLER_URL="https://raw.githubusercontent.com/pterodactyl-installer/pterodactyl-installer/master/install.sh"
PTERODACTYL_DIR="/var/www/pterodactyl"

ESC=$'\033'
BOLD="${ESC}[1m"
RESET="${ESC}[0m"
CYAN="${ESC}[36m"
GREEN="${ESC}[32m"
YELLOW="${ESC}[33m"
RED="${ESC}[31m"
MAGENTA="${ESC}[35m"
BLUE="${ESC}[34m"
WHITE="${ESC}[97m"
DIM="${ESC}[2m"
BG_BLUE="${ESC}[44m"


require_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo -e "${RED}✗ Please run this installer as root.${RESET}"
    exit 1
  fi
}

clear_screen() { clear 2>/dev/null || true; }

spinner() {
  local pid="$1" msg="$2" frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r%s%s %s%s' "$CYAN" "${frames:i++%${#frames}:1}" "$msg" "$RESET"
    sleep 0.12
  done
  printf '\r\033[K'
}

run_animated() {
  local msg="$1"; shift
  "$@" >/tmp/skn-action.log 2>&1 &
  local pid=$!
  spinner "$pid" "$msg"
  if wait "$pid"; then
    echo -e "${GREEN}✓ $msg${RESET}"
    return 0
  fi
  echo -e "${RED}✗ $msg failed${RESET}"
  echo -e "${DIM}Last output:${RESET}"
  tail -n 18 /tmp/skn-action.log 2>/dev/null || true
  return 1
}

banner() {
  clear_screen
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BLUE}║${RESET} ${CYAN}${BOLD}███████╗██╗  ██╗███╗   ██╗${RESET}    ${MAGENTA}${BOLD}██╗  ██╗ ██████╗ ███████╗████████╗${RESET} ${BLUE}║${RESET}"
  echo -e "${BLUE}║${RESET} ${CYAN}${BOLD}██╔════╝██║ ██╔╝████╗  ██║${RESET}    ${MAGENTA}${BOLD}██║  ██║██╔═══██╗██╔════╝╚══██╔══╝${RESET} ${BLUE}║${RESET}"
  echo -e "${BLUE}║${RESET} ${CYAN}${BOLD}███████╗█████╔╝ ██╔██╗ ██║${RESET}    ${MAGENTA}${BOLD}███████║██║   ██║███████╗   ██║${RESET}   ${BLUE}║${RESET}"
  echo -e "${BLUE}║${RESET} ${CYAN}${BOLD}╚════██║██╔═██╗ ██║╚██╗██║${RESET}    ${MAGENTA}${BOLD}██╔══██║██║   ██║╚════██║   ██║${RESET}   ${BLUE}║${RESET}"
  echo -e "${BLUE}║${RESET} ${CYAN}${BOLD}███████║██║  ██╗██║ ╚████║${RESET}    ${MAGENTA}${BOLD}██║  ██║╚██████╔╝███████║   ██║${RESET}   ${BLUE}║${RESET}"
  echo -e "${BLUE}║${RESET} ${CYAN}${BOLD}╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝${RESET}    ${MAGENTA}${BOLD}╚═╝  ╚═╝ ╚═════╝ ╚══════╝   ╚═╝${RESET}   ${BLUE}║${RESET}"
  echo -e "${BLUE}╠══════════════════════════════════════════════════════════════════════════════╣${RESET}"
  echo -e "${BLUE}║${RESET}              ${WHITE}${BOLD}SKN HOSTING — ALL IN ONE${RESET} ${DIM}•${RESET} ${MAGENTA}Made By Zyren${RESET}              ${BLUE}║${RESET}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════╝${RESET}"
}
system_status() {
  local cpu ram net os up
  cpu="$(LC_ALL=C top -bn1 2>/dev/null | awk '/Cpu\(s\)/{print int(100-$8); exit}' || echo 0)"
  ram="$(free -m 2>/dev/null | awk '/Mem:/{if ($2) printf "%d", ($3/$2)*100; else print 0}' || echo 0)"
  if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 3 https://github.com >/dev/null 2>&1; then net="CONNECTED"; else net="OFFLINE"; fi
  os="$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Linux}" || echo Linux)"
  up="$(uptime -p 2>/dev/null || echo unknown)"
  echo -e "   ${GREEN}CPU${RESET}: ${WHITE}${cpu}%${RESET}   ${MAGENTA}RAM${RESET}: ${WHITE}${ram}%${RESET}   ${CYAN}Network${RESET}: $([[ "$net" == CONNECTED ]] && echo -e "${GREEN}● CONNECTED${RESET}" || echo -e "${RED}● OFFLINE${RESET}")"
  echo -e "   ${BLUE}OS${RESET}: ${WHITE}${os}${RESET}"
  echo -e "   ${BLUE}Uptime${RESET}: ${WHITE}${up}${RESET}"
}

menu() {
  banner
  echo
  echo -e "${BLUE}╭───────────────────────────────╮  ${MAGENTA}╭───────────────────────────────╮${RESET}"
  echo -e "${BLUE}│${RESET} ${CYAN}${BOLD}⚡ SYSTEM STATUS${RESET}            ${BLUE}│  ${MAGENTA}│${RESET} ${YELLOW}${BOLD}🚀 SKN CONTROL PANEL${RESET}      ${MAGENTA}│${RESET}"
  echo -e "${BLUE}╰───────────────────────────────╯  ${MAGENTA}╰───────────────────────────────╯${RESET}"
  system_status
  echo
  echo -e "${CYAN}${BOLD}╭──────────────────────────────────────────────────────────────────────────────╮${RESET}"
  echo -e "${CYAN}${BOLD}│${RESET} ${WHITE}${BOLD}DEPLOYMENT & SERVICES${RESET}                                                   ${CYAN}${BOLD}│${RESET}"
  echo -e "${CYAN}${BOLD}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
  printf "${CYAN}│${RESET}  ${GREEN}[1]${RESET} ${WHITE}Panel${RESET}              ${GREEN}[5]${RESET} ${WHITE}Themes${RESET}                                  ${CYAN}│${RESET}\n"
  printf "${CYAN}│${RESET}  ${GREEN}[2]${RESET} ${WHITE}Wings${RESET}              ${GREEN}[6]${RESET} ${WHITE}System${RESET}                                  ${CYAN}│${RESET}\n"
  printf "${CYAN}│${RESET}  ${GREEN}[3]${RESET} ${WHITE}Panel + Wings${RESET}      ${GREEN}[7]${RESET} ${WHITE}Container${RESET}                               ${CYAN}│${RESET}\n"
  printf "${CYAN}│${RESET}  ${GREEN}[8]${RESET} ${WHITE}New Module${RESET}         ${GREEN}[4]${RESET} ${WHITE}Toolbox${RESET}                                  ${CYAN}│${RESET}\n"
  echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────────┤${RESET}"
  echo -e "${CYAN}│${RESET} ${MAGENTA}${BOLD}MAINTENANCE & TOOLS${RESET}       ${YELLOW}[9]${RESET} ${WHITE}Extras${RESET}       ${RED}[0]${RESET} ${WHITE}Shutdown${RESET}             ${CYAN}│${RESET}"
  echo -e "${CYAN}╰──────────────────────────────────────────────────────────────────────────────╯${RESET}"
  echo
  echo -e "${YELLOW}${BOLD}➜ Enter Option ${RESET}${DIM}(0-9)${RESET}: \c"
}
fetch_upstream() {
  if ! command -v curl >/dev/null 2>&1; then
    apt-get update -y && apt-get install -y curl
  fi
  curl -fsSL "$PTERO_INSTALLER_URL" -o /tmp/skn-pterodactyl-upstream.sh
  chmod +x /tmp/skn-pterodactyl-upstream.sh
}

install_panel() { fetch_upstream && bash /tmp/skn-pterodactyl-upstream.sh panel; }
install_wings() { fetch_upstream && bash /tmp/skn-pterodactyl-upstream.sh wings; }
install_both() { fetch_upstream && bash /tmp/skn-pterodactyl-upstream.sh panel; bash /tmp/skn-pterodactyl-upstream.sh wings; }

update_panel() {
  [[ -d "$PTERODACTYL_DIR" ]] || { echo "Pterodactyl panel directory not found."; return 1; }
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
    *) echo "Unsupported architecture: $arch"; return 1 ;;
  esac
  install -d /usr/local/bin /etc/pterodactyl
  curl -fsSL "$url" -o /usr/local/bin/wings
  chmod +x /usr/local/bin/wings
  systemctl daemon-reload
  systemctl enable wings >/dev/null 2>&1 || true
  systemctl start wings || true
}

toolbox() {
  echo
  echo -e "${CYAN}[1]${RESET} Service status"
  echo -e "${CYAN}[2]${RESET} Validate Nginx"
  echo -e "${CYAN}[3]${RESET} Wings logs"
  echo -e "${CYAN}[4]${RESET} Panel queue logs"
  echo -e "${RED}[0]${RESET} Back"
  read -r -p "➜ Toolbox option: " x
  case "$x" in
    1) systemctl --no-pager --full status nginx pteroq wings docker mariadb redis-server 2>&1 || true ;;
    2) nginx -t 2>&1 || true ;;
    3) journalctl -u wings -n 60 --no-pager 2>&1 || true ;;
    4) journalctl -u pteroq -n 60 --no-pager 2>&1 || true ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  read -r -p "Press Enter to continue..." _
}

themes() {
  echo
  echo "Blueprint is the extension/theme framework for Pterodactyl."
  echo "[1] Install Blueprint"
  echo "[2] Run Blueprint CLI"
  echo "[3] Remove Blueprint"
  echo "[0] Back"
  read -r -p "➜ Themes option: " x
  case "$x" in
    1)
      [[ -d "$PTERODACTYL_DIR" ]] || { echo "Install Panel first."; return 1; }
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
  read -r -p "Press Enter to continue..." _
}

system_tools() {
  echo
  echo "[1] Update system packages"
  echo "[2] Disk usage"
  echo "[3] Memory usage"
  echo "[4] Network ports"
  echo "[5] Reboot server"
  echo "[0] Back"
  read -r -p "➜ System option: " x
  case "$x" in
    1) apt-get update && apt-get upgrade -y ;;
    2) df -h ;;
    3) free -h ;;
    4) ss -tulpn ;;
    5) read -r -p "Type REBOOT to confirm: " c; [[ "$c" == REBOOT ]] && reboot ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  read -r -p "Press Enter to continue..." _
}

container_tools() {
  echo
  echo "[1] Install Docker Engine"
  echo "[2] Docker status"
  echo "[3] Docker containers"
  echo "[4] Docker images"
  echo "[5] Restart Docker"
  echo "[0] Back"
  read -r -p "➜ Container option: " x
  case "$x" in
    1) curl -fsSL https://get.docker.com | sh; systemctl enable --now docker ;;
    2) systemctl --no-pager --full status docker ;;
    3) docker ps -a ;;
    4) docker images ;;
    5) systemctl restart docker ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  read -r -p "Press Enter to continue..." _
}

new_module() {
  echo
  echo "NEW MODULE"
  echo "[1] Install phpMyAdmin"
  echo "[2] Install Composer"
  echo "[3] Install Node.js 22"
  echo "[0] Back"
  read -r -p "➜ Module option: " x
  case "$x" in
    1) apt-get update -y && apt-get install -y phpmyadmin ;;
    2) curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer ;;
    3) curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  read -r -p "Press Enter to continue..." _
}

extras() {
  echo
  echo "[1] Update Panel"
  echo "[2] Update Wings"
  echo "[3] Restart Pterodactyl services"
  echo "[4] Clear Panel cache"
  echo "[0] Back"
  read -r -p "➜ Extras option: " x
  case "$x" in
    1) run_animated "Updating Panel..." update_panel || true ;;
    2) run_animated "Updating Wings..." update_wings || true ;;
    3) systemctl restart nginx pteroq wings 2>/dev/null || true ;;
    4) cd "$PTERODACTYL_DIR" 2>/dev/null && php artisan optimize:clear || true ;;
    0) return ;;
    *) echo "Invalid option." ;;
  esac
  read -r -p "Press Enter to continue..." _
}

main() {
  printf "\033]0;SKN HOSTING — ALL IN ONE\007" 2>/dev/null || true
  require_root
  while true; do
    menu
    read -r option
    case "$option" in
      1) echo; echo -e "${GREEN}➜ Starting Panel installation...${RESET}"; install_panel || true; read -r -p "Press Enter to return to menu..." _ ;;
      2) echo; echo -e "${MAGENTA}➜ Starting Wings installation...${RESET}"; install_wings || true; read -r -p "Press Enter to return to menu..." _ ;;
      3) echo; echo -e "${YELLOW}➜ Starting Panel + Wings installation...${RESET}"; install_both || true; read -r -p "Press Enter to return to menu..." _ ;;
      4) toolbox ;;
      5) themes ;;
      6) system_tools ;;
      7) container_tools ;;
      8) new_module ;;
      9) extras ;;
      0) clear_screen; echo -e "${GREEN}SKN HOSTING installer stopped safely. Goodbye!${RESET}"; exit 0 ;;
      *) echo -e "${RED}✗ Invalid option. Please choose 0-9.${RESET}"; sleep 1 ;;
    esac
  done
}

main "$@"
