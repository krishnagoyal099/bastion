#!/bin/bash
# Bastion TUI - UI Library
# Engineering Chic: Bloomberg Terminal meets Stripe CLI

# Colors - Muted, Professional Palette
export C_RESET='\033[0m'
export C_BOLD='\033[1m'
export C_DIM='\033[2m'
export C_ITALIC='\033[3m'

# Primary colors (no hacker green!)
export C_WHITE='\033[97m'
export C_GRAY='\033[90m'
export C_BLUE='\033[38;5;75m'       # Soft blue
export C_PURPLE='\033[38;5;141m'    # Muted purple
export C_CYAN='\033[38;5;117m'      # Soft cyan
export C_YELLOW='\033[38;5;222m'    # Warm yellow
export C_RED='\033[38;5;203m'       # Soft red
export C_ORANGE='\033[38;5;215m'    # Warm orange

# Status colors
export C_SUCCESS='\033[38;5;114m'   # Sage green (not neon)
export C_ERROR='\033[38;5;203m'     # Soft red
export C_WARN='\033[38;5;222m'      # Warm yellow
export C_INFO='\033[38;5;117m'      # Soft cyan

# Background
export C_BG_DARK='\033[48;5;234m'
export C_BG_DARKER='\033[48;5;232m'

# Box drawing characters
export BOX_TL='╭' BOX_TR='╮' BOX_BL='╰' BOX_BR='╯'
export BOX_H='─' BOX_V='│'
export BOX_TL_D='╔' BOX_TR_D='╗' BOX_BL_D='╚' BOX_BR_D='╝'
export BOX_H_D='═' BOX_V_D='║'

# Icons
export ICON_SUCCESS='✓'
export ICON_ERROR='✗'
export ICON_WARN='⚠'
export ICON_INFO='ℹ'
export ICON_ARROW='→'
export ICON_DOT='●'
export ICON_RING='○'
export ICON_LOCK='🔐'
export ICON_UNLOCK='🔓'
export ICON_ROOK='♜'
export ICON_WHALE='🐳'
export ICON_BOT='🤖'
export ICON_HIDDEN='🙈'
export ICON_CHART='📊'
export ICON_MONEY='💰'

# ═══════════════════════════════════════════════════════════════════
# ASCII Banner - BASTION with Rook-styled I
# ═══════════════════════════════════════════════════════════════════
show_banner() {
    echo -e "${C_WHITE}${C_BOLD}"
    cat << 'EOF'
    ╔═════════════════════════════════════════════════════════════════════╗
    ║                                                                     ║
    ║   ██████╗  █████╗ ███████╗████████╗ ██▄██▄██   ██████╗ ███╗   ██╗   ║
    ║   ██╔══██╗██╔══██╗██╔════╝╚══██╔══╝ ▀██████▀  ██╔═══██╗████╗  ██║   ║
    ║   ██████╔╝███████║███████╗   ██║      ████    ██║   ██║██╔██╗ ██║   ║
    ║   ██╔══██╗██╔══██║╚════██║   ██║     ▄████▄   ██║   ██║██║╚██╗██║   ║
    ║   ██████╔╝██║  ██║███████║   ██║    ▓██████▓  ╚██████╔╝██║ ╚████║   ║
    ║   ╚═════╝ ╚═╝  ╚═╝╚══════╝   ╚═╝    ▀▀▀▀▀▀▀▀   ╚═════╝ ╚═╝  ╚═══╝   ║
    ║                                                                     ║
    ║              ━━━━  ZK-POWERED ANTI-MEV DARK POOL  ━━━━              ║
    ╚═════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${C_RESET}"
}

# ═══════════════════════════════════════════════════════════════════
# Status Bar - Network, Connection, Block Height
# ═══════════════════════════════════════════════════════════════════
show_status_bar() {
    local network="${1:-casper-test}"
    local status="${2:-connected}"
    local block="${3:-...}"
    local identity="${4:-user}"
    
    local status_icon status_color
    if [[ "$status" == "connected" ]]; then
        status_icon="●"
        status_color="${C_SUCCESS}"
    else
        status_icon="○"
        status_color="${C_ERROR}"
    fi
    
    echo -e "${C_BG_DARK}${C_WHITE}"
    printf " %-20s │ %b%-12s${C_RESET}${C_BG_DARK}${C_WHITE} │ %-18s │ %b%-15s${C_RESET}${C_BG_DARK}${C_WHITE} \n" \
        "Network: ${network}" \
        "${status_color}${status_icon} " "${status}" \
        "Block: #${block}" \
        "${C_PURPLE}♜ " "${identity}"
    echo -e "${C_RESET}"
}

# ═══════════════════════════════════════════════════════════════════
# Pipeline Animation
# ═══════════════════════════════════════════════════════════════════
pipeline_step() {
    local step="$1"
    local status="$2"  # pending, active, done, error
    local label="$3"
    
    case "$status" in
        pending)
            echo -e "${C_DIM}  ○ ${label}${C_RESET}"
            ;;
        active)
            echo -e "${C_CYAN}  ◐ ${label}...${C_RESET}"
            ;;
        done)
            echo -e "${C_SUCCESS}  ${ICON_SUCCESS} ${label}${C_RESET}"
            ;;
        error)
            echo -e "${C_ERROR}  ${ICON_ERROR} ${label}${C_RESET}"
            ;;
    esac
}

show_pipeline() {
    local current_step="$1"
    local steps=("HASHING" "PROVING" "SENDING" "CONFIRMING")
    
    echo ""
    for i in "${!steps[@]}"; do
        if (( i < current_step )); then
            pipeline_step "$i" "done" "${steps[$i]}"
        elif (( i == current_step )); then
            pipeline_step "$i" "active" "${steps[$i]}"
        else
            pipeline_step "$i" "pending" "${steps[$i]}"
        fi
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# Box Drawing Utilities
# ═══════════════════════════════════════════════════════════════════
draw_box() {
    local title="$1"
    local width="${2:-78}"
    local padding=$(( (width - ${#title} - 4) / 2 ))
    
    echo -e "${C_WHITE}${BOX_TL_D}$(printf '%0.s═' $(seq 1 $width))${BOX_TR_D}"
    printf "${BOX_V_D}%*s %s %*s${BOX_V_D}\n" "$padding" "" "$title" "$padding" ""
    echo -e "${BOX_BL_D}$(printf '%0.s═' $(seq 1 $width))${BOX_BR_D}${C_RESET}"
}

draw_section() {
    local title="$1"
    echo -e "\n${C_BOLD}${C_WHITE}━━━ ${title} ━━━${C_RESET}\n"
}

# ═══════════════════════════════════════════════════════════════════
# Message Utilities
# ═══════════════════════════════════════════════════════════════════
msg_info() {
    echo -e "${C_INFO}${ICON_INFO}${C_RESET} $1"
}

msg_success() {
    echo -e "${C_SUCCESS}${ICON_SUCCESS}${C_RESET} $1"
}

msg_error() {
    echo -e "${C_ERROR}${ICON_ERROR}${C_RESET} $1"
}

msg_warn() {
    echo -e "${C_WARN}${ICON_WARN}${C_RESET} $1"
}

# ═══════════════════════════════════════════════════════════════════
# Spinner
# ═══════════════════════════════════════════════════════════════════
spin() {
    local pid=$!
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " ${C_CYAN}%c${C_RESET} " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b"
    done
    printf "   \b\b\b"
}

# ═══════════════════════════════════════════════════════════════════
# Table Drawing
# ═══════════════════════════════════════════════════════════════════
draw_table_header() {
    local cols=("$@")
    echo -e "${C_BOLD}${C_WHITE}"
    printf "│"
    for col in "${cols[@]}"; do
        printf " %-15s │" "$col"
    done
    echo -e "${C_RESET}"
    printf "├"
    for col in "${cols[@]}"; do
        printf "─────────────────┼"
    done | sed 's/┼$/┤/'
    echo ""
}

draw_table_row() {
    local cols=("$@")
    printf "│"
    for col in "${cols[@]}"; do
        printf " %-15s │" "$col"
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# Progress Bar
# ═══════════════════════════════════════════════════════════════════
progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-40}
    local percent=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    
    printf "${C_CYAN}["
    printf '%0.s█' $(seq 1 $filled)
    printf '%0.s░' $(seq 1 $empty)
    printf "] ${C_WHITE}%3d%%${C_RESET}" "$percent"
}

# ═══════════════════════════════════════════════════════════════════
# Clear screen and position
# ═══════════════════════════════════════════════════════════════════
clear_screen() {
    printf '\033[2J\033[H'
}

move_cursor() {
    local row=$1
    local col=$2
    printf '\033[%d;%dH' "$row" "$col"
}

hide_cursor() {
    printf '\033[?25l'
}

show_cursor() {
    printf '\033[?25h'
}
