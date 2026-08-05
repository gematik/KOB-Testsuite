# language: de
@Mandatory @KOB @EPA_3_1_3 @PVS @ZPVS @KIS @AVS
Funktion: KOB Testfall 2: eMP-Eintrag aktualisieren

  Grundlage:
    Gegeben sei KOB Testsuite "Kob" Version "2.0.0-RC3"
    Gegeben sei KOB finde Aktensystem

  Szenariogrundriss: Testfall 2: eMP-Eintrag aktualisieren (nach Anweisung) (<AS>)
  Getestete Anforderungen: IG-MED04646V85, IG-MED15823A2P
  Die Operation eMP-Eintrag aktualisieren dient der gezielten Aktualisierung eines bestehenden Medikationseintrags im elektronischen Medikationsplan (eMP).
  Sie ermöglicht es, inhaltliche Änderungen an einer bereits dokumentierten Medikation vorzunehmen – beispielsweise um eine Notiz zu ergänzen,
  eine Dosierung zu verändern oder den Status des Eintrags zu aktualisieren.

    # Bereite Testumgebung vor
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    # Wir triggern das Aktualisieren eines existierenden eMP-Eintrags im vorgegebenen Format
    Wenn KOB aktualisiere einen neuen eMP-Eintrag im Aktensystem "<AS>" für das Aktenkonto des Patienten "<KVNR>"

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

    ### Wir überprüfen noch den Verkehr des Einstellen eines eMP-Eintrags. Dazu müssen wir zunächst die Abfrage zum Hinzufügen des eMP-Eintrags finden
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "^\/epa\/medication\/api\/v1\/fhir\/\$update-emp-entry(\?.*)?$" übereinstimmt

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

    # Grundstruktur: Parameters mit genau einer MedicationRequest in empEntry
    Und FHIR evaluiert FHIRPath "($this is Parameters) and parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).count() = 1" mit Fehlermeldung "Der Request enthält nicht die erwartete Parameters-Ressource mit genau einer MedicationRequest im Parameter 'empEntry'"

   # Profil: Parameters
    Und FHIR evaluiert FHIRPath "meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/epa-op-update-emp-entry-input-parameters')).exists()" mit Fehlermeldung "Die Parameters-Ressource deklariert nicht das erwartete Profil für die Operation 'eMP-Eintrag aktualisieren'"

    # Profil: MedicationRequest
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/emp-medication-request')).exists()" mit Fehlermeldung "Die MedicationRequest deklariert nicht das erwartete EMPMedicationRequest-Profil"

    # acknowledgedChronologyId: optional, aber falls vorhanden korrekt
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'acknowledgedChronologyId').empty() or (parameter.where(name = 'acknowledgedChronologyId').count() = 1 and parameter.where(name = 'acknowledgedChronologyId').value.ofType(id).count() = 1 and parameter.where(name = 'acknowledgedChronologyId').value.ofType(id).toString().matches('^[A-Za-z0-9.-]{1,64}$'))" mit Fehlermeldung "Der optionale Parameter 'acknowledgedChronologyId' hat nicht den erwarteten Datentyp oder ein ungültiges Format"

    # medicationPlanIdentifier
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationPlanIdentifier').value.ofType(Identifier).where(system.toString() = 'https://gematik.de/fhir/sid/emp-identifier' and value.toString().matches('^[A-Za-z0-9.-]{1,64}$')).count() = 1" mit Fehlermeldung "Der medicationPlanIdentifier muss ein Identifier mit System 'https://gematik.de/fhir/sid/emp-identifier' und gültigem Werteformat sein"

    # Kontext-Extension: MedicationRequest = 'EMP'
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension').exists()" mit Fehlermeldung "Die EMP-Kontext-Extension fehlt in der MedicationRequest"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension' and value.ofType(code) = 'EMP').exists()" mit Fehlermeldung "Die EMP-Kontext-Extension in MedicationRequest enthält nicht den erwarteten Code 'EMP'"

    # eMP-Identifier
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).identifier.where(system.toString() = 'https://gematik.de/fhir/sid/emp-identifier' and value.toString().matches('^[A-Za-z0-9.-]{1,64}$')).exists()" mit Fehlermeldung "Die MedicationRequest enthält keinen gültigen EMP-Identifier"

   # MedicationRequest.intent = 'plan'
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).intent.toString() = 'plan'" mit Fehlermeldung "Das Element 'intent' fehlt oder entspricht nicht dem erwarteten Wert 'plan'"

    # 1. Status = 'on-hold'
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).status.toString() = 'on-hold'" mit Fehlermeldung "Der Status fehlt oder entspricht nicht dem erwarteten Wert 'on-hold'"

    # 2. Medication-Referenz
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).medication.reference.toString().matches('^Medication/[A-Za-z0-9.-]{1,64}$')" mit Fehlermeldung "Die Medication-Referenz fehlt oder entspricht nicht dem erwarteten Format 'Medication/<ID>'"

    # 3. Gerenderte Dosieranweisung (markdown)
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.renderedDosageInstruction').exists()" mit Fehlermeldung "Die Extension für die gerenderte Dosieranweisung fehlt"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.renderedDosageInstruction' and value.ofType(markdown).where(toString().trim().length() > 0).exists()).exists()" mit Fehlermeldung "Die gerenderte Dosieranweisung fehlt, hat den falschen Datentyp oder ist leer"

    # 4. Dosieranweisung: Freitext ODER strukturiert mit täglich 08:00 Uhr, 1 Stück
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).dosageInstruction.exists()" mit Fehlermeldung "Die MedicationRequest enthält keine Dosieranweisung"
    Und FHIR evaluiert FHIRPath "(parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).dosageInstruction.text.where(toString().trim().length() > 0).exists()) or (parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).dosageInstruction.where(timing.repeat.frequency = 1 and timing.repeat.period = 1 and timing.repeat.periodUnit.toString() = 'd' and timing.repeat.timeOfDay.count() = 1 and timing.repeat.timeOfDay.where(toString() = '08:00:00').count() = 1 and doseAndRate.dose.ofType(Quantity).where(value = 1 and unit.toString() = 'Stück' and system.toString() = 'https://fhir.kbv.de/CodeSystem/KBV_CS_SFHIR_BMP_DOSIEREINHEIT' and code.toString() = '1').exists()).exists())" mit Fehlermeldung "Weder eine textuelle Dosieranweisung noch die erwartete strukturierte Dosierung 'täglich um 08:00 Uhr — je 1 Stück' ist vorhanden"

    # 5. Patientenbezug
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).subject.identifier.where(system.toString() = 'http://fhir.de/sid/gkv/kvid-10' and value.exists()).exists()" mit Fehlermeldung "Der Patientenbezug enthält keinen KVNR-Identifier mit einem Wert"

    @IBM @Mandatory
    Beispiele: IBM_RU-REF

      | AS  | KVNR           | FQDN                    |
      | IBM | ${kob.kvnrIbm} | epa-as-1.ref.epa4all.de |

    @RISE @Mandatory
    Beispiele: RISE_RU-REF

      | AS   | KVNR            | FQDN                    |
      | RISE | ${kob.kvnrRise} | epa-as-2.ref.epa4all.de |
