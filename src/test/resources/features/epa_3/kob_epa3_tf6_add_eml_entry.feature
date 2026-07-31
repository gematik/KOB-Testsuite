# language: de
@Mandatory @KOB @EPA_3_1_3 @PVS @ZPVS @KIS @AVS
Funktion: KOB Testfall 6: eML-Eintrag hinzufügen

  Grundlage:
    Gegeben sei KOB Testsuite "Kob" Version "2.0.0-RC1"
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

    # eML Eintrag - manuell (nicht über E-Rezept Fachdienst)
    Und TGR current request at "$.body.decrypted.body.parameter.[?(@..name=='medicationStatement')].resource.extension.[?(@..url =$ 'context-extension')]" matches as JSON:
    """
    {
      "url" : "https://gematik.de/fhir/epa-medication/StructureDefinition/context-extension",
      "valueCode" : "MANUAL"
    }
    """

    # 1. Dosierangabe (strukturiert oder Freitext)
    Und TGR current request at "$.body.decrypted.body.parameter.[?(@..name=='medicationStatement')].resource.extension.[?(@..url =$ 'renderedDosageInstruction')]" matches as JSON:
    """
    {
      "url" : "http://hl7.org/fhir/5.0/StructureDefinition/extension-MedicationStatement.renderedDosageInstruction",
      "valueMarkdown" : "${json-unit.ignore}"
    }
    """
    Und KOB current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='empEntry')].resource.dosage.[*].text" matches ".*" or at "$.body.decrypted.body.parameter.[?(@..name=='medicationStatement')].resource.dosage.[*]" matches as JSON:
    """
    {
      "timing" : {
        "repeat" : {
          "frequency" : 4,
          "period" : 1,
          "periodUnit" : "d",
          "when" : [ "MORN","NOON","EVE","NIGHT" ]
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
    # 2. Medikation-Angaben - Handelsname (Freitext, PZN falls vorhanden)
    Und TGR current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='medication')].resource.code.text" matches "(?i).*Benazepril.*"
    Und KOB current request with optional attribute "$.body.decrypted.body.parameter.[?(@..name=='medication')].resource.code.coding.[?(@..system =$ 'pzn')]" matches as JSON :
    """
    {
      "system" : "http://fhir.de/CodeSystem/ifa/pzn",
      "code" : "04351682",
      "display" : "Benazepril AL 5 mg Filmtabletten 98 Stk."
     }
    """

    # 2. Medikation-Angaben - Wirkstoff (ASK/ATC)
    Und TGR current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='medication')].resource.ingredient.[*].itemCodeableConcept.text" matches "Benazepril hydrochlorid"

    # 2. Medikation-Angaben - Wirkstärke (strukturiert oder Freitext)
    Und KOB current request with attribute "$.body.decrypted.body.parameter.[?(@..name=='medication')].resource.ingredient.[*].strength.extension.[?(@..url =$ 'amount-extension')].valueString" matches ".*(?i)5 ?mg.*" or at "$.body.decrypted.body.parameter.[?(@..name=='medication')].resource.ingredient.[*].strength" matches as JSON:
    """
    {
      "numerator" : {
        "value" : 5,
        "unit" : "mg"
      }
    }
    """

    # 2. Medikation-Angaben - Darreichungsform (KBV Darreichungsform)
    Und TGR current request at "$.body.decrypted.body.parameter.[?(@..name=='medication')].resource.form" matches as JSON:
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
