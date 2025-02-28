# Khai báo provider cần thiết
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

# Cấu hình provider Docker
provider "docker" {
  host = "npipe:////./pipe/docker_engine"  # Kết nối đến Docker daemon trên Windows
}

# Tạo network cho container (tùy chọn)
resource "docker_network" "web_network" {
  name = "web_network"
}

# Pull image NGINX từ Docker Hub
resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = false
}

# Tạo container NGINX với trang web từ GitHub
resource "docker_container" "web_container" {
  name  = "web-container"
  image = docker_image.nginx.name
  
  # Cấu hình port mapping
  ports {
    internal = 80
    external = 2112  # Truy cập từ host qua port 8080
  }

  # Gắn container vào network
  networks_advanced {
    name = docker_network.web_network.name
  }

  # Dùng command để clone GitHub repo và sao chép nội dung
  command = [
    "/bin/bash",
    "-c",
    "apt-get update && apt-get install -y git && rm -rf /usr/share/nginx/html/* && git clone https://github.com/[YOUR_USERNAME]/[YOUR_REPO].git /tmp/repo && cp -r /tmp/repo/* /usr/share/nginx/html/ && nginx -g 'daemon off;'"
  ]
}

# Output thông tin container
output "container_info" {
  value = {
    name = docker_container.web_container.name
    ip   = docker_container.web_container.network_data[0].ip_address
    port = docker_container.web_container.ports[0].external
  }
}