#!/usr/bin/env bash

rm -rf /app/report/*
mvn clean verify || true
mv -v /app/target/*report.zip /app/report/
