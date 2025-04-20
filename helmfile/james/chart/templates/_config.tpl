{{- define "james.config" -}}
deletedMessageVault.properties: |
  # ============================================= Deleted Messages Vault Configuration ==================================
  # Retention period for your deleted messages into the vault, after which they expire and can be potentially cleaned up
  # Optional, default 1y
  # retentionPeriod=1y
  enabled=false

dnsservice.xml: |
  <?xml version="1.0"?>
  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->
  <!-- Read https://james.apache.org/server/config-dnsservice.html for further details -->

  <dnsservice>
    <autodiscover>true</autodiscover>
    <authoritative>false</authoritative>
    <maxcachesize>50000</maxcachesize>
  </dnsservice>

domainlist.xml: |
  <?xml version="1.0"?>
  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <!-- Read https://james.apache.org/server/config-domainlist.html for further details -->

  <domainlist>
      <autodetect>false</autodetect>
      <autodetectIP>false</autodetectIP>
      <defaultDomain>localhost</defaultDomain>
  </domainlist>

elasticsearch.properties: |
  #  Licensed to the Apache Software Foundation (ASF) under one
  #  or more contributor license agreements.  See the NOTICE file
  #  distributed with this work for additional information
  #  regarding copyright ownership.  The ASF licenses this file
  #  to you under the Apache License, Version 2.0 (the
  #  "License"); you may not use this file except in compliance
  #  with the License.  You may obtain a copy of the License at
  #
  #    http://www.apache.org/licenses/LICENSE-2.0
  #
  #  Unless required by applicable law or agreed to in writing,
  #  software distributed under the License is distributed on an
  #  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  #  KIND, either express or implied.  See the License for the
  #  specific language governing permissions and limitations
  #  under the License.

  #  This template file can be used as example for James Server configuration
  #  DO NOT USE IT AS SUCH AND ADAPT IT TO YOUR NEEDS
  # Read https://james.apache.org/server/config-elasticsearch.html for further details (metrics only)


  # Configuration file for ElasticSearch

  # Reports for metrics into ElasticSearch
  # Defaults to elasticsearch.masterHost : on which server to publish metrics
  elasticsearch.http.host=elasticsearch
  elasticsearch.http.port=9200
  elasticsearch.metrics.reports.enabled=true
  elasticsearch.metrics.reports.period=30
  elasticsearch.metrics.reports.index=james-metrics

extensions.properties: |
  # This files enables customization of users extensions injections with guice.
  # A user can drop some jar-with-dependencies within the ./extensions-jars folder and
  # reference classes of these jars in some of James extension mechanisms.

  # This includes mailets, matchers, mailboxListeners, preDeletionHooks, protocolHandlers, webAdmin routes

  # Upon injections, the user can reference additional guice modules, that are going to be used only upon extensions instantiation.

  #List of coma separated (',') fully qualified class names of additional guice modules to be used to instantiate extensions
  #guice.extension.module=
healthcheck.properties: |
  #  Licensed to the Apache Software Foundation (ASF) under one
  #  or more contributor license agreements.  See the NOTICE file
  #  distributed with this work for additional information
  #  regarding copyright ownership.  The ASF licenses this file
  #  to you under the Apache License, Version 2.0 (the
  #  "License"); you may not use this file except in compliance
  #  with the License.  You may obtain a copy of the License at
  #
  #    http://www.apache.org/licenses/LICENSE-2.0
  #
  #  Unless required by applicable law or agreed to in writing,
  #  software distributed under the License is distributed on an
  #  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  #  KIND, either express or implied.  See the License for the
  #  specific language governing permissions and limitations
  #  under the License.

  #  This template file can be used as example for James Server configuration
  #  DO NOT USE IT AS SUCH AND ADAPT IT TO YOUR NEEDS

  # Configuration file for Periodical Health Checks

  # Read https://james.apache.org/server/config-healthcheck.html for further details

  # Optional. Period between two PeriodicalHealthChecks.
  # Units supported are (ms - millisecond, s - second, m - minute, h - hour, d - day). Default unit is millisecond.
  # Default duration is 60 seconds.
  # Duration must be greater or at least equals to 10 seconds.
  # healthcheck.period=60s


imapserver.xml: |
  <?xml version="1.0"?>

  <!--
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
  -->

  <!-- Read https://james.apache.org/server/config-imap4.html for further details -->


  <imapservers>
      <imapserver enabled="true">
          <jmxName>imapserver</jmxName>
          <bind>0.0.0.0:143</bind>
          <connectionBacklog>200</connectionBacklog>
          <tls socketTLS="false" startTLS="true">
              <!-- To create a new keystore execute:
              keytool -genkey -alias james -keyalg RSA -keystore /path/to/james/conf/keystore
                -->
              <keystore>file://conf/keystore</keystore>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
          </tls>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <idleTimeInterval>120</idleTimeInterval>
          <idleTimeIntervalUnit>SECONDS</idleTimeIntervalUnit>
          <enableIdle>true</enableIdle>
      </imapserver>
      <imapserver enabled="true">
          <jmxName>imapserver-ssl</jmxName>
          <bind>0.0.0.0:993</bind>
          <connectionBacklog>200</connectionBacklog>
          <tls socketTLS="true" startTLS="false">
              <!-- To create a new keystore execute:
                keytool -genkey -alias james -keyalg RSA -keystore /path/to/james/conf/keystore
               -->
              <keystore>file://conf/keystore</keystore>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
          </tls>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <idleTimeInterval>120</idleTimeInterval>
          <idleTimeIntervalUnit>SECONDS</idleTimeIntervalUnit>
          <enableIdle>true</enableIdle>
      </imapserver>
  </imapservers>

jmap.properties: |
  # Configuration file for JMAP
  # Read https://james.apache.org/server/config-jmap.html for further details

  enabled=true

  tls.keystoreURL=file://conf/keystore
  tls.secret=james72laBalle

  #
  # If you wish to use OAuth authentication, you should provide a valid JWT public key.
  # The following entry specify the link to the URL of the public key file,
  # which should be a PEM format file.
  #
  jwt.publickeypem.url=file://conf/jwt_publickey

  # Should simple Email/query be resolved against a Cassandra projection, or should we resolve them against ElasticSearch?
  # This enables a higher resilience, but the projection needs to be correctly populated. False by default.
  # view.email.query.enabled=true

jmx.properties: |
  #  Licensed to the Apache Software Foundation (ASF) under one
  #  or more contributor license agreements.  See the NOTICE file
  #  distributed with this work for additional information
  #  regarding copyright ownership.  The ASF licenses this file
  #  to you under the Apache License, Version 2.0 (the
  #  "License"); you may not use this file except in compliance
  #  with the License.  You may obtain a copy of the License at
  #
  #    http://www.apache.org/licenses/LICENSE-2.0
  #
  #  Unless required by applicable law or agreed to in writing,
  #  software distributed under the License is distributed on an
  #  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  #  KIND, either express or implied.  See the License for the
  #  specific language governing permissions and limitations
  #  under the License.
  #

  #  This template file can be used as example for James Server configuration
  #  DO NOT USE IT AS SUCH AND ADAPT IT TO YOUR NEEDS

  # Read https://james.apache.org/server/config-system.html#jmx.properties for further details

  jmx.enabled=true
  jmx.address=127.0.0.1
  jmx.port=9999

jwt_publickey: |
  -----BEGIN PUBLIC KEY-----
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtlChO/nlVP27MpdkG0Bh
  16XrMRf6M4NeyGa7j5+1UKm42IKUf3lM28oe82MqIIRyvskPc11NuzSor8HmvH8H
  lhDs5DyJtx2qp35AT0zCqfwlaDnlDc/QDlZv1CoRZGpQk1Inyh6SbZwYpxxwh0fi
  +d/4RpE3LBVo8wgOaXPylOlHxsDizfkL8QwXItyakBfMO6jWQRrj7/9WDhGf4Hi+
  GQur1tPGZDl9mvCoRHjFrD5M/yypIPlfMGWFVEvV5jClNMLAQ9bYFuOc7H1fEWw6
  U1LZUUbJW9/CH45YXz82CYqkrfbnQxqRb2iVbVjs/sHopHd1NTiCfUtwvcYJiBVj
  kwIDAQAB
  -----END PUBLIC KEY-----

listeners.xml: |
  <?xml version="1.0"?>
  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <!-- Read https://james.apache.org/server/config-listeners.html for further details -->

  <listeners>
    <listener>
      <class>org.apache.james.mailbox.spamassassin.SpamAssassinListener</class>
      <async>true</async>
    </listener>
    <preDeletionHook>
      <class>org.apache.james.vault.DeletedMessageVaultHook</class>
    </preDeletionHook>
  </listeners>

logback.xml: |
  <?xml version="1.0" encoding="UTF-8"?>
  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <configuration>

          <contextListener class="ch.qos.logback.classic.jul.LevelChangePropagator">
                  <resetJUL>true</resetJUL>
          </contextListener>

          <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
                  <encoder>
                          <pattern>%d{HH:mm:ss.SSS} %highlight([%-5level]) %logger{15} - %msg%n%rEx</pattern>
                          <immediateFlush>false</immediateFlush>
                  </encoder>
          </appender>

          <appender name="LOG_FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
                  <file>/logs/james.log</file>
                  <rollingPolicy class="ch.qos.logback.core.rolling.FixedWindowRollingPolicy">
                      <fileNamePattern>/logs/james.%i.log.tar.gz</fileNamePattern>
                      <minIndex>1</minIndex>
                      <maxIndex>3</maxIndex>
                  </rollingPolicy>

                  <triggeringPolicy class="ch.qos.logback.core.rolling.SizeBasedTriggeringPolicy">
                      <maxFileSize>100MB</maxFileSize>
                  </triggeringPolicy>

                  <encoder>
                          <pattern>%d{HH:mm:ss.SSS} [%-5level] %logger{15} - %msg%n%rEx</pattern>
                          <immediateFlush>false</immediateFlush>
                  </encoder>
          </appender>

          <root level="WARN">
                  <appender-ref ref="CONSOLE" />
                  <appender-ref ref="LOG_FILE" />
          </root>

          <logger name="org.apache.james" level="INFO" />
  </configuration>

mailetcontainer.xml: |
  <?xml version="1.0"?>

  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <!-- Read https://james.apache.org/server/config-mailetcontainer.html for further details -->

  <mailetcontainer enableJmx="true">

      <context>
          <!-- When the domain part of the postmaster mailAddress is missing, the default domain is appended.
          You can configure it to (for example) <postmaster>postmaster@myDomain.com</postmaster> -->
          <postmaster>postmaster</postmaster>
      </context>

      <spooler>
          <threads>20</threads>
          <errorRepository>memory://var/mail/error/</errorRepository>
      </spooler>

      <processors>
          <processor state="root" enableJmx="true">
              <mailet match="All" class="PostmasterAlias"/>
              <mailet match="RelayLimit=30" class="Null"/>
              <mailet match="All" class="ToProcessor">
                  <processor>transport</processor>
              </mailet>
          </processor>

          <processor state="error" enableJmx="true">
              <mailet match="All" class="MetricsMailet">
                  <metricName>mailetContainerErrors</metricName>
              </mailet>
              <mailet match="All" class="Bounce">
                  <onMailetException>ignore</onMailetException>
              </mailet>
              <mailet match="All" class="ToRepository">
                  <repositoryPath>memory://var/mail/error/</repositoryPath>
                  <onMailetException>ignore</onMailetException>
              </mailet>
          </processor>

          <processor state="transport" enableJmx="true">
              <matcher name="relay-allowed" match="org.apache.james.mailetcontainer.impl.matchers.Or">
                  <matcher match="SMTPAuthSuccessful"/>
                  <matcher match="SMTPIsAuthNetwork"/>
                  <matcher match="SentByMailet"/>
                  <matcher match="org.apache.james.jmap.mailet.SentByJmap"/>
              </matcher>

              <mailet match="All" class="RemoveMimeHeader">
                  <name>bcc</name>
                  <onMailetException>ignore</onMailetException>
              </mailet>
              <mailet match="All" class="RecipientRewriteTable">
                  <errorProcessor>rrt-error</errorProcessor>
              </mailet>
              <mailet match="RecipientIsLocal" class="ToProcessor">
                  <processor>local-delivery</processor>
              </mailet>
              <mailet match="HostIsLocal" class="ToProcessor">
                  <processor>local-address-error</processor>
                  <notice>550 - Requested action not taken: no such user here</notice>
              </mailet>
              <mailet match="relay-allowed" class="ToProcessor">
                  <processor>relay</processor>
              </mailet>
              <mailet match="All" class="ToProcessor">
                  <processor>relay-denied</processor>
              </mailet>
          </processor>

          <processor state="local-delivery" enableJmx="true">
              <mailet match="All" class="org.apache.james.jmap.mailet.VacationMailet"/>
              <mailet match="All" class="Sieve"/>
              <mailet match="All" class="AddDeliveredToHeader"/>
              <mailet match="All" class="org.apache.james.jmap.mailet.filter.JMAPFiltering"/>
              <mailet match="All" class="LocalDelivery"/>
          </processor>

          <processor state="relay" enableJmx="true">
              <mailet match="All" class="RemoteDelivery">
                  <outgoingQueue>outgoing</outgoingQueue>
                  <delayTime>5000, 100000, 500000</delayTime>
                  <maxRetries>3</maxRetries>
                  <maxDnsProblemRetries>0</maxDnsProblemRetries>
                  <deliveryThreads>10</deliveryThreads>
                  <sendpartial>true</sendpartial>
                  <bounceProcessor>bounces</bounceProcessor>
              </mailet>
          </processor>

          <processor state="local-address-error" enableJmx="true">
              <mailet match="All" class="MetricsMailet">
                  <metricName>mailetContainerLocalAddressError</metricName>
              </mailet>
              <mailet match="All" class="Bounce">
                  <attachment>none</attachment>
              </mailet>
              <mailet match="All" class="ToRepository">
                  <repositoryPath>memory://var/mail/address-error/</repositoryPath>
              </mailet>
          </processor>

          <processor state="relay-denied" enableJmx="true">
              <mailet match="All" class="MetricsMailet">
                  <metricName>mailetContainerRelayDenied</metricName>
              </mailet>
              <mailet match="All" class="Bounce">
                  <attachment>none</attachment>
              </mailet>
              <mailet match="All" class="ToRepository">
                  <repositoryPath>memory://var/mail/relay-denied/</repositoryPath>
                  <notice>Warning: You are sending an e-mail to a remote server. You must be authenticated to perform such an operation</notice>
              </mailet>
          </processor>

          <processor state="bounces" enableJmx="true">
              <mailet match="All" class="MetricsMailet">
                  <metricName>bounces</metricName>
              </mailet>
              <mailet match="All" class="DSNBounce">
                  <passThrough>false</passThrough>
              </mailet>
          </processor>

          <processor state="rrt-error" enableJmx="false">
              <mailet match="All" class="ToRepository">
                  <repositoryPath>memory://var/mail/rrt-error/</repositoryPath>
                  <passThrough>true</passThrough>
              </mailet>
              <mailet match="IsSenderInRRTLoop" class="Null"/>
              <mailet match="All" class="Bounce"/>
          </processor>

      </processors>

  </mailetcontainer>



mailrepositorystore.xml: |
  <?xml version="1.0"?>

  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <!-- Read https://james.apache.org/server/config-mailrepositorystore.html for further details -->

  <mailrepositorystore>
      <defaultProtocol>memory</defaultProtocol>
      <mailrepositories>
          <mailrepository class="org.apache.james.mailrepository.memory.MemoryMailRepository">
              <protocols>
                  <protocol>memory</protocol>
              </protocols>
          </mailrepository>
      </mailrepositories>
  </mailrepositorystore>

managesieveserver.xml: |
  <?xml version="1.0"?>
  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <!--
     This template file can be used as example for James Server configuration
     DO NOT USE IT AS SUCH AND ADAPT IT TO YOUR NEEDS
  -->

  <!-- See http://james.apache.org/server/3/config.html for usage -->

  <managesieveservers>

     <managesieveserver enabled="false">

       <jmxName>managesieveserver</jmxName>

       <bind>0.0.0.0:4190</bind>

       <connectionBacklog>200</connectionBacklog>

       <tls socketTLS="false" startTLS="false">
         <!-- To create a new keystore execute:
          keytool -genkey -alias james -keyalg RSA -keystore /path/to/james/conf/keystore
           -->
         <keystore>file://conf/keystore</keystore>
         <secret>james72laBalle</secret>
         <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
         <!-- The algorithm is optional and only needs to be specified when using something other
          than the Sun JCE provider - You could use IbmX509 with IBM Java runtime. -->
         <algorithm>SunX509</algorithm>
       </tls>

          <!-- connection timeout in secconds -->
          <connectiontimeout>360</connectiontimeout>

          <!-- Set the maximum simultaneous incoming connections for this service -->
          <connectionLimit>0</connectionLimit>

          <!-- Set the maximum simultaneous incoming connections per IP for this service -->
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <maxmessagesize>0</maxmessagesize>
          <addressBracketsEnforcement>true</addressBracketsEnforcement>

     </managesieveserver>

  </managesieveservers>



pop3server.xml: |
  <?xml version="1.0"?>
  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <!-- Read https://james.apache.org/server/config-pop3.html for further details -->

  <pop3servers>
      <pop3server enabled="false">
          <jmxName>pop3server</jmxName>
          <bind>0.0.0.0:110</bind>
          <connectionBacklog>200</connectionBacklog>
          <tls socketTLS="false" startTLS="false">
              <!-- To create a new keystore execute:
                    keytool -genkey -alias james -keyalg RSA -keystore /path/to/james/conf/keystore
               -->
              <keystore>file://conf/keystore</keystore>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
          </tls>
          <connectiontimeout>1200</connectiontimeout>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <handlerchain>
              <handler class="org.apache.james.pop3server.core.CoreCmdHandlerLoader"/>
          </handlerchain>
      </pop3server>
  </pop3servers>

recipientrewritetable.xml: |
  <?xml version="1.0"?>
  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <!-- Read https://james.apache.org/server/config-recipientrewritetable.html for further details -->

  <!-- The default table for storing James' RecipientRewriteTable mappings. -->
  <recipientrewritetable>
    <recursiveMapping>true</recursiveMapping>
    <mappingLimit>10</mappingLimit>
  </recipientrewritetable>


smtpserver.xml: |
  <?xml version="1.0"?>

  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <!-- Read https://james.apache.org/server/config-smtp-lmtp.html#SMTP_Configuration for further details -->

  <smtpservers>
      <smtpserver enabled="true">
          <jmxName>smtpserver-global</jmxName>
          <bind>0.0.0.0:25</bind>
          <connectionBacklog>200</connectionBacklog>
          <tls socketTLS="false" startTLS="false">
              <keystore>file://conf/keystore</keystore>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
              <algorithm>SunX509</algorithm>
          </tls>
          <connectiontimeout>360</connectiontimeout>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <authRequired>false</authRequired>
          <authorizedAddresses>127.0.0.0/8</authorizedAddresses>
          <verifyIdentity>true</verifyIdentity>
          <maxmessagesize>0</maxmessagesize>
          <addressBracketsEnforcement>true</addressBracketsEnforcement>
          <smtpGreeting>Apache JAMES awesome SMTP Server</smtpGreeting>
          <handlerchain>
              <handler class="org.apache.james.smtpserver.fastfail.ValidRcptHandler"/>
              <handler class="org.apache.james.smtpserver.CoreCmdHandlerLoader"/>
          </handlerchain>
      </smtpserver>
      <smtpserver enabled="true">
          <jmxName>smtpserver-TLS</jmxName>
          <bind>0.0.0.0:465</bind>
          <connectionBacklog>200</connectionBacklog>
          <tls socketTLS="true" startTLS="false">
              <keystore>file://conf/keystore</keystore>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
              <algorithm>SunX509</algorithm>
          </tls>
          <connectiontimeout>360</connectiontimeout>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <!--
             Authorize only local users
          -->
          <authRequired>true</authRequired>
          <authorizedAddresses>127.0.0.0/8</authorizedAddresses>
          <!-- Trust authenticated users -->
          <verifyIdentity>false</verifyIdentity>
          <maxmessagesize>0</maxmessagesize>
          <addressBracketsEnforcement>true</addressBracketsEnforcement>
          <smtpGreeting>Apache JAMES awesome SMTP Server</smtpGreeting>
          <handlerchain>
              <handler class="org.apache.james.smtpserver.fastfail.ValidRcptHandler"/>
              <handler class="org.apache.james.smtpserver.CoreCmdHandlerLoader"/>
          </handlerchain>
      </smtpserver>
      <smtpserver enabled="true">
          <jmxName>smtpserver-authenticated</jmxName>
          <bind>0.0.0.0:587</bind>
          <connectionBacklog>200</connectionBacklog>
          <tls socketTLS="false" startTLS="true">
              <keystore>file://conf/keystore</keystore>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
              <algorithm>SunX509</algorithm>
          </tls>
          <connectiontimeout>360</connectiontimeout>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <!--
             Authorize only local users
          -->
          <authRequired>true</authRequired>
          <authorizedAddresses>127.0.0.0/8</authorizedAddresses>
          <!-- Trust authenticated users -->
          <verifyIdentity>false</verifyIdentity>
          <maxmessagesize>0</maxmessagesize>
          <addressBracketsEnforcement>true</addressBracketsEnforcement>
          <smtpGreeting>Apache JAMES awesome SMTP Server</smtpGreeting>
          <handlerchain>
              <handler class="org.apache.james.smtpserver.fastfail.ValidRcptHandler"/>
              <handler class="org.apache.james.smtpserver.CoreCmdHandlerLoader"/>
          </handlerchain>
      </smtpserver>
  </smtpservers>



usersrepository.xml: |
  <?xml version="1.0"?>
  <!--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
   -->

  <!-- Read https://james.apache.org/server/config-users.html for further details -->

  <usersrepository name="LocalUsers">
      <algorithm>SHA-512</algorithm>
      <enableVirtualHosting>true</enableVirtualHosting>
      <enableForwarding>true</enableForwarding>
  </usersrepository>


webadmin.properties: |
  #  Licensed to the Apache Software Foundation (ASF) under one
  #  or more contributor license agreements.  See the NOTICE file
  #  distributed with this work for additional information
  #  regarding copyright ownership.  The ASF licenses this file
  #  to you under the Apache License, Version 2.0 (the
  #  "License"); you may not use this file except in compliance
  #  with the License.  You may obtain a copy of the License at
  #
  #    http://www.apache.org/licenses/LICENSE-2.0
  #
  #  Unless required by applicable law or agreed to in writing,
  #  software distributed under the License is distributed on an
  #  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  #  KIND, either express or implied.  See the License for the
  #  specific language governing permissions and limitations
  #  under the License.

  #  This template file can be used as example for James Server configuration
  #  DO NOT USE IT AS SUCH AND ADAPT IT TO YOUR NEEDS

  # Read https://james.apache.org/server/config-webadmin.html for further details

  enabled=true
  port=8000
  host=localhost

  # Defaults to false
  https.enabled=false

  # Compulsory when enabling HTTPS
  #https.keystore=/path/to/keystore
  #https.password=password

  # Optional when enabling HTTPS (self signed)
  #https.trust.keystore
  #https.trust.password

  # Defaults to false
  #jwt.enabled=true
  #
  ## If you wish to use OAuth authentication, you should provide a valid JWT public key.
  ## The following entry specify the link to the URL of the public key file,
  ## which should be a PEM format file.
  ##
  #jwt.publickeypem.url=file://conf/jwt_publickey

  # Defaults to false
  #cors.enable=true
  #cors.origin


  # List of fully qualified class names that should be exposed over webadmin
  # in addition to your product default routes. Routes needs to be located
  # within the classpath or in the ./extensions-jars folder.
  #extensions.routes=

postgres.properties: |
    # String. Optional, default to 'postgres'. Database name.
    database.name=james

    # String. Optional, default to 'public'. Database schema.
    database.schema=public

    # String. Optional, default to 'localhost'. Database host.
    database.host=postgres

    # Integer. Optional, default to 5432. Database port.
    database.port=5432

    # String. Required. Database username.
    database.username=james

    # String. Required. Database password of the user.
    database.password={{ (.Values.database).password | default "postgres" }}

    # Boolean. Optional, default to false. Whether to enable row level security.
    row.level.security.enabled=false

    # String. It is required when row.level.security.enabled is true. Database username with the permission of bypassing RLS.
    #database.by-pass-rls.username=bypassrlsjames

    # String. It is required when row.level.security.enabled is true. Database password of by-pass-rls user.
    #database.by-pass-rls.password=secret1

    # Integer. Optional, default to 10. Database connection pool initial size.
    pool.initial.size=10

    # Integer. Optional, default to 15. Database connection pool max size.
    pool.max.size=15

    # Integer. Optional, default to 5. rls-bypass database connection pool initial size.
    by-pass-rls.pool.initial.size=5

    # Integer. Optional, default to 10. rls-bypass database connection pool max size.
    by-pass-rls.pool.max.size=10

    # String. Optional, defaults to allow. SSLMode required to connect to the Postgresql db server.
    # Check https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for a list of supported SSLModes.
    ssl.mode=allow

    ## Duration. Optional, defaults to 10 second. jOOQ reactive timeout when executing Postgres query. This setting prevent jooq reactive bug from causing hanging issue.
    #jooq.reactive.timeout=10second
jvm.properties: |
    # ============================================= Extra JVM System Properties ===========================================
    # To avoid clutter on the command line, any properties in this file will be added as system properties on server start.

    # Example: If you need an option -Dmy.property=whatever, you can instead add it here as
    # my.property=whatever

    # (Optional). String (size, integer + size units, example: `12 KIB`, supported units are bytes KIB MIB GIB TIB). Defaults to 100KIB.
    # This governs the threshold MimeMessageInputStreamSource relies on for storing MimeMessage content on disk.
    # Below, data is stored in memory. Above data is stored on disk.
    # Lower values will lead to longer processing time but will minimize heap memory usage. Modern SSD hardware
    # should however support a high throughput. Higher values will lead to faster single mail processing at the cost
    # of higher heap usage.
    #james.message.memory.threshold=12K

    # Optional. Boolean. Defaults to false. Recommended value is false.
    # Should MimeMessageWrapper use a copy of the message in memory? Or should bigger message exceeding james.message.memory.threshold
    # be copied to temporary files?
    #james.message.usememorycopy=false

    # Mode level of resource leak detection. It is used to detect a resource not be disposed of before it's garbage-collected.
    # Example `MimeMessageInputStreamSource`
    # Optional. Allowed values are: none, simple, advanced, testing
    #   - none: Disables resource leak detection.
    #   - simple: Enables output a simplistic error log if a leak is encountered and would free the resources (default).
    #   - advanced: Enables output an advanced error log implying the place of allocation of the underlying object and would free resources.
    #   - testing: Enables output an advanced error log implying the place of allocation of the underlying object and rethrow an error, that action is being taken by the development team.
    #james.lifecycle.leak.detection.mode=simple

    # Should we add the host in the MDC logging context for incoming IMAP, SMTP, POP3? Doing so, a DNS resolution
    # is attempted for each incoming connection, which can be costly. Remote IP is always added to the logging context.
    # Optional. Boolean. Defaults to true.
    #james.protocols.mdc.hostname=true

    # Manage netty leak detection level see https://netty.io/wiki/reference-counted-objects.html#leak-detection-levels
    # io.netty.leakDetection.level=SIMPLE

    # Should James exit on Startup error? Boolean, defaults to true. This prevents partial startup.
    # james.exit.on.startup.error=true

    # Fails explicitly on missing configuration file rather that taking implicit values. Defautls to false.
    # james.fail.on.missing.configuration=true

    # JMX, when enable causes RMI to plan System.gc every hour. Set this instead to once every 1000h.
    sun.rmi.dgc.server.gcInterval=3600000000
    sun.rmi.dgc.client.gcInterval=3600000000

    # Automatically generate a JMX password upon start. CLI is able to retrieve this password.
    james.jmx.credential.generation=true

    # Disable Remote Code Execution feature from JMX
    # CF https://github.com/AdoptOpenJDK/openjdk-jdk11/blob/19fb8f93c59dfd791f62d41f332db9e306bc1422/src/java.management/share/classes/com/sun/jmx/remote/security/MBeanServerAccessController.java#L646
    jmx.remote.x.mlet.allow.getMBeansFromURL=false

    # Integer. Optional, defaults to 5000. In case of large data, this argument specifies the maximum number of rows to return in a single batch set when executing query.
    #query.batch.size=5000
droplists.properties: |
  enabled=false
{{- end }}