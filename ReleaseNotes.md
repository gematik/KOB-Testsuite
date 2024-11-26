# Release Notes KOB Testsuite

## Release 0.6.4

* Bugfix for IP-Selector
* Selected test for docker container is configured via `.env` file
* Fixed docker execution issues
  * missing user rights inside docker container (throwing exception)
    - different user than root is used due to security reasons
  * added settings.xml to optional configure a proxy server for maven inside the container
    & thus added new section in ReadMe
* Fixed error message when checking availability of health record system IPs

## Release 0.6.3

* Added TLS-RU-certificates for AS-servers
* Added message for screenshot creation
* IP-Selection for epa-as-1.dev now works correctly
* Refactor KOB testcase
  * run KOB testcase at least against one health record system (IBM and/or RISE)
  * Necessary to define one KVNR for each health record system (kob.yml)
* Refactor optional testcases
  * modified to match at least one health record system 

## Release 0.6.2

* Refactor testcase
  * add check in general if message contain VAU-nonPU-Tracing http header and correct PU flag in VAU header
  * add check if FHIR or Render path was in request
  * remove checks that EGK card is available and a screenshot has to be placed inside testsuite repo
  * remove checks that the accept http header is given in a request
  * add checks that the http header for x-insurantid is as configured and x-useragent is given in inner http request
  * fixed check that the correct content-type header in inner http response is given
* Extend / Rewrite several section in ReadMe
  * setup in general
  * necessary testsuite & routing configurations
  * KOB with TITUS

## Release 0.6.1

* internal release

## Release 0.6.0

* Update Tiger Libs to v3.4.4
* Use docker image for kob-testsuite from DockerHub
* Added more details to ReadMe

## Release 0.5.0

* Initial Release
