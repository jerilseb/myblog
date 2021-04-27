FROM klakegg/hugo:0.82.0-ubuntu

WORKDIR /app

EXPOSE 1313

CMD ["server", "."]
