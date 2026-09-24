import socket
import json
import base64

def main():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect(('127.0.0.1', 9090))
    s.sendall(json.dumps({"command": "screenshot"}).encode('utf-8') + b'\n')
    
    data = b""
    while True:
        chunk = s.recv(4096)
        if not chunk:
            break
        data += chunk
        # Some JSON replies might end with newline, but to be safe we can check if it parses
        try:
            # wait until we have a complete json object
            response = json.loads(data.decode('utf-8'))
            break
        except json.JSONDecodeError:
            continue
            
    if "data" in response:
        with open("screenshot.png", "wb") as f:
            f.write(base64.b64decode(response["data"]))
        print("Screenshot saved to screenshot.png")
    else:
        print("No image data:", response)

if __name__ == "__main__":
    main()
