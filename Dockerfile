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

FROM maven:3.9.9-eclipse-temurin-17-focal
RUN apt-get update

ARG COMMIT_HASH
ARG VERSION

LABEL de.gematik.vendor="gematik GmbH"
LABEL maintainer="software-development@gematik.de"
LABEL de.gematik.app="ePA KOB Testsuite for PS"
LABEL de.gematik.git-repo-name="https://gitlab.prod.ccs.gematik.solutions/git/Testtools/ePA/kob-testsuite"
LABEL de.gematik.commit-sha=$COMMIT_HASH
LABEL de.gematik.version=$VERSION

RUN mkdir -p /.m2/repository && chown -R $USERID:$GROUPID /.m2/repository

WORKDIR /app

COPY src /app/src
COPY pom.xml /app/pom.xml

RUN mvn pre-integration-test
