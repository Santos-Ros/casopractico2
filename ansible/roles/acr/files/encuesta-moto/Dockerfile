FROM python:3.11-slim

WORKDIR /app
COPY app.py requirements.txt ./

RUN pip install --no-cache-dir -r requirements.txt
RUN echo "Contenido de /app:" && ls -l /app
EXPOSE 5000
CMD ["python", "app.py"]