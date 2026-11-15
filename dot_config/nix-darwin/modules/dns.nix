{ pkgs, lib, ... }:
# DNS per network, with ad blocking on every network.
#
#   Home network (DHCP router is ${homeRouter}):
#     Wi-Fi DNS = automatic (DHCP) -> the router, which runs AdGuard Home.
#   Every other network:
#     Wi-Fi DNS = 127.0.0.1 -> dnscrypt-proxy -> AdGuard DNS (public service)
#     over DNS-over-HTTPS. Queries are encrypted and ads are blocked.
#
# Two launchd daemons:
#   dnscrypt-proxy  the local encrypted DNS proxy on 127.0.0.1:53
#   dns-switch      sets the Wi-Fi DNS servers on every network change
#
# Fail-safe: dns-switch selects the proxy only if the proxy answers a real
# query. If the proxy is down, or the network blocks it (for example a hotel
# login page), the Wi-Fi DNS goes back to automatic (DHCP).
#
# Before this module is removed, reset the DNS, or the Mac can stay on
# 127.0.0.1 with no proxy behind it:
#   sudo networksetup -setdnsservers Wi-Fi empty
#
# LuLu: dnscrypt-proxy makes outbound connections. Its store path changes on
# upgrades, so LuLu can ask for approval again after a `nix flake update`.
let
  homeRouter = "10.11.222.1";
  wifiService = "Wi-Fi";
  proxyAddress = "127.0.0.1";
  stateDir = "/var/lib/dnscrypt-proxy";

  dnsSwitch = pkgs.writeShellScript "dns-switch" ''
    set -u
    ns=/usr/sbin/networksetup

    dev=$($ns -listallhardwareports | /usr/bin/awk '/^Hardware Port: Wi-Fi$/ { getline; print $2; exit }')
    [ -n "$dev" ] || exit 0

    # No DHCP router: Wi-Fi is off or not connected. Change nothing.
    router=$(/usr/sbin/ipconfig getoption "$dev" router 2>/dev/null || true)
    [ -n "$router" ] || exit 0

    want=dhcp
    if [ "$router" != "${homeRouter}" ]; then
      # A random name is never in the proxy cache, so this query proves that
      # the encrypted upstream is reachable from this network.
      probe="dns-switch-$RANDOM$RANDOM.example.com"
      if /usr/bin/dig +tries=2 +time=3 @${proxyAddress} "$probe" A 2>/dev/null \
          | /usr/bin/grep -qE 'status: (NOERROR|NXDOMAIN)'; then
        want=proxy
      fi
    fi

    # With no manual servers, networksetup prints a sentence, not addresses.
    current=$($ns -getdnsservers "${wifiService}" 2>/dev/null | /usr/bin/tr '\n' ' ' | /usr/bin/sed 's/ *$//')
    case "$current" in
      *[0-9].[0-9]*|*:*) manual=1 ;;
      *) manual=0 ;;
    esac

    now=$(/bin/date '+%Y-%m-%d %H:%M:%S')
    if [ "$want" = proxy ]; then
      if [ "$current" != "${proxyAddress}" ]; then
        $ns -setdnsservers "${wifiService}" ${proxyAddress}
        echo "$now router=$router dns=${proxyAddress} (dnscrypt-proxy)"
      fi
    else
      if [ "$manual" = 1 ]; then
        $ns -setdnsservers "${wifiService}" empty
        echo "$now router=$router dns=automatic (DHCP)"
      fi
    fi
  '';
in
{
  services.dnscrypt-proxy = {
    enable = true;
    # Keys are from the example file shipped with the package:
    #   ${pkgs.dnscrypt-proxy}/etc/dnscrypt-proxy/dnscrypt-proxy.toml
    settings = {
      listen_addresses = [ "${proxyAddress}:53" ];
      # Start as root to bind port 53, then drop to this user (see below).
      user_name = "_dnscrypt-proxy";

      # AdGuard DNS "Default": blocks ads, trackers, phishing and malware.
      # Name from the public-resolvers list (v3).
      server_names = [ "adguard-dns-doh" ];
      ipv4_servers = true;
      ipv6_servers = false;
      dnscrypt_servers = false;
      doh_servers = true;
      # Must be false: a filtering resolver is the purpose of this setup.
      require_nofilter = false;
      require_nolog = false;
      require_dnssec = false;

      # Used only to find the resolver list and the DoH server at start.
      bootstrap_resolvers = [ "9.9.9.9:53" "1.1.1.1:53" ];
      ignore_system_dns = true;
      cache = true;

      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
          "https://cdn.jsdelivr.net/gh/DNSCrypt/dnscrypt-resolvers@master/v3/public-resolvers.md"
        ];
        cache_file = "${stateDir}/public-resolvers.md";
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
        refresh_delay = 73;
      };
    };
  };

  # The nix-darwin module runs the proxy as _dnscrypt-proxy. On macOS a
  # non-root process cannot bind 127.0.0.1:53 (only 0.0.0.0:53), and the
  # system DNS settings accept no other port. So launchd starts the proxy as
  # root, and `user_name` above drops the privileges after the bind.
  launchd.daemons.dnscrypt-proxy.serviceConfig = {
    UserName = lib.mkForce null;
    GroupName = lib.mkForce null;
  };

  launchd.daemons.dns-switch = {
    command = toString dnsSwitch;
    serviceConfig = {
      RunAtLoad = true;
      # Network changes rewrite these paths. StartInterval is the fallback,
      # and it also restores the proxy after a hotel login page is passed.
      WatchPaths = [
        "/var/run/resolv.conf"
        "/private/var/db/dhcpclient/leases"
      ];
      StartInterval = 60;
      StandardOutPath = "/var/log/dns-switch.log";
      StandardErrorPath = "/var/log/dns-switch.log";
    };
  };
}
