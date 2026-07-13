FROM httpd:2.4

RUN sed -i \
      -e 's/^#LoadModule ssl_module/LoadModule ssl_module/' \
      -e 's/^#LoadModule socache_shmcb_module/LoadModule socache_shmcb_module/' \
      -e 's/^#LoadModule authn_file_module/LoadModule authn_file_module/' \
      -e 's/^#LoadModule auth_basic_module/LoadModule auth_basic_module/' \
      -e 's|^#Include conf/extra/httpd-ssl.conf|Include conf/extra/httpd-ssl.conf|' \
      conf/httpd.conf

COPY index.html /usr/local/apache2/htdocs/index.html
COPY style.css /usr/local/apache2/htdocs/style.css
COPY httpd-ssl.conf /usr/local/apache2/conf/extra/httpd-ssl.conf

EXPOSE 443