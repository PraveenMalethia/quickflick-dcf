FROM mongo:7.0

# Copy the replica set init script
COPY rs-init.sh /rs-init.sh
RUN chmod +x /rs-init.sh

ENTRYPOINT ["/rs-init.sh"]