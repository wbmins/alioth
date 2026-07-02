#!/usr/bin/env python3
import os
import datetime
from pathlib import Path

def format_size(size):
    """格式化文件大小"""
    for unit in ['B', 'KiB', 'MiB', 'GiB']:
        if size < 1024.0:
            return f"{size:.1f} {unit}"
        size /= 1024.0
    return f"{size:.1f} GiB"

def get_file_icon(filename):
    """根据文件类型返回对应的图标"""
    if filename.endswith('.apk'):
        return '📦'
    elif filename == 'APKINDEX.tar.gz':
        return '📄'
    elif filename.endswith('.pub'):
        return '🔑'
    else:
        return '📎'

def generate_index():
    # 设置目标目录
    target_dir = Path('./edge/aarch64')
    
    # 检查目录是否存在
    if not target_dir.exists():
        print(f"警告: 目录 {target_dir} 不存在，创建空目录...")
        target_dir.mkdir(parents=True, exist_ok=True)
        print(f"已创建目录: {target_dir}")
    
    # 获取目标目录下所有文件
    files = []
    for file in target_dir.iterdir():
        if file.is_file() and file.name != 'index.html':  # 排除 index.html 自身
            name = file.name
            # 只显示 .apk, APKINDEX.tar.gz, .pub 文件
            if name.endswith('.apk') or name == 'APKINDEX.tar.gz' or name.endswith('.pub'):
                stat = file.stat()
                files.append({
                    'name': name,
                    'size': stat.st_size,
                    'mtime': datetime.datetime.fromtimestamp(stat.st_mtime)
                })
    
    # 按文件名排序
    files.sort(key=lambda x: x['name'].lower())
    
    # 获取当前时间
    current_time = datetime.datetime.now()
    
    # 固定的下载链接前缀
    base_url = "https://wbmins.github.io/alioth"
    
    # 生成HTML
    html = f'''<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Index of /edge/aarch64/</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            max-width: 1200px;
            margin: 20px auto;
            padding: 0 20px;
            background: #f5f5f5;
            font-size: 18px;
        }}
        .container {{
            padding: 30px 0;
        }}
        h1 {{
            color: #333;
            border-bottom: 2px solid #eaecef;
            padding-bottom: 15px;
            margin-top: 0;
            font-size: 32px;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            font-size: 18px;
        }}
        th {{
            text-align: left;
            padding: 12px 10px;
            border-bottom: 2px solid #eaecef;
            color: #666;
            font-weight: 600;
            font-size: 18px;
        }}
        td {{
            padding: 10px 10px;
            border-bottom: 1px solid #eaecef;
            font-size: 18px;
        }}
        tr:hover {{
            background-color: #f8f9fa;
        }}
        .filename {{
            color: #0366d6;
            text-decoration: none;
            word-break: break-all;
            font-size: 18px;
        }}
        .filename:hover {{
            text-decoration: underline;
        }}
        .file-icon {{
            margin-right: 8px;
        }}
        .size {{
            color: #666;
            font-family: monospace;
            white-space: nowrap;
            font-size: 17px;
        }}
        .date {{
            color: #666;
            font-family: monospace;
            white-space: nowrap;
            font-size: 17px;
        }}
        .footer {{
            margin-top: 25px;
            color: #666;
            font-size: 16px;
            border-top: 1px solid #eaecef;
            padding-top: 15px;
            text-align: center;
        }}
        .empty {{
            text-align: center;
            color: #999;
            padding: 40px 0;
            font-size: 20px;
        }}
        @media (max-width: 600px) {{
            .hide-mobile {{
                display: none;
            }}
            td, th {{
                padding: 8px 6px;
                font-size: 16px;
            }}
            .container {{
                padding: 15px 0;
            }}
            h1 {{
                font-size: 24px;
            }}
            .filename, .size, .date {{
                font-size: 16px;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <h1>Index of /edge/aarch64/</h1>
        <table>
            <thead>
                <tr>
                    <th>File Name</th>
                    <th class="hide-mobile">File Size</th>
                    <th class="hide-mobile">Date</th>
                </tr>
            </thead>
            <tbody>
'''
    
    if not files:
        html += '''
                <tr>
                    <td colspan="3" class="empty">No files found in edge/aarch64 directory</td>
                </tr>
'''
    else:
        for file in files:
            size_display = format_size(file['size'])
            date_display = file['mtime'].strftime('%Y-%m-%d %H:%M')
            # 构建完整的下载链接: 前缀 + 文件夹 + 文件名
            download_url = f"{base_url}/edge/aarch64/{file['name']}"
            # 获取文件图标
            icon = get_file_icon(file['name'])
            html += f'''
                <tr>
                    <td><a href="{download_url}" class="filename"><span class="file-icon">{icon}</span>{file['name']}</a></td>
                    <td class="size hide-mobile">{size_display}</td>
                    <td class="date hide-mobile">{date_display}</td>
                </tr>
'''
    
    html += f'''
            </tbody>
        </table>
        <div class="footer">
            Generated by GitHub Actions • {current_time.strftime('%Y-%m-%d %H:%M:%S')}
        </div>
    </div>
</body>
</html>
'''
    
    # 在当前目录生成 index.html
    index_path = Path('./index.html')
    with open(index_path, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"✅ Generated index.html in current directory with {len(files)} files from {target_dir}")
    print(f"🔗 Download URL prefix: {base_url}/edge/aarch64/")
    if files:
        print(f"📋 Files: {', '.join([f['name'] for f in files[:5]])}" + 
              (f" and {len(files)-5} more..." if len(files) > 5 else ""))

if __name__ == '__main__':
    generate_index()