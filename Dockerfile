FROM rust:1.80.1-bookworm
USER root

ENV RUNNING_IN_DOCKER true

################################################
# basics
################################################

RUN apt update && apt upgrade -y
RUN apt install -yq \
    git vim curl gnupg2 sudo wget file zip unzip build-essential libssl-dev \
    libwebkit2gtk-4.1-dev libxdo-dev libayatana-appindicator3-dev librsvg2-dev

################################################
# rust
################################################

RUN rustup update

RUN rustup target add \
    aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

RUN rustup component add rustfmt

################################################
# locals
################################################

RUN apt install -yq locales locales-all

ENV LC_ALL en_US.UTF-8
ENV LC_TYPE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

################################################
# shell
################################################

# install fish
RUN echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_12/ /' | tee /etc/apt/sources.list.d/shells:fish:release:3.list
RUN curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_12/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
RUN apt install -y fish

# install starship
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

SHELL ["fish", "-c"]
ENV SHELL /usr/bin/fish

################################################
# cleanup
################################################

# Clean up to reduce container size
RUN apt clean && rm -rf /var/lib/apt/lists/*

################################################
# user
################################################

ARG USERNAME=vscode
ARG USER_ID=1000
ARG GROUP_ID=$USER_ID

RUN groupadd -g $GROUP_ID -o $USERNAME
RUN useradd -m -u $USER_ID -g $GROUP_ID -o -s /usr/bin/fish $USERNAME

# add to sudoers
RUN echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && chmod 0440 /etc/sudoers.d/$USERNAME

# cache mount points
RUN mkdir -p /home/$USERNAME/.cache && chown $USERNAME:$USERNAME /home/$USERNAME/.cache
RUN mkdir -p /home/$USERNAME/.local && chown $USERNAME:$USERNAME /home/$USERNAME/.local

USER $USERNAME

# install fisher
RUN curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

################################################
# node
################################################

ENV NODE_VERSION 22.11.0

# install nvm via fisher
RUN fisher install jorgebucaran/nvm.fish

RUN set --universal nvm_default_version $NODE_VERSION
RUN set --universal nvm_default_packages pnpm

RUN nvm install $NODE_VERSION
RUN nvm use $NODE_VERSION && npm install --global pnpm
