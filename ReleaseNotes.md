# Release Notes KOB Testsuite

## Release 1.0.6
* The KOB test case must now be executed for both medical record systems (IBM and RISE) in RU-REF environment.
* Fixed default HTTPS port for tiger proxy from 433 to standard 443
* Updated license information
* Upgrade to Tiger 3.7.7
  * see [release notes](https://github.com/gematik/app-Tiger/blob/master/ReleaseNotes.md) for details

## Release 1.0.5 (KOB Stufe 2)
* Upgrade to Tiger 3.7.5
  * see [release notes](https://github.com/gematik/app-Tiger/blob/master/ReleaseNotes.md) for details
* The screenshots uploaded to get the KOB certificate should show medical prescriptions as described in [ReadMe Section "Einzustellende E-Rezepte"](README.adoc) for both medical record systems (IBM and RISE).


## Release 1.0.4

* Upgrade to Tiger 3.6.0
  * see [release notes](https://github.com/gematik/app-Tiger/blob/master/ReleaseNotes.md) for details
  * Bugs
    * During a TLS-Handshake the Tiger-Proxy no longer signals HTTP/2-support in the ALPN
* Docker container now uses the user “kobtest” (non-root)
* Updated PS test driver openAPI

## Release 1.0.3

* Updated 
  * added check for HTTP Header `x-useragent` in outer HTTP request (not VAU encrypted part) within KOB and optional testcase
  * added regex check for HTTP Header `x-useragent` in inner HTTP request within optional testcases
  * checking HTTP header field name `x-useragent`, `x-insurantid` & `VAU-nonPU-Tracing` is now case-insensitive (as in standard RFC-9110 Section-5.1 )
* Bugs
  * Fixed missing correction in testcase for IBM and RISE resp.

## Release 1.0.2

* Upgrade to Tiger 3.4.6
* Test execution with maven uses .env configuration to filter tests and starts with `mvn clean verify`  
* Bugs
  * Allow content-type text/html with specified charset in backend response for eML as XHTML (GH-21)
  * Remove run.sh script due to issues during git checkout and modified line endings (GH-20)
  * Corrected custom error messages
  * Corrected OPTIONAL/Optional spelling, leading to a failed report upload if failing the non-KOB-testcases
  * Settings.xml is mapped to maven folder .m2 of the root user
* Extended descriptions in Readme for Forward Proxy and GIT configuration (HowTo)

## Release 1.0.1

* Added corrected NO-PROXY flag for AS-Selector
* Added preparation test step to check if health record systems are reachable (now visible in Workflow UI)
* Rework docker container handling (issues with access rights)
  * Remove access from docker container to host system. Thus, the report has to be copied from container to host system manually (please see Readme)
  * Test report will be moved to extra docker volume `kob-testsuite-report` after finishing the testsuite
  * Copy report zip file from container to host system (please see Readme)

## Release 1.0.0

* Initial version to get KOB certification 
* New static identity (server cert) for localhost fqdn
* Issue accessing the test report with docker fixed

## Release 0.6.5

* Server-TLS-Suites now conforming to specified values
  * TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256
  * TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
* Fix Login testcase with IDP endpoint url - currently accept internet and TI endpoint 
* Added FAQ section in ReadMe
  * How to get TGR file for service desk tickets from docker container
  * How to get rid of `/.m2/repository/org` issue when starting the docker container

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
