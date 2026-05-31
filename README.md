# Filie

ブラウザで動くローカルファイルマネージャー。Directory Opus にインスパイアされたデュアルペイン型。

## 機能

- デュアルペイン + タブ
- サムネイル表示（画像・動画・PSD）
- プレビューパネル（テキスト・画像・動画・音声・PDF・CSV・ZIP）
- フォルダツリー / お気に入り
- ファイル検索（再帰）
- バッチリネーマー
- 設定の自動保存（localStorage）

## 必要環境

- Python 3.10 以上

## インストール

### macOS

```bash
chmod +x install-mac.sh
./install-mac.sh
```

デスクトップの「Filie.command」をダブルクリックで起動。

### Windows

`install-windows.bat` をダブルクリック。  
デスクトップの「Filie」ショートカットで起動。

## 手動起動

```bash
pip install -r requirements.txt
python server.py
# → http://127.0.0.1:8000 をブラウザで開く
```

## ライセンス

MIT
