#TODO finish

FROM rust:1.70 as builder
WORKDIR /usr/src/app
COPY Cargo.toml Cargo.lock ./

COPY . .

RUN cargo build --release

FROM debian:buster-slim
WORKDIR /app

COPY --from=builder /usr/src/app/target/release/my-actix-app .

EXPOSE 8080

CMD ["./my-actix-app"]