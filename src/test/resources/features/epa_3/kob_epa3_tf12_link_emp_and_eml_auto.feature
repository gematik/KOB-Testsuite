# language: de
@Mandatory @KOB @EPA_3_1_3 @PVS @ZPVS @KIS
Funktion: KOB Testfall 12: Automatische eML-eMP-Verknüpfung durch E-Rezept

  Grundlage:
    Gegeben sei KOB Testsuite "Kob" Version "2.0.0-RC6"
    Gegeben sei KOB finde Aktensystem

  Szenariogrundriss: Testfall 12: Automatische eML-eMP-Verknüpfung durch E-Rezept (<AS>)
  Getestete Anforderungen: Gesamtintegration eMP-eML-E-Rezept
  Der Testfall validiert die durchgängige Verknüpfung zwischen Medikationsplan, E-Rezept und Medikationsliste.
  Dabei wird zunächst ein Medikationsplaneintrag angelegt, anschließend ein darauf basierendes E-Rezept erstellt und danach die Medikationsliste abgerufen.
  Abschließend wird geprüft, ob die Verknüpfung zwischen den erstellten Datensätzen korrekt in der Medikationsliste abgebildet und referenziert wird.

    # Bereite Testumgebung vor
    Gegeben sei TGR lösche aufgezeichnete Nachrichten
    Und TGR lösche die benutzerdefinierte Fehlermeldung

    # 1. eMP-Eintrag einstellen
    Wenn KOB füge einen neuen eMP-Eintrag im Aktensystem "<AS>" für das Aktenkonto des Patienten "<KVNR>" hinzu

    # medicationPlanIdentifier aus $add-emp-entry Antwort extrahieren und speichern
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "^\/epa\/medication\/api\/v1\/fhir\/\$add-emp-entry(\?.*)?$" übereinstimmt
    Und KOB speichere den medicationPlanIdentifier aus der aktuellen Antwort

   # 2. E-Rezept einstellen (Popup zeigt den gespeicherten eMP-Identifier an)
    Wenn KOB ein neues E-Rezept erstellt, übergibt er den eMP-Identifier aus dem EMP-Eintrag an das E-Rezept

    # 3. Get eML
    Wenn KOB rufe die Medikationsliste mit der FHIR Operation im Aktensystem "<AS>" für das Aktenkonto des Patienten "<KVNR>" ab

     ### Wir überprüfen noch den Verkehr des Abrufs der Medikationsliste
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.decrypted.path.basicPath" der mit "^\/epa\/medication\/api\/v1\/fhir\/\$medication-list$" übereinstimmt
    Und TGR current request with attribute "$.header.[~'host']" matches "<FQDN>.*"

    # Äußere Antwort prüfen
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.header.[~'content-type']" überein mit "application/octet-stream"

    # Innere Antwort prüfen
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.responseCode" überein mit "200"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.header.[~'content-type']" überein mit "(application\/fhir\+json|application\/fhir\+xml)"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.decrypted.body" überein mit ".*"

    # 4. rxPrescriptionProcessIdentifier aus eML-Antwort extrahieren (via gespeichertem medicationPlanIdentifier)
    Und KOB speichere den rxPrescriptionProcessIdentifier aus der aktuellen eML-Antwort

    # 5. Prüfung: MedicationStatement hat basedOn mit exaktem medicationPlanIdentifier + is-emp-extension
    Und FHIR response evaluiert FHIRPath "entry.resource.ofType(MedicationStatement).where(basedOn.where(reference = 'MedicationRequest/${kob.medicationPlanIdentifier}' and extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/is-emp-extension' and value.ofType(boolean) = true).exists()).exists()).exists()" mit Fehlermeldung "Die eML enthält kein MedicationStatement mit basedOn-Referenz auf MedicationRequest/${kob.medicationPlanIdentifier} und is-emp-extension=true"

    # 6. Prüfung: E-Rezept-MedicationRequest hat basedOn mit exaktem medicationPlanIdentifier in reference UND identifier
    Und FHIR response evaluiert FHIRPath "entry.resource.ofType(MedicationRequest).where(basedOn.where(reference = 'MedicationRequest/${kob.medicationPlanIdentifier}' and identifier.where(system = 'https://gematik.de/fhir/sid/emp-identifier' and value = '${kob.medicationPlanIdentifier}').exists()).exists()).exists()" mit Fehlermeldung "Der E-Rezept-MedicationRequest enthält keine basedOn-Verknüpfung mit reference UND identifier auf MedicationRequest/${kob.medicationPlanIdentifier}"

    # 7. Prüfung: MedicationStatement hat denselben rxPrescriptionProcessIdentifier
    Und FHIR response evaluiert FHIRPath "entry.resource.ofType(MedicationStatement).where(basedOn.where(reference = 'MedicationRequest/${kob.medicationPlanIdentifier}' and extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/is-emp-extension' and value.ofType(boolean) = true).exists()).exists() and extension.where(url = 'https://gematik.de/fhir/epa-medication/StructureDefinition/rx-prescription-process-identifier-extension' and value.ofType(Identifier).where(system = 'https://gematik.de/fhir/epa-medication/sid/rx-prescription-process-identifier' and value = '${kob.rxPrescriptionProcessIdentifier}').exists()).exists()).exists()" mit Fehlermeldung "Das eMP-verknüpfte MedicationStatement besitzt nicht den erwarteten rxPrescriptionProcessIdentifier ${kob.rxPrescriptionProcessIdentifier}"

    # 8. Prüfung: E-Rezept-MedicationRequest hat denselben rxPrescriptionProcessIdentifier
    Und FHIR response evaluiert FHIRPath "entry.resource.ofType(MedicationRequest).where(basedOn.where(reference = 'MedicationRequest/${kob.medicationPlanIdentifier}').exists() and identifier.where(system = 'https://gematik.de/fhir/epa-medication/sid/rx-prescription-process-identifier' and value = '${kob.rxPrescriptionProcessIdentifier}').exists()).exists()" mit Fehlermeldung "Der E-Rezept-MedicationRequest besitzt nicht den erwarteten rxPrescriptionProcessIdentifier ${kob.rxPrescriptionProcessIdentifier}"


    @IBM @Mandatory
    Beispiele: IBM_RU-REF
      | AS  | KVNR           | FQDN                    |
      | IBM | ${kob.kvnrIbm} | epa-as-1.ref.epa4all.de |

    @RISE @Mandatory
    Beispiele: RISE_RU-REF
      | AS   | KVNR            | FQDN                    |
      | RISE | ${kob.kvnrRise} | epa-as-2.ref.epa4all.de |