import os
import shutil
import base64
import mimetypes
import stat
import struct
import zipfile
import tarfile
import csv
import io
import urllib.parse
from pathlib import Path
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, FileResponse, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="Filie")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8000", "http://127.0.0.1:8000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def extract_psd_thumb(path: Path) -> bytes | None:
    """PSD/PSB ファイルからリソース 1036 の埋め込み JPEG サムネイルを抽出する。"""
    try:
        with open(str(path), 'rb') as f:
            if f.read(4) != b'8BPS':
                return None
            version = struct.unpack('>H', f.read(2))[0]
            if version not in (1, 2):
                return None
            f.seek(6, 1)           # reserved
            f.seek(2+4+4+2+2, 1)   # channels, height, width, depth, color_mode

            # カラーモードデータセクション
            f.seek(struct.unpack('>I', f.read(4))[0], 1)

            # イメージリソースセクション
            res_len = struct.unpack('>I', f.read(4))[0]
            res_end = f.tell() + res_len

            while f.tell() + 12 <= res_end:
                if f.read(4) != b'8BIM':
                    break
                res_id = struct.unpack('>H', f.read(2))[0]
                # Pascal 文字列 (名前): 偶数バイトにパディング
                nl = struct.unpack('B', f.read(1))[0]
                f.seek(nl + (1 if nl % 2 == 0 else 0), 1)

                data_len = struct.unpack('>I', f.read(4))[0]
                data_start = f.tell()

                if res_id in (1033, 1036):  # サムネイルリソース (古/新)
                    fmt = struct.unpack('>I', f.read(4))[0]
                    f.seek(16, 1)   # w, h, widthBytes, totalSize
                    comp_size = struct.unpack('>I', f.read(4))[0]
                    f.seek(4, 1)    # bpp, planes
                    if fmt == 1:    # kJpegRGB
                        jpeg = f.read(comp_size)
                        if jpeg[:2] == b'\xff\xd8':
                            return jpeg

                f.seek(data_start + data_len + (data_len % 2), 0)
    except Exception:
        pass
    return None


def safe_path(path: str) -> Path:
    if not path or path.strip() in ("", "~"):
        return Path.home()
    return Path(os.path.abspath(os.path.expanduser(path)))


@app.get("/", response_class=HTMLResponse)
async def index():
    here = Path(__file__).parent / "index.html"
    if not here.exists():
        return HTMLResponse("<h1>index.html not found</h1>", status_code=404)
    return HTMLResponse(content=here.read_text(encoding="utf-8"))


@app.get("/files")
async def list_files(path: str = ""):
    target = safe_path(path)
    if not target.exists():
        raise HTTPException(404, "Path not found")
    if not target.is_dir():
        raise HTTPException(400, "Not a directory")
    try:
        entries = sorted(target.iterdir(), key=lambda x: (not x.is_dir(), x.name.lower()))
    except PermissionError:
        raise HTTPException(403, "Permission denied")

    items = []
    for item in entries:
        try:
            stat = item.stat()
            items.append({
                "name": item.name,
                "path": str(item),
                "is_dir": item.is_dir(),
                "size": stat.st_size if not item.is_dir() else -1,
                "modified": stat.st_mtime,
                "ext": item.suffix.lower() if not item.is_dir() else "",
            })
        except (PermissionError, OSError):
            continue

    parent = target.parent
    return {
        "path": str(target),
        "parent": str(parent) if parent != target else str(target),
        "items": items,
    }


@app.get("/tree")
async def get_tree(path: str = ""):
    target = safe_path(path)
    if not target.exists() or not target.is_dir():
        raise HTTPException(404, "Directory not found")

    def build(p: Path, depth: int = 0) -> dict:
        node = {"name": p.name or str(p), "path": str(p), "children": []}
        if depth < 4:
            try:
                dirs = sorted(
                    (x for x in p.iterdir() if x.is_dir()),
                    key=lambda x: x.name.lower(),
                )
                for d in dirs:
                    try:
                        node["children"].append(build(d, depth + 1))
                    except (PermissionError, OSError):
                        node["children"].append({"name": d.name, "path": str(d), "children": []})
            except (PermissionError, OSError):
                pass
        return node

    return build(target)


class PathPair(BaseModel):
    src: str
    dst: str


class PathItem(BaseModel):
    path: str


@app.post("/copy")
async def copy_file(req: PathPair):
    src = safe_path(req.src)
    dst = safe_path(req.dst)
    if not src.exists():
        raise HTTPException(404, "Source not found")
    try:
        dst_path = dst / src.name if dst.is_dir() else dst
        if src.is_dir():
            shutil.copytree(str(src), str(dst_path))
        else:
            shutil.copy2(str(src), str(dst_path))
        return {"success": True, "dst": str(dst_path)}
    except Exception as e:
        raise HTTPException(500, str(e))


@app.post("/move")
async def move_file(req: PathPair):
    src = safe_path(req.src)
    dst = safe_path(req.dst)
    if not src.exists():
        raise HTTPException(404, "Source not found")
    try:
        dst_path = dst / src.name if dst.is_dir() else dst
        shutil.move(str(src), str(dst_path))
        return {"success": True, "dst": str(dst_path)}
    except Exception as e:
        raise HTTPException(500, str(e))


@app.delete("/delete")
async def delete_file(req: PathItem):
    target = safe_path(req.path)
    if not target.exists():
        raise HTTPException(404, "Path not found")
    try:
        if target.is_dir():
            shutil.rmtree(str(target))
        else:
            target.unlink()
        return {"success": True}
    except Exception as e:
        raise HTTPException(500, str(e))


@app.get("/preview")
async def preview_file(path: str):
    target = safe_path(path)
    if not target.exists() or not target.is_file():
        raise HTTPException(404, "File not found")

    mime, _ = mimetypes.guess_type(str(target))
    size = target.stat().st_size
    ext = target.suffix.lower()
    raw_url = f"/raw?path={urllib.parse.quote(str(target), safe='')}"

    # PSD / PSB — 埋め込みサムネイルを JPEG として返す (画像判定より先に処理する)
    if ext in {'.psd', '.psb'}:
        jpeg = extract_psd_thumb(target)
        if jpeg is not None:
            thumb_url = f"/psd-thumb?path={urllib.parse.quote(str(target), safe='')}"
            return {"type": "image", "mime": "image/jpeg", "url": thumb_url, "size": size,
                    "label": f"PSD サムネイル ({size:,} bytes)"}
        return {"type": "binary", "mime": "image/vnd.adobe.photoshop", "size": size}

    # 画像
    image_exts = {'.png','.jpg','.jpeg','.gif','.webp','.svg','.bmp','.ico','.tiff','.tif','.avif'}
    if (mime and mime.startswith("image/")) or ext in image_exts:
        return {"type": "image", "mime": mime or "image/png", "url": raw_url, "size": size}

    # 動画
    video_exts = {'.mp4','.webm','.ogg','.ogv','.mov','.avi','.mkv','.m4v','.flv','.wmv','.3gp'}
    if (mime and mime.startswith("video/")) or ext in video_exts:
        return {"type": "video", "mime": mime or "video/mp4", "url": raw_url, "size": size}

    # 音声
    audio_exts = {'.mp3','.wav','.ogg','.oga','.flac','.aac','.m4a','.opus','.wma','.aiff'}
    if (mime and mime.startswith("audio/")) or ext in audio_exts:
        return {"type": "audio", "mime": mime or "audio/mpeg", "url": raw_url, "size": size}

    # PDF
    if mime == "application/pdf" or ext == ".pdf":
        return {"type": "pdf", "url": raw_url, "size": size}

    # CSV
    if ext == ".csv":
        try:
            content = target.read_text(encoding="utf-8", errors="replace")
            reader = csv.reader(io.StringIO(content))
            rows = []
            for row in reader:
                rows.append(row)
                if len(rows) >= 500:
                    break
            return {"type": "csv", "rows": rows, "size": size, "truncated": size > 500}
        except Exception:
            pass

    # ZIP
    if ext == ".zip":
        try:
            with zipfile.ZipFile(str(target)) as zf:
                entries = [
                    {"name": i.filename, "size": i.file_size, "is_dir": i.filename.endswith("/")}
                    for i in sorted(zf.infolist(), key=lambda x: x.filename)[:1000]
                ]
            return {"type": "archive", "format": "ZIP", "entries": entries, "size": size}
        except Exception:
            pass

    # TAR系
    if ext in {'.tar', '.tgz', '.gz', '.bz2', '.xz'}:
        try:
            with tarfile.open(str(target)) as tf:
                entries = [
                    {"name": m.name, "size": m.size, "is_dir": m.isdir()}
                    for m in tf.getmembers()[:1000]
                ]
            return {"type": "archive", "format": "TAR", "entries": entries, "size": size}
        except Exception:
            pass

    # テキスト
    text_exts = {
        ".txt",".py",".js",".ts",".jsx",".tsx",".html",".css",".json",
        ".xml",".yaml",".yml",".md",".log",".sh",".bash",".zsh",
        ".bat",".cmd",".ini",".cfg",".conf",".toml",".rs",".go",".java",
        ".c",".cpp",".h",".hpp",".rb",".php",".sql",".r",".swift",
        ".kt",".scala",".vue",".svelte",".gitignore",".env",
        ".makefile",".mk",".tf",".lua",".pl",".pm",".dockerfile",
        ".tsv",".jsonl",".ndjson",".graphql",".proto",".plist",
    }
    is_text = (mime and mime.startswith("text/")) or ext in text_exts
    if not is_text and not ext and size < 512 * 1024:
        try:
            target.read_text(encoding="utf-8")
            is_text = True
        except Exception:
            pass

    if is_text:
        limit = 100 * 1024
        try:
            content = target.read_text(encoding="utf-8", errors="replace")[:limit]
            return {"type": "text", "content": content, "size": size,
                    "truncated": size > limit, "ext": ext}
        except Exception:
            pass

    return {"type": "binary", "mime": mime or "application/octet-stream", "size": size}


@app.get("/psd-thumb")
async def psd_thumb(path: str):
    target = safe_path(path)
    if not target.exists() or not target.is_file():
        raise HTTPException(404, "File not found")
    if target.suffix.lower() not in ('.psd', '.psb'):
        raise HTTPException(400, "Not a PSD file")
    jpeg = extract_psd_thumb(target)
    if jpeg is None:
        raise HTTPException(404, "No embedded thumbnail")
    return Response(content=jpeg, media_type="image/jpeg")


@app.get("/raw")
async def serve_raw(path: str):
    target = safe_path(path)
    if not target.exists() or not target.is_file():
        raise HTTPException(404, "File not found")
    mime, _ = mimetypes.guess_type(str(target))
    headers = {}
    if mime == "application/pdf":
        headers["Content-Disposition"] = "inline"
    return FileResponse(str(target), media_type=mime or "application/octet-stream", headers=headers)


@app.get("/meta")
async def file_meta(path: str):
    target = safe_path(path)
    if not target.exists():
        raise HTTPException(404, "Not found")
    s = target.stat()
    mime, _ = mimetypes.guess_type(str(target))
    result = {
        "name": target.name,
        "path": str(target),
        "is_dir": target.is_dir(),
        "size": s.st_size,
        "modified": s.st_mtime,
        "created": s.st_ctime,
        "accessed": s.st_atime,
        "mime": mime or ("inode/directory" if target.is_dir() else "application/octet-stream"),
        "ext": target.suffix.lower(),
        "permissions": oct(stat.S_IMODE(s.st_mode)),
    }
    if target.is_file() and s.st_size < 10 * 1024 * 1024:
        try:
            text = target.read_text(encoding="utf-8", errors="replace")
            result["lines"] = text.count('\n') + (1 if text and not text.endswith('\n') else 0)
        except Exception:
            pass
    return result


@app.get("/search")
async def search_files(q: str, path: str = ""):
    target = safe_path(path)
    if not target.exists() or not target.is_dir():
        raise HTTPException(404, "Directory not found")

    results = []
    q_lower = q.lower()
    try:
        for item in target.rglob("*"):
            if q_lower in item.name.lower():
                try:
                    stat = item.stat()
                    results.append({
                        "name": item.name,
                        "path": str(item),
                        "is_dir": item.is_dir(),
                        "size": stat.st_size if not item.is_dir() else -1,
                        "modified": stat.st_mtime,
                        "ext": item.suffix.lower() if not item.is_dir() else "",
                        "parent": str(item.parent),
                    })
                    if len(results) >= 500:
                        break
                except (PermissionError, OSError):
                    continue
    except (PermissionError, OSError) as e:
        raise HTTPException(403, str(e))

    return {"results": results, "query": q, "path": str(target), "total": len(results)}


@app.post("/mkdir")
async def make_dir(req: PathItem):
    target = safe_path(req.path)
    try:
        target.mkdir(parents=True, exist_ok=False)
        return {"success": True, "path": str(target)}
    except FileExistsError:
        raise HTTPException(409, "Already exists")
    except Exception as e:
        raise HTTPException(500, str(e))


@app.post("/rename")
async def rename_file(req: PathPair):
    src = safe_path(req.src)
    dst = safe_path(req.dst)
    if not src.exists():
        raise HTTPException(404, "Source not found")
    try:
        src.rename(dst)
        return {"success": True, "dst": str(dst)}
    except Exception as e:
        raise HTTPException(500, str(e))


if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000, reload=False)
