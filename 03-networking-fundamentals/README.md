# Networking Fundamentals

Practice run of core networking commands, with real output captured on this
machine (macOS), and a short explanation of what each command does.

## `hostname`

Prints the machine's network hostname.

```
$ hostname
Aryans-MacBook-Pro.local
```

## `ifconfig`

Shows network interface configuration — IP address, MAC address, MTU, link state.

```
$ ifconfig en0
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether 7a:50:c6:61:b0:fd
	inet6 fe80::18cb:8a29:5494:4d87%en0 prefixlen 64 secured scopeid 0xb
	inet 100.128.174.237 netmask 0xfffff000 broadcast 100.128.175.255
	media: autoselect
	status: active
```
On Linux, the modern equivalent is `ip addr show`.

## `ping`

Sends ICMP echo requests to check reachability and measure round-trip latency.

```
$ ping -c 4 8.8.8.8
PING 8.8.8.8 (8.8.8.8): 56 data bytes
64 bytes from 8.8.8.8: icmp_seq=0 ttl=120 time=16.596 ms
64 bytes from 8.8.8.8: icmp_seq=1 ttl=120 time=18.521 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=120 time=15.478 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=120 time=18.234 ms

--- 8.8.8.8 ping statistics ---
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 15.478/17.207/18.521/1.239 ms
```

## `traceroute`

Shows every network hop (router) a packet passes through on the way to a destination.

```
$ traceroute -m 8 8.8.8.8
traceroute to 8.8.8.8 (8.8.8.8), 8 hops max, 40 byte packets
 1  wifi.height8tech.com (100.128.160.1)  6.074 ms  11.264 ms  6.966 ms
 2  114.79.130.29.dvois.com (114.79.130.29)  17.638 ms  19.673 ms  18.812 ms
 3  72.14.208.165 (72.14.208.165)  18.548 ms  18.385 ms  18.453 ms
 4  192.178.111.151 (192.178.111.151)  19.016 ms ...
 5  142.250.238.199 (142.250.238.199)  20.202 ms ...
 6  dns.google (8.8.8.8)  19.295 ms  18.505 ms  19.352 ms
```

## `dig` / `nslookup`

Query DNS to resolve a domain name to an IP address.

```
$ dig +short github.com
20.207.73.82

$ nslookup github.com
Server:		100.128.160.1
Address:	100.128.160.1#53

Non-authoritative answer:
Name:	github.com
Address: 20.207.73.82
```

## `netstat -rn`

Prints the local routing table — which gateway/interface traffic to a given
destination goes through.

```
$ netstat -rn
Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
default            100.128.160.1      UGScg                 en0
100.128.160/20     link#11            UCS                   en0      !
100.128.160.1/32   link#11            UCS                   en0      !
```

## `netstat -an`

Lists active network connections and their state (e.g. `ESTABLISHED`, `LISTEN`).

```
$ netstat -an | grep ESTABLISHED | head -5
tcp4  0  0  100.128.174.237.57034  20.207.73.82.443   ESTABLISHED
tcp4  0  0  100.128.174.237.57033  20.207.73.85.443   ESTABLISHED
tcp4  0  0  100.128.174.237.57021  140.82.113.26.443  ESTABLISHED
```
On Linux, `ss -tan` is the modern equivalent and is much faster.

## `arp -a`

Shows the ARP cache — IP-to-MAC address mappings for devices on the local network.

```
$ arp -a
wifi.height8tech.com (100.128.160.1) at d0:ea:11:32:0:19 on en0 ifscope [ethernet]
? (100.128.160.70) at ea:ad:3e:c9:ce:29 on en0 ifscope [ethernet]
```

## `whois`

Looks up domain/IP registration information from the relevant registry.

```
$ whois github.com | head -10
% IANA WHOIS server
refer:        whois.verisign-grs.com
domain:       COM
organisation: VeriSign Global Registry Services
```

## `curl -I`

Sends an HTTP request and prints only the response headers — useful for
checking a server is up and inspecting its response without downloading the body.

```
$ curl -sI https://github.com
HTTP/2 200
content-type: text/html; charset=utf-8
strict-transport-security: max-age=31536000; includeSubdomains; preload
```

## Summary

| Command | Purpose |
|---|---|
| `hostname` | Show the machine's network name |
| `ifconfig` / `ip addr` | Show interface IP/MAC/link state |
| `ping` | Test reachability + latency |
| `traceroute` | Show the path (hops) to a destination |
| `dig` / `nslookup` | Resolve a domain name via DNS |
| `netstat -rn` | Show the routing table |
| `netstat -an` / `ss -tan` | Show active connections |
| `arp -a` | Show IP↔MAC mappings on the LAN |
| `whois` | Look up domain/IP registration info |
| `curl -I` | Check an HTTP endpoint's response headers |
