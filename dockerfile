FROM ubuntu:22.04 as base

LABEL io.k8s.description="Platform for VSphere SDK" \
    io.k8s.display-name="ESX Scaler"

ENV XC_API_TOKEN="1234567"
ENV XC_TENANT_URL="https://customer.console.ves.volterra.io"
ENV XC_SITE_NAME="cluster-0"
ENV XC_SITE_ADMIN_PASSWORD="pass@word1"
ENV XC_SITE_SCALE_IPS="192.168.125.66,192.168.125.67,192.168.12.68"
ENV XC_SITE_SCALE_CIDR="24"
ENV VSPHERE_HOST="192.168.125.27"
ENV VSPHERE_USER="administrator@vsphere.local"
ENV VSPHERE_PASS="pass@word1"
ENV VSPHERE_DC="DC"
ENV VSPHERE_RESOURCE_POOL="XC Limited-Medium"
ENV VSPHERE_XC_CLUSTER_PREFIX="ce-cluster"
ENV VSPHERE_NEW_VM_HOST="vcenter.domain.com"
ENV VSPHERE_VAPP_PREFIX="scaled-worker"
ENV USAGE_HIGH_MARK=75
ENV USAGE_LOW_MARK=25

COPY *.ps1 /
COPY *.sh /

ADD tf /tmp/tf

RUN apt-get clean && apt-get -y update && apt-get upgrade -y \
    && apt-get install -y \
    software-properties-common \
    gnupg2 \
    wget \
    curl \
    apt-transport-https && \
    # Download the Microsoft repository GPG keys
    wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb" && \
    # Register the Microsoft repository GPG keys
    dpkg -i packages-microsoft-prod.deb && \
    rm -rf packages-microsoft-prod.deb && \
    add-apt-repository universe && \
    apt-get update -y && \
    apt-get install --no-install-recommends -y\
    git \
    jq \
    nano \
    build-essential \
    powershell && \
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list && \
    apt-get update -y && \
    apt-get install terraform -y && \
    chmod +x ./entrypoint.sh

FROM base AS powershell

RUN echo A | pwsh -Command Install-Module -Name VMware.PowerCLI -Force && \
    echo A | pwsh -Command Set-PowerCLIConfiguration -InvalidCertificateAction Ignore && \
    echo A | pwsh -Command Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP 0 -WebOperationTimeoutSeconds 300 && \
    echo A | pwsh -Command . ./VMOvfProperty.ps1

# Default commands to pwsh
CMD ["./entrypoint.sh"]
#ENTRYPOINT ["pwsh"]
