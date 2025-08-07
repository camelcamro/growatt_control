Home Assistant Integration Guide
Use growatt_control.sh from Home Assistant via shell_command to read and write inverter parameters.

⚠️ Important:
Home Assistant’s limited shell may lack needed utilities. We recommend invoking the script over SSH to a host that has all required tools installed (bash, curl, sed, grep, awk, sort, uniq, wc).

Prerequisites
growatt_control.sh installed on a remote Linux host (e.g. Raspberry Pi) and executable.

These tools must be present on that host:

bash

curl

sed

grep

awk

sort, uniq, wc

SSH access from Home Assistant’s host to that remote machine, via key-based auth or securely stored credentials.

Configuration (configuration.yaml)
Define two shell commands:

yaml
Kopieren
Bearbeiten
shell_command:
  growatt_read: >-
    ssh -o "StrictHostKeyChecking=no" root@<REMOTE_HOST> \
      "/home/growatt/growatt_control.sh \
      --action read \
      --method {{ method }} \
      --serial {{ serial }} \
      --type {{ type }} \
      --user {{ user }} \
      --password {{ password }}"

  growatt_write: >-
    ssh -o "StrictHostKeyChecking=no" root@<REMOTE_HOST> \
      "/home/growatt/growatt_control.sh \
      --action write \
      --method {{ method }} \
      --serial {{ serial }} \
      --type {{ type }} \
      --user {{ user }} \
      --password {{ password }} \
      --value {{ value }}"
Replace root@<REMOTE_HOST> with your SSH user and host.

Adjust the path to growatt_control.sh if yours differs.

When calling the service, fill in template variables ({{ method }}, {{ serial }}, etc.).

Service Calls
Read a Parameter
yaml
Kopieren
Bearbeiten
service: shell_command.growatt_read
data:
  method: readStorageParam
  serial: NUK2NYQ02V
  type: storage_spf5000_buzzer
  user: you@example.com
  password: YOURPASS
Write a Parameter
yaml
Kopieren
Bearbeiten
service: shell_command.growatt_write
data:
  method: storageSPF5000Set
  serial: NUK2NYQ02V
  type: storage_spf5000_buzzer
  user: you@example.com
  password: YOURPASS
  value: 1
You can call these from automations, scripts, or the Developer Tools → Services panel.

Exposing as a Command-Line Sensor
To surface a Growatt parameter as a sensor:

yaml
Kopieren
Bearbeiten
sensor:
  - platform: command_line
    name: Growatt Buzzer State
    command: >-
      ssh -o "StrictHostKeyChecking=no" root@<REMOTE_HOST> \
        "/home/growatt/growatt_control.sh \
         --action read \
         --method readStorageParam \
         --serial NUK2NYQ02V \
         --type storage_spf5000_buzzer \
         --user you@example.com \
         --password YOURPASS"
    scan_interval: 300
    value_template: "{{ value }}"
Security Notes
Store SSH credentials and inverter passwords securely (consider Home Assistant’s secrets.yaml or the keyring integration).

Limit SSH access to a dedicated, low-privilege user.

Enjoy seamless Growatt management through Home Assistant!
