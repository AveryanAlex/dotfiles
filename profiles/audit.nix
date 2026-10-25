{ config, lib, ... }:
{
  security.audit.enable = true;
  security.auditd.enable = true;
  security.audit.rules = [
    "-w /home/alex/.ssh -p rwa -k ssh_access"
    "-w /home/alex/.local/share/gnupg -p rwa -k gpg_access"
    "-w /home/alex/.local/share/keyrings -p rwa -k keyring_access"
  ];

  persist.state.dirs = [
    {
      directory = "/var/log/audit";
      mode = "0700";
    }
  ];

  security.auditd.settings = {
    # Rotate daily rather than by size; keep the active log and 30 daily archives.
    max_log_file_action = "ignore";
    num_logs = 31;
  };

  systemd.services.audit-log-rotate = {
    description = "Rotate audit logs with one month of daily history";
    requires = [ "auditd.service" ];
    after = [ "auditd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lib.getExe' config.security.auditd.package "auditctl"} --signal rotate";
    };
  };

  systemd.timers.audit-log-rotate = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
