# Lab local con Terraform: **Ollama + OpenWebUI**

Este repo levanta un pequeño **laboratorio local** para probar LLMs usando:
- **Ollama** (servidor de modelos en `:11434`)
- **OpenWebUI** (interfaz web en `:3000`) conectada a Ollama

Tu configuración usa el **provider Docker** de Terraform y crea red, volúmenes y contenedores con persistencia.

---

## ✅ Qué vas a obtener
- Un contenedor `ollama_tf` corriendo `ollama/ollama:latest`
- Un contenedor `openwebui_tf` corriendo `ghcr.io/open-webui/open-webui:main`
- Red Docker `local_ai_stack_net` para que OpenWebUI hable con Ollama por el hostname `ollama`
- Volúmenes Docker para **persistir** modelos y datos de la UI

---

## 🧰 Requisitos
- Docker Engine 20.10+ (Linux/macOS/Windows + WSL2)
- Terraform 1.5+
- (Opcional GPU NVIDIA) Driver + NVIDIA Container Toolkit

> **Nota:** Este stack está pensado para uso **local**. No expongas puertos a internet sin un proxy/autenticación delante.

---

## 🔌 Puertos
- Ollama API: `11434` (host) → `11434` (container)
- OpenWebUI: `3000` (host) → `8080` (container)

Puedes cambiarlos vía variables (`ollama_port`, `openwebui_port`).

---

## 🗂️ Estructura mínima del repo
```
.
├── main.tf  # Terraform + Docker
└── README.md
```

---

## ⚙️ Variables útiles
En `main.tf`:
```hcl
variable "ollama_port"   { default = 11434 }
variable "openwebui_port"{ default = 3000 }
```
> Esta infra **no descarga** el modelo por sí sola; abajo tienes formas de hacerlo.

---

## 🚀 Puesta en marcha
```bash
terraform init
terraform fmt         # opcional, pero recomendado
terraform validate    # opcional
terraform apply -auto-approve
```

- Abre OpenWebUI: http://localhost:3000  
- Ollama API (check): http://localhost:11434/api/version

---

## ⬇️ Descarga de modelos (elige 1 método)

### 1) Desde OpenWebUI (sencillo)
1. Entra a http://localhost:3000
2. Ajustes → *Models* → “Add model”
3. Escribe el nombre (ej. `gemma3:latest`) y confirma

### 2) Con CLI dentro del contenedor
```bash
docker exec -it ollama_tf ollama pull gemma3:latest
```
> Cambia el nombre de modelo si usas otro.

### 3) Vía API de Ollama
```bash
curl -X POST http://localhost:11434/api/pull \
  -H "Content-Type: application/json" \
  -d '{"name":"gemma3:latest"}'
```

---

En OpenWebUI, simplemente selecciona el modelo y chatea.

---

## 💾 Persistencia 
- Modelos: volumen `ollama_models` montado en `/root/.ollama`
- Datos UI: volumen `openwebui_data` en `/app/backend/data`


---

## ⚡ (Opcional) GPU NVIDIA
1) Instala **NVIDIA Container Toolkit** en el host  
2) Añade al recurso `docker_container "ollama"` en `main.tf`:
```hcl
# dentro de docker_container.ollama
device_requests {
  count        = 1
  capabilities = [["gpu"]]
}
```
3) `terraform apply` de nuevo

> Muchos modelos (y contextos largos) van mejor con GPU. Asegúrate de que el host ve la GPU con `nvidia-smi` y que Docker puede usarla.


---

## 🛠️ Troubleshooting
- **`Invalid multi-line string`**: suele ser una comilla sin cerrar en `env = ["..."]` o un bloque mal escrito.
- **Bloque de red mal nombrado**: es `networks_advanced { ... }` (no `network_advanced`).
- **Tag de OpenWebUI**: si `:main` no existe en tu host, cambia a `ghcr.io/open-webui/open-webui:latest`.
- **Puertos ocupados**: cambia `openwebui_port` u `ollama_port`.
- **Logs**: `docker logs -f ollama_tf` y `docker logs -f openwebui_tf`.
- **Conectividad**: desde `openwebui_tf`, prueba `curl http://ollama:11434/api/version`.

---

## 🔐 Seguridad (importante)
- No expongas `11434`/`3000` fuera de tu máquina sin protección.
- Si publicas, pon un **reverse proxy** (Caddy/Nginx/Traefik) al frente de OpenWebUI.
- Mantén las imágenes actualizadas (`terraform apply` volverá a tirar las últimas).

---

## 🧹 Tear-down
```bash
terraform destroy
# (opcional) borrar volúmenes si quieres empezar de cero:
docker volume rm ollama_models openwebui_data
```

