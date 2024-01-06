# accelerate-llvm-ptx requires nvcc, which is included in cuda's devel images
# https://hub.docker.com/r/nvidia/cuda/
# FROM nvidia/cuda:12.0.1-devel-ubuntu20.04

FROM ubuntu:22.04
LABEL org.opencontainers.image.authors="Tom Smeding <t.j.smeding@uu.nl>, Trevor L. McDonell <trevor.mcdonell@gmail.com>"

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
# ENV LD_LIBRARY_PATH "/usr/local/cuda/lib64:/usr/local/cuda/nvvm/lib64:${LD_LIBRARY_PATH}"

# Don't install suggested or recommended dependencies
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-docker
RUN echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-docker

# tzdata is (?) a dependency of the packages, which requires a set timezone
ARG CONTAINER_TIMEZONE=Europe/Amsterdam
RUN ln -snf /usr/share/zoneinfo/${CONTAINER_TIMEZONE} /etc/localtime && echo ${CONTAINER_TIMEZONE} > /etc/timezone

# Install dependencies to add package sources
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y software-properties-common curl gnupg

# Add LLVM package repository
ARG LLVM_VERSION=15
RUN curl https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - \
 && add-apt-repository "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-${LLVM_VERSION} main"

# Install dependencies then clean up package lists
# The glut, capstone etc. dependencies are for the Quickhull practical
# specifically (either for the framework or for Accelerate)
RUN apt-get update \
 && apt-get install -y \
        pkg-config git g++ make graphviz libgmp-dev openssh-client \
        clang-${LLVM_VERSION} libclang-${LLVM_VERSION}-dev llvm-${LLVM_VERSION}-dev \
        freeglut3-dev libgmp-dev libcapstone-dev libfreetype6-dev libglfw3-dev \
        libspice-client-gtk-3.0-dev libtbb-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# create the vscode user
ARG USERNAME=vscode
RUN adduser ${USERNAME}
# RUN mkdir -p /home/${USERNAME}/.ssh \
#  && mkdir -p /home/${USERNAME}/.ghcup \
#  && mkdir -p /home/${USERNAME}/.cabal \
#  && mkdir -p /home/${USERNAME}/.stack \
#  && mkdir -p /home/${USERNAME}/.vscode-server/extensions \
#  && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
ENV PATH "/home/${USERNAME}/.local/bin:/home/${USERNAME}/.cabal/bin:/home/${USERNAME}/.ghcup/bin:${PATH}"
USER "${USERNAME}"

# install minimal ghcup
ENV BOOTSTRAP_HASKELL_NONINTERACTIVE=True
ENV BOOTSTRAP_HASKELL_MINIMAL=True
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

# install ghc and related tools
RUN ghcup install cabal 3.10.2.1
RUN ghcup install ghc --set 9.4.7
RUN ghcup install hls 2.4.0.0
# RUN ghcup install stack

# configure stack to install via ghcup
# RUN mkdir -p ~/.stack/hooks \
#  && curl https://raw.githubusercontent.com/haskell/ghcup-hs/master/scripts/hooks/stack/ghc-install.sh > ~/.stack/hooks/ghc-install.sh \
#  && chmod +x ~/.stack/hooks/ghc-install.sh

# Make sure cabal's package database is up to date
RUN cabal update

# set shell to bash to use auto completion (e.g. arrow up for last command)
ENV SHELL="/bin/bash"
