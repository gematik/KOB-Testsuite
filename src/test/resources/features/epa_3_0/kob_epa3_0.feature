# language: de
@KOB @MANDATORY @EPA_3_0
Funktion: KOB Testsuite for EPA 3.0

  Szenario: Download EML
    # Bereite Testumgebung vor
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung
    Und KOB setze alle EPA sessions des Primärsystems zurück
    Und KOB stecke EGK mit der KVNR "${kob.kvnr}"
    # Aktensystem-Lokalisierung und Entitlement auf der Akte sind nicht im Scope dieses Tests.
    # Sie müssen implizit durchgeführt werden oder schon durchgeführt worden sein.
    # Das Login auf dem Aktensystem wird hier ebenfalls nicht betrachtet.

    # Testfall: EML Download. Wir lösen den Download aus (entweder über die Testtreiber-API oder manuell über die UI)
    # Vergleiche kob.yaml: kob.useTestdriverApi
    # Das Format des Downloads kann frei gewählt werden
    Wenn KOB downloade die EML für die KVNR "${kob.kvnr}" im Format "${kob.emlType}"
    # Der Screenshot wird händisch von der gematik überprüft. Er soll die Anzeige des EML in der UI demonstrieren
    Und KOB speichere einen Screenshot der letzten Aktion in der Datei "target/screenshots/eml_${kob.emlType}.png"

    # Wir überprüfen noch den Verkehr des Downloads selbst. Dazu müssen wir zunächst die Abfrage zum Auslösen des Downloads finden
    Dann TGR die Fehlermeldung wird gesetzt auf: "Eine EML-Download Nachricht konnte nicht gefunden werden!"
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "/epa/medication/render/v1/eml/.*" übereinstimmt

    # Nun prüfen wir die Struktur der Anfrage
    Und TGR die Fehlermeldung wird gesetzt auf: "Der äußere Request des EML Downloads ist nicht korrekt"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.method" überein mit "POST"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'accept']" überein mit ".*application/octet-stream.*"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    # In nicht-PU Umgebungen muss der Client (das Primärsystem) die verwendeten Schlüssel (K2_c2s_app_data und K2_s2c_app_data)
    # Base64 kodiert im Header "VAU-nonPU-Tracing" übertragen. Diese Schlüssel dürfen NICHT in der PU übertragen werden.
    Und TGR prüfe aktueller Request stimmt im Knoten "$.header.[~'VAU-nonPU-Tracing']" überein mit "[A-Za-z0-9+\/]{41,44}=? [A-Za-z0-9+\/]{41,44}=?"

    # Und nun die Struktur der inneren Anfrage (der VAU-verschlüsselte HTTP-Request)
    Und TGR die Fehlermeldung wird gesetzt auf: "Der innere Request des EML Downloads ist nicht korrekt"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.method" überein mit "GET"
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.decrypted.header.[~'accept']" überein mit ".*/.*"

    # Nun prüfen wir die Antwort des Downloads. Damit stellen wir sicher, dass der Server die Anfrage korrekt verstanden hat
    Und TGR die Fehlermeldung wird gesetzt auf: "Die äußere Response des EML Downloads ist nicht korrekt"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"

    # Als letztes prüfen wir die Struktur der inneren Antwort (der VAU-verschlüsselte HTTP-Response)
    Und TGR die Fehlermeldung wird gesetzt auf: "Die innere Response des EML Downloads ist nicht korrekt"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'content-type']" überein mit "application/.*"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.body" überein mit ".*"
