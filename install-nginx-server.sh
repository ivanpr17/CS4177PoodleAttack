#!/bin/bash

# A nginx server installation and configuration script.
# created by RootDev4 (c) 09/2020
# modified by Ivan Perez
# 

echo "[>] Installing a nginx server 'bank.com' that is vulnerable to the POODLE attack"
apt-get install nginx php5-fpm -y > /dev/null

echo "[>] Generating SSL certificate"
mkdir /etc/nginx/ssl
cd /etc/nginx/ssl
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -subj "/C=/ST=/L=/O=/CN=secretserver.com" -keyout server.key -out server.crt > /dev/null 2>&1

echo "[>] Adding HTTPS support to nginx configuration"
cat <<EOF >> /etc/nginx/sites-enabled/default
# HTTPS server
server {
    listen 443;
    server_name secretserver.com;
    root /usr/share/nginx/www;
    index index.php;

    ssl on;
    ssl_certificate /etc/nginx/ssl/server.crt;
    ssl_certificate_key /etc/nginx/ssl/server.key;
    ssl_session_timeout 5m;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers DES-CBC3-SHA;
    ssl_prefer_server_ciphers on;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass 127.0.0.1:9000;
        #fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
    }

    location / {
        try_files \$uri \$uri/ /index.php;
        add_header 'Access-Control-Allow-Origin' '*';
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
        add_header 'Access-Control-Allow-Credentials' 'true';
    }
}
EOF

echo "[>] Creating a simple login script to demonstrate the POODLE attack"
touch /usr/share/nginx/www/index.php
cat <<EOF >> /usr/share/nginx/www/index.php
<?php
/*
* A simple login script to demonstrate the POODLE attack.
* @author: RootDev4 (c) 09/2020
* @url: https://github.com/RootDev4/poodle-PoC
*/
header("Access-Control-Allow-Origin: http://".\$_SERVER["REMOTE_ADDR"]);
header("Access-Control-Allow-Credentials: true");
header("Access-Control-Allow-Methods: GET, POST");
header("Access-Control-Allow-Headers: Content-Type");

session_start();

// Default user credentials
define("USERNAME", "admin");
define("PASSWORD", "adminmypasswd");

// User login
if (isset(\$_POST["login"])) {
    \$username = @\$_POST["username"];
    \$password = @\$_POST["password"];

    if (\$username == USERNAME && \$password == PASSWORD) {
        \$_SESSION["user"] = USERNAME;
        header("Location: .");
    } else {
        echo "<script>alert('Login failed!');</script>";
    }
}

// User logout
if (isset(\$_GET["logout"]) && isset(\$_SESSION["user"])) {
    session_destroy();
    header("Location: .");
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>bank.com</title>
    <style type="text/css">
        body {
            padding: 5% 0 0 10%;
            font-size: larger;
        }
        input, button {
            display: block;
            padding: 5px;
            margin-bottom: 10px;
            outline: none;
        }
    </style>
</head>
<body>
    <?php if (!isset(\$_SESSION['user'])) { ?>
        <form action="" method="POST">
            <h3>Sign in</h3>
            <input type="text" name="username" placeholder="Your username" required>
            <input type="password" name="password" placeholder="Your password" required>
            <button type="submit" name="login">Sign in</button>
        </form>
    <?php } else { echo "<h3>Hello ".\$_SESSION['user']."</h3><a href=\"?logout\">&raquo; Sign out</a>"; } ?>
</body>
</html>
EOF

echo "[>] Restarting nginx server"
service nginx restart > /dev/null
echo "[>] Installation finished. Open server's website and sign in with admin:adminmypassword (default)"
