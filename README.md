# growatt\_control.sh

**Version:** 1.0.0 (Parser v1.0.0)

A unified Bash script to manage Growatt inverters (here made SPF5000) via the growatt or PVButler web service.

> **⚠️ IMPORTANT:** Always run `--action read_all` first to discover available parameters and valid ranges. Incorrect writes can damage your system or void warranties.

---

## Prerequisites

Ensure the following command-line tools are installed and available in your `$PATH`:

* `bash`
* `curl`
* `sed`
* `grep`
* `awk`
* `sort`, `uniq`, `wc`

---

## Requirements

* Bash 4+
* curl
* sed
* grep
* awk
* sort, uniq, wc

**Disclaimer:** Use at your own risk. Incorrect settings may harm equipment or void warranty.

---

## Inverter Requirements

Please always check your inverter manual for valid values and test it be careful - specially on "--action write" !

INVERTER SERIAL - you need to find your inverter serial number, you will need that for the tool on request.
Account and Access to web portal of pvbutler or/and growatt web portal
User name (most email address) and password, which you use to connect to pvbutler or/and growatt web portal

---

## Usage

```bash
./growatt_control.sh \
  --action <read_all|read|write> \
  --serial <inverter_serial> \
  --user <email> \
  --password <password> \
  [--type <parameter>] \
  [--value <value>] \
  [--method <api_method>] \
  [--debug]
```

* `--action read_all`
  Discovers **all** configurable parameters and their current values. Prints two tables:

  1. **Possible parameters** (key, description, current value, allowed range)
  2. **Current values** (all JSON fields and their values)

* `--action read`
  Reads one parameter via API. Requires `--type` and optional `--method` (default: `readStorageParam`).

* `--action write`
  Writes a new value to one parameter. Requires `--type`, `--value`, and optional `--method` (default: `storageSPF5000Set`).

  ! After write, pls check with "--action read" if the value was changed
  
---

## Available Parameters (`--type` values)

Below is the list of parameters you can use with `--action read`/`write`, along with their description and valid value formats.
(that example is for inverter SPF 5000-12000)
| Parameter                                            | Description                              | Allowed Values / Range                                                             |
| ---------------------------------------------------- | ---------------------------------------- | ---------------------------------------------------------------------------------- |
| `storage_spf5000_ac_output_source`                   | AC Output Source                         | `0=Battery First`, `1=Pv Priority`, `2=Uti Priority`, `3=Pv&Uti`                   |
| `storage_spf5000_charge_source`                      | Charge Source                            | `0=Pv Priority`, `1=Pv&Uti`, `2=Only Pv`                                           |
| `storage_spf5000_pv_input_model`                     | PV Input Model                           | `0=Independent`, `1=Energy storage and machine`                                    |
| `storage_spf5000_ac_input_model`                     | AC Input Model                           | `0=APL`, `1=UPS`, `2=GEN`                                                          |
| `storage_spf5000_ac_discharge_voltage`               | AC Discharge Voltage                     | `0=208VAC`, `1=230VAC`, `2=240VAC`, `3=220VAC`, `4=100VAC`, `5=110VAC`, `6=120VAC` |
| `storage_spf5000_ac_discharge_frequency`             | AC Discharge Frequency                   | `0=50Hz`, `1=60Hz`                                                                 |
| `storage_spf5000_overlad_restart`                    | Overload Restart                         | `0=Restart`, `1=No Restart`, `2=Switch to Uti`                                     |
| `storage_spf5000_overtemp_restart`                   | Overtemp Restart                         | `0=Restart`, `1=No Restart`                                                        |
| `storage_spf5000_buzzer`                             | Audible Buzzer On/Off                    | `0=Off`, `1=On`                                                                    |
| `storage_spf5000_max_charge_current`                 | Maximum Charge Current                   | range `0–180` (A) or `10–130` (A) depending on model                               |
| `storage_spf5000_bulk_charge_voltage`                | Bulk Charge Voltage Point                | range `50.0–57.4` (V)                                                              |
| `storage_spf5000_folat_charge_voltage`               | Float Charge Voltage Point               | range `50.0–56.0` (V)                                                              |
| `storage_spf5000_max_ac_charge_current`              | Maximum AC Charge Current                | range `0–100` (A)                                                                  |
| `storage_spf5000_battery_type`                       | Battery Type                             | `0=AGM`, `1=Flooded`, `2=User Defined`, `3=Li`, `4=User Defined 2`                 |
| `storage_spf5000_bLightEn`                           | LCD Backlight On/Off                     | `0=Off`, `1=On`                                                                    |
| `storage_spf5000_manualStartEn`                      | Manual Start Enable                      | `0=On`, `256=Off`                                                                  |
| `storage_spf5000_uti_output`                         | UTI Output Schedule (hours)              | range `0–23`                                                                       |
| `storage_spf5000_uti_charge`                         | UTI Charge Schedule (hours)              | range `0–23`                                                                       |
| `storage_spf5000_system_time`                        | System Timestamp (read-only)             | (read-only string)                                                                 |
| `storage_shangke_output_start_time_period`           | Output Start Time Period (hours)         | range `0–23`                                                                       |
| `storage_shangke_output_end_time_period`             | Output End Time Period (hours)           | range `0–23`                                                                       |
| `storage_shangke_charging_start_time_period`         | Charging Start Time Period (hours)       | range `0–23`                                                                       |
| `storage_shangke_charging_end_time_period`           | Charging End Time Period (hours)         | range `0–23`                                                                       |
| `storage_shangke_battery_to_mains_working_point`     | Battery-to-Mains Voltage Operating Point | range `9.0–64.0` (V)                                                               |
| `storage_shangke_mains_to_battery_operating_point`   | Mains-to-Battery Voltage Operating Point | range `9.0–64.0` (V)                                                               |
| `storage_shangke_lithium_battery_protocol_type`      | Lithium Battery Protocol Type            | range `1–99`                                                                       |
| `storage_shangke_battery_undervoltage_cut_off_point` | Battery Undervoltage Cut-off Point       | range `9.0–64.0` (V)                                                               |
| `storage_shangke_solar_to_grid`                      | Solar-to-Grid Feed Enable/Disable        | `0=Disable`, `1=Enable`                                                            |
| `storage_shangke_solar_supply_priority`              | Solar Supply Priority                    | `0=Charge First`, `1=Load First`                                                   |
| `storage_shangke_grid_voltage_regulations`           | Grid Voltage Regulation Standard         | `0=Asia`, `1=Europe`, `2=South America`                                            |

---

## Examples

1. **Discover all parameters and current values** (--action read_all)

   ```bash
   ./growatt_control.sh \
     --serial NUKXY123YYV \
     --user you@example.com \
     --password YOURPASS
     --action read_all
   ```

2. **Read a single parameter**

  ! *--method* key -> you need to find from "--action read_all" your *method* which is valid for reading and writing !
  ! *--type* key -> you need to find the supported type parameter from "--action read_all" your *method* which is valid for your system !

   ```bash
   ./growatt_control.sh \
     --serial NUKXY123YYV \
     --user you@example.com \
     --password YOURPASS
     --action read \
     --method readStorageParam \
     --type storage_spf5000_max_ac_charge_current
   ```

3. **Write a new value to a parameter**

  ! *--method* key -> you need to find from "--action read_all" your *method* which is valid for reading and writing !
  ! *--type* key -> you need to find the supported type parameter from "--action read_all" your *method* which is valid for your system !
  ! *--value* key -> you need to check which values are supported by your inverter from "--action read_all" your *method* which is valid for your system !

   ```bash
   ./growatt_control.sh \
     --serial NUKXY123YYV \
     --user you@example.com \
     --password YOURPASS
     --action read \
     --method storageSPF5000Set \
     --type storage_spf5000_max_ac_charge_current
     --value 99 \
   ```

---

**Disclaimer:** Use at your own risk. Incorrect settings may harm equipment or void warranty.
