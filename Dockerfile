ARG JDK_BASE_IMAGE=openjdk:8u162-jdk
FROM ${JDK_BASE_IMAGE}

ARG SBT_VERSION=0.13.18
ARG SCALA_VERSION=2.11.8

# Export values for sub container use
ENV SBT_VERSION=${SBT_VERSION}
ENV SCALA_VERSION=${SCALA_VERSION}

# Install baseline utility packages
RUN apt-get update \
    && apt-get install -y --fix-broken \
    && apt-get install -y --no-install-recommends \
        apt-transport-https\
        awscli\
        bc \
        curl\
        dirmngr \
        git\
        gnupg\
        gzip\
        lsb-release\
        python\
        software-properties-common\
        ssh\
        sudo\
        tar\
    && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Docker
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" \
    && curl -fsSL -o "docker-key.gpg" "https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg" \
    && apt-key add "docker-key.gpg" \
    && rm "docker-key.gpg" \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create harrys user for running commands non-root
RUN ["adduser", "--disabled-password", "--gecos", "", "harrys"]
RUN ["usermod", "-aG", "sudo", "harrys"]
RUN echo 'harrys ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/harrys
RUN usermod -aG docker harrys
USER harrys

# Default path is HOME
WORKDIR /home/harrys

# Install SBT
# https://www.scala-sbt.org/1.x/docs/Installing-sbt-on-Linux.html#Ubuntu+and+other+Debian-based+distributions
RUN    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | sudo tee /etc/apt/sources.list.d/sbt.list \
    && echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | sudo tee /etc/apt/sources.list.d/sbt_old.list \
    && curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add \
    && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823 \
    && sudo apt-get update \
    && sudo apt-get install sbt \
    && sudo apt-get clean \
    && sudo rm -rf /var/lib/apt/lists/*

ENV SBT_HOME=/home/harrys/.sbt
RUN mkdir -p "$SBT_HOME"

# Force SBT to bootstrap SBT_HOME and the compiler interface
RUN mkdir -p /tmp/force-compile/project  \
  && cd /tmp/force-compile      \
  && mkdir -p src/main/scala    \
  && echo "sbt.version=$SBT_VERSION" > project/build.properties \
  && echo "scalaVersion := \"$SCALA_VERSION\"" > build.sbt \
  && echo 'object EmptyMain { def main(args: Array[String]): Unit = {}  }' > src/main/scala/EmptyMain.scala \
  && sbt compile \
  && cd ~/ \
  && sudo rm -fR /tmp/*

# Copy code (in order of odds of changing)
COPY build.sbt ./tallboy/
COPY project/ ./tallboy/project
COPY app/ ./tallboy/app
COPY conf/ ./tallboy/conf

RUN cd /home/harrys/tallboy \
    && sbt compile
