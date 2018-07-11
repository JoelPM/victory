#===================
# Build Stage
#===================
FROM elixir:1.6.4-alpine as builder

# Get the application name from a build_arg and set it in the ENV
ARG APP_NAME
ENV APP_NAME ${APP_NAME}

# Building a container means targeting prod
ENV MIX_ENV=prod

# Install make so we can execute the make targets
RUN apk update
RUN apk add make

# Copy the src to a /build dir. This will go faster if you've done
# 'make clean' first so you're not copying over garbage.
RUN mkdir /build
WORKDIR /build
COPY . .

# Install local hex and rebar3
RUN echo "hi there!"
RUN which sh
RUN "mix local.hex --force"
RUN mix local.rebar --force

# Build the release
RUN make release

# Copy and expand the release to a directory that's easy to copy from.
RUN RELEASE_DIR=`ls -d _build/prod/rel/$APP_NAME/releases/*/` && \
    mkdir /export/ && \
    tar -xf "$RELEASE_DIR/$APP_NAME.tar.gz" -C /export

# And we're done! (Wasn't that easy?)

#===================
# Deployment Stage
#===================
FROM alpine:3.7

# Elixir needs bash and openssl
RUN apk update && apk add bash openssl

# Get the application name from a build_arg and set it in the ENV
ARG APP_NAME

# Set environment variables and expose port
EXPOSE 4000
ENV REPLACE_OS_VARS=true \
    PORT=4000 \
    URL_HOST="$APP_NAME.svc" \
    URL_PORT=80

# Copy expanded release over
RUN mkdir $APP_NAME
WORKDIR $APP_NAME
COPY --from=builder /export/ .

# Create user for the application
RUN addgroup -g 1000 -S $APP_NAME && \
    adduser  -u 1000 -S $APP_NAME -G $APP_NAME && \
    chown -R $APP_NAME:$APP_NAME /$APP_NAME

USER $APP_NAME

# Set default entrypoint and command. To make this generic and still work
# with the exec form of ENTRYPOINT we need to have a script we know the
# name of, which is why we create the link.
RUN ln -s /$APP_NAME/bin/$APP_NAME /$APP_NAME/bin/run && chmod 755 ./bin/run

ENTRYPOINT ["bin/run"]
CMD ["foreground"]
