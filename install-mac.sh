#!/bin/bash
set -e

APP_NAME="Filie"
INSTALL_DIR="$HOME/.local/share/filie"
BIN_DIR="$HOME/.local/bin"
LAUNCH_SCRIPT="$BIN_DIR/filie"
DESKTOP="$HOME/Desktop"
PYTHON_VER="3.12.7"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "================================================"
echo "  Filie インストーラー (macOS)"
echo "================================================"
echo ""

# ── Python 自動インストール ───────────────────────────
install_python() {
  echo -e "${YELLOW}⚠ Python 3 が見つかりません。自動インストールします...${NC}"
  echo ""

  # Homebrew が使える場合
  if command -v brew &>/dev/null; then
    echo "📦 Homebrew で Python をインストール中..."
    brew install python3
    hash -r 2>/dev/null || true
    return 0
  fi

  # Homebrew がない場合 → 公式 .pkg をダウンロードしてインストール
  PKG="python-${PYTHON_VER}-macos11.pkg"
  PKG_URL="https://www.python.org/ftp/python/${PYTHON_VER}/${PKG}"
  echo "📥 Python ${PYTHON_VER} をダウンロード中..."
  echo "   (数分かかる場合があります)"
  echo ""
  curl -L --progress-bar -o "/tmp/${PKG}" "${PKG_URL}"

  echo ""
  echo "🔧 Python をインストール中... (管理者パスワードが必要です)"
  sudo installer -pkg "/tmp/${PKG}" -target /
  rm -f "/tmp/${PKG}"
  hash -r 2>/dev/null || true
}

if ! command -v python3 &>/dev/null; then
  install_python
fi

# 再確認
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}❌ Python のインストールに失敗しました。${NC}"
  echo "手動でインストールしてください: https://www.python.org/downloads/"
  exit 1
fi

PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')")
echo -e "${GREEN}✅ Python ${PY_VER} が見つかりました${NC}"

# ── インストール先作成 ─────────────────────────────────
echo ""
echo "📁 インストール先: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/server.py"        "$INSTALL_DIR/"
cp "$SCRIPT_DIR/index.html"       "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"

# ── 仮想環境と依存パッケージ ────────────────────────────
echo ""
echo "🔧 Python 仮想環境を作成中..."
python3 -m venv "$INSTALL_DIR/venv"

echo "📦 依存パッケージをインストール中..."
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip -q
"$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt" -q
echo -e "${GREEN}✅ パッケージのインストール完了${NC}"

# ── ターミナル用起動スクリプト ───────────────────────────
cat > "$LAUNCH_SCRIPT" << 'EOF'
#!/bin/bash
INSTALL_DIR="$HOME/.local/share/filie"
cd "$INSTALL_DIR"
"$INSTALL_DIR/venv/bin/python" server.py &
sleep 1.5
open http://127.0.0.1:8000
wait
EOF
chmod +x "$LAUNCH_SCRIPT"

# ── デスクトップ .command ファイル ────────────────────────
COMMAND_FILE="$DESKTOP/Filie.command"
cat > "$COMMAND_FILE" << EOF
#!/bin/bash
INSTALL_DIR="\$HOME/.local/share/filie"
cd "\$INSTALL_DIR"
"\$INSTALL_DIR/venv/bin/python" server.py &
PID=\$!
sleep 1.5
open http://127.0.0.1:8000
echo ""
echo "Filie が起動しました → http://127.0.0.1:8000"
echo "このウィンドウを閉じるとサーバーが停止します。"
wait \$PID
EOF
chmod +x "$COMMAND_FILE"

# ── PATH 登録 ──────────────────────────────────────────
SHELL_RC=""
if [[ "$SHELL" == *"zsh"* ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
  SHELL_RC="$HOME/.bashrc"
fi
if [[ -n "$SHELL_RC" ]] && ! grep -q "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
  echo "" >> "$SHELL_RC"
  echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$SHELL_RC"
fi

echo ""
echo "================================================"
echo -e "  ${GREEN}✅ インストール完了！${NC}"
echo "================================================"
echo ""
echo "起動方法:"
echo "  ① デスクトップの「Filie.command」をダブルクリック"
echo "  ② ターミナルで: filie"
echo ""
echo "アンインストール:"
echo "  rm -rf $INSTALL_DIR $LAUNCH_SCRIPT \"$COMMAND_FILE\""
echo ""
