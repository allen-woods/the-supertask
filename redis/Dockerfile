FROM redis:alpine
COPY ./redis_entrypoint.sh /redis_entrypoint.sh
RUN chmod +x /redis_entrypoint.sh
ENTRYPOINT ["/redis_entrypoint.sh"]