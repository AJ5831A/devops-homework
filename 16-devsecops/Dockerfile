FROM python:3.12-alpine
# Apply distribution security updates without shipping unused Debian utilities.
RUN apk upgrade --no-cache
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY --chown=10001:10001 app/ ./app/
USER 10001:10001
EXPOSE 8080
CMD ["python", "-m", "app.calculator"]
