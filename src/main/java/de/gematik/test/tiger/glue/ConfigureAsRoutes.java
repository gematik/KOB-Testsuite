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

import de.gematik.test.tiger.common.data.config.tigerproxy.ForwardProxyInfo;
import de.gematik.test.tiger.lib.TigerDirector;
import de.gematik.test.tiger.proxy.TigerProxy;
import de.gematik.test.tiger.testenvmgr.util.InsecureTrustAllManager;
import de.gematik.test.tiger.util.NoProxyUtils;
import io.cucumber.java.BeforeAll;
import java.io.IOException;
import java.net.*;
import java.net.Proxy.Type;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.security.cert.X509Certificate;
import java.time.Duration;
import java.util.List;
import javax.net.ssl.*;
import lombok.AccessLevel;
import lombok.NoArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@NoArgsConstructor(access = AccessLevel.PRIVATE)
public class ConfigureAsRoutes {
  private static TigerProxy tigerProxy;
  private static ForwardProxyInfo forwardProxyInfo;

  @BeforeAll
  public static void configureRoutes() {
    tigerProxy =
        TigerDirector.getTigerTestEnvMgr()
            .getLocalTigerProxyOptional()
            .orElseThrow(() -> new IllegalStateException("TigerProxy not available"));
    forwardProxyInfo = tigerProxy.getTigerProxyConfiguration().getForwardToProxy();
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
            () ->
                log.info("No route found with host containing '{}', skipping...", hostPartialHit));
  }

  private static String findFirstOnlineHost(List<String> potentialIpAdresses) {
    return potentialIpAdresses.stream()
        .filter(ConfigureAsRoutes::isReachable)
        .findFirst()
        .orElseThrow(
            () -> new IllegalStateException("No online host found in list " + potentialIpAdresses));
  }

  private static boolean isReachable(String destination) {
    try {
      HttpClient.Builder clientBuilder =
          HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(10));

      if (forwardProxyInfo != null) {
        final InetAddress targetHost = InetAddress.getByName(forwardProxyInfo.getHostname());
        if (NoProxyUtils.shouldUseProxyForHost(targetHost, forwardProxyInfo.getNoProxyHosts())) {
          clientBuilder.proxy(
              ProxySelector.of(new InetSocketAddress(targetHost, forwardProxyInfo.getPort())));
        }
      }
      SSLParameters sslParameters = new SSLParameters();
      sslParameters.setEndpointIdentificationAlgorithm(null);
      clientBuilder.sslParameters(sslParameters);
      clientBuilder.sslContext(insecureSSLContext());

      HttpClient client = clientBuilder.build();
      HttpRequest request =
          HttpRequest.newBuilder()
              .uri(URI.create("https://" + destination))
              .method("HEAD", HttpRequest.BodyPublishers.noBody())
              .timeout(Duration.ofSeconds(5))
              .build();

      client.send(request, HttpResponse.BodyHandlers.discarding());
      //client.close(); JAVA 21 only
      return true;
    } catch (IOException e) {
      log.atInfo().addArgument(e.getMessage()).log("Error checking host: {}");
      return false;
    } catch (InterruptedException e) {
      Thread.currentThread().interrupt();
      return false;
    }
  }

  private static SSLContext insecureSSLContext() {
    try {
      SSLContext sslContext = SSLContext.getInstance("TLS");
      sslContext.init(
          null,
          new TrustManager[] {
            new X509ExtendedTrustManager() {
              @Override
              public void checkClientTrusted(
                  X509Certificate[] chain, String authType, Socket socket) {}

              @Override
              public void checkServerTrusted(
                  X509Certificate[] chain, String authType, Socket socket) {}

              @Override
              public void checkClientTrusted(
                  X509Certificate[] chain, String authType, SSLEngine engine) {}

              @Override
              public void checkServerTrusted(
                  X509Certificate[] chain, String authType, SSLEngine engine) {}

              @Override
              public java.security.cert.X509Certificate[] getAcceptedIssuers() {
                return null;
              }

              @Override
              public void checkClientTrusted(X509Certificate[] certs, String authType) {}

              @Override
              public void checkServerTrusted(X509Certificate[] certs, String authType) {}
            }
          },
          null);
      return sslContext;
    } catch (Exception e) {
      throw new RuntimeException("Failed to create insecure SSL context", e);
    }
  }
}
