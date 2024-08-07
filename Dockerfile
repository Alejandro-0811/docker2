# Usa una imagen base oficial de Python
FROM python:3.12-slim

# Instala las herramientas de compilación necesarias
RUN apt-get update && apt-get install -y \
    gcc \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Crea un directorio para la aplicación
WORKDIR /app

# Copia los archivos de la aplicación al contenedor
COPY . .

# Instala las dependencias de la aplicación
RUN pip install --no-cache-dir -r requirements.txt

# Expone el puerto que la aplicación usará
EXPOSE 5000

# Comando para ejecutar la aplicación
CMD ["python", "app.py"]
