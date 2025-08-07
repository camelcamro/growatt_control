# Home Assistant Integration Guide

Use `growatt_control.sh` from Home Assistant via `shell_command` to read and write inverter parameters.

> **⚠️ Important:** Home Assistant’s built‑in shell may lack utilities. We recommend invoking the script over SSH to a host with all required tools (`bash`, `curl`, `sed`, `grep`, `awk`, `sort`, `uniq`, `wc`).

---

## Prerequisites

1. **growatt\_control.sh** installed on a remote Linux host (e.g., Raspberry Pi).
2. Required tools on that host:

   * `bash`
   * `curl`
   * `sed`
   * `grep`
   * `awk`
   * `sort`, `uniq`, `wc`
3. SSH access from the Home Assistant server to the remote host. Configure key‑based auth or store credentials securely.

---

## Configuration (`configuration.yaml`)

Add the following to your Home Assistant configuration:

```yaml
shell_command:
  growatt_read: >-
    ssh -o "StrictHostKeyChecking=no" root@localhost \
      "/home/growatt/growatt_control.sh \
      --action read \
      --method {{ method }} \
      --serial {{ serial }} \
      --type {{ type }} \
      --user {{ user }} \
      --password {{ password }}"

  growatt_write: >-
    ssh -o "StrictHostKeyChecking=no" root@localhost \
      "/home/growatt/growatt_control.sh \
      --action write \
      --method {{ method }} \
      --serial {{ serial }} \
      --type {{ type }} \
      --user {{ user }} \
      --password {{ password }} \
      --value {{ value }}"
```

* **Replace**:

  * `root@localhost` with your actual SSH user and host.
  * Paths to `growatt_control.sh` if different.
  * Template variables (`{{ method }}`, `{{ serial }}`, etc.) with your own input when calling the service.

---

## Using Shell Commands

Call the shell commands via Home Assistant services:

1. **Read a parameter**

   ```yaml
   service: shell_command.growatt_read
   data:
     method: readStorageParam
     serial: NUK2NYQ02V
     type: storage_spf5000_buzzer
     user: you@example.com
     password: YOURPASS
   ```

2. **Write a parameter**

   ```yaml
   service: shell_command.growatt_write
   data:
     method: storageSPF5000Set
     serial: NUK2NYQ02V
     type: storage_spf5000_buzzer
     user: you@example.com
     password: YOURPASS
     value: 1
   ```

You can invoke these services from automations, scripts, or the Developer Tools → Services panel.

---

## Example: Command-Line Sensor

To expose a parameter as a sensor in Home Assistant:

```yaml
sensor:
  - platform: command_line
    name: Growatt Buzzer State
    command: >
      ssh -o "StrictHostKeyChecking=no" root@localhost \
        "/home/growatt/growatt_control.sh --action read --method readStorageParam --serial NUK2NYQ02V --type storage_spf5000_buzzer --user you@example.com --password YOURPASS"
    scan_interval: 300  # poll every 5 minutes
    value_template: "{{ value }}"
```

---

## Security Notes

* Store SSH keys and passwords securely (e.g., use `keyring` integration or encrypted secrets).
* Limit SSH access to a dedicated user with minimal permissions.

Enjoy seamless Growatt inverter management from Home Assistant!
