/*
 * Copyright 2024 gematik GmbH
 *
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
 */

package de.gematik.test.tiger.glue;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

import com.fasterxml.jackson.databind.ObjectMapper;
import de.gematik.test.psTestdriver.dto.*;
import de.gematik.test.tiger.common.config.TigerGlobalConfiguration;
import de.gematik.test.tiger.common.config.TigerTypedConfigurationKey;
import de.gematik.test.tiger.lib.TigerDirector;
import io.cucumber.java.Before;
import io.cucumber.java.de.Und;
import io.cucumber.java.en.And;
import io.cucumber.java.en.When;
import java.io.File;
import java.io.IOException;
import java.net.ProxySelector;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpRequest.Builder;
import java.net.http.HttpResponse;
import java.net.http.HttpResponse.BodyHandlers;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;
import javax.annotation.Nullable;
import lombok.SneakyThrows;
import lombok.extern.slf4j.Slf4j;
import lombok.val;
import org.apache.commons.io.FileUtils;
import org.junit.platform.engine.TestExecutionResult;

@Slf4j
public class KobTestdriverGlueCode {

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
  @Nullable private Action lastActionExecuted = null;
  private final ObjectMapper objectMapper = new ObjectMapper();
  private HttpClient httpClient;

  @Before
  public void beforeScenario() {
    httpClient = HttpClient.newBuilder().proxy(ProxySelector.of(null)).build();
  }

  @Und("KOB stecke EGK mit der KVNR {tigerResolvedString}")
  public void kobInsertEgkCardWithKvnr(String kvnr) {
    executeTestdriverAction(
        () ->
            executeActionAndWaitForCompletion(new InsertEgk().patient(kvnr), "/patient/insert-egk"),
        TigerGlobalConfiguration.resolvePlaceholders(
            "Stecken Sie die Karte mit der KVNR " + kvnr + " ein"));
  }

  @And("KOB setze alle EPA sessions des Primärsystems zurück")
  public void kobResetPrimaersystem() {
    executeTestdriverAction(
        () ->
            executeActionAndWaitForCompletion(
                new ResetPrimaersystem().reboot(false).closeAllEpaSessions(true), "/system/reset"),
        "Setzen sie das Primärsystem zurück. Insbesondere müssen Sie alle offenen EPA-Sitzungen schließen.");
  }

  @When("KOB lade die EML für die KVNR {tigerResolvedString} im Format {tigerResolvedString} von dem Aktensystem {tigerResolvedString} herunter")
  public void kobDownloadEmlForKvnrAs(String kvnr, String emlTypeString, String aktenSystem) {
    EmlType emlType = EmlType.fromValue(emlTypeString.toLowerCase());
    executeTestdriverAction(
        () ->
            executeActionAndWaitForCompletion(
                new EmlRetrieval().emlType(emlType).patient(kvnr),
                "/patient/medication/medication-service/eml"),
        "Laden Sie für den Patienten mit der KVNR "
            + kvnr
            + " die EML-Datei als "
            + emlTypeString
            + " von dem Aktensystem "
            + aktenSystem
            + " herunter.");
  }

  @When("KOB speichere einen Screenshot der letzten Aktion in der Datei {tigerResolvedString}")
  public void kobSaveScreenshotOfLastActionTo(String filename) {
    executeTestdriverAction(
        () -> saveScreenshotOfLastActionTo(filename),
        "Speichern Sie einen Screenshot der letzten Aktion in der Datei " + filename);
  }

  @SneakyThrows
  private void saveScreenshotOfLastActionTo(String filename) {
    final HttpResponse<byte[]> response =
        httpClient.send(
            HttpRequest.newBuilder(
                    URI.create(
                        kobApiUrl.getValue().orElseThrow(missingKobApiUrl)
                            + "/actions/"
                            + lastActionExecuted.getId()
                            + "/screenshot"))
                .GET()
                .header("content-type", TESTDRIVER_CONTENT_TYPE)
                .header("accept", TESTDRIVER_CONTENT_TYPE)
                .build(),
            BodyHandlers.ofByteArray());

    if (response.statusCode() != 200) {
      throw new AssertionError("Failed to retrieve screenshot: " + new String(response.body()));
    }

    FileUtils.writeByteArrayToFile(new File(filename), response.body());

    log.info("Successfully saved screenshot of last action to {}", filename);
  }

  private void executeTestdriverAction(Runnable testdriverAction, String message) {
    if (useTestdriver.getValueOrDefault()) {
      testdriverAction.run();
    } else {
      TigerDirector.pauseExecution(message);
    }
  }

  @SneakyThrows
  private void executeActionAndWaitForCompletion(Object body, String url) {
    final String actionUrl = kobApiUrl.getValue().orElseThrow(missingKobApiUrl) + url;
    log.info("Executing action: POST {}", actionUrl);
    val action = postObject(body, actionUrl, "POST");

    await()
        .given()
        .pollInterval(pollingIntervalInMilliseconds.getValueOrDefault(), TimeUnit.MILLISECONDS)
        .atMost(pollingTimeoutInSeconds.getValueOrDefault(), TimeUnit.SECONDS)
        .until(() -> isCompleted(retrieveActionStatus(action.getId()).getStatus()));

    lastActionExecuted = action;

    assertThat(retrieveActionStatus(action.getId()).getStatus())
      .isEqualTo(TestExecutionResult.Status.SUCCESSFUL);
  }

  private Action postObject(Object body, String actionUrl, String method) {
    try {
      final Builder builder = HttpRequest.newBuilder(URI.create(actionUrl));
      if (body != null) {
        builder
            .method(method, BodyPublishers.ofString(objectMapper.writeValueAsString(body)))
            .header("content-type", TESTDRIVER_CONTENT_TYPE);
      } else {
        builder.method(method, BodyPublishers.noBody());
      }
      final HttpResponse<String> response =
          httpClient.send(
              builder.header("accept", TESTDRIVER_CONTENT_TYPE).build(), BodyHandlers.ofString());
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
        null, kobApiUrl.getValue().orElseThrow(missingKobApiUrl) + "/actions/" + id, "GET");
  }

  private boolean isCompleted(Status status) {
    return status == Status.FAILED || status == Status.SUCCESSFUL;
  }
}
