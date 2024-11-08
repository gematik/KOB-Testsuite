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

import de.gematik.test.tiger.lib.TigerDirector;
import de.gematik.test.tiger.proxy.TigerProxy;
import io.cucumber.java.BeforeAll;
import java.net.URI;
import java.util.List;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@NoArgsConstructor(access = AccessLevel.PRIVATE)
public class ConfigureAsRoutes {
  private static TigerProxy tigerProxy;

  @BeforeAll
  public static void configureRoutes() {
    tigerProxy =
        TigerDirector.getTigerTestEnvMgr()
            .getLocalTigerProxyOptional()
            .orElseThrow(() -> new IllegalStateException("TigerProxy not available"));
    selectOnlineIpForRouteWithHost("epa-as-1.dev", List.of("10.30.19.70", "10.30.19.135"));
  }

  private static void selectOnlineIpForRouteWithHost(
      String hostPartialHit, List<String> potentialIpAdresses) {
    tigerProxy.getRoutes().stream()
        .filter(route -> route.getHosts().stream().anyMatch(host -> host.contains(hostPartialHit)))
        .findFirst()
        .ifPresentOrElse(
            route -> {
              log.info("Selecting online IP for route {}", route);
              route.setTo("https://" + findFirstOnlineHost(potentialIpAdresses));
            },
            () -> log.info("No route found with host containing '{}', skipping...", hostPartialHit));
  }

  private static String findFirstOnlineHost(List<String> potentialIpAdresses) {
    return potentialIpAdresses.stream()
        .filter(
            ip -> {
              try {
                log.info("Checking if host {} is online", ip);
                new URI("https://" + ip).toURL().openConnection();
                log.info("Host {} is online", ip);
                return true;
              } catch (Exception e) {
                return false;
              }
            })
        .findFirst()
        .orElseThrow(
            () -> new IllegalStateException("No online host found in list " + potentialIpAdresses));
  }
}
