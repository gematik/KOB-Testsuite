# language: de
@DIGA
Funktion: KOB Testsuite für DiGA Verordnungen
  # Im Testverfahren durchläuft ein DiGA Rezept die drei Stufen Erzeugen, Einstellen und Löschen

  # Ein DiGA Rezept wurde am Fachdienst erzeugt
  @Mandatory
  Szenario: DiGA Rezept wurde erzeugt
    Wenn TGR zeige Banner "Testfall: GF E-Rezept erzeugen (ein Diga Verordnungsdatensatz)"
    Und TGR pausiere Testausführung mit Nachricht "Warten auf Nutzerinteraktion"
    Dann TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/$create" übereinstimmt
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.message.body.Parameters.parameter.valueCoding.code.value" überein mit "162"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "201"

  # Ein DiGA Rezept wurde am Fachdienst eingestellt
  @Mandatory
  Szenario: DiGA Rezept wurde aktiviert
    Wenn TGR zeige Banner "Testfall: GF E-Rezept einstellen"
    Und TGR pausiere Testausführung mit Nachricht "Warten auf Nutzerinteraktion"
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/162.000.000.000.000.01/$activate" übereinstimmt
    Dann TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "200"
  
  # Ein DiGA Rezept wurde vom Fachdienst gelöscht
  @Mandatory
  Szenario: DiGA Rezept wurde gelöscht
    Wenn TGR zeige Banner "Testfall: GF E-Rezept durch Verordnenden löschen"
    Und TGR pausiere Testausführung mit Nachricht "Warten auf Nutzerinteraktion"
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/162.000.000.000.000.01/$abort" übereinstimmt
    Dann TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "204"
