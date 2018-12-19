FROM nginx
MAINTAINER Noel del Castillo

RUN rm /etc/nginx/conf.d/default.conf
COPY ./scripts/k8/frontend.conf /etc/nginx/conf.d
