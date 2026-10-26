{ pkgs, lib, ... }:
# Host metrics exporters scraped by VictoriaMetrics on the NAS
# (~/workspace/homelab/monitoring). Both Macs.
#
#   :9100  node_exporter  (nix-darwin module; launchd daemon, own system user)
#          + textfile collector fed by the process-metrics daemon below
#   :9101  macmon serve   (Apple Silicon power/temps/GPU; launchd daemon)
#
# The application firewall is on with stealth mode (common.nix) and nix
# binaries are only ad-hoc signed, so each exporter binary is registered and
# unblocked in socketfilterfw on activation. Store paths change on upgrades,
# which is why this runs on every switch.
let
  nodeExporterBin = lib.getExe pkgs.prometheus-node-exporter;
  macmonBin = lib.getExe pkgs.macmon;
  socketfilterfw = "/usr/libexec/ApplicationFirewall/socketfilterfw";
  exporterHome = "/var/lib/prometheus-node-exporter";
  textfileDir = "${exporterHome}/textfile";

  # Per-process CPU / memory / uptime for every process on the host, grouped
  # by executable name and user, written as Prometheus text every 15 s. macOS
  # has no process-exporter; `ps` is the source. ~500 groups x 4 series per
  # Mac; pids are deliberately not a label (series churn).
  processMetrics = pkgs.writeShellScript "process-metrics" ''
    set -eu
    dir=${textfileDir}
    mkdir -p "$dir"
    now=$(/bin/date +%s)
    # comm is last: app bundle paths contain spaces, so it is taken as "the rest
    # of the line" rather than a field.
    /bin/ps -axo pid=,user=,rss=,cputime=,etime=,comm= | /usr/bin/awk -v now="$now" '
      function base(p,  n, a) { n = split(p, a, "/"); return a[n] }
      # [dd-][hh:]mm:ss[.cs] -> seconds (ps cputime and etime)
      function secs(t,  d, n, a, s) { d = 0; if (index(t, "-")) { split(t, a, "-"); d = a[1]; t = a[2] }
        n = split(t, a, ":"); if (n == 3) s = a[1]*3600 + a[2]*60 + a[3]; else s = a[1]*60 + a[2]; return d*86400 + s }
      function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }
      {
        rest = $0
        for (i = 1; i <= 5; i++) sub(/^[ \t]*[^ \t]+/, "", rest)
        sub(/^[ \t]+/, "", rest)
        k = "name=\"" esc(base(rest)) "\",user=\"" esc($2) "\""
        count[k]++
        rss[k] += $3 * 1024
        cpu[k] += secs($4)
        start = now - secs($5)
        if (!(k in oldest) || start < oldest[k]) oldest[k] = start
      }
      END {
        print "# HELP homelab_process_count Number of processes in the group (executable name, user)."
        print "# TYPE homelab_process_count gauge"
        for (k in count) printf "homelab_process_count{%s} %d\n", k, count[k]
        print "# HELP homelab_process_resident_memory_bytes Resident set size summed over the group."
        print "# TYPE homelab_process_resident_memory_bytes gauge"
        for (k in count) printf "homelab_process_resident_memory_bytes{%s} %d\n", k, rss[k]
        print "# HELP homelab_process_cpu_seconds_total CPU time consumed by the group (user+system)."
        print "# TYPE homelab_process_cpu_seconds_total counter"
        for (k in count) printf "homelab_process_cpu_seconds_total{%s} %.2f\n", k, cpu[k]
        print "# HELP homelab_process_oldest_start_time_seconds Unix start time of the oldest process in the group."
        print "# TYPE homelab_process_oldest_start_time_seconds gauge"
        for (k in count) printf "homelab_process_oldest_start_time_seconds{%s} %d\n", k, oldest[k]
      }' > "$dir/process.prom.tmp"
    mv "$dir/process.prom.tmp" "$dir/process.prom"
  '';
in
{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "0.0.0.0";
    # darwin collectors enabled by default: boottime cpu diskstats filesystem
    # loadavg meminfo netdev os time uname. Add thermal (throttle ratios),
    # battery state and the textfile directory.
    enabledCollectors = [ "thermal" "powersupplyclass" "textfile" ];
    extraFlags = [ "--collector.textfile.directory=${textfileDir}" ];
  };

  environment.systemPackages = [ pkgs.macmon ];

  # System daemon (not a user agent) so it also runs on a headless Mac mini
  # before anyone logs in. macmon reads IOReport, no root needed.
  launchd.daemons.macmon = {
    command = "${macmonBin} serve --host 0.0.0.0 --port 9101 --interval 5000";
    serviceConfig = {
      KeepAlive = true;
      RunAtLoad = true;
      UserName = "_prometheus-node-exporter";
      GroupName = "_prometheus-node-exporter";
      StandardOutPath = "${exporterHome}/macmon.log";
      StandardErrorPath = "${exporterHome}/macmon.log";
    };
  };

  launchd.daemons.process-metrics = {
    command = toString processMetrics;
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 15;
      UserName = "_prometheus-node-exporter";
      GroupName = "_prometheus-node-exporter";
      StandardErrorPath = "${exporterHome}/process-metrics.log";
    };
  };

  system.activationScripts.postActivation.text = ''
    echo "monitoring: allowing exporters through the application firewall" >&2
    for bin in ${nodeExporterBin} ${macmonBin}; do
      ${socketfilterfw} --add "$bin" >/dev/null 2>&1 || true
      ${socketfilterfw} --unblockapp "$bin" >/dev/null 2>&1 || true
    done
  '';
}
