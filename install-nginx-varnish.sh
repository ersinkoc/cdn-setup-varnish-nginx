#!/bin/bash

# Update package list
sudo apt-get update

# Check if Varnish is installed
if ! command -v varnishd &> /dev/null; then
  echo "Varnish is not installed. Installing Varnish..."
  sudo apt-get install -y varnish
else
  echo "Varnish is already installed."
fi

# Check if Nginx is installed
if ! command -v nginx &> /dev/null; then
  echo "Nginx is not installed. Installing Nginx..."
  sudo apt-get install -y nginx
else
  echo "Nginx is already installed."
fi

# Check the status of Varnish and Nginx
echo "Checking the status of Varnish and Nginx..."
sudo systemctl status varnish
sudo systemctl status nginx
