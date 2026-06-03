#!/bin/bash

INSTALL_DIR="$HOME/.local/share/filie"
LAUNCH_SCRIPT="$HOME/.local/bin/filie"
COMMAND_FILE="$HOME/Desktop/Filie.command"
PLIST="/Library/LaunchDaemons/com.filie.portforward.plist"
ANCHOR="/etc/pf.anchors/filie"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "================================================"
echo "  Filie アンインストーラー (macOS)"
echo "================================================"
echo ""
echo "以下のファイル・設定を削除します:"
echo "  - $INSTALL_DIR"
echo "  - $LAUNCH_SCRIPT"
echo "  - $COMMAND_FILE"
echo "  - /etc/hosts の filie エントリ"
echo ""
read -p "続行しますか？ [y/N] " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "キャンセルしました。"
  exit 0
fi
echo ""

# ── アプリファイルの削除 ──────────────────────────────
remove() {
  if [ -e "$1" ]; then
    rm -rf "$1"
    echo -e "  ${GREEN}✅ 削除:${NC} $1"
  fi
}
remove "$INSTALL_DIR"
remove "$LAUNCH_SCRIPT"
remove "$COMMAND_FILE"

# ── /etc/hosts の filie エントリを削除 ─────────────────
if grep -q "filie" /etc/hosts 2>/dev/null; then
  sudo sed -i '' '/[[:space:]]filie$/d' /etc/hosts
  echo -e "  ${GREEN}✅ /etc/hosts から filie を削除しました${NC}"
fi

echo ""
echo "================================================"
echo -e "  ${GREEN}✅ アンインストール完了${NC}"
echo "================================================"
echo ""
echo "Python 自体はアンインストールされません。"
echo "Python を削除する場合は別途対応してください。"
echo ""
