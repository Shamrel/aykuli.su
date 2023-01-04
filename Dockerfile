FROM ruby:3.1-alpine3.15

ARG RAILS_ROOT=/app
ARG PACKAGES="vim openssl-dev postgresql-dev build-base curl nodejs yarn less tzdata git postgresql-client bash screen gcompat"

RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache $PACKAGES

# RUN gem install bundler:2.3.11 

RUN mkdir $RAILS_ROOT
WORKDIR $RAILS_ROOT

COPY . $RAILS_ROOT
COPY .env $RAILS_ROOT
RUN bundle install && bundle exec rails assets:precompile