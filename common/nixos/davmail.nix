# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
{pkgs, ...}: let
  acmeCertName = "proxy.m365.rnet.rodriguez.org.uk";
  acmeCertDir = "/var/lib/acme/${acmeCertName}";
  keystoreFile = "/var/lib/davmail/keystore.p12";

  # Only re-runs the PKCS#12 conversion when the ACME cert/key have actually
  # been renewed (i.e. are newer than the keystore we last built).
  pkcs12Convert = pkgs.writeShellScript "davmail-pkcs12-convert" ''
    set -euo pipefail
    key="$CREDENTIALS_DIRECTORY/key.pem"
    chain="$CREDENTIALS_DIRECTORY/fullchain.pem"

    if [ ! -f "${keystoreFile}" ] || [ "$key" -nt "${keystoreFile}" ]; then
      ${pkgs.openssl}/bin/openssl pkcs12 -export \
        -in "$chain" \
        -inkey "$key" \
        -out "${keystoreFile}" \
        -passout pass:
    fi
  '';
in {
  services.davmail = {
    enable = true;
    url = "https://outlook.office365.com/EWS/Exchange.asmx";
    config.davmail =
      {
        allowRemote = "false";
        authentication = "O365DeviceCode";
        caldavAutoSchedule = "true";
        caldavEditNotifications = "true";
        caldavImpersonate = "true";
        caldavPastDelay = "0";
        caldavPort = "1080";
        carddavReadPhoto = "true";
        clientSoTimeout = "600";
        disableGuiNotifications = "true";
        disableTrayActivitySwitch = "true";
        disableUpdateCheck = "true";
        enableKeepAlive = "true";
        enableKerberos = "false";
        enableProxy = "false";
        folderSizeLimit = "0";
        forceActiveSyncUpdate = "false";
        imapAlwaysApproxMsgSize = "true";
        imapAutoExpunge = "true";
        imapIdleDelay = "30";
        imapIncludeSpecialFolders = "true";
        imapPort = "1143";
        keepDelay = "30";
        ldapPort = "1389";
        logFilePath = "/var/log/davmail/davmail.log";
        logFileSize = "25MB";
        mode = "O365Graph";
        oauth.persistToken = "true";
        oauth.tokenFilePath = "/var/lib/davmail/creds.properties";
        popPort = "0";
        sentKeepDelay = "0";
        server = "true";
        showStartupBanner = "false";
        smtpPort = "1025";
        smtpSaveInSent = "true";
        ssl.keystoreFile = keystoreFile;
        ssl.keystorePass = "";
        ssl.keystoreType = "PKCS12";
        ssl.nosecurecaldav = "true";
        ssl.nosecureimap = "true";
        ssl.nosecureldap = "true";
        ssl.nosecurepop = "true";
        ssl.nosecuresmtp = "true";
        url = "https://outlook.office365.com/EWS/Exchange.asmx";
        useSystemProxies = "false";
        userWhiteList = "\@danx.org.uk,\@rodriguez.org.uk,\@planet-community.org,\@shymega.org.uk,\@dzr.org.uk,\@domrodriguez.org.uk,\@ddr.org.uk,\@dvda.org.uk";
      }
      // {
        log4j.logger.davmail = "INFO";
        log4j.logger.httpclient.wire = "WARN";
        log4j.logger.org.apache.commons.httpclient = "WARN";
        log4j.logger.org.apache.http.conn.ssl = "INFO";
        log4j.logger.org.apache.http.wire = "INFO";
        log4j.rootLogger = "INFO";
      };
  };
  systemd.services.davmail = {
    after = ["acme-finished-${acmeCertName}.service"];
    wants = ["acme-finished-${acmeCertName}.service"];

    serviceConfig = {
      ReadWritePaths = [
        "/var/log/davmail"
        "/var/lib/davmail"
      ];

      LoadCredential = [
        "fullchain.pem:${acmeCertDir}/fullchain.pem"
        "key.pem:${acmeCertDir}/key.pem"
      ];

      ExecStartPre = "${pkcs12Convert}";
    };
  };
}
