# SPDX-FileCopyrightText: 2024 Dom Rodriguez <shymega@shymega.org.uk
#
# SPDX-License-Identifier: GPL-3.0-only
#
{
  config,
  lib,
  ...
}: let
  userHome = config.users.users.dzrodriguez.home;
in {
  services.dovecot2 = {
    enable = true;
    user = "dzrodriguez";
    group = "users";
    mailLocation = "maildir:${userHome}/.mail/%d/%u/:LAYOUT=fs:INBOX=${userHome}/.mail/%d/%u/INBOX";
    enablePAM = false;
    sieve.globalExtensions = [
      "body"
      "copy"
      "date"
      "editheader"
      "envelope"
      "fileinto"
      "imap4flags"
      "include"
      "mailbox"
      "regex"
      "variables"
    ];
    enableImap = true;
    enablePop3 = false;
    extraConfig = ''
      listen = 127.0.0.1, ::1${lib.optionalString (config.networking.hostName == "delta-zero") ", 172.28.13.63"}
      mail_uid = 1000
      mail_gid = 100

      service imap {
        vsz_limit = 1G
      }

      default_vsz_limit = 1G

      namespace inbox {
          inbox = yes
          location =

          mailbox Drafts {
            special_use = \Drafts
            auto = subscribe
          }

          mailbox "Spam" {
            special_use = \Junk
          }

          mailbox "Sent" {
            special_use = \Sent
            auto = subscribe
          }

          mailbox "Trash" {
            special_use = \Trash
            auto = subscribe
          }

          prefix =
          separator = /
      }

      passdb {
          driver = static
          args = nopassword
      }

      maildir_broken_filename_sizes = yes
    '';
  };
}
