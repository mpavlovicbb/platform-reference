FROM python:3.13-slim
RUN pip install --no-cache-dir prometheus_client==0.21.1
COPY app.py /app/app.py
USER 65534
EXPOSE 8000
CMD ["python", "/app/app.py"]
