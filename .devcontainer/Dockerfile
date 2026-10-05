FROM mcr.microsoft.com/devcontainers/base:bookworm
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git ripgrep jq tzdata \
    qemu-system-x86 qemu-utils ovmf \
    && rm -rf /var/lib/apt/lists/* \
    && (getent group kvm || groupadd kvm) \
    && usermod -aG kvm vscode

RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://apt.releases.hashicorp.com/gpg -o /etc/apt/keyrings/hashicorp.asc \
    && echo "deb [signed-by=/etc/apt/keyrings/hashicorp.asc] https://apt.releases.hashicorp.com bookworm main" \
        > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update && apt-get install -y --no-install-recommends packer \
    && rm -rf /var/lib/apt/lists/*

USER vscode
ENV PATH="/home/vscode/.local/bin:${PATH}"

RUN curl -fsSL https://claude.ai/install.sh | bash -s stable \
    && claude --version \
    && mkdir -p /home/vscode/.claude
