# NixOS homelab plan

Reference doc for homelab hosts (starting with the homelab-laptop): NixOS laptop, DAS storage, **VPN/tailnet-first** access (FUTO-style), security-first rollout.

**When following this plan:** create a **new homelab host** in the flake—each physical machine gets its own `nixosConfigurations.<hostname>` and its own rebuild path. Use [New homelab host (flake entry)](#new-homelab-host-flake-entry) before or alongside [Phase 1 — Foundation](#phase-1--foundation).

## Threat model (summary)

- **Primary concern:** Remote attackers on the internet; keep **apps off the public WAN** and enter through **one well-maintained VPN/mesh path** (FUTO: prefer that over many forwarded service ports).
- **Not in scope:** Drive theft / physical extraction; full-disk encryption is optional, not required for this plan.

## Torrent egress (ISP path vs commercial VPN)

These are **two different paths** your qBittorrent traffic can take to reach people on the internet. They are **not** the same as **Tailscale** (Tailscale is for *you* getting *into* your home; torrents use a **different** path).

**Path A — Plain ISP (no extra VPN)**  
Traffic goes out your **normal home internet** (Comcast, AT&T, etc.). Peers see **your home’s public IP** (or your ISP’s CGNAT address). **Pros:** simplest setup; you can add **one** manual **TCP+UDP** forward on the TP-Link for qBittorrent’s **listen** port (not the Web UI) for better seeding, with UPnP still **off**. **Cons:** your ISP still sees encrypted volume/timing; if you ever used **public** swarms, copyright monitors could see your IP—less relevant for **private** trackers and direct invites, but rules and trust still matter.

**Path B — Commercial VPN (Mullvad, Proton VPN, IVPN, AirVPN, Windscribe, etc.)**  
You pay a company that runs **VPN servers elsewhere**. On the laptop you run their app or a **WireGuard/OpenVPN config**; qBittorrent is set to use **only** the **tunnel network interface** that software creates (often named like `wg0`, `tun0`, `mullvad`, etc.). Traffic to peers exits at **their datacenter**. **Pros:** peers see the **VPN’s IP**, not your home IP; many providers offer **port forwarding** for seeding **without** opening ports on your TP-Link. **Cons:** cost; trust in the provider; if the tunnel drops, you need a **kill switch** so torrents do not leak onto Path A.

**Mullvad** and **Proton VPN** are **examples** of Path B providers—not Tailscale.

**Locked for this plan:** **Path A (ISP egress)**. Use is **private file sharing sites / trackers**, not public open indexes. Revisit Path B if you later add **public** swarms or want egress IP hidden from peers.

## Constraints (locked in)

| Topic | Choice |
|--------|--------|
| Role | Plugged in, lid closed, minimal physical access; automate or manage remotely |
| Priority services | Jellyfin, Syncthing, backups, **qBittorrent** (24/7 seeding) first; add other stacks only after base is secure |
| Remote access | **VPN or tailnet first** (Tailscale and/or WireGuard). **No** Jellyfin, Syncthing, or admin UIs exposed to the open internet. |
| Edge / proxy | **Caddy** terminates TLS where useful (typically **tailnet/LAN/loopback only**), `reverse_proxy` to local backends |
| WAN exposure | **Prefer zero** forwarded ports (**Tailscale**). **Or** exactly **one UDP port** for **WireGuard** if you want direct VPN without Tailscale. **No** public HTTP/HTTPS to Jellyfin. |
| Router | **TP-Link** now (manual steps below); **pfSense** when hardware exists |
| Storage | DAS: at least 1 TB HDD + 24 TB HDD (plus internal disk for OS) |
| Network | Ethernet |
| Updates | Automatic security updates via Nix acceptable |
| Torrent egress | **Path A** — ISP egress; **private** trackers/sites only (see [Torrent egress](#torrent-egress-isp-path-vs-commercial-vpn)) |

## FUTO-aligned exposure (VPN / tailnet, not public apps)

**Principle:** Do not forward ports for Jellyfin, Syncthing, SSH, or random self-hosted UIs. Prefer **one controlled remote entry** (FUTO uses **OpenVPN** on pfSense; on NixOS, **Tailscale** or **WireGuard** is the same idea).

**BitTorrent is different:** Peer traffic is **not** tailnet traffic. **Do not** route torrents through **Tailscale**. This plan uses **Path A (ISP)** for **private** trackers—see [Torrent egress](#torrent-egress-isp-path-vs-commercial-vpn). A **commercial VPN** for torrents is **not** the same as the **Tailscale/WireGuard “into home”** tunnel; do not collapse those unless you know why.

**Preferred (often zero router forwards):** **Tailscale** on the laptop. You reach Jellyfin, SSH, and Syncthing **only** over the tailnet. The laptop firewall stays default-deny toward the internet; no need to publish services on your public IP.

**Alternative:** **WireGuard** on NixOS with **one** router forward: **UDP** (e.g. 51820) → laptop. All remote access tunnels through that; still **no** public TCP 443 to Caddy/Jellyfin.

**Caddy’s role:** Bind to **127.0.0.1** and/or **tailnet/LAN interfaces only**—not to the public WAN. Use it for HTTPS to Jellyfin on the tailnet (e.g. with **Tailscale HTTPS**, **DNS-01** + internal name, or a name that only resolves on the tailnet). Backends stay on **127.0.0.1**; Caddy is not a public internet entrypoint.

**SSH / admin:** **Never** on WAN. Tailscale, WireGuard, or LAN only.

**Later (pfSense):** Move the VPN endpoint to **OpenVPN or WireGuard on pfSense** if you want the router to be the single hardened choke point (FUTO pattern); keep the same rule—**no** port storms to individual apps.

## Consumer router until pfSense (interim)

Goals: **no surprise holes**, **no UPnP**, **no DMZ**, **no remote admin from the WAN**. Allowed manual forwards only: **(1)** optional **WireGuard UDP** for *into-home* access; **(2)** optional **one TCP+UDP** rule for qBittorrent’s **listen** port only (Path A seeding)—**not** Jellyfin, **not** qBittorrent **Web UI**, not random app ports.

### TP-Link — do these in order (web UI)

TP-Link moves labels between firmware versions. If a path below does not match your screen, use the router’s **search** box (magnifying glass, if present) or look under **Advanced** for the same keywords (**UPnP**, **DMZ**, **Virtual Servers**, **Port Forwarding**, **Remote Management**, **Firmware**).

**0. Connect and open the admin page**

- Plug a PC into the router with **Ethernet** (safer than Wi‑Fi for big changes).
- Open a browser. Try, in order: [http://tplinkwifi.net](http://tplinkwifi.net/), [http://tplinkmodem.net](http://tplinkmodem.net/) (common on modem/router combos), then the **gateway** printed on the router label (often `192.168.0.1` or `192.168.1.1`).
- Log in. If the password is still the factory default, **change it** on first login (set a **long, unique** password and store it in your password manager).

**1. Firmware**

- Go to **Advanced** → **System** → **Firmware Upgrade**, or **Advanced** → **System Tools** → **Firmware Upgrade** (wording varies).
- Use **Check for updates** / online upgrade if offered, or download the correct file for your **exact model and hardware version** from [TP-Link Download Center](https://www.tp-link.com/support/download/) and use **Local upgrade**.
- Do **not** power-cycle during the upgrade. Prefer **Ethernet** for the upgrade, not Wi‑Fi. Official overview: [How to upgrade the firmware on the TP-Link Wi-Fi Routers](https://www.tp-link.com/us/support/faq/2796/).

**2. Turn off UPnP**

- Go to **Advanced** → **Port Forwarding** and open **UPnP**, **or** **Advanced** → **NAT Forwarding** → **UPnP** (ISP-branded models often use the **NAT Forwarding** path).
- Set UPnP to **Off** / **Disable**, then **Save**.
- Reference: [Introduction to UPnP feature on TP-Link Router and Deco](https://www.tp-link.com/us/support/faq/4624/) (same steps are documented for **Deco** in the **Tether** app: **More** → **Advanced** → **NAT Forwarding** → UPnP).

**3. Turn off remote management from the internet**

- Go to **Advanced** → **System Tools** → **Administration** (sometimes under **System** → **Administration**).
- In **Remote Management**, choose **Disable Remote Management** (forbid all devices from managing the router from the internet), then **Save**.
- Reference: [How to set up Remote Management on the Wi-Fi Routers (new logo)](https://www.tp-link.com/us/support/faq/1553/) — you want the **disabled** case, not “allow all devices.”
- Optional hardening: if you do not need **TP-Link Cloud** / **Tether** remote control, on many models **Basic** → **TP-Link Cloud** you can **unbind** accounts you do not want linked (see your model’s manual; cloud features vary).

**4. Turn off DMZ**

- Go to **Advanced** → **NAT Forwarding** → **DMZ** (on some old UIs: **Forwarding** → **DMZ**).
- **Disable** DMZ; clear any **DMZ host IP**; **Save**. A DMZ host is fully exposed; it should stay **off** for this plan.

**5. Audit port forwarding / virtual servers**

- Go to **Advanced** → **NAT Forwarding** → **Virtual Servers** (or **Port Forwarding** / **NAT** → **Virtual Servers**).
- **Delete** every rule that points to your NixOS laptop’s IP **except** rules you **intentionally** keep: **one WireGuard UDP** (if used), and **at most one** **TCP+UDP** pair for qBittorrent’s **listen** port only (same external port → laptop, Path A). Remove anything else (8096, 8080, 22, 443, Web UI ports, old games, etc.).

**6. Wi‑Fi and WPS**

- Use **WPA2/WPA3** with a **strong** Wi‑Fi password (not the same as the admin password).
- **WPS:** go to **Advanced** → **Wireless** → **WPS** and **disable** if a toggle exists. On some models with **WPA3-only**, WPS is unavailable or greyed out (that is fine). Official community pointer: [Disable WPS](https://community.tp-link.com/en/home/forum/topic/665506) (location **Advanced** → **Wireless** → **WPS**).

**7. Guest network (if available)**

- Enable **Guest Network** in the **Basic** or **Wireless** section and turn **on** “**guest isolation**” / “**allow guests to access each other** = off” / “**access my local network** = off” (exact labels vary). Guests should not reach your **LAN** or the homelab-laptop.

**8. IPv6**

- If IPv6 is enabled on WAN, skim **IPv6** firewall / forwarding sections for anything that **exposes a LAN host** or duplicates old port forwards. Goal matches IPv4: **no** direct exposure of app ports on the laptop.

### Interim checklist (any brand, including TP-Link)

- [ ] **Firmware** updated; process documented if you use offline `.bin` upgrades
- [ ] **Admin** password strong and not default
- [ ] **UPnP** off (per TP-Link steps above)
- [ ] **Remote management** off from WAN (per TP-Link FAQ above)
- [ ] **DMZ** off
- [ ] **Port forwards** reviewed; only optional **WireGuard UDP** to laptop
- [ ] **Wi‑Fi** secured; **WPS** disabled where applicable; **guest** isolated from LAN
- [ ] **IPv6** reviewed if in use

## New homelab host (flake entry)

Do this whenever you add **another** NixOS box to the homelab, or on **first** install if the flake does not yet list this machine.

- [ ] Pick a **stable hostname** (matches DNS/MagicDNS intent if you use it); use it consistently in `nixosConfigurations.<hostname>` and on the machine (`networking.hostName`).
- [ ] On the target hardware (installer or bootstrapped NixOS), generate **`hardware-configuration.nix`** for that machine only (`nixos-generate-config`); do not reuse another host’s hardware file unless you know it is identical.
- [ ] Add **`nixosConfigurations.<hostname>`** to the flake: import the new `hardware-configuration.nix`, shared modules you want on all homelab hosts, and a **host-specific** `configuration.nix` (or equivalent) for disks, services, and firewall on **this** box.
- [ ] Run **`nix flake lock`** (or update inputs) and commit **`flake.lock`** when inputs change.
- [ ] Document the rebuild command for **this** host, e.g. `sudo nixos-rebuild switch --flake <path/to/flake>#<hostname>` (or your deploy wrapper).
- [ ] **Secrets:** add host-scoped secrets (agenix/sops paths or keys) so this host does not read another machine’s ciphertext unless intentionally shared.
- [ ] **Tailscale / WireGuard:** enroll **this** node (new Tailscale machine key or new WireGuard peer); update ACLs/peers so the new host has least privilege.
- [ ] **Router / DHCP:** if you use static leases or port forwards (e.g. WireGuard UDP, qBittorrent listen), add or adjust rules for **this** host’s LAN IP; do not copy another host’s forwards blindly.

## Architecture targets

- **Config**: flake-based NixOS in Git with a lock file; rebuilds and rollbacks via `nixos-rebuild`; **one flake attribute per homelab host** (see [New homelab host](#new-homelab-host-flake-entry)).
- **Data disks**: mount by **UUID** under stable paths (e.g. `/mnt/data-fast`, `/mnt/data-bulk`); avoid `/dev/sdX` for DAS.
- **Caddy**: binds **only** non-WAN addresses (loopback, tailnet, LAN as designed); **not** on the interface that faces the ISP/router for app traffic.
- **Apps**: Jellyfin and others listen on **127.0.0.1** (or tailnet/LAN bind if required); never as a **public** service.
- **Secrets**: agenix or sops-nix; DNS API keys for ACME if using DNS-01; Tailscale auth key / WireGuard keys in secrets.

## Remote access / TLS pattern

- [ ] **Tailscale** (recommended) **or** **WireGuard** documented as the **only** remote path to SSH and services.
- [ ] **Caddy** (optional but useful) for HTTPS on **private** interfaces only; ACME via **DNS-01** and/or **Tailscale HTTPS** (document which).
- [ ] **No** WAN forward to **80/tcp** or **443/tcp** on the laptop for Jellyfin.

---

## Phase 1 — Foundation

Complete before tailnet/VPN is trusted for admin and before media/sync go live.

### Flake and Git

- [ ] New host checklist completed: [New homelab host (flake entry)](#new-homelab-host-flake-entry)
- [ ] Flake defines `nixosConfigurations.<hostname>` with `hardware-configuration.nix` + main `configuration.nix`
- [ ] `flake.lock` committed; documented rebuild command (e.g. `sudo nixos-rebuild switch --flake .#<hostname>`)

### DAS and filesystems

- [ ] Partition/format 1 TB and 24 TB drives (choice: XFS for simplicity, or btrfs if snapshots matter)
- [ ] `fileSystems.*` entries using `/dev/disk/by-uuid/...` for each mount
- [ ] Mount points chosen and documented (e.g. fast vs bulk roles)
- [ ] Boot ordering OK if DAS powers on slower than the laptop (timeouts or `nofail` where appropriate)

### Power and lid (laptop as server)

- [ ] Lid close does not suspend on AC
- [ ] Sleep/hibernate on AC disabled or tuned so services stay up
- [ ] On-battery behavior acceptable if power blips (optional: treat battery as short UPS)

### Firewall

- [ ] Firewall enabled with default deny toward the internet
- [ ] **WAN-facing rules**: **none** for app ports. If using **WireGuard**, allow **only** that **UDP** port from `internet` to this host; if **Tailscale-only**, typically **no** inbound WAN rules on the laptop
- [ ] Jellyfin, Syncthing, Caddy (for apps), **qBittorrent Web UI**, and SSH **not** reachable from untrusted WAN; tailnet/LAN/loopback only as designed

### SSH

- [ ] `services.openssh` enabled
- [ ] Key-based login; **only** via Tailscale, WireGuard, or LAN—**never** bound to or forwarded from the public internet
- [ ] `authorizedKeys` managed in Nix (or documented process)

### Secrets

- [ ] agenix **or** sops-nix wired into the flake
- [ ] Pattern documented for adding a new secret (encrypt → reference in module → rebuild)

### Automatic updates

- [ ] `system.autoUpgrade` (or equivalent) configured for this host
- [ ] Decision recorded: auto-reboot on kernel vs manual reboot after upgrades
- [ ] If using a flake from Git: auto-upgrade source matches how you deploy (remote URL vs local path)

### Phase 1 sign-off

- [ ] Reboot test: all mounts present, SSH works (via intended path), firewall as expected
- [ ] Rollback test: `nixos-rebuild switch --rollback` understood and works

---

## Phase 2 — Tailnet/VPN, optional TLS (Caddy), no public apps

### Tailscale or WireGuard

- [ ] **Tailscale** or **WireGuard** on NixOS; you can SSH and reach LAN/tailnet services remotely **without** publishing Jellyfin to the world
- [ ] If **WireGuard**: router forwards **only** the chosen **UDP** port; document the port and keep it the **sole** forward to this host
- [ ] ACLs / peer list reviewed (Tailscale ACLs or WireGuard `AllowedIPs`) so least privilege

### DNS (optional)

- [ ] If using a **public** name for ACME or future use: document whether the name resolves only on tailnet (split DNS / MagicDNS) or publicly; **public A/AAAA to home is not required** for FUTO-style access

### Router (interim)

- [ ] **TP-Link** steps and interim checklist ([Consumer router until pfSense](#consumer-router-until-pfsense-interim)) completed; **no** 80/443/22 forwards to the laptop

### Caddy (private binding only)

- [ ] `services.caddy` enabled; config in Nix or included file
- [ ] Listens **only** on **127.0.0.1** and/or **tailnet/LAN**—verify with `ss -tlnp` (or equivalent) that nothing app-related is on `0.0.0.0` toward WAN
- [ ] Site block for Jellyfin with `reverse_proxy` to **127.0.0.1:JELLYFIN_PORT**
- [ ] TLS: **DNS-01** and/or **Tailscale HTTPS** as appropriate; **no** public **TLS-ALPN** on WAN for this host (because **443 is not open** to the internet)
- [ ] **Security headers:** HSTS (once stable hostname), `X-Content-Type-Options`, `Referrer-Policy`, `X-Frame-Options` or CSP as fits Jellyfin
- [ ] **Rate limiting / abuse:** connection or request limits on `reverse_proxy` (Caddy plugin such as rate-limit, or **Crowdsec** bouncer, or fail2ban on auth failures if you add HTTP basic auth)—document what you chose
- [ ] **Auth:** strong unique Jellyfin passwords; enable **2FA** in Jellyfin if available; consider **Authelia** (or similar) in front of Jellyfin via Caddy for an extra layer
- [ ] **Logging:** log **access** at a level you accept (IPs, status, latency); **avoid** logging **tokens, cookies, or full URLs with secrets**; restrict log file permissions; define **retention** (rotate/truncate)

### Jellyfin (not internet-facing)

- [ ] Jellyfin listens on **127.0.0.1** (or tailnet bind if required); **not** reachable from untrusted WAN

### Hardening

- [ ] No public SSH; admin path documented (tailnet/VPN/LAN only)
- [ ] From a **non-tailnet** network: confirm Jellyfin and SSH **fail** to connect to your **public IP** (only WireGuard handshake succeeds if you use WG)

### Phase 2 sign-off

- [ ] Remote: Jellyfin (and admin) work **only** via Tailscale or over **WireGuard after tunnel up**
- [ ] **nmap** (or provider scan) from internet: **no** unexpected open TCP services on the laptop’s public path; **only** optional **WireGuard UDP** if applicable

---

## Phase 3 — Priority services

### Syncthing

- [ ] NixOS `services.syncthing` enabled
- [ ] Data path on appropriate disk (1 TB vs 24 TB per your layout)
- [ ] GUI and sync **not** on WAN; **Tailscale** (or LAN) only
- [ ] Remote devices paired; folder paths aligned with mount layout

### Jellyfin

- [ ] `services.jellyfin` enabled
- [ ] Media libraries on 24 TB (or as designed)
- [ ] Remote playback **only** over **tailnet/VPN** (Caddy on **private** bind if using HTTPS, localhost backend)
- [ ] Admin password / secrets via agenix or sops-nix

### qBittorrent (24/7 seeding)

- [ ] **Path A locked:** torrents use **ISP egress** (private trackers only); no commercial VPN layer unless requirements change
- [ ] **NixOS package/service** (e.g. `qbittorrent` / `qbittorrent-nox` or documented module) runs as a long-lived service suitable for headless seeding
- [ ] **Download + seed paths** on the right disk (typically **bulk** 24 TB for completed library; optional fast disk for incomplete if you want less seeking)
- [ ] **Web UI / RPC:** bind **127.0.0.1** or **tailnet/LAN only**—same rule as Jellyfin; **never** on WAN. Admin password in **sops-nix / agenix**
- [ ] **Listen port:** fixed port in qBittorrent; **optional** matching **TCP+UDP** Virtual Server on TP-Link → laptop IP **only** for that listen port (UPnP stays off). Document port in decisions log if forwarded
- [ ] **Optional later:** switch to **Path B** (commercial VPN + bind + kill-switch) if you add **public** swarms or want peer-facing IP off your home
- [ ] **Not** bound to Tailscale for peer traffic (see FUTO-aligned section)
- [ ] Disk / DAS: confirm **constant IO** and free space; backups or Jellyfin paths unaffected by torrent temp files
- [ ] Only content you have the **right** to share and acquire under applicable law

### Backups

- [ ] Backup tool chosen (e.g. **restic** or **borg** to remote or object storage)
- [ ] Schedule (systemd timer or service) defined in Nix
- [ ] Encryption keys and repo credentials in secret manager
- [ ] Off-site or second-location copy for irreplaceable data
- [ ] Restore drill once (document steps)

### Phase 3 sign-off

- [ ] Jellyfin plays test media over **HTTPS on tailnet/LAN** (or HTTP on tailnet if that is what you accepted)
- [ ] Syncthing syncs over VPN/LAN only
- [ ] qBittorrent seeds with expected **ratio / connectability** (ISP path + optional listen-port forward); Web UI reachable **only** on tailnet/LAN
- [ ] Backup job completes and restore tested

---

## Phase 4 — Optional stacks (after sign-off)

- [ ] **Uptime monitoring**: uptime-kuma, or Prometheus + Grafana
- [ ] **LAN DNS / filtering**: AdGuard Home or blocky (LAN/tailnet; not a substitute for VPN-first exposure)
- [ ] **Authelia / SSO** in front of Jellyfin via Caddy (recommended if many tailnet users share access)
- [ ] **\*arr** stack (defer until ready); wire clients to **qBittorrent** on localhost when you add them

---

## Security checklist (ongoing)

- [ ] No plaintext secrets in Git
- [ ] **No** app or admin ports (80/443/8096/8080/…, no qBittorrent Web UI) forwarded; **at most** optional **WireGuard UDP** (if used) **plus** optional **one** qBittorrent **listen** TCP/UDP forward (Path A)
- [ ] Backends on localhost; Caddy **not** internet-facing for Jellyfin
- [ ] Jellyfin: strong credentials, 2FA if available, optional Authelia; Caddy rate limits / abuse controls as chosen
- [ ] Caddy logs: no secrets in logs; retention and file permissions sane
- [ ] Firewall reviewed after each new service
- [ ] NixOS + Tailscale/WireGuard + Jellyfin + **qBittorrent** **patch cadence** monitored (security advisories, `nixos-rebuild` when needed)
- [ ] qBittorrent Web UI never on WAN; torrent egress **Path A (ISP)** for private trackers; optional listen-port forward only as documented
- [ ] Auto-upgrades monitored (journal, or notify on failure)
- [ ] DAS disconnect: behavior understood (mount errors, service degradation)
- [ ] When **pfSense** is in service: VPN endpoint on router, regular router updates, revisit VLANs/segmentation (FUTO)

---

## Decisions log

| Date | Decision | Notes |
|------|----------|--------|
| | Remote access | **FUTO-aligned**: VPN/tailnet first; **no** public Jellyfin/SSH |
| | Edge | **Caddy** on **private** binds only; **Tailscale** preferred (often **zero** WAN forwards) **or** **WireGuard** one UDP port |
| | ACME | **DNS-01** and/or **Tailscale HTTPS** (no public 443 on laptop for apps) |
| | Router | Consumer hardening now; **pfSense** when hardware ready |
| | At-rest encryption | **Not** prioritized (physical theft out of scope) |
| | Filesystem on 1 TB / 24 TB | |
| | Backup backend (restic/borg/…) | |
| | Admin SSH path (Tailscale / WG / LAN) | |
| | Torrents | **qBittorrent** 24/7; Web UI private only; **Path A** ISP egress; **private** trackers/sites; optional TP-Link **listen** port forward |
