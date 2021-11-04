FROM registry.access.redhat.com/ubi8/php-74
  
USER root

ADD httpd.conf /etc/httpd/conf/httpd.conf
ADD config.ini /opt/app-root/src
ADD https://github.com/klaussilveira/gitlist/releases/download/1.0.2/gitlist-1.0.2.tar.gz .
RUN tar -xf ./gitlist-1.0.2.tar.gz --strip-components 1; rm ./gitlist-1.0.2.tar.gz;
RUN mkdir /opt/app-root/src/cache; chmod -R 777 /opt/app-root/src;

CMD httpd -D FOREGROUND
