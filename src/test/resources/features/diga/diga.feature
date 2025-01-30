# language: de
@DIGA
Funktion: KOB Testsuite für DiGA Verordnungen
  # Im Testverfahren durchläuft ein DiGA Rezept die drei Stufen Erzeugen, Einstellen und Löschen

  # Ein DiGA Rezept wurde am Fachdienst erzeugt
  @Mandatory
  Szenario: E-Rezept einer DiGA erstellen
    Wenn TGR zeige Banner "Testfall: E-Rezept einer DiGA erstellen"
    Und TGR pausiere Testausführung mit Nachricht "Erstellen Sie ein DiGA E-Rezept"
    Dann TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/$create" übereinstimmt
    Und TGR prüfe aktueller Request stimmt im Knoten "$.body.message.body.Parameters.parameter.valueCoding.code.value" überein mit "162"
    Und TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "201"

  # Ein DiGA Rezept wurde am Fachdienst eingestellt
  @Mandatory
  Szenario: E-Rezept einer DiGA bereitstellen
    Wenn TGR zeige Banner "Testfall: E-Rezept einer DiGA bereitstellen"
    Und TGR pausiere Testausführung mit Nachricht "Stellen Sie das erstellte E-Rezept einer DiGA bereit"
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/162.000.000.000.000.01/$activate" übereinstimmt
    Dann TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "200"
  
  # Ein DiGA Rezept wurde vom Fachdienst gelöscht
  @Mandatory
  Szenario: E-Rezept einer DiGA löschen
    Wenn TGR zeige Banner "Testfall: E-Rezept einer DiGA durch Verordnenden löschen"
    Und TGR pausiere Testausführung mit Nachricht "Löschen Sie das bereitgestellte E-Rezept einer DiGA"
    Und TGR finde die letzte Anfrage mit Pfad ".*" und Knoten "$.body.message.path.basicPath" der mit "/Task/162.000.000.000.000.01/$abort" übereinstimmt
    Dann TGR prüfe aktuelle Antwort stimmt im Knoten "$.body.message.responseCode" überein mit "204"
