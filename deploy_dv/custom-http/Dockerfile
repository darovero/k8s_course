# Usa la imagen oficial de NGINX como base
FROM nginx:alpine

# Copia los archivos de las páginas estáticas al directorio de NGINX
COPY 404.html /usr/share/nginx/html/
COPY 503.html /usr/share/nginx/html/

# Establece los permisos adecuados para los archivos
RUN chown -R nginx:nginx /usr/share/nginx/html/404.html /usr/share/nginx/html/503.html \
    && chmod 644 /usr/share/nginx/html/404.html /usr/share/nginx/html/503.html

# Copia el archivo de configuración personalizado
COPY nginx.conf /etc/nginx/

# Exponer el puerto 80
EXPOSE 80