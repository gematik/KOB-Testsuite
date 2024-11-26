# Copyright (c) 2023 gematik - Gesellschaft für Telematikanwendungen der Gesundheitskarte mbH
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

ARG COMMIT_HASH
ARG VERSION

LABEL de.gematik.vendor="gematik GmbH"
LABEL maintainer="software-development@gematik.de"
LABEL de.gematik.app="ePA KOB Testsuite for PS"
LABEL de.gematik.git-repo-name="https://gitlab.prod.ccs.gematik.solutions/git/Testtools/ePA/kob-testsuite"
LABEL de.gematik.commit-sha=$COMMIT_HASH
LABEL de.gematik.version=$VERSION

# Default USERID and GROUPID
ARG USERID=10000
ARG GROUPID=10000

RUN mkdir -p /.m2/repository
RUN chown -R $USERID:$GROUPID /.m2/repository

# Run as User (not root)
USER $USERID:$GROUPID

# Default Working directory
WORKDIR /app

# Defining default Healthcheck e.g. when run without docker-compose or without healthcheck definition in it
HEALTHCHECK --interval=15s --timeout=10s --start-period=15s \
   CMD ["wget", "--quiet", "--tries=1", "--output-document", "-", "http://localhost:8080/actuator/health"]

# Copy the resource to the destination folder and assign permissions
COPY --chown=$USERID:$GROUPID src /app/src
COPY --chown=$USERID:$GROUPID pom.xml /app/pom.xml

# Command to be executed.
ENTRYPOINT ["mvn", "clean", "verify"]
