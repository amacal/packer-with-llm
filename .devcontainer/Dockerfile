FROM mcr.microsoft.com/devcontainers/base:bookworm
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git ripgrep jq tzdata \
    qemu-system-x86 qemu-utils ovmf \
    && rm -rf /var/lib/apt/lists/* \
    && (getent group kvm >/dev/null && groupmod -g 104 kvm || groupadd -g 104 kvm) \
    && usermod -aG kvm vscode

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg -o /etc/apt/keyrings/hashicorp.asc \
    && echo "deb [signed-by=/etc/apt/keyrings/hashicorp.asc] https://apt.releases.hashicorp.com bookworm main" \
        > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y --no-install-recommends packer \
    && rm -rf /var/lib/apt/lists/*

RUN GH_RELEASE=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest) \
    && GH_DEB=$(echo "$GH_RELEASE" | grep -o 'https://[^"]*linux_amd64\.deb' | head -1) \
    && if [ -n "$GH_DEB" ]; then \
         curl -fsSL "$GH_DEB" -o /tmp/gh.deb \
         && apt-get update && apt-get install -y /tmp/gh.deb \
         && rm -f /tmp/gh.deb; \
       else \
         GH_TAR=$(echo "$GH_RELEASE" | grep -o 'https://[^"]*linux_amd64\.tar\.gz' | head -1) \
         && curl -fsSL "$GH_TAR" -o /tmp/gh.tar.gz \
         && tar -xzf /tmp/gh.tar.gz -C /usr/local --strip-components=1 \
         && rm -f /tmp/gh.tar.gz; \
       fi \
    && rm -rf /var/lib/apt/lists/* \
    && gh --version

USER vscode
ENV PATH="/home/vscode/.local/bin:${PATH}"

RUN curl -fsSL https://claude.ai/install.sh | bash -s stable \
    && claude --version \
    && mkdir -p /home/vscode/.claude
