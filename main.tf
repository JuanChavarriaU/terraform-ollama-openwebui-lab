terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

provider "docker" {}


variable "ollama_port" {
  type    = number
  default = 11434
}

variable "openwebui_port" {
  type    = number
  default = 3000
}


# Network and Volumes
resource "docker_network" "local_ai_stack" {
  name = "ai_stack_net"
}

resource "docker_volume" "ollama_models" {
  name = "ollama_models"
}

resource "docker_volume" "openwebui_data" {
  name = "openwebui_data"
}



#Images
resource "docker_image" "ollama" {
  name         = "ollama/ollama:latest"
  keep_locally = false
}

resource "docker_image" "openwebui" {
  name         = "ghcr.io/open-webui/open-webui:main"
  keep_locally = false
}

#Containers

resource "docker_container" "ollama" {
  name    = "ollama_tf"
  image   = docker_image.ollama.image_id
  restart = "unless-stopped"


  ports {
    internal = 11434
    external = var.ollama_port
  }

  #persist models
  volumes {
    volume_name    = docker_volume.ollama_models.name
    container_path = "/root/.ollama"
  }


  env = ["OLLAMA_HOST=0.0.0.0:${var.ollama_port}"]


  networks_advanced {
    name    = docker_network.local_ai_stack.name
    aliases = ["ollama"]

  }

}


resource "docker_container" "openwebui" {
  name    = "openwebui_tf"
  image   = docker_image.openwebui.image_id
  restart = "unless-stopped"

  depends_on = [
    docker_container.ollama
  ]

  ports {
    internal = 8080
    external = var.openwebui_port
  }


  env = ["OLLAMA_BASE_URL=http://ollama:${var.ollama_port}"]

  volumes {
    volume_name    = docker_volume.openwebui_data.name
    container_path = "/app/backend/data"
  }

  networks_advanced {
    name = docker_network.local_ai_stack.name
  }

}

