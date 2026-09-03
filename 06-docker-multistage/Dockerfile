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
