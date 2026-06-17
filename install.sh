#!/usr/bin/env bash
# MailCode 远程安装脚本
# 用法: curl -fsSL https://mailcode.site/install.sh | bash
set -euo pipefail

REPO="zsdfbb/mailcode"
INSTALL_DIR="${HOME}/.local/bin"
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

# ── 1. 检查 Python ──
PYTHON=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        PYTHON=$(command -v "$cmd")
        break
    fi
done

if [ -z "$PYTHON" ]; then
    err "未找到 python3，请先安装 Python 3.9+"
    err "  macOS: brew install python"
    err "  Ubuntu/Debian: sudo apt install python3"
    err "  Fedora: sudo dnf install python3"
    err "  Arch: sudo pacman -S python"
    exit 1
fi

PY_VER=$("$PYTHON" --version 2>&1 | grep -oP '\d+\.\d+' || echo "0")
PY_MAJOR=${PY_VER%.*}
PY_MINOR=${PY_VER#*.}

if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 9 ]; }; then
    err "需要 Python 3.9+，当前版本: $("$PYTHON" --version 2>&1)"
    exit 1
fi

log "Python: $("$PYTHON" --version 2>&1)"

# ── 2. 检查 pip ──
PIP=""
for cmd in pip3 pip; do
    if command -v "$cmd" &>/dev/null; then
        PIP=$(command -v "$cmd")
        break
    fi
done

if [ -z "$PIP" ]; then
    # 尝试用 python -m pip
    if "$PYTHON" -m pip --version &>/dev/null; then
        PIP="$PYTHON -m pip"
    else
        err "未找到 pip，请先安装: $PYTHON -m ensurepip --upgrade"
        exit 1
    fi
fi

log "pip: $("$PIP" --version 2>&1 | head -1)"

# ── 3. 安装 mailcode ──
info "安装 mailcode..."

# 检测是否需要 --break-system-packages (PEP 668)
PIP_FLAGS=""
IN_VENV=$("$PYTHON" -c "import sys; print(int(sys.prefix != sys.base_prefix))" 2>/dev/null || echo "0")
if [ "$IN_VENV" = "0" ]; then
    PIP_FLAGS="--user"
    # 检测是否 PEP 668 环境需要 --break-system-packages
    if "$PIP" install --dry-run --user mailcode 2>&1 | grep -q "externally-managed-environment"; then
        PIP_FLAGS="--user --break-system-packages"
    fi
fi

if ! $PIP install $PIP_FLAGS mailcode 2>&1; then
    warn "pip 安装失败，尝试从源码安装..."
    TMP_DIR=$(mktemp -d)
    trap "rm -rf ${TMP_DIR}" EXIT

    if ! command -v git &>/dev/null; then
        err "未找到 git，请手动安装: https://github.com/${REPO}"
        exit 1
    fi

    info "克隆仓库..."
    git clone --depth 1 "https://github.com/${REPO}.git" "${TMP_DIR}/mailcode" 2>&1 | tail -1
    cd "${TMP_DIR}/mailcode"
    bash install.sh
    exit 0
fi

log "mailcode 已安装"

# ── 4. 确保在 PATH 中 ──
INSTALLED_PATH=$(command -v mailcode 2>/dev/null || true)
if [ -z "$INSTALLED_PATH" ]; then
    USER_BIN=$("$PYTHON" -c "import site; print(site.USER_BASE + '/bin')" 2>/dev/null || echo "${HOME}/.local/bin")
    mkdir -p "$USER_BIN"
    INSTALLED_PATH="${USER_BIN}/mailcode"

    if [ -f "${USER_BIN}/mailcode" ]; then
        log "mailcode 位于: ${USER_BIN}/mailcode"
    fi

    if ! echo "${PATH}" | tr ':' '\n' | grep -qxF "${USER_BIN}"; then
        warn "${USER_BIN} 不在 PATH 中，请添加到 shell rc 文件:"
        echo "  export PATH=\"\${HOME}/.local/bin:\${PATH}\""
        INSTALLED_PATH=""
    fi
fi

# ── 5. 检查 Claude Code ──
if command -v claude &>/dev/null; then
    log "Claude Code 已安装: $(claude --version 2>/dev/null || echo '版本未知')"
else
    warn "未检测到 Claude Code"
    echo "  MailCode 需要 Claude Code 来处理邮件命令。请访问以下地址安装:"
    echo "  https://docs.anthropic.com/en/docs/claude-code/overview"
    echo ""
fi

echo ""

# ── 6. 初始化配置 ──
if command -v mailcode &>/dev/null; then
    mailcode config init 2>/dev/null || true
    log "配置已就绪"
    warn "请编辑配置填入邮箱和密码:"
    echo "  ${CONFIG_DIR}/config.json"
elif [ -n "$INSTALLED_PATH" ] && [ -f "$INSTALLED_PATH" ]; then
    "$PYTHON" -m mailcode.cli config init 2>/dev/null || true
    log "配置已就绪"
fi

echo ""

# ── 7. 完成 ──
log "安装完成！"
echo ""
info "下一步:"
echo "  1. 编辑配置: 编辑 ${CONFIG_DIR}/config.json"
echo "  2. 配置你的 Bot 邮箱和授权码"
echo "  3. 校验配置: mailcode config validate"
echo "  4. 自检连通性: mailcode health"
echo "  5. 启动中继:  mailcode serve"
echo ""
info "更多帮助:"
echo "  mailcode --help"
echo "  https://github.com/${REPO}#readme"
echo ""
