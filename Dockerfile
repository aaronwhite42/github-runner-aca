FROM ubuntu:focal

ARG GH_RUNNER_VERSION=2.289.3

ENV RUNNER_NAME=""
ENV GITHUB_TOKEN=""
ENV RUNNER_WORK_DIRECTORY="_work"
ENV RUNNER_ALLOW_RUNASROOT=false
ENV AGENT_TOOLS_DIRECTORY=/opt/hostedtoolcache

ENV DEBIAN_FRONTEND=noninteractive

# Update & Install common tools and packages
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    git \
    gnupg \
    iputils-ping \
    jq \
    libcurl4 \
    libicu66 \
    libssl1.0 \
    libunwind8 \
    lsb-release \
    netcat \
    software-properties-common \
    unzip

RUN apt-get update
RUN apt-get install ca-certificates curl apt-transport-https lsb-release gnupg
RUN curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ `lsb_release -cs` main" | tee /etc/apt/sources.list.d/azure-cli.list

# Create a user for running actions
RUN useradd -m actions
RUN mkdir -p /home/actions ${AGENT_TOOLS_DIRECTORY}
WORKDIR /home/actions

# Download the specified version of the GH runner for Linux
RUN curl -L -O https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && tar -zxf actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && rm -f actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh

# Copy out the runsvc.sh script to the root directory for running the service
RUN cp bin/runsvc.sh . && chmod +x ./runsvc.sh

COPY entrypoint.sh .
RUN chmod +x ./entrypoint.sh

# Now that the OS has been updated to include required packages, update ownership and then switch to actions user
RUN chown -R actions:actions /home/actions ${AGENT_TOOLS_DIRECTORY}

USER actions
CMD [ "./entrypoint.sh" ]
