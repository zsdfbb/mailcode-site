#!/usr/bin/env bash
# MailCode 远程安装脚本
# 用法: curl -fsSL https://mailcode.site/install.sh | bash
set -euo pipefail

REPO="zsdfbb/mailcode-site"
INSTALL_DIR="${HOME}/.local/bin"
LIB_DIR="${HOME}/.local/lib/mailcode"
CONFIG_DIR="${HOME}/.config/mailcode"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { echo -e "${GREEN}[✓]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
info() { echo -e "${CYAN}[i]${NC} $*"; }

echo ""
echo "  MailCode 远程安装"
echo "  ================="
echo ""

# ── 1. 检查环境 ──
if ! command -v python3 &>/dev/null; then
    err "未找到 python3，请先安装 Python 3.9+"
    exit 1
fi
log "Python3: $(command -v python3)"

if ! command -v tmux &>/dev/null; then
    warn "未找到 tmux，请先安装"
    warn "  macOS: brew install tmux"
    warn "  Ubuntu/Debian: sudo apt install tmux"
    warn "  Fedora: sudo dnf install tmux"
    warn "  Arch: sudo pacman -S tmux"
fi

if ! command -v curl &>/dev/null; then
    err "未找到 curl"
    exit 1
fi
log "curl: $(command -v curl)"

# ── 2. 检测平台 ──
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64|amd64) ARCH="x86_64" ;;
    aarch64)      ARCH="arm64" ;;
esac

case "$OS" in
    darwin|linux) ;;
    *)
        err "不支持的操作系统: ${OS}（仅支持 macOS 和 Linux）"
        exit 1
        ;;
esac

log "平台: ${OS}/${ARCH}"

# ── 3. 获取最新版本 ──
info "查询最新版本..."
LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' \
    | sed 's/.*"tag_name": "\(.*\)",/\1/' \
    || true)

if [ -z "$LATEST" ]; then
    err "无法获取最新版本信息，请检查网络连接"
    err "或手动安装: git clone https://github.com/zsdfbb/mailcode && cd MailCode && bash install.sh"
    exit 1
fi

VERSION="${LATEST#v}"
log "最新版本: ${LATEST}"

# ── 4. 下载二进制 ──
ARCHIVE_NAME="mailcode-${VERSION}-${OS}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST}/${ARCHIVE_NAME}"

TMP_DIR=$(mktemp -d)
trap "rm -rf ${TMP_DIR}" EXIT

info "下载 ${ARCHIVE_NAME}..."
curl -fsSL "$DOWNLOAD_URL" -o "${TMP_DIR}/mailcode.tar.gz" || {
    err "下载失败: ${DOWNLOAD_URL}"
    err "如果架构不匹配，尝试手动安装: git clone https://github.com/zsdfbb/mailcode && cd MailCode && bash install.sh"
    exit 1
}
log "下载完成"

# ── 5. 解压 ──
info "解压..."
EXTRACT_DIR="${TMP_DIR}/extract"
mkdir -p "$EXTRACT_DIR"
tar -xzf "${TMP_DIR}/mailcode.tar.gz" -C "$EXTRACT_DIR"

STAGING_DIR=$(ls -d "${EXTRACT_DIR}"/*/ 2>/dev/null | head -1)
if [ -z "$STAGING_DIR" ]; then
    err "解压后未找到内容"
    exit 1
fi
BINARY_DIR="${STAGING_DIR}/mailcode.dist"
BINARY="${BINARY_DIR}/mailcode"

if [ ! -f "$BINARY" ]; then
    err "未找到二进制文件: ${BINARY}"
    exit 1
fi
log "解压完成"

# ── 6. 安装二进制到 ~/.local ──
info "安装二进制..."
mkdir -p "${INSTALL_DIR}" "${LIB_DIR}"
rm -rf "${LIB_DIR}" "${INSTALL_DIR}/mailcode"
cp -r "$BINARY_DIR" "${LIB_DIR}"
ln -sf "${LIB_DIR}/mailcode" "${INSTALL_DIR}/mailcode"
log "已安装: ${INSTALL_DIR}/mailcode"

# ── 7. 生成配置 ──
if [ ! -f "${CONFIG_DIR}/config.json" ]; then
    info "生成默认配置..."
    mkdir -p "${CONFIG_DIR}"
    python3 -c "
import json
config = {
    'smtp': {'host': 'smtp.qq.com', 'port': 465, 'secure': True, 'user': '', 'pass': ''},
    'imap': {'host': 'imap.qq.com', 'port': 993, 'secure': True, 'user': '', 'pass': ''},
    'email': {
        'from': '', 'from_name': 'MailCode Remote', 'agent_type': 'opencode',
        'to': '', 'check_interval': 5,
        'session_expiry_hours': 24, 'max_commands_per_session': 10,
        'default_project_dir': '~/projects/current'
    },
    'security': {
        'allowed_senders': [],
        'blocked_commands': [
            'rm -rf /', 'sudo rm', 'chmod 777',
            'curl.*|.*sh', 'wget.*|.*sh'
        ],
        'auth_policy': 'warn',
        'coldstart_confirm': true
    },
    'notification': {
        'desktop': true,
        'desktop_sound': ''
    }
}
with open('${CONFIG_DIR}/config.json', 'w') as f:
    json.dump(config, f, ensure_ascii=False, indent=2)
"
    log "已创建配置: ${CONFIG_DIR}/config.json"
else
    log "配置已存在: ${CONFIG_DIR}/config.json"
fi

# ── 8. 验证冷启动配置 ──
info "冷启动要求：创建符号链接指向你的项目目录:"
echo "  ln -sfn /path/to/your/project ~/projects/current"
echo ""
info "启动完成后，发送新邮件包含 project: <name> 即可触发冷启动流程"
echo ""

# ── 9. 安装 bridge 插件 ──
# 从解压包中复制 mailcode-bridge.js
BRIDGE_SRC="${STAGING_DIR}/mailcode-bridge.js"
if [ -f "$BRIDGE_SRC" ]; then
    OC_PLUGINS_DIR="${HOME}/.config/opencode/plugins"
    mkdir -p "$OC_PLUGINS_DIR"
    cp -f "$BRIDGE_SRC" "${OC_PLUGINS_DIR}/mailcode-bridge.js"
    log "OpenCode bridge 已安装到 ~/.config/opencode/plugins/"
else
    warn "未找到 mailcode-bridge.js，跳过 OpenCode 插件安装"
fi

# Claude Code hooks（内联写入）
CLAUDE_DIR="${HOME}/.claude"
CLAUDE_SETTINGS="${CLAUDE_DIR}/settings.json"
CLAUDE_HOOK=$(cat << 'EOF'
{
  "hooks": {
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "mailcode notify completed"
          }
        ]
      }
    ]
  }
}
EOF
)

mkdir -p "${CLAUDE_DIR}"
if [ -f "$CLAUDE_SETTINGS" ]; then
    python3 -c "
import json
with open('${CLAUDE_SETTINGS}', 'r') as f:
    s = json.load(f)
hooks = s.setdefault('hooks', {})
stop = hooks.setdefault('Stop', [])
entry = {'matcher': '', 'hooks': [{'type': 'command', 'command': 'mailcode notify completed'}]}
if entry not in stop:
    stop.append(entry)
with open('${CLAUDE_SETTINGS}', 'w') as f:
    json.dump(s, f, ensure_ascii=False, indent=2)
"
    log "Claude Code hooks 已合并到 ~/.claude/settings.json"
else
    echo "$CLAUDE_HOOK" > "$CLAUDE_SETTINGS"
    log "Claude Code hooks 已安装到 ~/.claude/settings.json"
fi

# ── 10. 检查 PATH ──
if ! echo "${PATH}" | tr ':' '\n' | grep -qxF "${INSTALL_DIR}"; then
    echo ""
    warn "~/.local/bin 不在 PATH 中，请添加到 ~/.zshrc 或 ~/.bashrc:"
    echo "  export PATH=\"\${HOME}/.local/bin:\${PATH}\""
fi

# ── 11. 验证 ──
echo ""
if "${INSTALL_DIR}/mailcode" --version &>/dev/null; then
    log "安装验证通过: $("${INSTALL_DIR}/mailcode" --version)"
else
    warn "安装验证异常，请检查 ${INSTALL_DIR}/mailcode"
fi

echo ""
log "安装完成！"
echo ""
info "启动中继:"
echo "  mailcode serve --idle"
echo ""
info "启动 TUI:"
echo "  mailcode tui"
echo ""
info "查看帮助:"
echo "  mailcode --help"
echo ""
