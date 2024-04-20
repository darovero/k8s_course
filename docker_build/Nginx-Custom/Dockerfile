# Usa la imagen oficial de Nginx como base
FROM nginx:latest

# Elimina el archivo HTML por defecto de Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia el contenido del directorio "solid" al directorio por defecto de Nginx
COPY ./solid /usr/share/nginx/html

# Exponer el puerto 80 para permitir conexiones externas
EXPOSE 80

# Comando para iniciar Nginx en primer plano
CMD ["nginx", "-g", "daemon off;"]