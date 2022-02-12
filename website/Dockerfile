FROM nginx:mainline-alpine
COPY index.html /usr/share/nginx/html
COPY 404.html /usr/share/nginx/html
COPY content /usr/share/nginx/html/content
COPY css /usr/share/nginx/html/css
COPY default.template /etc/nginx/conf.d/
CMD ["/bin/sh", "-c", "envsubst < /etc/nginx/conf.d/default.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]