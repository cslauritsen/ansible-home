{{- define "james.config" -}}
{{- $fullname := include "james.fullname" . -}}
{{- with .Values.blobStore }}
blob.properties: |
  # ============================================= BlobStore Implementation ==================================
  # Read https://james.apache.org/server/config-blobstore.html for further details

  # Choose your BlobStore implementation
  # Mandatory, allowed values are: file, s3, postgres.
  implementation={{ .implementation | default "postgres" }}

  # ========================================= Deduplication ========================================
  # If you choose to enable deduplication, the mails with the same content will be stored only once.
  # Warning: Once this feature is enabled, there is no turning back as turning it off will lead to the deletion of all
  # the mails sharing the same content once one is deleted.
  # Mandatory, Allowed values are: true, false
  deduplication.enable={{ .deduplication }}

  # deduplication.family needs to be incremented every time the deduplication.generation.duration is changed
  # Positive integer, defaults to 1
  # deduplication.gc.generation.family=1

  # Duration of generation.
  # Deduplication only takes place within a singe generation.
  # Only items two generation old can be garbage collected. (This prevent concurrent insertions issues and
  # accounts for a clock skew).
  # deduplication.family needs to be incremented everytime this parameter is changed.
  # Duration. Default unit: days. Defaults to 30 days.
  # deduplication.gc.generation.duration=30days

  # ========================================= Encryption ========================================
  # If you choose to enable encryption, the blob content will be encrypted before storing them in the BlobStore.
  # Warning: Once this feature is enabled, there is no turning back as turning it off will lead to all content being
  # encrypted. This comes at a performance impact but presents you from leaking data if, for instance the third party
  # offering you a S3 service is compromised.
  # Optional, Allowed values are: true, false, defaults to false
  {{- with .encryption }}
  encryption.aes.enable={{ .enabled }}
    {{- if .enabled }}
  # Mandatory (if AES encryption is enabled) salt and password. Salt needs to be an hexadecimal encoded string
  encryption.aes.password={{ required "blobStore.encryption.password is required" .password }}
  encryption.aes.salt={{ required "blobStore.encryption.salt is required" .salt }}
  # Optional, defaults to PBKDF2WithHmacSHA512
  encryption.aes.private.key.algorithm={{ .alg | default "PBKDF2WithHmacSHA512" }}
    {{- end }}
{{- end }}

{{- if eq .implementation "s3" }}
    {{- with .s3 }}
  objectstorage.namespace={{required "S3 bucket name is required" .bucketName }}
  objectstorage.s3.endPoint=https://s3.{{ required "S3 region is required" .region }}.amazonaws.com
  objectstorage.s3.region={{ required "S3 region is required" .region }}
  objectstorage.s3.accessKeyId={{ required "S3 accessKey is required" .accessKey }}
  objectstorage.s3.secretKey={{ required "S3 secretKey is required" .secretKey }}
    {{- end }}
 {{- end }}
  # ============================================ Blobs Exporting ==============================================
  # Read https://james.apache.org/server/config-blob-export.html for further details

  # Choosing blob exporting mechanism, allowed mechanism are: localFile, linshare
  # LinShare is a file sharing service, will be explained in the below section
  # Optional, default is localFile
  blob.export.implementation=localFile

  # ======================================= Local File Blobs Exporting ========================================
  # Optional, directory to store exported blob, directory path follows James file system format
  # default is file://var/blobExporting
  blob.export.localFile.directory=file://var/blobExporting

  # ======================================= LinShare File Blobs Exporting ========================================
  # LinShare is a sharing service where you can use james, connects to an existing LinShare server and shares files to
  # other mail addresses as long as those addresses available in LinShare. For example you can deploy James and LinShare
  # sharing the same LDAP repository
  # Mandatory if you choose LinShare, url to connect to LinShare service
  # blob.export.linshare.url=http://linshare:8080

  # ======================================= LinShare Configuration BasicAuthentication ===================================
  # Authentication is mandatory if you choose LinShare, TechnicalAccount is need to connect to LinShare specific service.
  # For Example: It will be formalized to 'Authorization: Basic {Credential of UUID/password}'

  # blob.export.linshare.technical.account.uuid=Technical_Account_UUID
  # blob.export.linshare.technical.account.password=password
{{- end }}
deletedMessageVault.properties: |
  # ============================================= Deleted Messages Vault Configuration ==================================

  enabled=false

  # Retention period for your deleted messages into the vault, after which they expire and can be potentially cleaned up
  # Optional, default 1y
  # retentionPeriod=1y
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

droplists.properties: |
  # Configuration file for DropLists

  enabled=false
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

  # List of fully qualified HealthCheck class names in addition to James' default healthchecks.
  # Healthchecks need to be located within the classpath or in the ./extensions-jars folder.
  # additional.healthchecks=

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
            {{- if .Values.certManager }}
                <privateKey>file://conf/tls/tls.key</privateKey>
                <certificates>file://conf/tls/tls.crt</certificates>
            {{- else }}
              <!-- To create a new keystore execute:
                keytool -genkey -alias james -keyalg RSA -storetype PKCS12 -keystore /path/to/james/conf/keystore
               -->
              <keystore>file://conf/keystore</keystore>
              <keystoreType>PKCS12</keystoreType>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
              <algorithm>SunX509</algorithm>

              <!-- Alternatively TLS keys can be supplied via PEM files -->
              <!-- <privateKey>file://conf/private.key</privateKey> -->
              <!-- <certificates>file://conf/certs.self-signed.csr</certificates> -->
              <!-- An optional secret might be specified for the private key -->
              <!-- <secret>james72laBalle</secret> -->
              {{- end }}
          </tls>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <idleTimeInterval>120</idleTimeInterval>
          <idleTimeIntervalUnit>SECONDS</idleTimeIntervalUnit>
          <enableIdle>true</enableIdle>
          <plainAuthDisallowed>false</plainAuthDisallowed>
          <auth>
              <plainAuthEnabled>true</plainAuthEnabled>
          </auth>
      </imapserver>
      <imapserver enabled="true">
          <jmxName>imapserver-ssl</jmxName>
          <bind>0.0.0.0:993</bind>
          <connectionBacklog>200</connectionBacklog>
          <tls socketTLS="true" startTLS="false">
            {{- if .Values.certManager }}
                <privateKey>file://conf/tls/tls.key</privateKey>
                <certificates>file://conf/tls/tls.crt</certificates>
            {{- else }}
              <!-- To create a new keystore execute:
                keytool -genkey -alias james -keyalg RSA -storetype PKCS12 -keystore /path/to/james/conf/keystore
               -->
              <keystore>file://conf/keystore</keystore>
              <keystoreType>PKCS12</keystoreType>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
              <algorithm>SunX509</algorithm>

              <!-- Alternatively TLS keys can be supplied via PEM files -->
              <!-- <privateKey>file://conf/private.key</privateKey> -->
              <!-- <certificates>file://conf/certs.self-signed.csr</certificates> -->
              <!-- An optional secret might be specified for the private key -->
              <!-- <secret>james72laBalle</secret> -->
              {{- end }}
          </tls>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <idleTimeInterval>120</idleTimeInterval>
          <idleTimeIntervalUnit>SECONDS</idleTimeIntervalUnit>
          <enableIdle>true</enableIdle>
          <auth>
              <plainAuthEnabled>true</plainAuthEnabled>
          </auth>
      </imapserver>
  </imapservers>

jmap.properties: |
  # Configuration file for JMAP
  # Read https://james.apache.org/server/config-jmap.html for further details

  enabled=true

  tls.keystoreURL=file://conf/keystore
  tls.secret=james72laBalle

  # only not work for RabbitMQ mail queue
  #delay.sends.enabled=true

  # Alternatively TLS keys can be supplied via PEM files
  # tls.privateKey=file://conf/private.nopass.key
  # tls.certificates=file://conf/certs.self-signed.csr
  # An optional secret might be specified for the private key
  # tls.secret=james72laBalle

  #
  # If you wish to use OAuth authentication, you should provide a valid JWT public key.
  # The following entry specify the link to the URL of the public key file,
  # which should be a PEM format file.
  #
  # jwt.publickeypem.url=file://conf/jwt_publickey

  # Should simple Email/query be resolved against a Cassandra projection, or should we resolve them against OpenSearch?
  # This enables a higher resilience, but the projection needs to be correctly populated. False by default.
  # view.email.query.enabled=true

  # If you want to specify authentication strategies for Jmap rfc-8621 version
  # For custom Authentication Strategy not inside package "org.apache.james.jmap.http", you have to specify its FQDN
  # authentication.strategy.rfc8621=JWTAuthenticationStrategy,BasicAuthenticationStrategy

  # Prevent server side request forgery by preventing calls to the private network ranges. Defaults to true, can be disabled for testing.
  # webpush.prevent.server.side.request.forgery=false
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
  </listeners>
lmtpserver.xml: |
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

  <!-- Read https://james.apache.org/server/config-smtp-lmtp.html#LMTP_Configuration for further details -->

  <lmtpservers>

      <lmtpserver enabled="false">
          <jmxName>lmtpserver</jmxName>
          <!-- LMTP should not be reachable from outside your network so bind it to loopback-->
          <bind>127.0.0.1:24</bind>
          <connectionBacklog>200</connectionBacklog>
          <connectiontimeout>1200</connectiontimeout>
          <!-- Set the maximum simultaneous incoming connections for this service -->
          <connectionLimit>0</connectionLimit>
          <!-- Set the maximum simultaneous incoming connections per IP for this service -->
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <!--  This sets the maximum allowed message size (in kilobytes) for this -->
          <!--  LMTP service. If unspecified, the value defaults to 0, which means no limit. -->
          <maxmessagesize>0</maxmessagesize>
          <handlerchain>
              <handler class="org.apache.james.lmtpserver.CoreCmdHandlerLoader"/>
          </handlerchain>
      </lmtpserver>

  </lmtpservers>

logback.xml: |
  <?xml version="1.0" encoding="UTF-8"?>
  <configuration scan="true" scanPeriod="30 seconds">
          <contextListener class="ch.qos.logback.classic.jul.LevelChangePropagator">
            <resetJUL>true</resetJUL>
          </contextListener>
          <!-- in kubernetes, produce json output -->
          <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
            <encoder class="ch.qos.logback.classic.encoder.JsonEncoder">
              <withFormattedMessage>true</withFormattedMessage>
            </encoder>
          </appender>

          <root level="WARN">
                  <appender-ref ref="CONSOLE" />
          </root>

          <logger name="org.apache.james" level="INFO" />
          <logger name="org.apache.james.webadmin.mdc" level="WARN" />
          <logger name="org.apache.james.imapserver" level="DEBUG" />
          <logger name="org.apache.james.transport.mailets.RemoteDelivery" level="DEBUG"/>
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
          <errorRepository>postgres://var/mail/error/</errorRepository>
      </spooler>

      <processors>
          <processor state="root" enableJmx="true">
              <mailet match="All" class="PostmasterAlias"/>
              <mailet match="RelayLimit=30" class="ToRepository">
                  <repositoryPath>postgres://var/mail/relay-limit-exceeded/</repositoryPath>
              </mailet>
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
                  <repositoryPath>postgres://var/mail/error/</repositoryPath>
                  <onMailetException>propagate</onMailetException>
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
              <mailet match="All" class="RemoveMimeHeader">
                  <name>X-SMIME-Status</name>
                  <onMailetException>ignore</onMailetException>
              </mailet>
              <mailet match="All" class="RecipientRewriteTable">
                  <errorProcessor>rrt-error</errorProcessor>
              </mailet>
              <mailet match="RecipientIsLocal" class="VacationMailet">
                  <onMailetException>ignore</onMailetException>
              </mailet>
              <mailet match="RecipientIsLocal" class="org.apache.james.jmap.mailet.filter.JMAPFiltering">
                  <onMailetException>ignore</onMailetException>
              </mailet>
              <mailet match="RecipientIsLocal" class="Sieve"/>
              <mailet match="RecipientIsLocal" class="AddDeliveredToHeader"/>
              <mailet match="RecipientIsLocal" class="LocalDelivery"/>
              <mailet match="HostIsLocal" class="ToProcessor">
                  <processor>local-address-error</processor>
                  <notice>550 - Requested action not taken: no such user here</notice>
              </mailet>

              <mailet match="relay-allowed" class="ToProcessor">
                  <processor>relay</processor>
              </mailet>
          </processor>

          <processor state="relay" enableJmx="true">
          {{- if .Values.ses }}
              <mailet match="All" class="RemoteDelivery">
                  <outgoingQueue>outgoing</outgoingQueue>
                  <!-- <useSSL>true</useSSL> --> <!-- useSSL for port 465, or startTLS if false on port 587 -->
                  <startTLS>true</startTLS> <!-- StartTLS is preferred with port 587 -->
                  <authRequired>true</authRequired>
                  <heloName>planetlauritsen.com</heloName>
                  <gateway>{{.Values.ses.host}}</gateway>
                  <gatewayPort>587</gatewayPort>
                  <gatewayUsername>{{.Values.ses.username}}</gatewayUsername>
                  <gatewayPassword>{{.Values.ses.password}}</gatewayPassword>
                  <bounceProcessor>bounces</bounceProcessor>
                  <delayTime>5000, 100000, 500000</delayTime>
                  <maxRetries>3</maxRetries>
                  <maxDnsProblemRetries>0</maxDnsProblemRetries>
                  <debug>true</debug>
                  <verifyServerIdentity>true</verifyServerIdentity>
               </mailet>
              {{- else }}
              <mailet match="All" class="RemoteDelivery">
                  <outgoingQueue>outgoing</outgoingQueue>
                  <delayTime>5000, 100000, 500000</delayTime>
                  <maxRetries>3</maxRetries>
                  <maxDnsProblemRetries>0</maxDnsProblemRetries>
                  <deliveryThreads>10</deliveryThreads>
                  <sendpartial>true</sendpartial>
                  <bounceProcessor>bounces</bounceProcessor>
              </mailet>
               {{- end }}
          </processor>

          <processor state="local-address-error" enableJmx="true">
              <mailet match="All" class="MetricsMailet">
                  <metricName>mailetContainerLocalAddressError</metricName>
              </mailet>
              <mailet match="All" class="Bounce">
                  <attachment>none</attachment>
              </mailet>
              <mailet match="All" class="ToRepository">
                  <repositoryPath>postgres://var/mail/address-error/</repositoryPath>
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
                  <repositoryPath>postgres://var/mail/relay-denied/</repositoryPath>
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
                  <repositoryPath>postgres://var/mail/rrt-error/</repositoryPath>
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
      <defaultProtocol>postgres</defaultProtocol>
      <mailrepositories>
          <mailrepository class="org.apache.james.mailrepository.postgres.PostgresMailRepository">
              <protocols>
                  <protocol>postgres</protocol>
              </protocols>
              <!-- Set if the messages should be listed sorted. False by default -->
              <config FIFO="false" CACHEKEYS="true"/>
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
            {{- if .Values.certManager }}
                <privateKey>file://conf/tls/tls.key</privateKey>
                <certificates>file://conf/tls/tls.crt</certificates>
            {{- else }}
              <!-- To create a new keystore execute:
                keytool -genkey -alias james -keyalg RSA -storetype PKCS12 -keystore /path/to/james/conf/keystore
               -->
              <keystore>file://conf/keystore</keystore>
              <keystoreType>PKCS12</keystoreType>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
              <algorithm>SunX509</algorithm>

              <!-- Alternatively TLS keys can be supplied via PEM files -->
              <!-- <privateKey>file://conf/private.key</privateKey> -->
              <!-- <certificates>file://conf/certs.self-signed.csr</certificates> -->
              <!-- An optional secret might be specified for the private key -->
              <!-- <secret>james72laBalle</secret> -->
              {{- end }}
          </tls>
          <connectiontimeout>1200</connectiontimeout>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <handlerchain>
              <handler class="org.apache.james.pop3server.core.CoreCmdHandlerLoader"/>
          </handlerchain>
      </pop3server>
  </pop3servers>

postgres.properties: |
  # String. Optional, default to 'postgres'. Database name.
  database.name=james

  # String. Optional, default to 'public'. Database schema.
  database.schema=public

  # String. Optional, default to 'localhost'. Database host.
  database.host={{ $fullname }}-postgresql-hl

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

search.properties: |
  # not for production purposes. To be replaced by PG based search.
  implementation=scanning

smtpserver.xml: |
  <?xml version="1.0"?>
  <!-- Read https://james.apache.org/server/config-smtp-lmtp.html#SMTP_Configuration for further details -->
  <smtpservers>
      <smtpserver enabled="true">
          <jmxName>smtpserver-global</jmxName>
          <bind>0.0.0.0:25</bind>
          <connectionBacklog>200</connectionBacklog>
          <tls socketTLS="false" startTLS="false">
            {{- if .Values.certManager }}
                <privateKey>file://conf/tls/tls.key</privateKey>
                <certificates>file://conf/tls/tls.crt</certificates>
            {{- else }}
              <!-- To create a new keystore execute:
                keytool -genkey -alias james -keyalg RSA -storetype PKCS12 -keystore /path/to/james/conf/keystore
               -->
              <keystore>file://conf/keystore</keystore>
              <keystoreType>PKCS12</keystoreType>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
              <algorithm>SunX509</algorithm>

              <!-- Alternatively TLS keys can be supplied via PEM files -->
              <!-- <privateKey>file://conf/private.key</privateKey> -->
              <!-- <certificates>file://conf/certs.self-signed.csr</certificates> -->
              <!-- An optional secret might be specified for the private key -->
              <!-- <secret>james72laBalle</secret> -->
              {{- end }}

          </tls>
          <connectiontimeout>360</connectiontimeout>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <auth>
              <announce>never</announce>
              <requireSSL>false</requireSSL>
              <plainAuthEnabled>true</plainAuthEnabled>
          </auth>
          <authorizedAddresses>10.*</authorizedAddresses>
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
            {{- if .Values.certManager }}
                <privateKey>file://conf/tls/tls.key</privateKey>
                <certificates>file://conf/tls/tls.crt</certificates>
            {{- else }}
              <!-- To create a new keystore execute:
                keytool -genkey -alias james -keyalg RSA -storetype PKCS12 -keystore /path/to/james/conf/keystore
               -->
              <keystore>file://conf/keystore</keystore>
              <keystoreType>PKCS12</keystoreType>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
              <algorithm>SunX509</algorithm>

              <!-- Alternatively TLS keys can be supplied via PEM files -->
              <!-- <privateKey>file://conf/private.key</privateKey> -->
              <!-- <certificates>file://conf/certs.self-signed.csr</certificates> -->
              <!-- An optional secret might be specified for the private key -->
              <!-- <secret>james72laBalle</secret> -->
              {{- end }}
          </tls>
          <connectiontimeout>360</connectiontimeout>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <auth>
              <announce>forUnauthorizedAddresses</announce>
              <requireSSL>true</requireSSL>
              <plainAuthEnabled>true</plainAuthEnabled>
              <!-- Sample OIDC configuration -->
              <!--
              <oidc>
                  <oidcConfigurationURL>https://changeme.org/auth/realms/upn/.well-known/openid-configuration</oidcConfigurationURL>
                  <jwksURL>https://changeme.org/auth/realms/upn/protocol/openid-connect/certs</jwksURL>
                  <claim>email</claim>
                  <scope>openid profile email</scope>
              </oidc>
              -->
          </auth>
          <authorizedAddresses>10.*</authorizedAddresses>
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
          <jmxName>smtpserver-authenticated</jmxName>
          <bind>0.0.0.0:587</bind>
          <connectionBacklog>200</connectionBacklog>
          <tls socketTLS="false" startTLS="true">
            {{- if .Values.certManager }}
                <privateKey>file://conf/tls/tls.key</privateKey>
                <certificates>file://conf/tls/tls.crt</certificates>
            {{- else }}
              <!-- To create a new keystore execute:
                keytool -genkey -alias james -keyalg RSA -storetype PKCS12 -keystore /path/to/james/conf/keystore
               -->
              <keystore>file://conf/keystore</keystore>
              <keystoreType>PKCS12</keystoreType>
              <secret>james72laBalle</secret>
              <provider>org.bouncycastle.jce.provider.BouncyCastleProvider</provider>
              <algorithm>SunX509</algorithm>

              <!-- Alternatively TLS keys can be supplied via PEM files -->
              <!-- <privateKey>file://conf/private.key</privateKey> -->
              <!-- <certificates>file://conf/certs.self-signed.csr</certificates> -->
              <!-- An optional secret might be specified for the private key -->
              <!-- <secret>james72laBalle</secret> -->
              {{- end }}
          </tls>
          <connectiontimeout>360</connectiontimeout>
          <connectionLimit>0</connectionLimit>
          <connectionLimitPerIP>0</connectionLimitPerIP>
          <auth>
              <announce>forUnauthorizedAddresses</announce>
              <requireSSL>true</requireSSL>
              <plainAuthEnabled>true</plainAuthEnabled>
              <!-- Sample OIDC configuration -->
              <!--
              <oidc>
                  <oidcConfigurationURL>https://changeme.org/auth/realms/upn/.well-known/openid-configuration</oidcConfigurationURL>
                  <jwksURL>https://changeme.org/auth/realms/upn/protocol/openid-connect/certs</jwksURL>
                  <claim>email</claim>
                  <scope>openid profile email</scope>
              </oidc>
              -->
          </auth>
          <authorizedAddresses>10.*</authorizedAddresses>
          <verifyIdentity>disabled</verifyIdentity>
          <maxmessagesize>0</maxmessagesize>
          <addressBracketsEnforcement>true</addressBracketsEnforcement>
          <smtpGreeting>Unauthorized users will be prosecuted</smtpGreeting>
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
      <algorithm>PBKDF2-SHA512</algorithm>
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
  # Use host=0.0.0.0 to listen on all addresses
  host=0.0.0.0

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

  # Defaults to false
  #cors.enable=true
  #cors.origin

  # List of fully qualified class names that should be exposed over webadmin
  # in addition to your product default routes. Routes needs to be located
  # within the classpath or in the ./extensions-jars folder.
  #extensions.routes=
{{- end }}
