# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
_: {
  services.davmail = {
    enable = true;
    url = "https://outlook.office365.com/EWS/Exchange.asmx";
    config = {
      davmail.allowRemote = "false";
      davmail.caldavAutoSchedule = "true";
      davmail.caldavEditNotifications = "false";
      davmail.caldavPastDelay = "0";
      davmail.caldavPort = "1080";
      davmail.carddavReadPhoto = "true";
      davmail.disableGuiNotifications = "true";
      davmail.disableTrayActivitySwitch = "true";
      davmail.disableUpdateCheck = "true";
      davmail.enableKeepAlive = "true";
      davmail.enableKerberos = "false";
      davmail.enableProxy = "false";
      davmail.forceActiveSyncUpdate = "false";
      davmail.imapAlwaysApproxMsgSize = "true";
      davmail.imapAutoExpunge = "true";
      davmail.imapIdleDelay = "5";
      davmail.imapIncludeSpecialFolders = "false";
      davmail.imapPort = "1153";
      davmail.keepDelay = "30";
      davmail.ldapPort = "1081";
      davmail.logFilePath = "/var/log/davmail/davmail.log";
      davmail.logFileSize = "25MB";
      davmail.mode = "O365Modern";
      davmail.oauth.persistToken = "true";
      davmail.oauth.tokenFilePath = "/var/lib/davmail/creds.properties";
      davmail.popMarkReadOnRetr = "false";
      davmail.popPort = "0";
      davmail.sentKeepDelay = "0";
      davmail.server = "true";
      davmail.showStartupBanner = "false";
      davmail.smtpPort = "1025";
      davmail.smtpSaveInSent = "true";
      davmail.ssl.nosecurecaldav = "true";
      davmail.ssl.nosecureimap = "true";
      davmail.ssl.nosecureldap = "true";
      davmail.ssl.nosecurepop = "true";
      davmail.ssl.nosecuresmtp = "true";
      davmail.url = "https://outlook.office365.com/EWS/Exchange.asmx";
      davmail.useSystemProxies = "false";
      log4j.logger.davmail = "DEBUG";
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
