# language: de
@Mandatory @KOB @EPA_3_1_3
Funktion: KOB Testfall 1: eMP-Eintrag hinzufügen

  Grundlage:
    Gegeben sei KOB Testsuite "Kob" Version "2.0.0-RC6"
    Gegeben sei KOB finde Aktensystem

  Szenariogrundriss: Testfall 1: eMP-Eintrag hinzufügen (<AS>)
  Getestete Anforderungen: IG-MED32621WGJ, IG-MED75797HAU
  Die Operation eMP-Eintrag hinzufügen ermöglicht das gezielte Einfügen eines neuen Medikationseintrags in den elektronischen Medikationsplan (eMP).
  Dabei werden zwei Ressourcen kombiniert, die gemeinsam den vollständigen fachlichen Kontext der Medikation abbilden:
  eine MedicationRequest-Instanz mit dem intent plan sowie eine zugehörige Medication-Instanz.
  Die MedicationRequest-Ressource muss dabei stets dem fachlichen FHIR-Profil EMPMedicationRequest entsprechen.

    # Bereite Testumgebung vor
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    # Wir triggern das Hinzufügen eines neuen eMP-Eintrags im vorgegebenen Format
    Wenn KOB füge einen neuen eMP-Eintrag im Aktensystem "<AS>" für das Aktenkonto des Patienten "<KVNR>" hinzu

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

    ### Wir überprüfen noch den Verkehr des Einstellen eines eMP-Eintrags. Dazu müssen wir zunächst die Anfrage zum Hinzufügen des eMP-Eintrags finden
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "^\/epa\/medication\/api\/v1\/fhir\/\$add-emp-entry(\?.*)?$" übereinstimmt

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

    # Grundstruktur: Parameters mit MedicationRequest und Medication
    Und FHIR request evaluiert FHIRPath "($this is Parameters) and parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).count() = 1 and parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).count() = 1" mit Fehlermeldung "Der Request enthält nicht genau einen Parameter 'empEntry' mit MedicationRequest und einen Parameter 'medication' mit Medication-Ressource"

    # Profil: Parameters
    Und FHIR request evaluiert FHIRPath "meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/epa-op-add-emp-entry-input-parameters')).exists()" mit Fehlermeldung "Die Parameters-Ressource deklariert nicht das erwartete Profil für die Operation 'eMP-Eintrag hinzufügen'"

    # Profil: Medication
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/emp-medication')).exists()" mit Fehlermeldung "Die Medication deklariert nicht das erwartete EMPMedication-Profil"

    # Profil: MedicationRequest
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/emp-medication-request')).exists()" mit Fehlermeldung "Die MedicationRequest deklariert nicht das erwartete EMPMedicationRequest-Profil"

    # MedicationRequest.intent = 'plan'
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).intent.exists()" mit Fehlermeldung "Das Element 'intent' der MedicationRequest fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).where(intent.toString() = 'plan').exists()" mit Fehlermeldung "Das Element 'intent' entspricht nicht dem erwarteten Wert 'plan'"

    # Kontext-Extension: MedicationRequest = 'EMP'
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension').exists()" mit Fehlermeldung "Die EMP-Kontext-Extension fehlt in der MedicationRequest"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension' and value.ofType(code) = 'EMP').exists()" mit Fehlermeldung "Die EMP-Kontext-Extension in MedicationRequest enthält nicht den erwarteten Code 'EMP'"

    # Kontext-Extension: Medication = 'EMP'
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension').exists()" mit Fehlermeldung "Die EMP-Kontext-Extension fehlt in der Medication"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension' and value.ofType(code) = 'EMP').exists()" mit Fehlermeldung "Die EMP-Kontext-Extension in Medication enthält nicht den erwarteten Code 'EMP'"

    # 1. Indikation (ICD-10-GM): I11
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).reasonCode.exists()" mit Fehlermeldung "Die MedicationRequest enthält keine Indikation in 'reasonCode'"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).reasonCode.coding.where(system = 'http://fhir.de/CodeSystem/bfarm/icd-10-gm').exists()" mit Fehlermeldung "Die MedicationRequest enthält keine ICD-10-GM-Codierung"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).reasonCode.coding.where(system = 'http://fhir.de/CodeSystem/bfarm/icd-10-gm' and code = 'I11').exists()" mit Fehlermeldung "Die ICD-10-GM-Codierung enthält nicht den erwarteten Code 'I11'"

    # 2. Grund (Freitext): Bluthochdruck
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/reason-patient-instruction-extension').exists()" mit Fehlermeldung "Die Extension für den Begründungstext fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/reason-patient-instruction-extension' and value.ofType(string).exists()).exists()" mit Fehlermeldung "Die Extension für den Begründungstext enthält keinen Wert vom Typ string"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/reason-patient-instruction-extension' and value.ofType(string) = 'Bluthochdruck').exists()" mit Fehlermeldung "Der Begründungstext entspricht nicht dem erwarteten Wert 'Bluthochdruck'"

    # 3. Gerenderte Dosieranweisung (markdown)
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.renderedDosageInstruction').exists()" mit Fehlermeldung "Die Extension für die gerenderte Dosieranweisung fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.renderedDosageInstruction' and value.ofType(markdown).where(toString().trim().length() > 0).exists()).exists()" mit Fehlermeldung "Die gerenderte Dosieranweisung fehlt, hat den falschen Datentyp oder ist leer"

    # 4. Dosieranweisung (strukturiert oder Freitext)
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).dosageInstruction.exists()" mit Fehlermeldung "Die MedicationRequest enthält keine Dosieranweisung"
    Und FHIR request evaluiert FHIRPath "(parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).dosageInstruction.text.where(toString().trim().length() > 0).exists()) or (parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).dosageInstruction.where(timing.repeat.frequency = 2 and timing.repeat.period = 1 and timing.repeat.periodUnit = 'd' and timing.repeat.when.count() = 2 and timing.repeat.when.where($this = 'MORN').count() = 1 and timing.repeat.when.where($this = 'EVE').count() = 1 and doseAndRate.dose.ofType(Quantity).where(value = 1 and unit = 'Stück' and system = 'https://fhir.kbv.de/CodeSystem/KBV_CS_SFHIR_BMP_DOSIEREINHEIT' and code = '1').exists()).exists())" mit Fehlermeldung "Weder textuelle noch strukturierte Dosieranweisung vorhanden"

    # 5. Hinweis für Versicherte
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/patient-note-extension').exists()" mit Fehlermeldung "Die Extension für den Hinweis für Versicherte fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/patient-note-extension' and value.ofType(Annotation).text.toString().trim().length() > 0).exists()" mit Fehlermeldung "Hinweis für Versicherte fehlt oder ist leer"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/patient-note-extension' and value.ofType(Annotation).text.toString().matches('(?i).*Schwindel verursachen.*')).exists()" mit Fehlermeldung "Der Hinweis für Versicherte enthält nicht den erwarteten Inhalt 'Schwindel verursachen'"

    # 6. Hinweis für Mitbehandelnde
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).note.where(text.exists()).exists()" mit Fehlermeldung "Hinweis für Mitbehandelnde fehlt vollständig"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).note.where(text = 'Hinweis für LE').exists()" mit Fehlermeldung "Der Hinweis für Mitbehandelnde entspricht nicht dem erwarteten Wert 'Hinweis für LE'"

    # 7. Status = 'active'
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).status.exists()" mit Fehlermeldung "Der Status der MedicationRequest fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).where(status.toString() = 'active').exists()" mit Fehlermeldung "Der Status entspricht nicht dem erwarteten Wert 'active'"

    # 8. Anwendungszeitraum (Period mit start/end)
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.effectiveDosePeriod').exists()" mit Fehlermeldung "Die Extension für den Anwendungszeitraum fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.effectiveDosePeriod').value.ofType(Period).exists()" mit Fehlermeldung "Die Extension für den Anwendungszeitraum enthält keinen Wert vom Typ Period"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.effectiveDosePeriod').value.ofType(Period).start.exists()" mit Fehlermeldung "Das Startdatum des Anwendungszeitraums fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.effectiveDosePeriod').value.ofType(Period).end.exists()" mit Fehlermeldung "Das Enddatum des Anwendungszeitraums fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.effectiveDosePeriod').value.ofType(Period).where(start <= end).exists()" mit Fehlermeldung "Das Startdatum des Anwendungszeitraums liegt nach dem Enddatum"

    # Anwendungszeitraum: Datumsformat-Validierung
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.effectiveDosePeriod').value.ofType(Period).start.toString().matches('^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\\.[0-9]+)?(Z|(\\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00)))?$')" mit Fehlermeldung "Anwendungszeitraum: Startdatum hat ungültiges Format"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.effectiveDosePeriod').value.ofType(Period).end.toString().matches('^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\\.[0-9]+)?(Z|(\\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00)))?$')" mit Fehlermeldung "Anwendungszeitraum: Enddatum hat ungültiges Format"

    # 9. Handelsname (Freitext)
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).code.exists()" mit Fehlermeldung "Die Medication enthält keine Arzneimittelbezeichnung in 'code'"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).code.text.exists()" mit Fehlermeldung "Der Handelsname der Medication fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).code.text.where(matches('(?i).*Benazepril.*')).exists()" mit Fehlermeldung "Der Handelsname enthält nicht den erwarteten Text 'Benazepril'"

    # 10. PZN (optional, aber falls vorhanden korrekt)
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).code.coding.where(system = 'http://fhir.de/CodeSystem/ifa/pzn').empty() or (parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).code.coding.where(system = 'http://fhir.de/CodeSystem/ifa/pzn').count() = 1 and parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).code.coding.where(system = 'http://fhir.de/CodeSystem/ifa/pzn' and code = '04351736').count() = 1)" mit Fehlermeldung "Die angegebene PZN-Codierung entspricht nicht den erwarteten Werten"

    # 11. Wirkstoff (ASK-Code 23413)
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).ingredient.exists()" mit Fehlermeldung "Die Medication enthält keinen Wirkstoff"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).ingredient.where(item.ofType(CodeableConcept).text = 'Benazepril hydrochlorid' and item.ofType(CodeableConcept).coding.where(system = 'http://fhir.de/CodeSystem/ask' and code = '23413').exists()).exists()" mit Fehlermeldung "Kein Wirkstoff enthält die Bezeichnung 'Benazepril hydrochlorid' und den ASK-Code '23413'"

    # 12. Wirkstärke (20 mg strukturiert oder Freitext)
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).ingredient.strength.exists()" mit Fehlermeldung "Für den Wirkstoff ist keine Wirkstärke angegeben"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).ingredient.where(strength.extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/medication-ingredient-amount-extension' and value.ofType(string).where(matches('(?i).*20\\s*mg.*')).exists()).exists() or (strength.numerator.value = 20 and strength.numerator.unit.toString().matches('(?i)^mg$') and strength.denominator.value = 1)).exists()" mit Fehlermeldung "Die Wirkstärke entspricht weder der erwarteten Freitextangabe '20 mg' noch dem erwarteten strukturierten Verhältnis mit 20 mg und der Bezugsmenge 1"

    # 13. Darreichungsform (KBV: FTA)
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).form.exists()" mit Fehlermeldung "Die Darreichungsform der Medication fehlt"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).form.coding.where(system = 'https://fhir.kbv.de/CodeSystem/KBV_CS_SFHIR_KBV_DARREICHUNGSFORM').exists()" mit Fehlermeldung "Die Darreichungsform enthält keine Codierung aus dem erwarteten KBV-Codesystem"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'medication').part.where(name = 'resource').resource.ofType(Medication).form.coding.where(system = 'https://fhir.kbv.de/CodeSystem/KBV_CS_SFHIR_KBV_DARREICHUNGSFORM' and code = 'FTA' and (display.empty() or display.matches('(?i)^(FTA|Filmtablette[n]?|Filmtabl[.])$'))).exists()" mit Fehlermeldung "Die Darreichungsform enthält nicht den erwarteten KBV-Code 'FTA' oder ein vorhandenes display ist ungültig"

    # 14. Medication-Referenz (relativ)
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).medication.reference.exists()" mit Fehlermeldung "Die Medication-Referenz fehlt in der MedicationRequest"
    Und FHIR request evaluiert FHIRPath "parameter.where(name = 'empEntry').resource.ofType(MedicationRequest).medication.reference.where(matches('^Medication/.+$')).exists()" mit Fehlermeldung "Die Medication-Referenz entspricht nicht dem erwarteten Format 'Medication/<ID>'"

    @IBM @Mandatory
    Beispiele: IBM_RU-REF
      | AS   | KVNR            | FQDN                    |
      | IBM  | ${kob.kvnrIbm}  | epa-as-1.ref.epa4all.de |

    @RISE @Mandatory
    Beispiele: RISE_RU-REF
      | AS   | KVNR            | FQDN                    |
      | RISE | ${kob.kvnrRise} | epa-as-2.ref.epa4all.de |
