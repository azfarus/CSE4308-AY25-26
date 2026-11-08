import http.server
import socketserver
import os
import socket
import sys
import re
import io
import urllib.parse
from pathlib import Path

# Configuration
START_PORT = 8000
ADMIN_PATH = "/admin"
SHARED_FOLDER_NAME = "shared_files"

def get_local_ip():
    """Finds the local IP address of this computer on the LAN."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        IP = s.getsockname()[0]
    except Exception:
        IP = '127.0.0.1'
    finally:
        s.close()
    return IP

class DualInterfaceHandler(http.server.SimpleHTTPRequestHandler):
    
    def do_GET(self):
        """
        Handle GET requests.
        ROUTING LOGIC ONLY. Headers must be sent in the specific functions.
        """
        if self.path == '/':
            self.send_custom_directory_listing(admin_mode=False)
        elif self.path == ADMIN_PATH:
            self.send_custom_directory_listing(admin_mode=True)
        else:
            # Standard handler for downloading actual files
            super().do_GET()

    def do_POST(self):
        """Handle file uploads (Only allowed on ADMIN_PATH)."""
        if self.path != ADMIN_PATH:
            self.send_error(403, "Forbidden: Uploads only allowed via Admin URL")
            return

        r, info = self.deal_post_data()
        
        f = io.BytesIO()
        if r:
            f.write(b'<!DOCTYPE html><html><head><meta http-equiv="refresh" content="2;url=' + ADMIN_PATH.encode() + b'"></head><body><h3>Upload Success!</h3><p>Redirecting...</p></body></html>')
        else:
            f.write(b'<!DOCTYPE html><html><body><h3>Upload Failed</h3><p>' + info.encode() + b'</p></body></html>')
        f.seek(0)
        
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()
        self.copyfile(f, self.wfile)

    def send_custom_directory_listing(self, admin_mode=False):
        """Generates the HTML for the directory listing."""
        try:
            path = os.getcwd() 
            list_dir = os.listdir(path)
        except OSError:
            self.send_error(404, "No permission to list directory")
            return
            
        list_dir.sort(key=lambda a: a.lower())
        
        displaypath = "Shared Files"
        enc = sys.getfilesystemencoding()
        
        style = """
            body { font-family: sans-serif; padding: 20px; background: #f4f4f9; color: #333; }
            .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
            h1 { color: #2c3e50; border-bottom: 2px solid #eee; padding-bottom: 10px; }
            .upload-box { background: #e8f0fe; border: 2px dashed #4285f4; padding: 20px; text-align: center; margin-bottom: 20px; border-radius: 5px; }
            ul { list-style: none; padding: 0; }
            li { border-bottom: 1px solid #eee; padding: 8px 0; display: flex; align-items: center; }
            a { text-decoration: none; color: #007bff; font-weight: bold; margin-left: 10px; flex-grow: 1;}
            a:hover { text-decoration: underline; }
            .badge { background: #28a745; color: white; padding: 2px 6px; font-size: 0.8em; border-radius: 4px; margin-left: 10px;}
            .mode-label { float: right; font-size: 0.8em; color: #666; }
            .empty-msg { text-align:center; color: #999; margin-top: 20px; font-style: italic; }
        """

        html = [f'<!DOCTYPE html><html><head><title>{displaypath}</title>']
        html.append(f'<meta name="viewport" content="width=device-width, initial-scale=1"><style>{style}</style></head><body>')
        html.append('<div class="container">')
        
        mode_text = "🔒 ADMIN MODE" if admin_mode else "👁️ READ ONLY"
        html.append(f'<span class="mode-label">{mode_text}</span>')
        html.append(f'<h1>📂 {displaypath}</h1>')

        if admin_mode:
            html.append('''
            <div class="upload-box">
                <h3>🚀 Upload File</h3>
                <form ENCTYPE="multipart/form-data" method="post">
                    <input name="file" type="file" multiple/>
                    <input type="submit" value="Upload" style="background:#4285f4; color:white; border:none; padding:8px 16px; border-radius:4px; cursor:pointer;"/>
                </form>
            </div>
            ''')
        else:
            html.append('<p style="color:#666; font-style:italic;">You are in Guest mode. You can download files below.</p>')

        html.append('<ul>')
        files_to_show = [name for name in list_dir if not name.startswith('.')]
        
        if not files_to_show:
             html.append('<div class="empty-msg">No files shared yet.</div>')

        for name in files_to_show:
            fullname = os.path.join(path, name)
            displayname = linkname = name
            
            if os.path.isdir(fullname):
                icon = "📁"
            else:
                icon = "📄"
            
            linkname = urllib.parse.quote(linkname)
            html.append(f'<li>{icon} <a href="{linkname}">{displayname}</a></li>')

        html.append('</ul></div></body></html>')
        
        encoded = "".join(html).encode(enc, 'surrogateescape')
        
        # --- FIXED HTTP ORDER HERE ---
        self.send_response(200) # 1. Send Status Code FIRST
        self.send_header("Content-type", "text/html; charset=%s" % enc) # 2. Send Headers
        self.send_header("Content-Length", str(len(encoded)))
        # Disable caching
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        self.end_headers() # 3. End Headers
        
        self.wfile.write(encoded) # 4. Write Body

    def deal_post_data(self):
        content_type = self.headers['content-type']
        if not content_type:
            return (False, "Content-Type header doesn't contain boundary")
        
        boundary = content_type.split("=")[1].encode()
        remainbytes = int(self.headers['content-length'])
        line = self.rfile.readline()
        remainbytes -= len(line)
        
        if boundary not in line:
            return (False, "Content NOT begin with boundary")
            
        line = self.rfile.readline()
        remainbytes -= len(line)
        fn = re.findall(r'Content-Disposition.*name="file"; filename="(.*)"', line.decode())
        
        if not fn:
            return (False, "Can't find out file name...")
            
        path = os.getcwd() 
        fn = os.path.join(path, fn[0])
        
        line = self.rfile.readline()
        remainbytes -= len(line)
        line = self.rfile.readline()
        remainbytes -= len(line)
        
        try:
            out = open(fn, 'wb')
        except IOError:
            return (False, "Can't create file to write. Permission denied.")
            
        preline = self.rfile.readline()
        remainbytes -= len(preline)
        
        while remainbytes > 0:
            line = self.rfile.readline()
            remainbytes -= len(line)
            if boundary in line:
                preline = preline[0:-1]
                if preline.endswith(b'\r'):
                    preline = preline[0:-1]
                out.write(preline)
                out.close()
                return (True, "File '%s' upload success!" % fn)
            else:
                out.write(preline)
                preline = line
        return (False, "Unexpected End of data.")

def setup_environment():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    shared_dir_path = os.path.join(script_dir, SHARED_FOLDER_NAME)
    if not os.path.exists(shared_dir_path):
        os.makedirs(shared_dir_path)
        print(f"[*] Created new folder: {shared_dir_path}")
    else:
        print(f"[*] Using existing folder: {shared_dir_path}")
    os.chdir(shared_dir_path)

if __name__ == '__main__':
    setup_environment()
    local_ip = get_local_ip()
    
    # --- AUTO PORT FINDER LOGIC ---
    socketserver.TCPServer.allow_reuse_address = True
    httpd = None
    current_port = START_PORT
    
    # Try up to 100 ports if 8000 is busy
    for i in range(100):
        try:
            httpd = socketserver.ThreadingTCPServer(("", current_port), DualInterfaceHandler)
            break 
        except OSError:
            print(f"[!] Port {current_port} is busy. Trying {current_port + 1}...")
            current_port += 1
    
    if httpd is None:
        print("[-] Could not find an open port after 100 tries.")
        sys.exit(1)

    print("=" * 60)
    print(f" SERVER STARTED ON PORT: {current_port}")
    print("-" * 60)
    print(f" [1] ADMIN LINK (Upload here):")
    print(f"     http://{local_ip}:{current_port}{ADMIN_PATH}")
    print("-" * 60)
    print(f" [2] GUEST LINK (Share this):")
    print(f"     http://{local_ip}:{current_port}/")
    print("=" * 60)
    print(" Press Ctrl+C to stop.")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
        httpd.shutdown()
        httpd.server_close()
