# language: de
@Mandatory @KOB @EPA_3_1_3
Funktion: KOB Testfall 8: eML-eMP-Verknüpfung hinzufügen (manuell)

  Grundlage:
    Gegeben sei KOB Testsuite "Kob" Version "2.0.0-RC6"
    Gegeben sei KOB finde Aktensystem

  Szenariogrundriss: Testfall 8: eML-eMP-Verknüpfung hinzufügen (manuell)  (<AS>)
  Getestete Anforderungen: IG-MED18027VAP, IG-MED68008AH6
  Die Operation eML-eMP Verknüpfung hinzufügen ermöglicht dem Primärsystem einen eML-Eintrag mit einem eMP-Eintrag zu
  verknüpfen. Die Einträge werden verknüpft, indem das angegebene MedicationStatment mit dem eMP hinter dem übergebenen
  MedicationPlanIdentifier verlinkt werden. Wie bei allen Änderungen des eMP muss der Request die neuste ChronologyProvenanceID
  mitliefern um zu beweisen, dass die aktuellste Version genutzt wird.

    # Bereite Testumgebung vor
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    # Wir fragen an, dass die eML und eMP mit den angegebenen IDs verknüpft
    Wenn KOB verknüpfe im Aktensystem "<AS>" einen eML-Eintrag mit einem eMP-Eintrag des Patienten "<KVNR>"

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

    ### Wir überprüfen den Verkehr des Verlinken der eML-eMP
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "^/epa/medication/api/v1/fhir/MedicationStatement/[^/]+/\$link-emp(\?.*)?$" übereinstimmt

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
    Und FHIR request evaluiert FHIRPath "($this is Parameters) and parameter.count() = 2" mit Fehlermeldung "Der Request ist keine Parameters-Ressource oder enthält nicht genau zwei Parameter"

   # Profil: Link-eMP-Operation
    Und FHIR request evaluiert FHIRPath "meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/epa-op-link-emp-entry-parameters')).exists()" mit Fehlermeldung "Die Parameters-Ressource deklariert nicht das erwartete Profil für die Operation 'eML-Eintrag mit eMP-Eintrag verknüpfen'"

   # medicationPlanIdentifier
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medicationPlanIdentifier').count() = 1" mit Fehlermeldung "Der Parameter 'medicationPlanIdentifier' muss genau einmal vorhanden sein"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medicationPlanIdentifier').value.ofType(Identifier).where(system.toString() = 'https://gematik.de/fhir/sid/emp-identifier' and value.toString().matches('^[A-Za-z0-9.-]{1,64}$')).exists()" mit Fehlermeldung "Der medicationPlanIdentifier muss ein Identifier mit System 'https://gematik.de/fhir/sid/emp-identifier' und gültigem Werteformat sein"

   # acknowledgedChronologyId
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'acknowledgedChronologyId').count() = 1" mit Fehlermeldung "Der Parameter 'acknowledgedChronologyId' muss genau einmal vorhanden sein"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'acknowledgedChronologyId').value.ofType(id).exists() and parameter.where(name = 'acknowledgedChronologyId').value.ofType(id).toString().matches('^[A-Za-z0-9.-]{1,64}$')" mit Fehlermeldung "Der acknowledgedChronologyId hat nicht den erwarteten Datentyp id oder ein ungültiges Format"


    @IBM @Mandatory
    Beispiele: IBM_RU-REF
      | AS   | KVNR            | FQDN                    |
      | IBM  | ${kob.kvnrIbm}  | epa-as-1.ref.epa4all.de |

    @RISE @Mandatory
    Beispiele: RISE_RU-REF
      | AS   | KVNR            | FQDN                    |
      | RISE | ${kob.kvnrRise} | epa-as-2.ref.epa4all.de |
