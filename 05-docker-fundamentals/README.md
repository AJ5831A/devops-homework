# Docker Fundamentals — Hello World Applications

Six "Hello World" web apps, each in its own folder with its own `Dockerfile`.

**Executed on 2026-10-07 using Docker in the Ubuntu Colima lab VM.**
All six images built and returned their Hello World pages. Browser screenshots
below show the running applications; the [full transcript](../evidence/docker/runtime.log)
records the actual build/run/curl commands. The evidence script uses distinct
host ports 18030, 18050, 18080–18083 so the apps run together.

![Node.js](../evidence/docker/nodejs-app.png)
![Python](../evidence/docker/python-app.png)
![Java](../evidence/docker/java-app.png)
![Apache](../evidence/docker/Apache-app.png)
![React](../evidence/docker/React-app.png)
![Nginx](../evidence/docker/nginx-app.png)

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
