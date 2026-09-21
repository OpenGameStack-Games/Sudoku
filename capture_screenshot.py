import socket
import json
import base64

def send_command(command_dict):
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.connect(('127.0.0.1', 9090))
        payload = json.dumps(command_dict) + "\n"
        s.sendall(payload.encode('utf-8'))
        
        # Read the response
        response = b""
        while True:
            chunk = s.recv(4096)
            if not chunk:
                break
            response += chunk
            if b"\n" in chunk:
                break
                
        s.close()
        return json.loads(response.decode('utf-8').strip())
    except Exception as e:
        return {"error": str(e)}

res = send_command({"command": "screenshot"})
if "data" in res and "screenshot" in res["data"]:
    img_data = base64.b64decode(res["data"]["screenshot"])
    with open("screenshot.png", "wb") as f:
        f.write(img_data)
    print("Screenshot saved to screenshot.png")
else:
    print("Failed to get screenshot:", res)
