# language: de
@OPTIONAL @EPA_3_0
Funktion: Test ePA login

  Szenario: Create a user session
    Wenn TGR show banner "Testfall: Aufbau einer USer Session mit IDP und Authorization Service"
    # For customers who trigger the handshake manually via UI
    Dann TGR pause test run execution with message "Bitte initiiere den Aufbau einer User Session mit dem Primärsystem!"
    # For gematik who triggers the handshake via an API call
    # Dann TGR send empty GET request to "http://ps/services/epa/testdriver/api/v1/login?telematikId=5-SMC-B-Testkarte-883110000117894&fqdn=gematik.de"

    ### getNonce
    Und TGR find last request to path ".*" with "$.body.decrypted.path.basicPath" matching "/epa/authz/v1/getNonce"
    # outer request
    Und TGR current request with attribute "$.method" matches "POST"
    Und TGR current request with attribute "$.header.[~'accept']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.['VAU-nonPU-Tracing']" matches ".* .*"
    # inner request
    Und TGR current request with attribute "$.body.decrypted.method" matches "GET"
    Und TGR current request with attribute "$.body.decrypted.header.[~'accept']" matches "application/json"
    Und TGR current request with attribute "$.body.decrypted.header.['x-useragent']" matches ".*"
    # outer response
    Und TGR current response with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current response with attribute "$.responseCode" matches "200"
    # inner response
    Und TGR current response with attribute "$.body.decrypted.responseCode" matches "200"
    Und TGR current response with attribute "$.body.decrypted.body.nonce" matches ".*"
    Und TGR current response at "$.body.decrypted.body" matches as JSON:
    """
    {
      "nonce" : "${json-unit.ignore}"
    }
    """

    ###  send_authorization_request_sc
    Und TGR find last request to path ".*" with "$.body.decrypted.path.basicPath" matching "/epa/authz/v1/send_authorization_request_sc"
    # outer request
    Und TGR current request with attribute "$.method" matches "POST"
    Und TGR current request with attribute "$.header.[~'accept']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.['VAU-nonPU-Tracing']" matches ".* .*"
    # inner request
    Und TGR current request with attribute "$.body.decrypted.method" matches "GET"
    Und TGR current request with attribute "$.body.decrypted.header.['x-useragent']" matches ".*"
    # outer response
    Und TGR current response with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current response with attribute "$.responseCode" matches "200"
    # inner response
    Und TGR current response with attribute "$.body.decrypted.responseCode" matches "302"
    Und TGR current response with attribute "$.body.decrypted.reasonPhrase" matches "Found"
    Und TGR current response with attribute "$.body.decrypted.header.[~'location']" matches "https://idp-ref.app.ti-dienste.de.*"
    Und TGR current response with attribute "$.body.decrypted.header.[~'location'].redirect_uri" matches ".*"
    Und TGR current response with attribute "$.body.decrypted.header.[~'location'].state" matches ".*"
    Und TGR current response with attribute "$.body.decrypted.header.[~'location'].nonce" matches ".*"
    Und TGR current response with attribute "$.body.decrypted.header.[~'location'].code_challenge" matches ".*"
    Und TGR current response with attribute "$.body.decrypted.header.[~'location'].code_challenge_method.value" matches "S256"
    Und TGR current response with attribute "$.body.decrypted.header.[~'location'].scope.value" matches "gem-auth openid"
    Und TGR current response with attribute "$.body.decrypted.header.[~'location'].response_type.value" matches "code"

     ###  send_authcode_sc
    Und TGR find last request to path ".*" with "$.body.decrypted.path.basicPath" matching "/epa/authz/v1/send_authcode_sc"
    # outer request
    Und TGR current request with attribute "$.method" matches "POST"
    Und TGR current request with attribute "$.header.[~'accept']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.['VAU-nonPU-Tracing']" matches ".* .*"
    # inner request
    Und TGR current request with attribute "$.body.decrypted.method" matches "POST"
    Und TGR current request with attribute "$.body.decrypted.header.[~'content-type']" matches "application/json"
    Und TGR current request with attribute "$.body.decrypted.header.['x-useragent']" matches ".*"

    Und TGR current request at "$.body.decrypted.body" matches as JSON:
    """
      {
        "authorizationCode" : "${json-unit.ignore}",
        "clientAttest" : "${json-unit.ignore}"
      }
    """
    Und TGR current request with attribute "$.body.decrypted.body.authorizationCode.content.header.enc" matches "A256GCM"
    Und TGR current request with attribute "$.body.decrypted.body.authorizationCode.content.header.cty" matches "NJWT"
    Und TGR current request with attribute "$.body.decrypted.body.authorizationCode.content.header.exp" matches "[\d]*"
    Und TGR current request with attribute "$.body.decrypted.body.authorizationCode.content.header.alg" matches "dir"
    Und TGR current request with attribute "$.body.decrypted.body.authorizationCode.content.header.kid" matches "0001"
    Und TGR current request at "$.body.decrypted.body.authorizationCode.content.header" matches as JSON:
    """
    {
      "enc" : "A256GCM",
      "cty" : "NJWT",
      "exp" : "[\\d]*",
      "alg" : "dir",
      "kid" : "0001"
    }
    """
    Und TGR current request with attribute "$.body.decrypted.body.clientAttest.content.header.typ" matches "JWT"
    Und TGR current request with attribute "$.body.decrypted.body.clientAttest.content.header.x5c" matches ".*"
    Und TGR current request with attribute "$.body.decrypted.body.clientAttest.content.header.alg" matches "(ES256|PS256)"
    Und TGR current request at "$.body.decrypted.body.clientAttest.content.header" matches as JSON:
    """
      {
      "typ" : "JWT",
      "x5c" : "${json-unit.ignore}",
      "alg" : "${json-unit.ignore}"
      }
    """
    Und TGR current request contains node "$.body.decrypted.body.clientAttest.content.body"
    Und TGR current request at "$.body.decrypted.body.clientAttest.content.body" matches as JSON:
    """
      {
      "nonce" : "${json-unit.ignore}",
      "iat" : "[\\d]*"
      }
    """
    Und TGR current request contains node "$.body.decrypted.body.clientAttest.content.signature"
    # Cannot be validate any longer due to ES256 stUndard representing an algorithm with NIST curves
    # instead of brainpool curves witch Gematik defines for ePA
    #Und TGR current request with attribute "$.body.decrypted.body.clientAttest.content.signature.isValid" matches "true"
    #Und TGR current request with attribute "$.body.decrypted.body.clientAttest.content.signature.verifiedUsing" matches "x5c-header certificate"

    # outer response
    Und TGR current response with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current response with attribute "$.responseCode" matches "200"
    # inner response
    Und TGR current response with attribute "$.body.decrypted.responseCode" matches "200"
    Und TGR current response with attribute "$.body.decrypted.reasonPhrase" matches "OK"
    Und TGR current response with attribute "$.body.decrypted.header.[~'content-type']" matches "application/json"
    Und TGR current response with attribute "$.body.decrypted.body" matches ".*"
