# CI builder image for Plus/4 projects: ACME assembler + make, so the
# pipeline's build step does not run apt-get on every run. The VICE
# emulator (xplus4) is a local-dev tool only and is intentionally not included.
#
# Build & push (the CI runner is linux/amd64):
#   docker build --platform linux/amd64 -f builder.Dockerfile \
#     -t git.teletypegames.org/build/plus4-builder:latest .
#   docker push git.teletypegames.org/build/plus4-builder:latest

FROM debian:stable-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends make acme zip curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]
