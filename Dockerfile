# https://hub.docker.com/_/microsoft-dotnet-core
#FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build

#WORKDIR /source

# copy csproj and restore as distinct layers
#COPY *.sln .
#COPY aspnetapp/*.csproj ./aspnetapp/
#RUN dotnet restore

# copy everything else and build app
#COPY aspnetapp/. ./aspnetapp/
#WORKDIR /source/aspnetapp
#RUN dotnet publish -c release -o /app --no-restore

# final stage/image
FROM mcr.microsoft.com/dotnet/sdk:6.0




#
# Openvscode-server from https://github.com/gitpod-io/openvscode-releases/
#

#FROM buildpack-deps:22.04-curl

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        libatomic1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/

ARG RELEASE_TAG="openvscode-server-v1.69.2"
ARG RELEASE_ORG="gitpod-io"
ARG OPENVSCODE_SERVER_ROOT="/home/.openvscode-server"

# Downloading the latest VSC Server release and extracting the release archive
# Rename `openvscode-server` cli tool to `code` for convenience
RUN if [ -z "${RELEASE_TAG}" ]; then \
        echo "The RELEASE_TAG build arg must be set." >&2 && \
        exit 1; \
    fi && \
    arch=$(uname -m) && \
    if [ "${arch}" = "x86_64" ]; then \
        arch="x64"; \
    elif [ "${arch}" = "aarch64" ]; then \
        arch="arm64"; \
    elif [ "${arch}" = "armv7l" ]; then \
        arch="armhf"; \
    fi && \
    wget https://github.com/${RELEASE_ORG}/openvscode-server/releases/download/${RELEASE_TAG}/${RELEASE_TAG}-linux-${arch}.tar.gz && \
    tar -xzf ${RELEASE_TAG}-linux-${arch}.tar.gz && \
    mv -f ${RELEASE_TAG}-linux-${arch} ${OPENVSCODE_SERVER_ROOT} && \
    cp ${OPENVSCODE_SERVER_ROOT}/bin/remote-cli/openvscode-server ${OPENVSCODE_SERVER_ROOT}/bin/remote-cli/code && \
    rm -f ${RELEASE_TAG}-linux-${arch}.tar.gz

ARG USERNAME=openvscode-server
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Creating the user and usergroup
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USERNAME -m -s /bin/bash $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

RUN chmod g+rw /home && \
    mkdir -p /home/workspace && \
    chown -R $USERNAME:$USERNAME /home/workspace && \
    chown -R $USERNAME:$USERNAME ${OPENVSCODE_SERVER_ROOT}

#RUN mkdir -p /home/workspace/.vscode && \
#    echo '{ "recommendations": ["ms-dotnettools.csharp"] }'

USER $USERNAME

WORKDIR /home/workspace/

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/home/workspace \
    EDITOR=code \
    VISUAL=code \
    GIT_EDITOR="code --wait" \
    OPENVSCODE_SERVER_ROOT=${OPENVSCODE_SERVER_ROOT}

# Default exposed port if none is specified
EXPOSE 8080




ENV \
    # Unset ASPNETCORE_URLS from aspnet base image
    ASPNETCORE_URLS=http://0.0.0.0:8000 \
    # development environment
    ASPNETCORE_ENVIRONMENT=”development” \
    # Do not generate certificate
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # SDK version
    DOTNET_SDK_VERSION=6.0.302 \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip


VOLUME /app
#WORKDIR /app
#COPY --from=build /app ./
EXPOSE 8000
#ENTRYPOINT ["dotnet", "aspnetapp.dll"]







ENTRYPOINT [ "/bin/sh", "-c", "exec ${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server --host 0.0.0.0 --port 8080 --connection-token v15ua15tudi0 \"${@}\"", "--" ]
## odo changed --without-connection-token to --connection-token 


#
# openvscode server custom environment
#

#FROM gitpod/openvscode-server:latest

# to get permissions to install packages and such 
#USER root 
# the installation process for software needed
#RUN #
# to restore permissions for the web interface
#USER openvscode-server 

#
#
#

# to build me:
# docker build -t vscsdn6:1.0.0.1 -t vscsdn6:latest .
# to run me
#old docker run -it --rm --name vscsdn6test -p 8000:80 -p 8080:8080 -v /Users/odo/local/docker/dev:/app -w /app vscodeserverdotnet6:latest
# docker run -it --name vscsdn6 -p 8000:8000 -p 8080:8080 -v $(pwd)/app:/app vscsdn6:1.0.0.1
# launch: http://localhost:8080/?tkn=v15ua15tudi0




###
###
### README
###
# https://www.pluralsight.com/blog/software-development/how-to-build-custom-containers-docker
###
###
###


