# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
_: {
  services.davmail = {
    enable = true;
    url = "https://outlook.office365.com/EWS/Exchange.asmx";
    config.davmail =
      {
        allowRemote = "false";
        authentication = "O365Interactive";
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
    serviceConfig = {
      ReadWritePaths = [
        "/var/log/davmail"
        "/var/lib/davmail"
      ];
    };
  };
}
