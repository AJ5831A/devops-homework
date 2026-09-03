# Docker Fundamentals — Hello World Applications

Six "Hello World" web apps, each in its own folder with its own `Dockerfile`.

> **Note:** Docker isn't installed on the machine these were authored on, so
> the images below were **not built or run here** — the code and Dockerfiles
> are written and ready, but need to actually be built/run (and the resulting
> "Hello World" webpage screenshotted) on a machine with Docker before final
> submission.

## nodejs-app

Plain Node.js `http` server (no dependencies).

```bash
cd nodejs-app
docker build -t nodejs-hello .
docker run -p 3000:3000 nodejs-hello
# visit http://localhost:3000
```

## python-app

Plain Python `http.server` (standard library only, no pip install needed).

```bash
cd python-app
docker build -t python-hello .
docker run -p 5000:5000 python-hello
# visit http://localhost:5000
```

## java-app

Plain Java using the built-in `com.sun.net.httpserver.HttpServer` (no build
tool / dependencies needed — compiled directly in the Dockerfile with `javac`).

```bash
cd java-app
docker build -t java-hello .
docker run -p 8000:8000 java-hello
# visit http://localhost:8000
```

## Apache-app

Static `index.html` served by the official `httpd` image.

```bash
cd Apache-app
docker build -t apache-hello .
docker run -p 8080:80 apache-hello
# visit http://localhost:8080
```

## React-app

Minimal React app (React + ReactDOM loaded from CDN, no build step) served
as a static file by `nginx`.

```bash
cd React-app
docker build -t react-hello .
docker run -p 8081:80 react-hello
# visit http://localhost:8081
```

## nginx-app

Static `index.html` served by the official `nginx` image.

```bash
cd nginx-app
docker build -t nginx-hello .
docker run -p 8082:80 nginx-hello
# visit http://localhost:8082
```

## Folder structure

```
05-docker-fundamentals/
├── nodejs-app/     (server.js, Dockerfile)
├── python-app/     (app.py, Dockerfile)
├── java-app/       (HelloWorld.java, Dockerfile)
├── Apache-app/     (index.html, Dockerfile)
├── React-app/      (index.html, Dockerfile)
└── nginx-app/      (index.html, Dockerfile)
```
