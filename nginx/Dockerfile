#TODO Finish

FROM cirrusci/flutter:latest AS builder

WORKDIR /app

COPY . .

RUN flutter build web

FROM nginx:alpine

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]