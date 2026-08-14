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

import ca.uhn.fhir.context.FhirContext;
import ca.uhn.fhir.parser.IParser;
import de.gematik.test.tiger.common.config.TigerGlobalConfiguration;
import de.gematik.test.tiger.fhir.validation.fhirpath.NetTracer;
import io.cucumber.java.de.Und;
import java.util.Locale;
import lombok.extern.slf4j.Slf4j;
import org.hl7.fhir.instance.model.api.IBaseResource;
import org.hl7.fhir.r4.model.*;

@Slf4j
public class KobIdentifierExtractionGlue {

    private static final FhirContext FHIR_CONTEXT = FhirContext.forR4();
    private static final String BODY_PATH = "$.body.decrypted.body";
    private static final String CONTENT_TYPE_PATH = "$.body.decrypted.header.[~'Content-Type']";

    private static final String RX_PROCESS_ID_EXT_URL =
            "https://gematik.de/fhir/epa-medication/StructureDefinition/rx-prescription-process-identifier-extension";
    private static final String RX_PROCESS_ID_SYSTEM =
            "https://gematik.de/fhir/epa-medication/sid/rx-prescription-process-identifier";
    private static final String IS_EMP_EXT_URL =
            "https://gematik.de/fhir/epa-medication/StructureDefinition/is-emp-extension";

    private final NetTracer netTracer = new NetTracer();

    /**
     * Extrahiert den medicationPlanIdentifier aus der aktuellen $add-emp-entry Antwort.
     * Sucht in der Antwort nach einem MedicationRequest und speichert dessen ID.
     */
    @Und("KOB speichere den medicationPlanIdentifier aus der aktuellen Antwort")
    public void storeMedicationPlanIdentifierFromResponse() {
        IBaseResource resource = parseCurrentResponseBody();
        String medicationPlanId = extractEmpIdentifier(resource);

        TigerGlobalConfiguration.putValue("kob.medicationPlanIdentifier", medicationPlanId);
        log.info("Gespeicherter medicationPlanIdentifier: {}", medicationPlanId);
    }

    /**
     * Extrahiert den rxPrescriptionProcessIdentifier aus der eML-Antwort.
     * Findet das MedicationStatement mit basedOn-Referenz zum gespeicherten medicationPlanIdentifier
     * und liest dessen rx-prescription-process-identifier-extension.
     */
    @Und("KOB speichere den rxPrescriptionProcessIdentifier aus der aktuellen eML-Antwort")
    public void storeRxPrescriptionProcessIdentifierFromEml() {
        String medicationPlanId = TigerGlobalConfiguration.resolvePlaceholders("${kob.medicationPlanIdentifier}");
        if (medicationPlanId.isBlank() || medicationPlanId.contains("${")) {
            throw new AssertionError(
                    "medicationPlanIdentifier ist nicht gesetzt. Bitte zuerst den Step 'KOB speichere den medicationPlanIdentifier' ausführen.");
        }

        IBaseResource resource = parseCurrentResponseBody();

        if (!(resource instanceof Bundle bundle)) {
            throw new AssertionError("Die eML-Antwort ist kein Bundle, sondern: " + resource.fhirType());
        }

        String expectedRef = "MedicationRequest/" + medicationPlanId;
        String rxProcessId = null;

        for (Bundle.BundleEntryComponent entry : bundle.getEntry()) {
            if (!(entry.getResource() instanceof MedicationStatement ms)) continue;

            boolean hasEmpBasedOn = ms.getBasedOn().stream().anyMatch(ref ->
                    expectedRef.equals(ref.getReference()) &&
                            ref.getExtension().stream().anyMatch(ext ->
                                    IS_EMP_EXT_URL.equals(ext.getUrl()) &&
                                            ext.getValue() instanceof BooleanType bt && bt.booleanValue()));

            if (!hasEmpBasedOn) continue;

            rxProcessId = ms.getExtension().stream()
                    .filter(ext -> RX_PROCESS_ID_EXT_URL.equals(ext.getUrl()))
                    .map(Extension::getValue)
                    .filter(Identifier.class::isInstance)
                    .map(Identifier.class::cast)
                    .filter(id -> RX_PROCESS_ID_SYSTEM.equals(id.getSystem()))
                    .map(Identifier::getValue)
                    .findFirst()
                    .orElse(null);

            if (rxProcessId != null) break;
        }

        if (rxProcessId == null) {
            throw new AssertionError(
                    "Kein MedicationStatement mit basedOn-Referenz 'MedicationRequest/" + medicationPlanId
                            + "' und rx-prescription-process-identifier-extension in der eML-Antwort gefunden.");
        }

        TigerGlobalConfiguration.putValue("kob.rxPrescriptionProcessIdentifier", rxProcessId);
        log.info("Gespeicherter rxPrescriptionProcessIdentifier: {}", rxProcessId);
    }

    private String extractEmpIdentifier(IBaseResource resource) {
        if (!(resource instanceof Parameters params)) {
            throw new AssertionError("Antwort ist kein Parameters, sondern: " + resource.fhirType());
        }

        return params.getParameter().stream()
                .filter(p -> "empEntry".equals(p.getName()))
                .map(Parameters.ParametersParameterComponent::getResource)
                .filter(MedicationRequest.class::isInstance)
                .map(MedicationRequest.class::cast)
                .flatMap(mr -> mr.getIdentifier().stream())
                .filter(id -> "https://gematik.de/fhir/sid/emp-identifier".equals(id.getSystem()))
                .map(Identifier::getValue)
                .findFirst()
                .orElseThrow(() -> new AssertionError(
                        "Kein emp-identifier in der add-emp-entry Response gefunden."));
    }

    private IBaseResource parseCurrentResponseBody() {
        String contentType = netTracer.getCurrentResponseRawStringByRbelPath(CONTENT_TYPE_PATH)
                .filter(v -> !v.isBlank())
                .orElseThrow(() -> new AssertionError(
                        "Kein Content-Type in der aktuellen Antwort gefunden."));

        String body = netTracer.getCurrentResponseRawStringByRbelPath(BODY_PATH)
                .filter(v -> !v.isBlank())
                .orElseThrow(() -> new AssertionError(
                        "Kein Body in der aktuellen Antwort gefunden."));

        IParser parser = normalizeContentType(contentType).contains("xml")
                ? FHIR_CONTEXT.newXmlParser()
                : FHIR_CONTEXT.newJsonParser();

        return parser.parseResource(body);
    }

    private String normalizeContentType(String contentType) {
        if (contentType == null) return "";
        int sep = contentType.indexOf(';');
        return (sep >= 0 ? contentType.substring(0, sep) : contentType).trim().toLowerCase(Locale.ROOT);
    }
}