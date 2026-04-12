---
name: nixos-update
description: >-
  Guides safe NixOS upgrades using flakes or channels—flake lock updates,
  nixos-rebuild switch/boot/test, dry-run, rollback, and reboot checks.
  Use when the user asks to update or upgrade NixOS, refresh nixpkgs, rebuild
  the system, or fix a failed switch. If mcp-nixos is available, use it to
  verify option and package names before editing configuration.
---

# NixOS update and rebuild

This skill is versioned at **`.cursor/skills/nixos-update/`** in the repo. On another computer, clone the repo and open this workspace in Cursor so the skill is available (or copy that folder into another project’s `.cursor/skills/` if you reuse the skill elsewhere).

## Before changing anything

1. Confirm **flake vs channels**: flakes use `flake.nix` + `flake.lock` at a known path; channel installs use `nix-channel --list` and `sudo nixos-rebuild switch` without `--flake`.
2. For flakes, read `flake.nix` (or user input) for **`nixosConfigurations.<hostname>`** and use that **exact** `hostname` in rebuild commands.
3. Prefer **`nixos-rebuild boot`** or **`switch`** only after a successful **`test`** when the change is large or risky (kernel, networking, boot).

## Flake workflow (typical)

Run from the directory that contains `flake.nix`:

```bash
# See what would change (no system mutation for rebuild dry-run)
sudo nixos-rebuild dry-run --flake .#HOSTNAME

# Refresh lockfile inputs (all) or one input only
nix flake update
# nix flake update nixpkgs

# Optional: review lock diff before rebuild
git diff flake.lock

# Apply (pick one)
sudo nixos-rebuild switch --flake .#HOSTNAME   # immediate
sudo nixos-rebuild boot --flake .#HOSTNAME     # next reboot only (safer for risky changes)
sudo nixos-rebuild test --flake .#HOSTNAME     # activate but do not add bootloader entry
```

## Rollback

```bash
sudo nixos-rebuild switch --rollback
# or choose generation in bootloader; list: sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

## After a successful switch

- If the **kernel** or **critical drivers** changed, plan a **reboot** when convenient.
- If **remote** machine: ensure **SSH** and network come back after reboot (tailnet/VPN path documented).

## mcp-nixos (optional MCP)

If **mcp-nixos** is enabled in Cursor (`uvx mcp-nixos` or equivalent), use its **`nix`** tool to **search or resolve** NixOS **options** and **packages** before guessing names in `configuration.nix` or modules. Examples (exact invocation depends on client wiring):

- Search options: `action=search`, `source=nixos`, `type=options`, `query=…`
- Search packages: `type=packages`, `query=…`
- Details: `action=info` with the resolved name

Upstream: [utensils/mcp-nixos](https://github.com/utensils/mcp-nixos). Cursor MCP config often looks like:

```json
"mcpServers": {
  "nixos": {
    "command": "uvx",
    "args": ["mcp-nixos"]
  }
}
```

If the MCP is **not** installed, use [search.nixos.org](https://search.nixos.org/packages) and [NixOS options](https://search.nixos.org/options) in the browser instead.

## Channel workflow (no flake)

```bash
sudo nix-channel --update
sudo nixos-rebuild switch
```

Use the same **dry-run** / **test** / **boot** ideas as above where applicable.
