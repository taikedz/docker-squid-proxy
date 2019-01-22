FROM ubuntu:16.04
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install squid -y
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh
#EXPOSE 3128/tcp
ENTRYPOINT ["/sbin/entrypoint.sh"]
