FROM mongo:7.0

# Bake both scripts into the image so no host files are needed at deploy time
COPY entrypoint.sh /entrypoint.sh
COPY rs-init.sh /rs-init.sh
RUN chmod +x /entrypoint.sh /rs-init.sh

ENTRYPOINT ["/entrypoint.sh"]