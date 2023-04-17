#!/bin/bash

# Check if Varnish and Nginx are installed
if ! command -v varnishd &> /dev/null || ! command -v nginx &> /dev/null; then
  echo "Varnish and/or Nginx are not installed. Please install them first."
  exit 1
fi

# Get the domain and subdomain from the user
read -p "Enter your domain (e.g. domain.com): " domain
read -p "Enter your subdomain (e.g. cdn): " subdomain

cdn_subdomain="${subdomain}.${domain}"

# Check if the domain is valid
if ! (host "${domain}" > /dev/null 2>&1); then
  echo "Invalid domain or not reachable. Please make sure your domain is valid and reachable."
  exit 1
fi

# Check if the subdomain's IP address matches the server's IP address
subdomain_ip=$(dig +short "${cdn_subdomain}")
server_ip=$(curl -s ifconfig.me)

if [[ "${subdomain_ip}" != "${server_ip}" ]]; then
  echo "The subdomain's IP address does not match the server's IP address. Please update the DNS record for ${cdn_subdomain}."
  exit 1
fi

# Ask the user whether the source domain uses SSL
read -p "Does the source domain (${domain}) use SSL (HTTPS)? (yes/no): " use_ssl

if [[ "${use_ssl,,}" == "yes" ]]; then
  backend_port="443"
  backend_proto="https"
else
  backend_port="80"
  backend_proto="http"
fi

# Create a new Varnish config for the domain
cat > /etc/varnish/${domain}.vcl << EOF
vcl 4.0;

backend default {
    .host = "${domain}";
    .port = "${backend_port}";
    .ssl = ${backend_proto} == "https";
}

sub vcl_recv {
    if (req.url ~ "\.(jpg|jpeg|png|gif)$") {
        unset req.http.cookie;
    } else {
        return (pass);
    }
}

sub vcl_backend_response {
    if (bereq.url ~ "\.(jpg|jpeg|png|gif)$") {
        set beresp.ttl = 24h;
        set beresp.http.Cache-Control = "public, max-age=86400";
    }
}

sub vcl_deliver {
    unset resp.http.X-Varnish;
}
EOF

# Update the Varnish default.vcl to use the new config
echo "include \"/etc/varnish/${domain}.vcl\";" >> /etc/varnish/default.vcl

# Create a new Nginx config for the CDN subdomain
cat > /etc/nginx/sites-available/${cdn_subdomain} << EOF
server {
    listen 80;
    server_name ${cdn_subdomain};

    location / {
        proxy_pass ${backend_proto}://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable the new Nginx site
ln -s /etc/nginx/sites-available/${cdn_subdomain} /etc/nginx/sites-enabled/

# Restart Varnish and Nginx
systemctl restart varnish
systemctl restart nginx

# Set up a Let's Encrypt certificate
read -p "Press enter to continue once the DNS record is set up and propagated..."
certbot certonly --nginx -d ${cdn_subdomain} --agree-tos --no-eff-email --email <YOUR_EMAIL>

# Update the Nginx config for the CDN subdomain with the SSL settings
cat > /etc/nginx/sites-available/${cdn_subdomain} << EOF
server {
    listen 80;
    server_name ${cdn_subdomain};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${cdn_subdomain};
    ssl_certificate /etc/letsencrypt/live/${cdn_subdomain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${cdn_subdomain}/privkey.pem;

    location / {
        proxy_pass ${backend_proto}://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Reload Nginx to apply the new configuration
systemctl reload nginx

echo "CDN setup for ${cdn_subdomain} is complete."
