#!/bin/bash
set -e

APP_NAME="File Manager"
INSTALL_DIR="$HOME/.local/share/file-manager"
BIN_DIR="$HOME/.local/bin"
LAUNCH_SCRIPT="$BIN_DIR/file-manager"
DESKTOP="$HOME/Desktop"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "================================================"
echo "  File Manager インストーラー (macOS)"
echo "================================================"
echo ""

# ── Python 確認 ──────────────────────────────────────
if ! command -v python3 &>/dev/null; then
  echo -e "${RED}❌ Python 3 が見つかりません。${NC}"
  echo ""
  echo "以下のいずれかの方法でインストールしてください:"
  echo "  1. https://www.python.org/downloads/ からダウンロード"
  echo "  2. Homebrew: brew install python3"
  exit 1
fi

PY_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo -e "${GREEN}✅ Python $PY_VER が見つかりました${NC}"

# ── インストール先作成 ────────────────────────────────
echo ""
echo "📁 インストール先: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# スクリプトのディレクトリからコピー
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "$SCRIPT_DIR/server.py"       "$INSTALL_DIR/"
cp "$SCRIPT_DIR/index.html"      "$INSTALL_DIR/"
cp "$SCRIPT_DIR/requirements.txt" "$INSTALL_DIR/"

# ── 仮想環境 ──────────────────────────────────────────
echo ""
echo "🔧 Python 仮想環境を作成中..."
python3 -m venv "$INSTALL_DIR/venv"

echo "📦 依存パッケージをインストール中..."
"$INSTALL_DIR/venv/bin/pip" install --upgrade pip -q
"$INSTALL_DIR/venv/bin/pip" install -r "$INSTALL_DIR/requirements.txt" -q
echo -e "${GREEN}✅ パッケージのインストール完了${NC}"

# ── 起動スクリプト ────────────────────────────────────
cat > "$LAUNCH_SCRIPT" << 'EOF'
#!/bin/bash
INSTALL_DIR="$HOME/.local/share/file-manager"
cd "$INSTALL_DIR"
"$INSTALL_DIR/venv/bin/python" server.py &
sleep 1.5
open http://127.0.0.1:8000
wait
EOF
chmod +x "$LAUNCH_SCRIPT"

# ── デスクトップ .command ファイル ─────────────────────
COMMAND_FILE="$DESKTOP/File Manager.command"
cat > "$COMMAND_FILE" << EOF
#!/bin/bash
INSTALL_DIR="\$HOME/.local/share/file-manager"
cd "\$INSTALL_DIR"
"\$INSTALL_DIR/venv/bin/python" server.py &
PID=\$!
sleep 1.5
open http://127.0.0.1:8000
echo ""
echo "File Manager が起動しました → http://127.0.0.1:8000"
echo "このウィンドウを閉じるとサーバーが停止します。"
wait \$PID
EOF
chmod +x "$COMMAND_FILE"

# PATH に BIN_DIR を追加（未追加の場合）
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
echo "  ① デスクトップの「File Manager.command」をダブルクリック"
echo "  ② ターミナルで: file-manager"
echo ""
echo "アンインストール:"
echo "  rm -rf $INSTALL_DIR $LAUNCH_SCRIPT \"$COMMAND_FILE\""
echo ""
