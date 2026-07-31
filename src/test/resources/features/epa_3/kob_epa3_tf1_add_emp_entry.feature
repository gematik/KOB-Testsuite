# language: de
@Mandatory @KOB @EPA_3_1_3 @PVS @ZPVS @KIS @AVS
Funktion: KOB Testfall 1: eMP-Eintrag hinzufügen

  Grundlage:
    Gegeben sei KOB Testsuite "Kob" Version "2.0.0-RC1"
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

    # eMP Eintrag
    Und TGR current request at "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.extension.[?(@..url =$ 'context-extension')]" matches as JSON:
    """
    {
      "url" : "https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension",
      "valueCode" : "EMP"
    }
    """

    # 1. Indikation (ICD-10-Code): I11
    Und TGR current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.reasonCode.[?(@..system=$'icd-10-gm')].coding.[?(@..system=$'icd-10-gm')].code" matches "I11"

    # 2. Grund (Freitext): Bluthochdruck
    Und TGR current request at "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.extension.[?(@..url =$ 'reason-patient-instruction-extension')]" matches as JSON:
    """
    {
      "url" : "https://gematik.de/fhir/epa-medication/StructureDefinition/reason-patient-instruction-extension",
      "valueString" : "Bluthochdruck"
    }
    """

    # 3. Dosierangabe (strukturiert oder Freitext)
    Und TGR current request at "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.extension.[?(@..url =$ 'renderedDosageInstruction')]" matches as JSON:
    """
    {
      "url" : "http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationRequest.renderedDosageInstruction",
      "valueMarkdown" : "${json-unit.ignore}"
    }
    """
    Und KOB current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.dosageInstruction.[*].text" matches ".*" or at "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.dosageInstruction.[*]" matches as JSON:
    """
    {
      "timing" : {
        "repeat" : {
          "frequency" : 2,
          "period" : 1,
          "periodUnit" : "d",
          "when" : [
            "MORN",
            "EVE"
          ]
        }
      },
      "doseAndRate" : [
        {
          "doseQuantity" : {
            "value" : 1,
            "unit" : "Stück",
            "system" : "https://fhir.kbv.de/CodeSystem/KBV_CS_SFHIR_BMP_DOSIEREINHEIT",
            "code" : "1"
          }
        }
      ]
    }
    """

    # 4. Hinweis für Versicherten (Freitext)
    Und TGR current request at "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.extension.[?(@..url =$ 'patient-note-extension')]" matches as JSON:
    """
    {
      "url" : "https://gematik.de/fhir/epa-medication/StructureDefinition/patient-note-extension",
      "valueAnnotation" : {
      "text" : "kann Schwindel verursachen"
      }
    }
    """

    # 5. Hinweis für Mitbehandelnde (Freitext)
    Und TGR current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.note.[*].text" matches "Hinweis für den LE"

    # 6. Status (Medication Status Code)
    Und TGR current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.status" matches "active"

    # 7. Anwendungszeitraum (Startdatum, Enddatum): entspricht Regex
    Und TGR current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.extension.[?(@..url =$ 'effectiveDosePeriod')].valuePeriod.start" matches "^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\\.[0-9]+)?(Z|(\\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00)))?$"
    Und TGR current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.extension.[?(@..url =$ 'effectiveDosePeriod')].valuePeriod.end" matches "^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)-(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])(T([01][0-9]|2[0-3]):[0-5][0-9]:([0-5][0-9]|60)(\\.[0-9]+)?(Z|(\\+|-)((0[0-9]|1[0-3]):[0-5][0-9]|14:00)))?$"

    # 8. Medikation-Angaben - Handelsname (Freitext, PZN falls vorhanden)
    Und TGR current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='medication')].part.[?(@..resource.resourceType=='Medication')].resource.code.text" matches "(?i).*Benazepril.*"
    Und KOB current request with optional attribute "$.body.decrypted.body.parameter.[?(@..name=='medication')].part.[?(@..resource.resourceType=='Medication')].resource.code.coding.[?(@..system =$ 'pzn')]" matches as JSON :
    """
    {
      "system" : "http://fhir.de/CodeSystem/ifa/pzn",
      "code" : "04351736",
      "display" : "Benazepril AL 20 mg Filmtabletten 98 Stk."
    }
    """

    # 8. Medikation-Angaben - Wirkstoff (ASK/ATC)
    Und TGR current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='medication')].part.[?(@..resource.resourceType=='Medication')].resource.ingredient.[*].itemCodeableConcept.text" matches "Benazepril hydrochlorid"

    # 8. Medikation-Angaben - Wirkstärke (strukturiert oder Freitext)
    Und KOB current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='medication')].part.[?(@..resource.resourceType=='Medication')].resource.ingredient.[*].strength.extension.[?(@..url =$ 'amount-extension')].valueString" matches ".*(?i)20 ?mg.*" or at "$.body.decrypted.body.parameter.[?(@..name=='medication')].part.[?(@..resource.resourceType=='Medication')].resource.ingredient.[*].strength" matches as JSON:
    """
    {
      "numerator" : {
        "value" : 20,
        "unit" : "mg"
      }
    }
    """

    # 8. Medikation-Angaben - Darreichungsform (KBV Darreichungsform)
    Und TGR current request at "$.body.decrypted.body.parameter.[?(@..name=='medication')].part.[?(@..resource.resourceType=='Medication')].resource.form" matches as JSON:
    """
    {
      "coding" : [ {
        "system" : "https://fhir.kbv.de/CodeSystem/KBV_CS_SFHIR_KBV_DARREICHUNGSFORM",
        "code" : "FTA",
        "display" : "FTA|Filmtablette[n]?|Filmtabl\\."
      } ]
    }
    """

    @IBM @Mandatory
    Beispiele: IBM_RU-REF
      | AS   | KVNR            | FQDN                    |
      | IBM  | ${kob.kvnrIbm}  | epa-as-1.ref.epa4all.de |

    @RISE @Mandatory
    Beispiele: RISE_RU-REF
      | AS   | KVNR            | FQDN                    |
      | RISE | ${kob.kvnrRise} | epa-as-2.ref.epa4all.de |
