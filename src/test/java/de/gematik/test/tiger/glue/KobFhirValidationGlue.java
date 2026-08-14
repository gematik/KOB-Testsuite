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

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.fail;

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.context.support.DefaultProfileValidationSupport;
import ca.uhn.fhir.parser.DataFormatException;
import ca.uhn.fhir.parser.IParser;
import de.gematik.test.tiger.common.config.TigerGlobalConfiguration;
import de.gematik.test.tiger.fhir.validation.fhirpath.NetTracer;
import io.cucumber.java.de.Dann;
import io.cucumber.java.de.Und;
import io.cucumber.java.en.Then;
import java.util.List;
import java.util.Locale;
import lombok.extern.slf4j.Slf4j;
import org.hl7.fhir.exceptions.FHIRException;
import org.hl7.fhir.instance.model.api.IBaseResource;
import org.hl7.fhir.r4.hapi.ctx.HapiWorkerContext;
import org.hl7.fhir.r4.model.Base;
import org.hl7.fhir.r4.utils.FHIRPathEngine;

@Slf4j
public class KobFhirValidationGlue {

    private static final FhirContext FHIR_CONTEXT = FhirContext.forR4();
    private static final FHIRPathEngine FHIR_PATH_ENGINE = new FHIRPathEngine(new HapiWorkerContext(FHIR_CONTEXT, new DefaultProfileValidationSupport(FHIR_CONTEXT)));
    private final NetTracer netTracer;

    private static final String DEFAULT_BODY_PATH = "$.body.decrypted.body";
    private static final String DEFAULT_CONTENT_TYPE_PATH = "$.body.decrypted.header.[~'Content-Type']";


    public KobFhirValidationGlue() {
        this.netTracer = new NetTracer();
    }

    @Then("FHIR request evaluates the FHIRPath {tigerResolvedString} with error message {tigerResolvedString}")
    @Und("FHIR request evaluiert FHIRPath {tigerResolvedString} mit Fehlermeldung {tigerResolvedString}")
    public void tgrCurrentRequestWithDefaultsEvaluatesTheFhirPath(
            final String fhirPath,
            final String errorMessage) {
        tgrCurrentRequestWithContentTypeAtEvaluatesTheFhirPath(
                DEFAULT_BODY_PATH,
                DEFAULT_CONTENT_TYPE_PATH,
                fhirPath,
                errorMessage);
    }

    @Then(
            "FHIR current request at {tigerResolvedString} with content type at {tigerResolvedString}"
                    + " evaluates the FHIRPath {tigerResolvedString} with error message {tigerResolvedString}")
    @Dann(
            "FHIR die aktuelle Anfrage im Knoten {tigerResolvedString} mit Content-Type im Knoten {tigerResolvedString}"
                    + " den FHIRPath {tigerResolvedString} mit der Fehlermeldung {tigerResolvedString} erfüllt")
    public void tgrCurrentRequestWithContentTypeAtEvaluatesTheFhirPath(
            final String rbelPath,
            final String contentTypePath,
            final String fhirPath,
            final String errorMessage) {

        final String resolvedRbelPath =
                TigerGlobalConfiguration.resolvePlaceholders(rbelPath);

        final String resolvedContentTypePath =
                TigerGlobalConfiguration.resolvePlaceholders(contentTypePath);

        final String resolvedFhirPath =
                TigerGlobalConfiguration.resolvePlaceholders(fhirPath);

        final String resolvedErrorMessage =
                TigerGlobalConfiguration.resolvePlaceholders(errorMessage);

        log.info(
                "Validiere FHIR-Resource bei '{}' mit Content-Type aus '{}'",
                resolvedRbelPath,
                resolvedContentTypePath);

        final String contentType =
                findRequiredRequestElement(
                        resolvedContentTypePath,
                        "Kein Content-Type im aktuellen Request gefunden unter RBEL-Pfad: ");

        final String fhirResourceString =
                findRequiredRequestElement(
                        resolvedRbelPath,
                        "Keine FHIR-Resource im aktuellen Request gefunden unter RBEL-Pfad: ");

        final IBaseResource resource =
                parseFhirResource(
                        fhirResourceString,
                        contentType,
                        resolvedRbelPath,
                        resolvedContentTypePath);

        final List<Base> results =
                evaluateFhirPath(resource, resolvedFhirPath);

        assertBooleanResult(
                results,
                resolvedFhirPath,
                resolvedErrorMessage);

        log.info(
                "FHIRPath erfolgreich validiert: {}",
                resolvedFhirPath);
    }

    private String findRequiredRequestElement(
            final String rbelPath,
            final String errorMessagePrefix) {

        return netTracer
                .getCurrentRequestsRawStringByRbelPath(rbelPath)
                .filter(value -> !value.isBlank())
                .orElseThrow(
                        () -> new AssertionError(
                                errorMessagePrefix + rbelPath));
    }


    @Then("FHIR response evaluates the FHIRPath {tigerResolvedString} with error message {tigerResolvedString}")
    @Und("FHIR response evaluiert FHIRPath {tigerResolvedString} mit Fehlermeldung {tigerResolvedString}")
    public void tgrCurrentResponseWithDefaultsEvaluatesTheFhirPath(
            final String fhirPath,
            final String errorMessage) {
        tgrCurrentResponseWithContentTypeAtEvaluatesTheFhirPath(
                DEFAULT_BODY_PATH,
                DEFAULT_CONTENT_TYPE_PATH,
                fhirPath,
                errorMessage);
    }

    @Then(
            "FHIR current response at {tigerResolvedString} with content type at {tigerResolvedString}"
                    + " evaluates the FHIRPath {tigerResolvedString} with error message {tigerResolvedString}")
    @Dann(
            "FHIR die aktuelle Antwort im Knoten {tigerResolvedString} mit Content-Type im Knoten {tigerResolvedString}"
                    + " den FHIRPath {tigerResolvedString} mit der Fehlermeldung {tigerResolvedString} erfüllt")
    public void tgrCurrentResponseWithContentTypeAtEvaluatesTheFhirPath(
            final String rbelPath,
            final String contentTypePath,
            final String fhirPath,
            final String errorMessage) {

        final String resolvedRbelPath =
                TigerGlobalConfiguration.resolvePlaceholders(rbelPath);

        final String resolvedContentTypePath =
                TigerGlobalConfiguration.resolvePlaceholders(contentTypePath);

        final String resolvedFhirPath =
                TigerGlobalConfiguration.resolvePlaceholders(fhirPath);

        final String resolvedErrorMessage =
                TigerGlobalConfiguration.resolvePlaceholders(errorMessage);

        log.info(
                "Validiere FHIR-Resource bei '{}' mit Content-Type aus '{}'",
                resolvedRbelPath,
                resolvedContentTypePath);

        final String contentType =
                findRequiredResponseElement(
                        resolvedContentTypePath,
                        "Kein Content-Type in der aktuellen Response gefunden unter RBEL-Pfad: ");

        final String fhirResourceString =
                findRequiredResponseElement(
                        resolvedRbelPath,
                        "Keine FHIR-Resource in der aktuellen Response gefunden unter RBEL-Pfad: ");

        final IBaseResource resource =
                parseFhirResource(
                        fhirResourceString,
                        contentType,
                        resolvedRbelPath,
                        resolvedContentTypePath);

        final List<Base> results =
                evaluateFhirPath(resource, resolvedFhirPath);

        assertBooleanResult(
                results,
                resolvedFhirPath,
                resolvedErrorMessage);

        log.info(
                "FHIRPath erfolgreich validiert: {}",
                resolvedFhirPath);
    }


    private String findRequiredResponseElement(
            final String rbelPath,
            final String errorMessagePrefix) {

        return netTracer.getCurrentResponseRawStringByRbelPath(rbelPath)
                .filter(value -> !value.isBlank())
                .orElseThrow(
                        () -> new AssertionError(
                                errorMessagePrefix + rbelPath));
    }

    private IBaseResource parseFhirResource(
            final String fhirResource,
            final String contentType,
            final String resourceRbelPath,
            final String contentTypeRbelPath) {

        final IParser parser = getParser(contentType);

        try {
            return parser.parseResource(fhirResource);
        } catch (final DataFormatException exception) {
            final String errorMessage = String.format(
                    "FHIR-Resource unter RBEL-Pfad '%s' konnte mit Content-Type '%s' "
                            + "aus RBEL-Pfad '%s' nicht geparst werden.",
                    resourceRbelPath,
                    contentType,
                    contentTypeRbelPath);

            fail(errorMessage, exception);

            return null;
        }
    }

    private List<Base> evaluateFhirPath(
            final IBaseResource resource,
            final String fhirPath) {

        if (!(resource instanceof Base baseResource)) {
            throw new AssertionError(
                    "Die geparste FHIR-Resource ist keine unterstützte "
                            + "FHIR-R4-Base-Resource: "
                            + resource.getClass().getName());
        }

        try {
            return FHIR_PATH_ENGINE.evaluate(
                    baseResource,
                    fhirPath);
        } catch (final FHIRException exception) {
            fail(
                    "Ungültiger oder nicht auswertbarer FHIRPath: " + fhirPath,
                    exception);

            return List.of();
        }
    }

    private void assertBooleanResult(
            final List<Base> results,
            final String fhirPath,
            final String errorMessage) {

        assertThat(results)
                .withFailMessage(
                        "FHIRPath lieferte kein Ergebnis: %s",
                        fhirPath)
                .isNotEmpty();

        assertThat(results)
                .withFailMessage(
                        "FHIRPath lieferte mindestens ein nicht-boolesches Ergebnis: %s",
                        fhirPath)
                .allMatch(Base::isBooleanPrimitive);

        final boolean allTrue =
                results.stream()
                        .allMatch(
                                result ->
                                        result.castToBoolean(result).booleanValue());

        assertThat(allTrue)
                .withFailMessage(errorMessage)
                .isTrue();
    }

    private IParser getParser(final String contentType) {
        final String normalizedContentType =
                normalizeContentType(contentType);

        if (normalizedContentType.contains("xml")) {
            return FHIR_CONTEXT.newXmlParser();
        }

        if (normalizedContentType.contains("json")) {
            return FHIR_CONTEXT.newJsonParser();
        }

        throw new AssertionError(
                "Nicht unterstützter FHIR Content-Type: '"
                        + contentType
                        + "'. Erwartet wurde ein XML- oder JSON-Content-Type.");
    }

    private String normalizeContentType(final String contentType) {
        if (contentType == null) {
            return "";
        }

        final int parameterSeparator = contentType.indexOf(';');

        final String mediaType =
                parameterSeparator >= 0
                        ? contentType.substring(0, parameterSeparator)
                        : contentType;

        return mediaType
                .trim()
                .toLowerCase(Locale.ROOT);
    }
}