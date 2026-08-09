# language: de
@Mandatory @KOB @EPA_3_1_3 @PVS @ZPVS @KIS @AVS
Funktion: KOB Testfall 6: eML-Eintrag hinzufügen

  Grundlage:
    Gegeben sei KOB Testsuite "Kob" Version "2.0.0-RC5"
    Gegeben sei KOB finde Aktensystem

  Szenariogrundriss: Testfall 6: eML-Eintrag hinzufügen (<AS>)
  Getestete Anforderungen: IG-MED49098H1E, IG-MED11340RGW
  Die Operation eML-Eintrag hinzufügen ermöglicht das gezielte Hinzufügen oder Nachtragen eines Medikationseintrags zur elektronischen Medikationsliste (eML). Anhand der Eingangsdaten werden im Medication Service folgende FHIR-Artefakte erzeugt bzw. aktualisiert.

    # Bereite Testumgebung vor
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    # Wir triggern das Hinzufügen eines neuen eML-Eintrags im vorgegebenen Format
    Wenn KOB füge einen neuen eML-Eintrag im Aktensystem "<AS>" für das Aktenkonto des Patienten "<KVNR>" hinzu

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

    ### Wir überprüfen noch den Verkehr des Einstellen eines eML-Eintrags. Dazu müssen wir zunächst die Anfrage zum Hinzufügen des eML-Eintrags finden
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "^\/epa\/medication\/api\/v1\/fhir\/MedicationStatement\/\$add-eml-entry(\?.*)?$" übereinstimmt

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

    # Grundstruktur: Parameters mit MedicationStatement und Medication
    Und FHIR evaluiert FHIRPath "($this is Parameters) and parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).count() = 1 and parameter.where(name = 'medication').resource.ofType(Medication).count() = 1" mit Fehlermeldung "Der Request enthält nicht genau einen Parameter 'medicationStatement' mit MedicationStatement und einen Parameter 'medication' mit Medication"

    # Profil: Parameters für add-eML-entry
    Und FHIR evaluiert FHIRPath "meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/epa-op-add-eml-entry-input-parameters')).exists()" mit Fehlermeldung "Die Parameters-Ressource deklariert nicht das erwartete Profil für die Operation 'eML-Eintrag hinzufügen'"

    # Profil: MedicationStatement
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/epa-medication-statement')).exists()" mit Fehlermeldung "Das MedicationStatement deklariert nicht das erwartete EPAMedicationStatement-Profil"

    # Profil: Medication
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).meta.profile.where(startsWith('https://gematik.de/fhir/epa-medication/StructureDefinition/epa-medication')).exists()" mit Fehlermeldung "Die Medication deklariert nicht das erwartete EPAMedication-Profil"

    # eML-Eintrag wurde manuell erstellt
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension').exists()" mit Fehlermeldung "Die Kontext-Extension fehlt im MedicationStatement"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension' and value.ofType(code).toString() = 'MANUAL').exists()" mit Fehlermeldung "Die Kontext-Extension des MedicationStatement enthält nicht den erwarteten Code 'MANUAL'"

    # 1. Gerenderte Dosieranweisung
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationStatement.renderedDosageInstruction').exists()" mit Fehlermeldung "Die Extension für die gerenderte Dosieranweisung fehlt"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).extension.where(url = 'http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationStatement.renderedDosageInstruction' and value.ofType(markdown).where(toString().trim().length() > 0).exists()).exists()" mit Fehlermeldung "Die gerenderte Dosieranweisung fehlt, hat den falschen Datentyp oder ist leer"

    # 2. Dosieranweisung: strukturiert oder Freitext
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).dosage.exists()" mit Fehlermeldung "Das MedicationStatement enthält keine Dosieranweisung"
    Und FHIR evaluiert FHIRPath "(parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).dosage.text.where(toString().trim().length() > 0).exists()) or (parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).dosage.where(timing.repeat.frequency = 4 and timing.repeat.period = 1 and timing.repeat.periodUnit.toString() = 'd' and timing.repeat.when.count() = 4 and timing.repeat.when.where(toString() = 'MORN').count() = 1 and timing.repeat.when.where(toString() = 'NOON').count() = 1 and timing.repeat.when.where(toString() = 'EVE').count() = 1 and timing.repeat.when.where(toString() = 'NIGHT').count() = 1 and doseAndRate.dose.ofType(Quantity).where(value = 1 and unit.toString() = 'Stück' and system.toString() = 'https://fhir.kbv.de/CodeSystem/KBV_CS_SFHIR_BMP_DOSIEREINHEIT' and code.toString() = '1').exists()).exists())" mit Fehlermeldung "Weder eine textuelle Dosierung noch die erwartete strukturierte Dosierung '1-1-1-1 Stück' ist vorhanden"

    # 3. Handelsname
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).code.exists()" mit Fehlermeldung "Die Medication enthält keine Arzneimittelbezeichnung in 'code'"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).code.text.where(matches('(?i).*Benazepril.*')).exists()" mit Fehlermeldung "Der Handelsname fehlt oder enthält nicht den erwarteten Text 'Benazepril'"

    # 4. PZN: optional, aber falls vorhanden mit erwarteten Testdaten
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).code.coding.where(system.toString() = 'http://fhir.de/CodeSystem/ifa/pzn').empty() or (parameter.where(name = 'medication').resource.ofType(Medication).code.coding.where(system.toString() = 'http://fhir.de/CodeSystem/ifa/pzn').count() = 1 and parameter.where(name = 'medication').resource.ofType(Medication).code.coding.where(system.toString() = 'http://fhir.de/CodeSystem/ifa/pzn' and code.toString() = '04351682' and display.toString() = 'Benazepril AL 5 mg Filmtabletten 98 Stk.').count() = 1)" mit Fehlermeldung "Die angegebene PZN-Codierung entspricht nicht den erwarteten Werten"

    # 5. Wirkstoff: Benazepril hydrochlorid mit ASK-Code 22686
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).ingredient.exists()" mit Fehlermeldung "Die Medication enthält keinen Wirkstoff"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).ingredient.where(item.ofType(CodeableConcept).text.toString() = 'Benazepril hydrochlorid' and item.ofType(CodeableConcept).coding.where(system.toString() = 'http://fhir.de/CodeSystem/ask' and code.toString() = '22686').exists()).exists()" mit Fehlermeldung "Kein Wirkstoff enthält die Bezeichnung 'Benazepril hydrochlorid' und den ASK-Code '22686'"

    # 6. Wirkstärke: 5 mg strukturiert oder Freitext
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).ingredient.strength.exists()" mit Fehlermeldung "Für den Wirkstoff ist keine Wirkstärke angegeben"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).ingredient.where(strength.extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/medication-ingredient-amount-extension' and value.ofType(string).where(matches('(?i).*5\\s*mg.*')).exists()).exists() or (strength.numerator.value = 5 and strength.numerator.unit.toString().matches('(?i)^mg$') and strength.denominator.value = 1)).exists()" mit Fehlermeldung "Die Wirkstärke entspricht weder der erwarteten Freitextangabe '5 mg' noch dem erwarteten strukturierten Verhältnis mit 5 mg und der Bezugsmenge 1"

    # 7. Darreichungsform: KBV FTA
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).form.exists()" mit Fehlermeldung "Die Darreichungsform der Medication fehlt"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).form.coding.where(system.toString() = 'https://fhir.kbv.de/CodeSystem/KBV_CS_SFHIR_KBV_DARREICHUNGSFORM').exists()" mit Fehlermeldung "Die Darreichungsform enthält keine Codierung aus dem erwarteten KBV-Codesystem"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medication').resource.ofType(Medication).form.coding.where(system = 'https://fhir.kbv.de/CodeSystem/KBV_CS_SFHIR_KBV_DARREICHUNGSFORM' and code = 'FTA' and (display.empty() or display.matches('(?i)^(FTA|Filmtablette[n]?|Filmtabl[.])$'))).exists()" mit Fehlermeldung "Die Darreichungsform enthält nicht den erwarteten KBV-Code 'FTA' oder ein vorhandenes display ist ungültig"

    # 8. Medication-Referenz im MedicationStatement
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).medication.reference.exists()" mit Fehlermeldung "Die Medication-Referenz fehlt im MedicationStatement"
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).medication.reference.where(matches('^Medication/[A-Za-z0-9.-]{1,64}$')).exists()" mit Fehlermeldung "Die Medication-Referenz entspricht nicht dem erwarteten Format 'Medication/<ID>'"

    # 9. Medication-Referenz verweist auf die enthaltene Medication
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).medication.reference.toString() = ('Medication/' + parameter.where(name = 'medication').resource.ofType(Medication).id.toString())" mit Fehlermeldung "Die Medication-Referenz im MedicationStatement verweist nicht auf die im Request enthaltene Medication"

    # 10. Patientenbezug
    Und FHIR evaluiert FHIRPath "parameter.where(name = 'medicationStatement').resource.ofType(MedicationStatement).subject.identifier.where(system.toString() = 'http://fhir.de/sid/gkv/kvid-10' and value.exists()).exists()" mit Fehlermeldung "Der Patientenbezug enthält keinen KVNR-Identifier mit einem Wert"

    @IBM @Mandatory
    Beispiele: IBM_RU-REF
      | AS   | KVNR            | FQDN                    |
      | IBM  | ${kob.kvnrIbm}  | epa-as-1.ref.epa4all.de |

    @RISE @Mandatory
    Beispiele: RISE_RU-REF
      | AS   | KVNR            | FQDN                    |
      | RISE | ${kob.kvnrRise} | epa-as-2.ref.epa4all.de |
