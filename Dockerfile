FROM ruby:3.2.0-slim as base

WORKDIR /mnt

RUN adduser --system app &&\
  bundle config --local path vendor/bundle &&\
  bundle config set --local deployment 'true' &&\
  bundle config set --local without 'development test'

RUN apt-get update &&\
  apt-get install -qy --no-install-recommends git


FROM base as builder

RUN apt-get update &&\
  apt-get install -qy --no-install-recommends build-essential

COPY . .
RUN bundle install

FROM base

COPY --from=builder /mnt/ .

USER app

CMD ["bundle", "exec", "./exe/kubezilla", "127.0.0.1:8001", "http"]
