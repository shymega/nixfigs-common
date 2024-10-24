# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only

#

{ config, ... }:
{
  services.postfix = {
    enable = true;
    enableSmtp = true;
    enableSubmission = false;
    enableSubmissions = false;
    setSendmail = true;
    enableHeaderChecks = true;
    headerChecks = [
      {
        pattern = "/^/";
        action = "HOLD";
      }
      {
        pattern = "/^Received:.*with ESMTPSA/";
        action = "IGNORE";
      }
      {
        pattern = "/^X-Originating-IP:/";
        action = "IGNORE";
      }
      {
        pattern = "/^X-Mailer:/";
        action = "IGNORE";
      }
      {
        pattern = "/^Received:/";
        action = "IGNORE";
      }
      {
        pattern = "/^User-Agent:/";
        action = "IGNORE";
      }
      {
        pattern = "/^X-Delay*:/";
        action = "IGNORE";
      }
    ];
    extraAliases = ''
      postmaster: root
      root:       dzrodriguez
    '';
    extraHeaderChecks = ''
      # add header to deal with unwanted Microsoft reactions (2024-07-16)
      /^Date:/i PREPEND x-ms-reactions: disallow 
    '';
    mapFiles."sasl_passwd" = config.age.secrets.postfix_sasl_passwd.path;
    mapFiles."sender_relay" = config.age.secrets.postfix_sender_relay.path;
    extraConfig = ''
      relayhost =
      smtp_sender_dependent_authentication = yes
      sender_dependent_default_transport_maps = hash:/etc/postfix/sender_relay

      smtp_sasl_auth_enable = yes
      smtp_tls_security_level = may
      smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
      smtp_sasl_security_options = noanonymous
      smtp_use_tls = yes
      smtp_tls_loglevel = 2
      smtp_use_tls = yes
      smtp_tls_security_level = may

      smtpd_sasl_auth_enable = yes
      smtpd_tls_auth_only = yes
    '';
  };
}
