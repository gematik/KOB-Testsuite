# language: de
@Optional @EPA_3_1_3 @eml_download
Funktion: Test eml download by PS

  Grundlage:
    Gegeben sei KOB finde Aktensystem

  # Testfall: EML Download.
  # Aktenlokalisierung, VAU Handshake, User Session, Entitlement auf der Akte und das Einstellen von E-Rezepten sind nicht im Scope dieses Tests.
  # Das Format des Downloads kann frei gewählt werde (siehe kob.yaml)
  # Der Download wird entweder über die Testtreiber-API oder manuell über die UI getriggert (siehe kob.yaml)
  # Der Screenshot wird in TITUS separat hochgeladen und händisch von der gematik überprüft. Er soll die Anzeige des EML in der UI demonstrieren
  Szenario: Download EML IBM
    # Bereite Testumgebung vor
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    # Wir triggern den Download der eML in dem konfigurierten Format
    Wenn KOB lade die EML im Format "${kob.emlType}" von dem Aktensystem "IBM" für das Aktenkonto des Patienten "${kob.kvnrIbm}" herunter

    # Zunächst überprüfen wir, ob grundsätzlich Verkehr gefunden werden kann und er den Mindestanforderungen entspricht
    Dann TGR die Fehlermeldung wird gesetzt auf: "Es konnte kein Verkehr gefunden werden! Bitte überprüfen Sie, ob der Verkehr tatsächlich über Tiger geroutet wird."
    Und TGR finde die letzte Anfrage mit dem Pfad ".*"
    # In nicht-PU Umgebungen muss der Client (das Primärsystem) die verwendeten Schlüssel (K2_c2s_app_data und K2_s2c_app_data)
    # Base64 kodiert im Header "VAU-nonPU-Tracing" übertragen. Diese Schlüssel dürfen NICHT in der PU übertragen werden.
    Dann TGR die Fehlermeldung wird gesetzt auf: "Der 'VAU-nonPU-Tracing'-Header konnte nicht gefunden werden! Dieser muss in der RU gesetzt werden!"
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.header.[~'VAU-nonPU-Tracing']" der mit "[A-Za-z0-9+\/]{41,44}=? [A-Za-z0-9+\/]{41,44}=?" übereinstimmt
    Dann TGR die Fehlermeldung wird gesetzt auf: "Das 'PU'-Flag im VAU-Header muss in der RU auf 0 gesetzt werden!"
    Und TGR current request with attribute "$.body.header.pu" matches "0"
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    ### Wir überprüfen noch den Verkehr des Einstellen einer Befugnis. Dazu müssen wir zunächst die Abfrage zum Setzen der Befugnis finden
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "/epa/basic/api/v1/ps/entitlements" übereinstimmt
    # inner request
    Und TGR current request with attribute "$.body.decrypted.method" matches "POST"
    Und TGR current request with attribute "$.body.decrypted.header.[~'x-insurantid']" matches "${kob.kvnrIbm}"
    # outer response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    # inner response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "201"
    Und TGR prüfe aktuelle Antwort im Knoten "$.body.decrypted.body" stimmt als JSON überein mit:
    """
    {
      "validTo" : "${json-unit.ignore}"
    }
    """

    # Wir überprüfen noch den Verkehr des Downloads selbst. Dazu müssen wir zunächst die Abfrage zum Auslösen des Downloads finden
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "(/epa/medication/api/v1/fhir/.*|/epa/medication/render/v1/eml/.*)" übereinstimmt

    # Nun prüfen wir die Struktur der Anfrage
    Dann TGR current request with attribute "$.method" matches "POST"
    Und TGR current request with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.[~'host']" matches "epa-as-1.ref.epa4all.de.*"
    Und TGR current request with attribute "$.header.[~'x-useragent']" matches "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"

    # Und nun die Struktur der inneren Anfrage (der VAU-verschlüsselte HTTP-Request)
    Und TGR current request with attribute "$.body.decrypted.method" matches "GET"
    Und TGR current request with attribute "$.body.decrypted.header.[~'x-insurantid']" matches "${kob.kvnrIbm}"
    Und TGR current request with attribute "$.body.decrypted.header.[~'x-useragent']" matches "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"

    # Nun prüfen wir die Antwort des Downloads. Damit stellen wir sicher, dass der Server die Anfrage korrekt verstanden hat
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"

    # Als letztes prüfen wir die Struktur der inneren Antwort (der VAU-verschlüsselte HTTP-Response)
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'content-type']" überein mit "(application\/fhir\+json|application\/pdf|text\/html.*)"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.body" überein mit ".*"

  Szenario: Download EML RISE
    # Bereite Testumgebung vor
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    # Wir triggern den Download der eML in dem konfigurierten Format
    Wenn KOB lade die EML im Format "${kob.emlType}" von dem Aktensystem "IBM" für das Aktenkonto des Patienten "${kob.kvnrIbm}" herunter

    # Zunächst überprüfen wir, ob grundsätzlich Verkehr gefunden werden kann und er den Mindestanforderungen entspricht
    Dann TGR die Fehlermeldung wird gesetzt auf: "Es konnte kein Verkehr gefunden werden! Bitte überprüfen Sie, ob der Verkehr tatsächlich über Tiger geroutet wird."
    Und TGR finde die letzte Anfrage mit dem Pfad ".*"
    # In nicht-PU Umgebungen muss der Client (das Primärsystem) die verwendeten Schlüssel (K2_c2s_app_data und K2_s2c_app_data)
    # Base64 kodiert im Header "VAU-nonPU-Tracing" übertragen. Diese Schlüssel dürfen NICHT in der PU übertragen werden.
    Dann TGR die Fehlermeldung wird gesetzt auf: "Der 'VAU-nonPU-Tracing'-Header konnte nicht gefunden werden! Dieser muss in der RU gesetzt werden!"
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.header.[~'VAU-nonPU-Tracing']" der mit "[A-Za-z0-9+\/]{41,44}=? [A-Za-z0-9+\/]{41,44}=?" übereinstimmt
    Dann TGR die Fehlermeldung wird gesetzt auf: "Das 'PU'-Flag im VAU-Header muss in der RU auf 0 gesetzt werden!"
    Und TGR current request with attribute "$.body.header.pu" matches "0"
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    ### Wir überprüfen noch den Verkehr des Einstellen einer Befugnis. Dazu müssen wir zunächst die Abfrage zum Setzen der Befugnis finden
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "/epa/basic/api/v1/ps/entitlements" übereinstimmt
    # inner request
    Und TGR current request with attribute "$.body.decrypted.method" matches "POST"
    Und TGR current request with attribute "$.body.decrypted.header.[~'x-insurantid']" matches "${kob.kvnrRise}"
    # outer response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    # inner response
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "201"
    Und TGR prüfe aktuelle Antwort im Knoten "$.body.decrypted.body" stimmt als JSON überein mit:
    """
    {
      "validTo" : "${json-unit.ignore}"
    }
    """

    # Wir überprüfen noch den Verkehr des Downloads selbst. Dazu müssen wir zunächst die Abfrage zum Auslösen des Downloads finden
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "(/epa/medication/api/v1/fhir/.*|/epa/medication/render/v1/eml/.*)" übereinstimmt

    # Nun prüfen wir die Struktur der Anfrage
    Dann TGR current request with attribute "$.method" matches "POST"
    Und TGR current request with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.[~'host']" matches "epa-as-1.ref.epa4all.de.*"
    Und TGR current request with attribute "$.header.[~'x-useragent']" matches "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"

    # Und nun die Struktur der inneren Anfrage (der VAU-verschlüsselte HTTP-Request)
    Und TGR current request with attribute "$.body.decrypted.method" matches "GET"
    Und TGR current request with attribute "$.body.decrypted.header.[~'x-insurantid']" matches "${kob.kvnrIbm}"
    Und TGR current request with attribute "$.body.decrypted.header.[~'x-useragent']" matches "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"

    # Nun prüfen wir die Antwort des Downloads. Damit stellen wir sicher, dass der Server die Anfrage korrekt verstanden hat
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"

    # Als letztes prüfen wir die Struktur der inneren Antwort (der VAU-verschlüsselte HTTP-Response)
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'content-type']" überein mit "(application\/fhir\+json|application\/pdf|text\/html.*)"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.body" überein mit ".*"
