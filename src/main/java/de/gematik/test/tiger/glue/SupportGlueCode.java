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

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.BinaryNode;
import com.fasterxml.jackson.databind.node.TextNode;
import de.gematik.rbellogger.data.facet.RbelCborFacet;
import de.gematik.test.tiger.lib.rbel.RbelMessageValidator;
import io.cucumber.java.en.When;

public class SupportGlueCode {

  @When("the current request at node {string} is a CBOR byte string")
  public void the_current_request_at_node_has_a_cbor_byte_string(String rbelPath) {
    final JsonNode node = extractJacksonNodeFromCurrentRequest(rbelPath);

    if (node instanceof TextNode) {
      throw new AssertionError("CBOR byte string at path: " + rbelPath + " is a TextNode but expected a BinaryNode");
    } else if (!(node instanceof BinaryNode)) {
      throw new AssertionError("CBOR byte string at path: " + rbelPath + " is not a BinaryNode");
    }
  }

  @When("the current request at node {string} has a CBOR byte string with length {int}")
  public void the_current_request_at_node_has_a_cbor_byte_string_with_length(String rbelPath, Integer length) {
    final JsonNode node = extractJacksonNodeFromCurrentRequest(rbelPath);

    if (node instanceof TextNode) {
      throw new AssertionError("CBOR byte string at path: " + rbelPath + " is a TextNode but expected a BinaryNode");
    } else if (node instanceof BinaryNode binaryNode) {
      final byte[] cbor = binaryNode.binaryValue();
      if (cbor.length != length) {
        throw new AssertionError(
          "CBOR byte string at path: " + rbelPath + " has length: " + cbor.length + " but expected: " + length);
      }
    } else {
      throw new AssertionError("CBOR byte string at path: " + rbelPath + " is not a BinaryNode");
    }
  }

  private static JsonNode extractJacksonNodeFromCurrentRequest(String rbelPath) {
    return RbelMessageValidator.getInstance().getCurrentRequest().findElement(rbelPath)
      .orElseThrow(() -> new AssertionError("Element not found in tree at path: " + rbelPath))
      .getParentNode().getFacet(RbelCborFacet.class)
      .orElseThrow(() -> new AssertionError("Element at path: " + rbelPath + " does not have a CBOR facet"))
      .getNode();
  }
}
