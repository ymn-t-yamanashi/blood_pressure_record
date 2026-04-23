FROM elixir:1.18.4-otp-28

RUN apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  git \
  curl \
  ca-certificates \
  inotify-tools \
  libsqlite3-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=dev \
    LANG=C.UTF-8

CMD ["bash", "-lc", "mix phx.server"]
