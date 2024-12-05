# Copyright (c) 2024 gematik - Gesellschaft für Telematikanwendungen der Gesundheitskarte mbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Docker Rules from https://wiki.gematik.de/display/DEV/Docker+Rules

# used java 21 image due to different m2 respository location
FROM maven:3-eclipse-temurin-21-alpine

# The STOPSIGNAL instruction sets the system call signal that will be sent to the container to exit
# SIGTERM = 15 - https://de.wikipedia.org/wiki/Signal_(Unix)
STOPSIGNAL SIGTERM

# Git Args
ARG COMMIT_HASH
ARG VERSION

###########################
# Labels
###########################
LABEL de.gematik.vendor="gematik GmbH" \
      maintainer="software-development@gematik.de" \
      de.gematik.app="ePA KOB Testsuite for PS" \
      de.gematik.git-repo-name="https://github.com/gematik/kob-Testsuite/" \
      de.gematik.commit-sha=$COMMIT_HASH \
      de.gematik.version=$VERSION


COPY . /app
COPY downloadDeps.sh /app

RUN mkdir -p /app/report

# Default Working directory
WORKDIR /app

RUN ./downloadDeps.sh
RUN rm -f ./downloadDeps.sh

# Command to be executed.
ENTRYPOINT ["bash", "-c", "/app/run.sh"]
