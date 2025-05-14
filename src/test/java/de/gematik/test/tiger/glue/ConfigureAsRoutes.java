package de.gematik.test.tiger.glue;

/*-
 * #%L
 * kob-testsuite
 * %%
 * Copyright (C) 2024 - 2025 gematik GmbH
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

import com.fasterxml.jackson.core.type.TypeReference;
import de.gematik.test.tiger.common.config.TigerGlobalConfiguration;
import de.gematik.test.tiger.common.data.config.tigerproxy.ForwardProxyInfo;
import de.gematik.test.tiger.lib.TigerDirector;
import de.gematik.test.tiger.proxy.TigerProxy;
import de.gematik.test.tiger.proxy.TigerRouteSelector;
import lombok.*;
import lombok.extern.slf4j.Slf4j;

import java.util.List;
import org.apache.commons.collections4.CollectionUtils;

@Slf4j
@NoArgsConstructor(access = AccessLevel.PRIVATE)
public class ConfigureAsRoutes {
  private static TigerProxy tigerProxy;
  private static ForwardProxyInfo forwardProxyInfo;
  private static boolean foundAktenSystem = false;

  @Data
  @NoArgsConstructor
  @AllArgsConstructor
  @Builder
  public static class AsRouteDefinition {
    private String targetHost;
    private List<String> ips;
  }

  public static synchronized void configureRoutes() {
    if (!foundAktenSystem) {
      tigerProxy =
          TigerDirector.getTigerTestEnvMgr()
              .getLocalTigerProxyOptional()
              .orElseThrow(() -> new IllegalStateException("TigerProxy not available"));
      forwardProxyInfo = tigerProxy.getTigerProxyConfiguration().getForwardToProxy();
      TigerGlobalConfiguration.instantiateConfigurationBean(
              new TypeReference<List<AsRouteDefinition>>() {}, "kob.asSelection")
          .forEach(
              route ->
                  selectOnlineIpForRouteWithHost(
                      route.getTargetHost(),
                      route.getIps().stream().map(ip -> "https://" + ip).toList()));
      foundAktenSystem = true;
    }
  }

  private static void selectOnlineIpForRouteWithHost(
      String hostPartialHit, List<String> potentialIpAdresses) {
    log.info("Selecting target for host {} from list {}", hostPartialHit, potentialIpAdresses);
    tigerProxy.getRoutes().stream()
        .filter(route -> CollectionUtils.isNotEmpty(route.getHosts()))
        .filter(route -> route.getHosts().stream().anyMatch(host -> host.contains(hostPartialHit)))
        .findFirst()
        .ifPresentOrElse(
            route -> {
              log.info("Selecting online IP for route {}", route.createShortDescription());
              route.setTo(findFirstOnlineHost(potentialIpAdresses));
            },
            () ->
                log.info("No route found with host containing '{}', skipping...", hostPartialHit));
  }

  private static String findFirstOnlineHost(List<String> potentialIpAdresses) {
    return new TigerRouteSelector(potentialIpAdresses, forwardProxyInfo)
        .selectFirstReachableDestination();
  }
}
