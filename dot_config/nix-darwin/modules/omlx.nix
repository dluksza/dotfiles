{ pkgs, lib, user, uid, ... }:
# Keeps the oMLX brew service (sh.brew.omlx, port 11435) healthy across
# Homebrew upgrades. Personal machine only.
#
# Failure mode this guards against (hit 2026-10-22 with omlx 0.7.1rc1 -> 0.7.2
# and 2026-10-26 with python@3.11 3.11.17_1 -> 3.11.18): `brew bundle` during
# `darwin-rebuild switch` (homebrew.onActivation.upgrade) upgrades omlx or its
# python@3.11 interpreter, deletes the old Cellar directory and does NOT
# restart the service. The running omlx-server then executes from deleted
# files. Symptoms: lazily imported modules fail, the admin dashboard 500s on
# TemplateNotFound, and the application firewall (stealth mode, common.nix)
# can no longer match the process to its allow entry, so every non-loopback
# connection to :11435 is reset ("connection refused" from LAN clients while
# 127.0.0.1 still works).
#
# The guard script below detects a running omlx-server that maps deleted
# /opt/homebrew files, waits until oMLX reports no in-flight work, and
# restarts the launchd agent in place. It also registers the current
# python@3.11 Python.app (the process executable) with socketfilterfw, since
# the Cellar path changes on every interpreter bump. It runs:
#   - at the end of every `darwin-rebuild switch` (right after brew bundle);
#   - every 5 minutes as a root launchd daemon, which also covers manual
#     `brew upgrade` runs and waits out busy periods.
let
  label = "sh.brew.omlx";
  port = 11435;
  settings = "/Users/${user}/.omlx/settings.json";
  socketfilterfw = "/usr/libexec/ApplicationFirewall/socketfilterfw";
  jq = "${pkgs.jq}/bin/jq";
  readlink = "${pkgs.coreutils}/bin/readlink";

  guard = pkgs.writeShellScript "omlx-guard" ''
    set -u
    log() { echo "$(/bin/date '+%F %T') omlx-guard: $*" >&2; }

    # 1. Firewall: allow incoming connections for the interpreter that
    #    omlx-server runs as (Python.app inside the python@3.11 keg).
    py=$(${readlink} -f /opt/homebrew/opt/python@3.11 2>/dev/null || true)
    app="$py/Frameworks/Python.framework/Versions/3.11/Resources/Python.app"
    if [ -d "$app" ]; then
      ${socketfilterfw} --add "$app" >/dev/null 2>&1 || true
      ${socketfilterfw} --unblockapp "$app" >/dev/null 2>&1 || true
    fi

    # 2. Is the running server executing from deleted Homebrew files?
    pid=$(/usr/bin/pgrep -x -u ${toString uid} omlx-server | /usr/bin/head -1 || true)
    if [ -z "$pid" ]; then
      exit 0  # not running; launchd KeepAlive on the brew agent owns (re)starts
    fi
    stale=$(/usr/sbin/lsof -p "$pid" 2>/dev/null \
      | /usr/bin/awk '$4 == "txt" && $NF ~ "^/opt/homebrew/" { print $NF }' \
      | /usr/bin/sort -u \
      | while IFS= read -r p; do [ -e "$p" ] || echo "$p"; done)
    if [ -z "$stale" ]; then
      exit 0
    fi
    log "omlx-server (pid $pid) maps deleted files, e.g. $(echo "$stale" | /usr/bin/head -1)"

    # 3. Only restart while idle: a restart unloads every model and aborts
    #    in-flight requests. A busy server is retried on the next run.
    key=$(${jq} -r '.auth.api_key // empty' ${settings} 2>/dev/null || true)
    status=$(/usr/bin/curl -s -m 5 -H "Authorization: Bearer $key" \
      http://127.0.0.1:${toString port}/api/status 2>/dev/null || true)

    # Fail closed. An unreachable status or a body without the counters must
    # read as busy, because a restart unloads live models and aborts in-flight
    # requests. The safe answer to doubt is the next run in 5 minutes.
    busy=1
    if [ -z "$status" ]; then
      log "no answer from /api/status; treating the server as busy"
    else
      busy=$(echo "$status" | ${jq} -r \
        '(.active_requests // 0) + (.waiting_requests // 0) + (.models_loading // 0)' 2>/dev/null || echo 1)
      printf '%s' "$busy" | /usr/bin/grep -Eq '^[0-9]+$' || busy=1
    fi
    if [ "$busy" != "0" ]; then
      log "server busy ($busy request(s)/loads in flight); retrying later"
      exit 0
    fi

    log "restarting ${label}"
    /bin/launchctl kickstart -k "gui/${toString uid}/${label}" || {
      log "launchctl kickstart failed (rc=$?)"; exit 1; }
    for _ in $(/usr/bin/seq 1 60); do
      /bin/sleep 2
      if /usr/bin/curl -s -m 2 -o /dev/null -w '%{http_code}' \
          http://127.0.0.1:${toString port}/health 2>/dev/null | /usr/bin/grep -q '^200$'; then
        log "restarted; /health OK (pid $(/usr/bin/pgrep -x -u ${toString uid} omlx-server | /usr/bin/head -1))"
        exit 0
      fi
    done
    log "restarted but /health not OK after 120s; check /opt/homebrew/var/log/omlx.log"
    exit 1
  '';
in
{
  # Root daemon: root can kickstart the user's gui/${uid} launchd domain and
  # edit the application firewall list; a user agent could do neither.
  launchd.daemons.omlx-guard = {
    command = toString guard;
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 300;
      StandardOutPath = "/var/log/omlx-guard.log";
      StandardErrorPath = "/var/log/omlx-guard.log";
    };
  };

  # Log rotation. launchd appends to both files forever; the oMLX log was
  # 20 MB with no rule on 2026-10-31. Owner matches what brew services creates.
  environment.etc."newsyslog.d/omlx.conf".text = ''
    /opt/homebrew/var/log/omlx.log  ${user}:admin  644  7  2048  *  NJ
    /var/log/omlx-guard.log         root:wheel     644  5  1024  *  NJ
  '';

  # postActivation runs after the `brew bundle` step, so an omlx/python bump
  # is picked up in the same `darwin-rebuild switch` that caused it.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "omlx: checking the omlx-server process after brew bundle" >&2
    ${guard} || true
  '';
}
