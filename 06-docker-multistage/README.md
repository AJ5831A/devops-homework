# Docker Multi-Stage Build

## Task 1: Multi-Stage Dockerfile

A two-stage build: stage 1 (`golang:1.22-alpine`) compiles a small Go HTTP
server; stage 2 (`alpine:latest`) copies in just the compiled binary, so the
final image ships without the Go toolchain.

**`app.go`**

```go
package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintln(w, "Hello World from Docker multi-stage build")
	})
	log.Println("listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```

**`Dockerfile`**

```dockerfile
# --- Stage 1: build ---
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY app.go .
RUN go build -o /out/app app.go

# --- Stage 2: run (small final image, no Go toolchain) ---
FROM alpine:latest
COPY --from=builder /out/app /app
EXPOSE 8080
CMD ["/app"]
```

**Build and run:**

```bash
docker build -t multistage-hello .
docker run -d -p 8080:8080 --name multistage-demo multistage-hello

curl http://localhost:8080
# Hello World from Docker multi-stage build

docker ps
# CONTAINER ID   IMAGE              COMMAND   ...   PORTS                    NAMES
# <id>           multistage-hello   "/app"    ...   0.0.0.0:8080->8080/tcp   multistage-demo
```

> **Note:** Docker isn't installed on the machine this was authored on, so
> this hasn't been built/run here yet — needs to be run on a Docker-capable
> machine to capture the real `curl`/`docker ps` output and screenshots below
> before final submission.

## Task 2: Documentation

- **Name:** Aryan Jakhar
- **Enrollment number:** 24BCS10305
- **Screenshot/output — app running successfully:** _\<add after running `curl http://localhost:8080` or opening it in a browser\>_
- **Screenshot/output — `docker ps` showing the container on port 8080:** _\<add after running `docker ps`\>_

## Task 3: Deploy 3 Different Application Types

Reuse the Node.js, Python, and Java apps from
[`../05-docker-fundamentals`](../05-docker-fundamentals) — build and run all
three simultaneously to demonstrate multiple app types running as separate
Docker containers:

```bash
cd ../05-docker-fundamentals
docker build -t nodejs-hello nodejs-app/ && docker run -d -p 3000:3000 --name node-demo nodejs-hello
docker build -t python-hello python-app/ && docker run -d -p 5000:5000 --name python-demo python-hello
docker build -t java-hello   java-app/   && docker run -d -p 8000:8000 --name java-demo   java-hello

docker ps
```
