# language: de
@OPTIONAL @EPA_3_0 @entitlement
Funktion: Test set entitlements by PS

  Grundlage:
    Gegeben sei KOB finde Aktensystem

  Szenario: Set entitlements by ps
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    Wenn TGR show banner "Testfall: Befugnisvergabe durch ein Primärsystem"
    # For customers who trigger the post request for a new entitlement manually via UI
    Dann TGR pause test run execution with message "Bitte initiiere die Befugnisvergabe durch ein Primärsystem!"

    ### set entitlements
    Und TGR find last request to path ".*" with "$.body.decrypted.path.basicPath" matching "/epa/basic/api/v1/ps/entitlements"
    # outer request
    Und TGR current request with attribute "$.method" matches "POST"
    Und TGR current request with attribute "$.header.[~'accept']" matches ".*application/octet-stream.*"
    Und TGR current request with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.['VAU-nonPU-Tracing']" matches ".* .*"
    # inner request
    Und TGR current request with attribute "$.body.decrypted.method" matches "POST"
    Und TGR current request with attribute "$.body.decrypted.header.[~'accept']" matches ".*application/json.*"
    Und TGR current request with attribute "$.body.decrypted.header.['x-useragent']" matches ".*"
    Und TGR current request with attribute "$.body.decrypted.header.['x-insurantid']" matches ".*"
    Und TGR current request at "$.body.decrypted.body" matches as JSON:
    """
      {
        "jwt" : "${json-unit.ignore}"
      }
    """

    Und TGR current request with attribute "$.body.decrypted.body.jwt.content.header.alg" matches "(ES256|PS256)"
    Und TGR current request at "$.body.decrypted.body.jwt.content.header" matches as JSON:
    """
      {
        "typ" : "${json-unit.ignore}",
        "x5c" : "${json-unit.ignore}",
        "alg" : "${json-unit.ignore}"
      }
    """

    Und TGR current request at "$.body.decrypted.body.jwt.content.body" matches as JSON:
    """
      {
        "iat" : "[\\d]*",
        "exp" : "[\\d]*",
        "auditEvidence" : "${json-unit.ignore}"
      }
    """

    Und TGR current request contains node "$.body.decrypted.body.jwt.content.signature"
    # Und TGR current request with attribute "$.body.decrypted.body.jwt.content.signature" matches "true"


    # outer response
    Und TGR current response with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current response with attribute "$.responseCode" matches "200"

    # inner response
    Und TGR current response with attribute "$.body.decrypted.responseCode" matches "201"
    Und TGR current response with attribute "$.body.decrypted.reasonPhrase" matches "Created"
    Und TGR current response with attribute "$.body.decrypted.header.[~'content-type']" matches "application/json"
    Und TGR current response at "$.body.decrypted.body" matches as JSON:
    """
    {
      "validTo" : "${json-unit.ignore}"
    }
    """
