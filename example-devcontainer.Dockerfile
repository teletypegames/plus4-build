# Dev container of a WarpEngine project: the platform's CI builder image (the
# same toolchain the pipeline builds with) plus git and a non-root user, so the
# files a build writes belong to you on Linux too. New Game fills {builderImage}
# from the host's platform description.
FROM {builderImage}

RUN apt-get update \
 && apt-get install -y --no-install-recommends git openssh-client sudo \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m -u 1000 -s /bin/bash dev \
 && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev
