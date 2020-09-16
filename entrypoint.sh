#!/bin/sh

bundle exec rake generate_secret_token

exec "$@"

