# CDN Setup with Varnish and Nginx

This repository provides a bash script to automate setting up a CDN using Varnish and Nginx on your server. The script will help you configure Varnish to cache static files such as images, and Nginx to serve as a reverse proxy for your domain.

## Requirements

- A Linux-based server with root access
- Varnish and Nginx installed on the server
- A valid domain and a subdomain (e.g., domain.com and cdn.domain.com)
- DNS records for the domain and subdomain, pointing to the server's IP address

## Usage

1. Clone this repository to your server:

```https://github.com/ersinkoc/cdn-setup-varnish-nginx.git```

2. Change the directory to the cloned repository:

```cd cdn-setup-varnish-nginx```

3. Make the script executable:

```chmod +x setup-cdn.sh```

4. Run the script:

```sudo ./setup-cdn.sh```

5. Follow the prompts to enter your domain, subdomain, and other necessary information.

6. The script will guide you through the process of setting up Varnish and Nginx, creating the necessary configuration files, and obtaining a Let's Encrypt SSL certificate for your CDN subdomain.

7. Once the script completes, your CDN will be ready to use!

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update the tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
