package de.gematik.test.tiger.glue;

/*-
 * #%L
 * kob-testsuite
 * %%
 * Copyright (C) 2024 - 2026 gematik GmbH
 * %%
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * *******
 *
 * For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
 * #L%
 */

import static de.gematik.test.psTestdriver.dto.Status.SUCCESSFUL;
import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

import com.fasterxml.jackson.databind.ObjectMapper;
import de.gematik.test.psTestdriver.KobEpa30Api;
import de.gematik.test.psTestdriver.OptionalApi;
import de.gematik.test.psTestdriver.dto.*;
import de.gematik.test.tiger.common.config.TigerGlobalConfiguration;
import de.gematik.test.tiger.common.config.TigerTypedConfigurationKey;
import de.gematik.test.tiger.lib.TigerDirector;
import de.gematik.test.tiger.lib.rbel.ModeType;
import io.cucumber.java.Before;
import io.cucumber.java.PendingException;
import io.cucumber.java.de.Und;
import io.cucumber.java.de.Wenn;
import io.cucumber.java.en.When;
import java.io.IOException;
import java.net.ProxySelector;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import lombok.val;
import org.junit.jupiter.api.Assertions;

@Slf4j
public class KobTestdriverGlueCode {

  private final RBelValidatorGlue tigerGlue = new RBelValidatorGlue();
  private static final String TESTDRIVER_CONTENT_TYPE =
      "application/gematik.psTestdriver.v0.1.0+json";
  private final TigerTypedConfigurationKey<String> kobApiUrl =
      new TigerTypedConfigurationKey<>("kob.Psurl", String.class);
  private final TigerTypedConfigurationKey<Boolean> useTestdriver =
      new TigerTypedConfigurationKey<>("kob.useTestdriverApi", Boolean.class, Boolean.TRUE);
  private final TigerTypedConfigurationKey<Integer> pollingTimeoutInSeconds =
      new TigerTypedConfigurationKey<>("kob.polling.timeoutInSeconds", Integer.class, 120);
  private final TigerTypedConfigurationKey<Integer> pollingIntervalInMilliseconds =
      new TigerTypedConfigurationKey<>("kob.polling.intervalInMilliseconds", Integer.class, 500);
  private final Supplier<RuntimeException> missingKobApiUrl =
      () -> new RuntimeException("Missing configuration: " + kobApiUrl.getKey().downsampleKey());
  private final ObjectMapper objectMapper = new ObjectMapper();
    private HttpClient httpClient;
  private final OptionalApi optionalApi = new OptionalApi();
  private final KobEpa30Api kobEpa30Api = new KobEpa30Api();

  @Before
  public void beforeScenario() {
    httpClient = HttpClient.newBuilder().proxy(ProxySelector.of(null)).build();
    optionalApi.getApiClient().setBasePath(kobApiUrl.getValue().orElseThrow(missingKobApiUrl));
    kobEpa30Api.getApiClient().setBasePath(kobApiUrl.getValue().orElseThrow(missingKobApiUrl));
  }

  @When("KOB lokalisiere die Akte und befrage Zustimmung des Patienten {tigerResolvedString} ab")
  public void getStatus(String kvnr) {
    executeTestdriverAction(
        () -> {
          executeActionAndWaitForCompletion(() -> optionalApi.getStatus(kvnr));
          log.info("Successfully localized health record for insurantId {}", kvnr);
        },
        "Bitte initiiere eine Abfrage des Status eines existierenden Aktenkontos beim Aktensystem durch ein Primärsystem!");
  }

  @When(
      "KOB erstelle eine User-Session mit dem Aktensystem des Patienten {tigerResolvedString} auf")
  public void getSession(String kvnr) {
    executeTestdriverAction(
        () -> {
          // Reset the primary system to ensure a clean state before creating a session (e.g. to close all previous VAU sessions)
          executeActionAndWaitForCompletion(() -> optionalApi.resetPrimaersystem(new ResetPrimaersystem().reboot(false).closeAllEpaSessions(true)));
          executeActionAndWaitForCompletion(() -> optionalApi.getSession(kvnr));
          log.info("Successfully logged in for insurantId {}", kvnr);
        },
        "Bitte initiiere den Aufbau einer User-Session mit dem Primärsystem!");
  }

  @When("KOB erstelle eine Befugnis für das Aktenkonto des Patienten {tigerResolvedString}")
  public void getEntitlement(String kvnr) {
    executeTestdriverAction(
        () -> {
          executeActionAndWaitForCompletion(() -> optionalApi.getEntitlement(kvnr));
          log.info("Successfully entitled for insurantId {}", kvnr);
        },
        "Bitte initiiere die Befugnisvergabe durch ein Primärsystem!");
  }

  @Wenn("KOB rufe den Medikationsplan mit der FHIR Operation im Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString} ab")
  public void kobRetrieveMedicationPlan(String aktenSystem, String kvnr) {
    executeTestdriverAction(
        () -> {
          throw new PendingException("Not yet implemented");
        },
        "Rufen Sie den vorhandenen Medikationsplan für den Patienten mit der KVNR "
            + kvnr
            + " im Aktensystem "
            + aktenSystem
            + " mit der FHIR Operation 'GetMedicationsPlan' ab");
  }

  @Wenn("KOB rufe die Medikationsliste mit der FHIR Operation im Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString} ab")
  public void kobRetrieveMedicationList(String aktenSystem, String kvnr) {
    executeTestdriverAction(
            () -> {
              throw new PendingException("Not yet implemented");
            },
            "Rufen Sie die Medikationsliste für den Patienten mit der KVNR "
                    + kvnr
                    + " im Aktensystem "
                    + aktenSystem
                    + " mit der FHIR Operation 'GetMedicationsList' ab");
  }

  @Wenn("KOB rufe die eMP-Chronologie im Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString} ab")
  public void kobRetrieveMedicationPlanLogs(String aktenSystem, String kvnr) {
    executeTestdriverAction(
            () -> {
              throw new PendingException("Not yet implemented");
            },
            "Rufen Sie die Chronologie des Medikationsplans für den Patienten mit der KVNR "
                    + kvnr
                    + " im Aktensystem "
                    + aktenSystem
                    + " mit der FHIR Operation '$medication-plan-log' ab");
  }

  @When(
      "KOB lade die EML im Format {tigerResolvedString} von dem Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString} herunter")
  public void kobDownloadEmlForAs(String emlTypeString, String aktenSystem, String kvnr) {
    EmlType emlType = EmlType.fromValue(emlTypeString.toLowerCase());
    executeTestdriverAction(
        () -> {
          executeActionAndWaitForCompletion(() -> kobEpa30Api.retrieveEml(
              new EmlRetrieval().emlType(emlType).patient(kvnr)));
          log.info("Successfully retrieved EML for insurantId {}", kvnr);
        },
        "Laden Sie für den Patienten mit der KVNR "
            + kvnr
            + " die eML als "
            + emlTypeString
            + " von dem Aktensystem "
            + aktenSystem
            + " herunter.");
  }

  @Wenn("KOB verknüpfe im Aktensystem {tigerResolvedString} einen eML-Eintrag mit einem eMP-Eintrag des Patienten {tigerResolvedString}")
  public void kobLinkmedicationListandMedicationPlanEntries(String aktenSystem, String kvnr) {
    executeTestdriverAction(
            () -> {
              throw new PendingException("Not yet implemented");
            },
            "Verknüpfen Sie für den Patienten mit der KVNR "
                    + kvnr
                    + " im Aktensystem "
                    + aktenSystem
                    + " einen Eintrag der Medikationsliste mit einem Medikationsplan-Eintrag.");
  }


    @Wenn("KOB entferne im Aktensystem {tigerResolvedString} einen eML-Eintrag von einem eMP-Eintrag des Patienten {tigerResolvedString}")
    public void kobEntferneImAktensystemEinenEMLEintragVonEinemEMPEintragDesPatienten(String aktenSystem, String kvnr) {
        executeTestdriverAction(
                () -> {
                    throw new PendingException("Not yet implemented");
                },
                "Entfernen Sie für den Patienten mit der KVNR "
                        + kvnr
                        + " im Aktensystem "
                        + aktenSystem
                        + " die Verknüpfung zwischen Medikationslisten- und Medikationsplaneintrag wieder.");
    }

  private void executeTestdriverAction(Runnable testdriverAction, String message) {
    if (useTestdriver.getValueOrDefault()) {
      testdriverAction.run();
    } else {
      TigerDirector.pauseExecution(message, true);
    }
  }

  @SneakyThrows
  private void executeActionAndWaitForCompletion(Supplier<Action> lambda) {
    val action = lambda.get();
    await()
        .given()
        .pollInterval(pollingIntervalInMilliseconds.getValueOrDefault(), TimeUnit.MILLISECONDS)
        .atMost(pollingTimeoutInSeconds.getValueOrDefault(), TimeUnit.SECONDS)
        .until(() -> isCompleted(retrieveActionStatus(action.getId()).getStatus()));

      assertThat(retrieveActionStatus(action.getId()).getStatus()).isEqualTo(SUCCESSFUL);
  }

  private Action postObject(String actionUrl) {
    try {
      final HttpRequest request = HttpRequest
              .newBuilder(URI.create(actionUrl))
              .header("accept", TESTDRIVER_CONTENT_TYPE)
              .method("GET", BodyPublishers.noBody())
              .build();
      final HttpResponse<String> response = httpClient.send(request, BodyHandlers.ofString());
      final String stringBody = response.body();
      log.info("got response: HTTP {} with '{}'", response.statusCode(), stringBody);
      return objectMapper.readValue(stringBody, Action.class);
    } catch (IOException e) {
      throw new RuntimeException("Failed to send request", e);
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      throw new RuntimeException("Failed to send request", e);
    }
  }

  private Action retrieveActionStatus(UUID id) {
    return postObject(
            kobApiUrl.getValue().orElseThrow(missingKobApiUrl) + "/actions/" + id);
  }

  private boolean isCompleted(Status status) {
    return status == Status.FAILED || status == SUCCESSFUL;
  }


  @Wenn("KOB füge einen neuen eMP-Eintrag im Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString} hinzu")
  public void kobAddEmpEntry(String aktenSystem, String kvnr) {
    executeTestdriverAction(
        () -> {
          throw new PendingException("Not yet implemented");
        },
        "<div style=\"text-align: left;\">\n" +
                "  <p>Fügen Sie für den Patienten mit der KVNR <strong>" + kvnr + "</strong> einen neuen eMP-Eintrag im Aktensystem <strong>" + aktenSystem + "</strong> hinzu:</p>\n" +
                "  <ol>\n" +
                "    <li>1. Indikation (ICD-10-Code): I11</li>\n" +
                "    <li>2. Grund (Freitext): Bluthochdruck</li>\n" +
                "    <li>3. Dosierangabe (strukturiert oder Freitext): 1-0-1-0 Stück</li>\n" +
                "    <li>4. Hinweis für Versicherten (Freitext): Benazepril kann anfangs Schwindel verursachen</li>\n" +
                "    <li>5. Hinweis für Mitbehandelnde (Freitext): Hinweis für LE</li>\n" +
                "    <li>6. Status (Medication Status Code): aktiv</li>\n" +
                "    <li>7. Anwendungszeitraum (Startdatum, Enddatum): muss mindestens aus Tag, Monat und Jahr bestehen</li>\n" +
                "    <li>8. Medikation-Angaben:\n" +
                "      <ol type=\"a\">\n" +
                "        <li>• Handelsname (Freitext, PZN falls vorhanden): Benazepril AL 20 mg Filmtabletten 98 Stk., (PZN 04351736)</li>\n" +
                "        <li>• Wirkstoff (ASK/ATC): Benazepril hydrochlorid</li>\n" +
                "        <li>• Wirkstärke (strukturiert oder Freitext): 20mg</li>\n" +
                "        <li>• Darreichungsform (KBV Darreichungsform): Filmtablette</li>\n" +
                "      </ol>\n" +
                "    </li>\n" +
                "  </ol>\n" +
                "</div>");
  }

  @Wenn("KOB füge einen neuen eML-Eintrag im Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString} hinzu")
  public void kobAddEmlEntry(String aktenSystem, String kvnr) {
    executeTestdriverAction(
        () -> {
          throw new PendingException("Not yet implemented");
        },
        "<div style=\"text-align: left;\">\n" +
            "  <p>Fügen Sie für den Patienten mit der KVNR <strong>" + kvnr + "</strong> einen neuen eML-Eintrag im Aktensystem <strong>" + aktenSystem + "</strong> hinzu:</p>\n" +
            "  <ol>\n" +
            "    <li>1. Dosieranweisung (strukturiert oder Freitext): 1-1-1-1 Stück</li>\n" +
            "    <li>2. Medikation-Angaben:\n" +
            "      <ol type=\"a\">\n" +
            "        <li>• Handelsname (Freitext, PZN falls vorhanden): Benazepril AL 5 mg Filmtabletten 98 Stk., (PZN 04351682)</li>\n" +
            "        <li>• Wirkstoff (ASK/ATC): Benazepril hydrochlorid</li>\n" +
            "        <li>• Wirkstärke (strukturiert oder Freitext): 5mg</li>\n" +
            "        <li>• Darreichungsform (KBV Darreichungsform): Filmtablette</li>\n" +
            "      </ol>\n" +
            "    </li>\n" +
            "  </ol>\n" +
            "</div>");
  }

  /**
   * Validates the current request using two alternative checks and succeeds if either one matches.
   * First, it applies a regular-expression-based attribute check at path A. If that fails, it
   * validates the content at path B against the provided JSON or XML document.
   *
   * @param rbelPathA the RBEL path used for the regular-expression-based attribute check
   * @param regexA the expected regular expression for the attribute at path A
   * @param rbelPathB the RBEL path used for the structured JSON or XML validation
   * @param modeB the validation mode that determines whether JSON or XML matching is used
   * @param docStringB the expected JSON or XML document used for structured validation
   */
  @Und("KOB current request with attribute {tigerResolvedString} matches {tigerResolvedString} or at {tigerResolvedString} matches as {modeType}:")
  public void currentRequestMessageAttributeMatchesOrMatchesAsJsonOrXml(String rbelPathA, String regexA, String rbelPathB, final ModeType modeB, final String docStringB) {
    AssertionError assertionA = null;
    AssertionError assertionB = null;

    // 1. Prüfung A versuchen (Standard Matcher)
    try {
      tigerGlue.getRbelValidator()
          .assertAttributeOfCurrentRequestMatches(rbelPathA, regexA, true,
              tigerGlue.getRbelMessageRetriever());
    } catch (AssertionError e) {
      assertionA = e; // Fehler merken, falls B auch fehlschlägt
    }

    // 2. Prüfung B versuchen (DocString / Block Matcher für JSON/XML)
    try {
      tigerGlue.getRbelValidator().assertAttributeOfCurrentRequestMatchesAs(
          rbelPathB,
          modeB,
          TigerGlobalConfiguration.resolvePlaceholders(docStringB),
          tigerGlue.getRbelMessageRetriever());
    } catch (AssertionError e) {
      assertionB = e;
    }

    // 3. Logische ODER-Auswertung
    if (assertionA != null && assertionB != null) {
      String details = String.format(
          """
              
              -> Pfad A (%s) schlug fehl: %s
              
              -> Pfad B (%s) schlug fehl: %s""",
          rbelPathA, assertionA.getMessage(),
          rbelPathB, assertionB.getMessage()
      );
      Assertions.fail(
          "Kombinierte ODER-Prüfung fehlgeschlagen! Weder Bedingung A noch B traf zu.\n" + details);
    }
  }

  /**
   * Validates the JSON content at the given RBEL path in the current request if the attribute is
   * present. If no element exists at the path, the check is skipped.
   *
   * @param rbelPath the RBEL path of the optional request attribute
   * @param docString the expected JSON document used for validation
   */
  @Und("KOB current request with optional attribute {string} matches as JSON :")
  public void currentRequestWithOptionalAttributeMatchesAsJSON(
      final String rbelPath, final String docString) {
    if (tigerGlue.getRbelMessageRetriever().findElementsInCurrentRequestOrEmpty(rbelPath).isEmpty()) {
      return;
    }

    tigerGlue.getRbelValidator().assertAttributeOfCurrentRequestMatchesAs(
        rbelPath,
        ModeType.JSON,
        TigerGlobalConfiguration.resolvePlaceholders(docString),
        tigerGlue.getRbelMessageRetriever());
  }

  @Wenn("KOB aktualisiere einen neuen eMP-Eintrag im Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString}")
  public void kobUpdateEmpEntry(String aktenSystem, String kvnr) {
    executeTestdriverAction(
            () -> {
              throw new PendingException("Not yet implemented");
            },
            "<div style=\"text-align: left;\">\n" +
                    "  <p>Aktualisieren Sie für den Patienten mit der KVNR <strong>" + kvnr + "</strong> den bestehenden EMP-Eintrag im Aktensystem <strong>" + aktenSystem + "</strong>:</p>\n" +
                    "  <ol>\n" +
                    "    <li>1. Dosierangabe (strukturiert oder Freitext):  täglich: 08:00 Uhr — je 1 Stück</li>\n" +
                    "    <li>2. Status-Änderung eMP-Eintrag: on-hold (Pausieren)</li>\n" +
                    "  </ol>\n" +
                    "</div>");
  }

    @Wenn("KOB storniere einen neuen eMP-Eintrag im Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString}")
    public void kobCancelEmpEntry(String aktenSystem, String kvnr) {
        executeTestdriverAction(
                () -> {
                    throw new PendingException("Not yet implemented");
                },
                "<div style=\"text-align: left;\">" +
                        "  <p><strong>Testszenario:</strong></p>" +
                        "  <p>Das Primärsystem storniert einen fehlerhaften eMP-Eintrag.</p>" +
                        "  <p>" +
                        "    Stornieren Sie für den Patienten mit der KVNR " +
                        "    <strong>" + kvnr + "</strong> im Aktensystem " +
                        "    <strong>" + aktenSystem + "</strong> einen Medikationsplaneintrag, " +
                        "    indem Sie dessen Status auf <code>entered-in-error</code> setzen." +
                        "  </p>" +
                        "</div>"
        );
    }

  @Wenn("KOB rufe den Medikationsplan als PDFA im Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString} ab")
  public void kobRetrieveMedicationPlanAsPDFA(String aktenSystem, String kvnr) {
    executeTestdriverAction(
            () -> {
              throw new PendingException("Not yet implemented");
            },
            "Rufen Sie den vorhandenen Medikationsplan für den Patienten "
                    + kvnr
                    + " im Aktensystem "
                    + aktenSystem
                    + " als gerendertes PDF/A ab");

  }

    @Wenn("KOB storniere einen eML-Eintrag mit der FHIR Operation im Aktensystem {tigerResolvedString} für das Aktenkonto des Patienten {tigerResolvedString}")
    public void kobCancelEmlEntry(String aktenSystem, String kvnr) {
        executeTestdriverAction(
                () -> {
                    throw new PendingException("Not yet implemented");
                },
                "Stornieren Sie für den Patienten "
                        + kvnr
                        + " im Aktensystem "
                        + aktenSystem
                        + " einen Medikationlisteneintrag (Operation $cancel-eml-entry).");
    }
}
