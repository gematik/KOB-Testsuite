# language: de
@OPTIONAL @EPA_3_0
Funktion: Test information operations by PS

  @information-record-status
  Szenario: Get record status by ps
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    Wenn TGR show banner "Testfall: Frage den Status eines existierenden Aktenkontos beim Aktensystem mit dem Primärsystem ab"
    # For customers who trigger the record status request manually via UI
    Dann TGR pause test run execution with message "Bitte initiiere eine Abfrage des Status eines existierenden Aktenkontos beim Aktensystem durch ein Primärsystem!"

    ### get record status
    # request
    Und TGR find last request to path "/information/api/v1/ehr" with "$.method" matching "GET"
    Und TGR current request with attribute "$.header.['x-insurantid']" matches ".*"
    Und TGR current request with attribute "$.header.['x-useragent']" matches ".*"

    # response
    Und TGR current response with attribute "$.responseCode" matches "204"

  @information-consent-decisions
  Szenario: Get consent decisions by ps
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    Wenn TGR show banner "Testfall: Frage den Status von Widersprüchen eines existierenden Aktenkontos beim Aktensystem mit dem Primärsystem ab"
    # For customers who trigger the record status request manually via UI
    Dann TGR pause test run execution with message "Bitte initiiere eine Abfrage des Status von Widersprüchen eines existierenden Aktenkontos beim Aktensystem durch ein Primärsystem!"

    ### get consent decisions
    # request
    Und TGR find last request to path "/information/api/v1/ehr/consentdecisions" with "$.method" matching "GET"
    Und TGR current request with attribute "$.header.[~'accept']" matches ".*application/json.*"
    Und TGR current request with attribute "$.header.['x-insurantid']" matches ".*"
    Und TGR current request with attribute "$.header.['x-useragent']" matches ".*"

    # response
    Und TGR current response with attribute "$.responseCode" matches "200"
    Und TGR current response at "$.body" matches as JSON:
    """
      {
        "data": [
                  {"functionId":"medication","decision":"${json-unit.ignore}"},
                  {"functionId":"erp-submission","decision":"${json-unit.ignore}"}
                ]
      }
    """

    Und TGR current response with attribute "$.body.data.0.decision" matches "(permit|deny)"
    Und TGR current response with attribute "$.body.data.1.decision" matches "(permit|deny)"
