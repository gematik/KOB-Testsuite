# language: de
@KOB @EPA_3_1_3 @PVS @ZPVS @KIS @AVS
Funktion: KOB Testfall 9: eML-eMP-Verknüpfung entfernen

  Grundlage:
    Gegeben sei KOB Testsuite "Kob" Version "2.0.0-RC5"
    Gegeben sei KOB finde Aktensystem

  Szenariogrundriss: Testfall 9: eML-eMP-Verknüpfung entfernen (<AS>)
  Getestete Anforderungen: IG-MED55518RUD, IG-MED76653G6V
  Die Operation eML-eMP-Verknüpfung entfernen ermöglicht es dem Primärsystem, einen eML-Eintrag von einem eMP-Eintrag zu trennen.
  Dazu wird das angegebene MedicationStatement von dem eMP entlinkt, der durch den übergebenen MedicationPlanIdentifier identifiziert wird.
  Wie bei allen Änderungen am eMP muss der Request die ID der neuesten ChronologyProvenance enthalten. Dadurch wird sichergestellt, dass die Änderung auf Grundlage der aktuellen Version des eMP erfolgt.

    # Bereite Testumgebung vor
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    # Wir fragen an, dass die Verknüpfung zwischen eML und eMP mit den angegebenen IDs entfernt wird
    Wenn KOB entferne im Aktensystem "<AS>" einen eML-Eintrag von einem eMP-Eintrag des Patienten "<KVNR>"

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

    ### Wir überprüfen den Verkehr des Entfernen der eML-eMP Verknüpfung
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "^/epa/medication/api/v1/fhir/MedicationStatement/[^/]+/\$unlink-emp(\?.*)?$" übereinstimmt


    # Nun prüfen wir die Struktur der äußeren Anfrage
    Dann TGR current request with attribute "$.method" matches "POST"
    Und TGR current request with attribute "$.header.[~'content-type']" matches "application/octet-stream"
    Und TGR current request with attribute "$.header.[~'host']" matches "<FQDN>.*"
    Und TGR current request with attribute "$.header.[~'x-useragent']" matches "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"

    # Und nun die Struktur der inneren Anfrage (der VAU-verschlüsselte HTTP-Request)
    Und TGR current request with attribute "$.body.decrypted.method" matches "POST"
    Und TGR current request with attribute "$.body.decrypted.header.[~'accept']" matches "(application\/fhir\+json|application\/fhir\+xml)"
    Und TGR current request with attribute "$.body.decrypted.header.[~'X-Requesting-Organization']" matches ".*"
    Und TGR current request with attribute "$.body.decrypted.header.[~'X-Request-ID']" matches "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
    Und TGR current request with attribute "$.body.decrypted.header.[~'x-insurantid']" matches "<KVNR>"
    Und TGR current request with attribute "$.body.decrypted.header.[~'x-useragent']" matches "^[a-zA-Z0-9\-]{1,20}\/[a-zA-Z0-9\-\.]{1,15}$"

    # Nun prüfen wir die äußere Antwort. Damit stellen wir sicher, dass der Server die Anfrage korrekt verstanden hat
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"

    # Als letztes prüfen wir die Struktur der inneren Antwort (der VAU-verschlüsselte HTTP-Response)
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'content-type']" überein mit "(application\/fhir\+json|application\/fhir\+xml)"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.body" überein mit ".*"

   # Grundstruktur: Parameters mit genau zwei Parametern
    Und FHIR evaluiert FHIRPath "($this is Parameters) and parameter.count() = 2" mit Fehlermeldung "Der Request ist keine Parameters-Ressource oder enthält nicht genau zwei Parameter"

   # Profil: Unlink-eMP-Operation
    Und FHIR evaluiert FHIRPath "meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/epa-op-link-emp-entry-parameters')).exists()" mit Fehlermeldung "Die Parameters-Ressource deklariert nicht das erwartete Profil für die Operation 'eML-eMP-Verknüpfung entfernen'"

   # medicationPlanIdentifier
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationPlanIdentifier').count() = 1" mit Fehlermeldung "Der Parameter 'medicationPlanIdentifier' muss genau einmal vorhanden sein"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationPlanIdentifier').value.ofType(Identifier).where(system.toString() = 'https://gematik.de/fhir/sid/emp-identifier' and value.toString().matches('^[A-Za-z0-9.-]{1,64}$')).exists()" mit Fehlermeldung "Der medicationPlanIdentifier muss ein Identifier mit System 'https://gematik.de/fhir/sid/emp-identifier' und gültigem Werteformat sein"

   # acknowledgedChronologyId
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'acknowledgedChronologyId').count() = 1" mit Fehlermeldung "Der Parameter 'acknowledgedChronologyId' muss genau einmal vorhanden sein"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'acknowledgedChronologyId').value.ofType(id).exists() and parameter.where(name = 'acknowledgedChronologyId').value.ofType(id).toString().matches('^[A-Za-z0-9.-]{1,64}$')" mit Fehlermeldung "Der acknowledgedChronologyId hat nicht den erwarteten Datentyp id oder ein ungültiges Format"


    @IBM @Mandatory
    Beispiele: IBM_RU-REF
      | AS   | KVNR            | FQDN                    |
      | IBM  | ${kob.kvnrIbm}  | epa-as-1.ref.epa4all.de |

    @RISE @Mandatory
    Beispiele: RISE_RU-REF
      | AS   | KVNR            | FQDN                    |
      | RISE | ${kob.kvnrRise} | epa-as-2.ref.epa4all.de |
