#!/bin/bash
# growatt_control.sh - Dynamic Growatt SPF5000 Tool (100% runtime mapping)

DEBUG=0
VERSION="1.0.1 - 2025-08-06"
SCRIPTNAME="$(basename "$0")"

show_help() {
  echo "Usage: $0 --action <read|write|read_all> --serial <serial> --user <mail> --password <pw> [--type <param>] [--value <val>] [--method <api_method>] [--debug]"
  echo
  echo "  --action         Action: read, write, read_all"
  echo "  --serial         Inverter serial number"
  echo "  --type           Parameter type (for read/write)"
  echo "  --value          Value for write"
  echo "  --user           Growatt username/email"
  echo "  --password       Password (plain text)"
  echo "  --method         API Action-Method for read/write (optional)"
  echo "  --debug          Enable debug output"
  echo
  echo "Examples:"
  echo "  $0 --serial NUK2NYQ02V --user you@mail.com --password YOURPASS --action read_all" 
  echo "  $0 --serial NUK2NYQ02V --user you@mail.com --password YOURPASS --action read --method readStorageParam --type storage_spf5000_max_ac_charge_current --debug"
  echo "  $0 --serial NUK2NYQ02V --user you@mail.com --password YOURPASS --action write --method storageSPF5000Set --type storage_spf5000_max_ac_charge_current --value 54 --debug"
  exit 1
}

SERVER="https://server.pvbutler.com"
COOKIE_FILE="/tmp/growatt_cookie.txt"
RESPONSE_FILE="/tmp/growatt_response.txt"

ACTION=""; SERIAL=""; EMAIL=""; PASSWORD=""; TYPE=""; VALUE=""; METHOD=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action)   ACTION="$2"; shift 2 ;;
    --serial)   SERIAL="$2"; shift 2 ;;
    --user)     EMAIL="$2"; shift 2 ;;
    --password) PASSWORD="$2"; shift 2 ;;
    --type)     TYPE="$2"; shift 2 ;;
    --value)    VALUE="$2"; shift 2 ;;
    --method)   METHOD="$2"; shift 2 ;;
    --debug)    DEBUG=1; shift ;;
    --help|-h)  show_help ;;
    *)          echo "Unknown argument: $1"; show_help ;;
  esac
done

if [[ -z "$ACTION" || -z "$SERIAL" || -z "$EMAIL" || -z "$PASSWORD" ]]; then
  show_help
fi

[[ $DEBUG -eq 1 ]] && echo "$SCRIPTNAME - version $VERSION"

# --- Login ---
LOGIN_PAYLOAD="account=${EMAIL}&password=${PASSWORD}&validateCode=&isReadPact=1&passwordCrc="
curl -s -c "$COOKIE_FILE" -X POST "$SERVER/login?lang=en" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-raw "$LOGIN_PAYLOAD" > /dev/null

# --- read_all: fetch page and parse ---
if [[ "$ACTION" == "read_all" ]]; then
  URL="$SERVER/commonDeviceSetC/setStorage?type=server&storageSn=${SERIAL}&ttt=$(date +%s%3N)&lang=en"
  [[ $DEBUG -eq 1 ]] && echo "DEBUG: curl -s -b \"$COOKIE_FILE\" \"$URL\" > \"$RESPONSE_FILE\""
  curl -s -b "$COOKIE_FILE" "$URL" > "$RESPONSE_FILE"

  ##############################################################################
  # Begin Parser v1.0.0
  ##############################################################################
  IN="$RESPONSE_FILE"
  TMPMETHODS="/tmp/growatt_methods.txt"
  TMPBEAN="/tmp/growatt_bean.json"
  TMPBODY="/tmp/growatt_body.txt"
  TMPBEANS_ALL="/tmp/growatt_beans_all.json"
  TMPBEAN_BODY="/tmp/growatt_bean_body.txt"
  TMPVALUES="/tmp/growatt_values.txt"
  PARSER_VER="1.0.0"

  echo "growatt_response.sh parser version $PARSER_VER"
  echo

  # === 0) Available methods ===
  echo "Available methods:"
  echo "=================="
  # Grep nach action:'…' und datas.action="…"
  grep -Eo "datas\.action\s*=\s*\"[^\"]+\"|action\s*:\s*'[^']+'" "$IN" \
    | sed -E "s/.*[=:'\"]+([[:alnum:]]+)[\"']?/\1/" \
    | sort -u > "$TMPMETHODS"

  # Output Methods-Tabble (Spalte 50)
  printf '| %-50s |\n' "Methods (for --action read / write)"
  printf '|%s|\n' "$(printf '%.0s-' {1..52})"
  while read -r m; do
    printf '| %-50s |\n' "$m"
  done < "$TMPMETHODS"
  echo


  # === 1) Possible parameters ===
  echo "Possible parameters:"
  echo "===================="

  # Extract bean JSON
  sed -n "s/.*dialog_setStorage_init.*'\({.*}\)'.*/\1/p" "$IN" > "$TMPBEAN"
  BEAN_JSON=$(cat "$TMPBEAN")

  # Prepare header and divider
  HEADER="| %-55s | %-45s | %-10s | %-70s |"
  DIV="|%s|%s|%s|%s|"
  H1=$(printf "$HEADER" "Parameter" "Description" "Value" "Allowed Values / Range")
  H2=$(printf "$DIV" \
       "$(printf '%.0s-' {1..57})" \
       "$(printf '%.0s-' {1..47})" \
       "$(printf '%.0s-' {1..12})" \
       "$(printf '%.0s-' {1..72})")

  # Parse parameter rows
  awk -v BEAN="$BEAN_JSON" '
    BEGIN { RS="</tr>" }
    /clickRad/ && /value="/ {
      b=$0; gsub(/\n/, " ", b)
      if (!match(b, /value="([^"]+)"/, k)) next
      key=k[1]
      if (key !~ /^storage_spf5000_/ && key !~ /^storage_shangke_/) next

      desc=""
      if (match(b, /<label[^>]*>.*?<input[^>]*>\s*([^<]+)/, d)) desc=d[1]
      else if (match(b, /<label[^>]*>\s*([^<]+)\s*<\/label>/, d2)) desc=d2[1]
      gsub(/^[ \t]+|[ \t]+$/, "", desc)

      val=""
      if (match(BEAN, "\"" key "\":\"?([^\"]+)\"?", v)) val=v[1]

      allowed=""
      while (match(b, /<option[^>]*value="([^"]+)">([^<]+)<\/option>/, o)) {
        allowed = allowed ? allowed "," o[1]"="o[2] : o[1]"="o[2]
        b = substr(b, RSTART+RLENGTH)
      }
      if (allowed=="" && match(b, /\(\s*([^)]+)\s*\)/, r)) allowed=r[1]
      if (allowed=="" && match(b, /data-min="([^"]+)"/, m) && match(b, /data-max="([^"]+)"/, M))
        allowed = m[1] "-" M[1]
      gsub(/^[ \t]+|[ \t]+$/, "", allowed)

      printf("| %-55s | %-45s | %-10s | %-70s |\n", key, desc, val, allowed)
    }
  ' "$IN" | sort -t '|' -k2,2 | uniq > "$TMPBODY"

  # Print parameters table
  printf '%s\n%s\n' "$H1" "$H2"
  cat "$TMPBODY"
  COUNT_P=$(wc -l < "$TMPBODY")
  echo "------------------------------------"
  echo "Total number of parameters: $COUNT_P"
  echo

  # === 2) Current values ===
  echo "Current values:"
  echo "==============="

  # Extract all JSON.parse('{…}') blocks
  grep "JSON.parse" "$IN" \
    | sed -n "s/.*JSON\.parse('\({.*}\)').*/\1/p" \
    > "$TMPBEANS_ALL"

  # Flatten each JSON into lines of key:value
  > "$TMPBEAN_BODY"
  while IFS= read -r js; do
    echo "$js" \
      | sed -e 's/[{}]//g' -e 's/,/\
/g' \
      >> "$TMPBEAN_BODY"
  done < "$TMPBEANS_ALL"

  # Format as 40 | 30
  awk -F: '
    {
      key=$1; val=$2
      gsub(/^[ \t"]+|[ \t"]+$/,"",key)
      gsub(/^[ \t"]+|[ \t"]+$/,"",val)
      printf("| %-40s | %-30s |\n", key, val)
    }
  ' "$TMPBEAN_BODY" \
    | sort \
    | uniq \
    > "$TMPVALUES"

  # Print current values table
  printf '| %-40s | %-30s |\n' "Parameter" "Value"
  printf '|%s|%s|\n' \
    "$(printf '%.0s-' {1..42})" \
    "$(printf '%.0s-' {1..32})"
  cat "$TMPVALUES"
  COUNT_V=$(wc -l < "$TMPVALUES")
  echo "------------------------------------"
  echo "Total number of values: $COUNT_V"
  echo

  # Cleanup parser temps
  rm -f "$TMPMETHODS $TMPBEAN" "$TMPBODY" "$TMPBEANS_ALL" "$TMPBEAN_BODY" "$TMPVALUES"
  ##############################################################################
  # End Parser v1.0.0
  ##############################################################################

  rm -f "$COOKIE_FILE"
  exit 0
fi

# --- READ single parameter ---
if [[ "$ACTION" == "read" ]]; then
  [[ -z "$TYPE" ]] && echo "Error: --type is required for read." && exit 1
  METH="${METHOD:-readStorageParam}"
  CMD_DATA="action=$METH&paramId=${TYPE}&serialNum=${SERIAL}&startAddr=-1&endAddr=-1"
  [[ $DEBUG -eq 1 ]] && echo "DEBUG: curl -s -b \"$COOKIE_FILE\" -X POST \"$SERVER/tcpSet.do\" -H \"Content-Type: application/x-www-form-urlencoded\" --data-raw \"$CMD_DATA\""
  RESPONSE=$(curl -s -b "$COOKIE_FILE" -X POST "$SERVER/tcpSet.do" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-raw "$CMD_DATA")
  VALUE_RESULT=$(echo "$RESPONSE" | grep -o '"msg":"[^"]*"' | cut -d':' -f2- | tr -d '"')
  if echo "$RESPONSE" | grep -q '"success":true' && [[ "$VALUE_RESULT" != "" ]]; then
    echo "$VALUE_RESULT"
    rm -f "$COOKIE_FILE"
    exit 0
  else
    echo "ERROR"
    rm -f "$COOKIE_FILE"
    exit 1
  fi
fi

# --- WRITE parameter ---
if [[ "$ACTION" == "write" ]]; then
  [[ -z "$TYPE" ]] && echo "Error: --type is required for write." && exit 1
  [[ -z "$VALUE" ]] && echo "Error: --value is required for write." && exit 1
  METH="${METHOD:-storageSPF5000Set}"
  CMD_DATA="action=$METH&serialNum=${SERIAL}&type=${TYPE}&param1=${VALUE}&param2=&param3=&param4="
  [[ $DEBUG -eq 1 ]] && echo "DEBUG: curl -s -b \"$COOKIE_FILE\" -X POST \"$SERVER/tcpSet.do\" -H \"Content-Type: application/x-www-form-urlencoded\" --data-raw \"$CMD_DATA\""
  RESPONSE=$(curl -s -b "$COOKIE_FILE" -X POST "$SERVER/tcpSet.do" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-raw "$CMD_DATA")
  if echo "$RESPONSE" | grep -q '"success":true'; then
    echo "OK"
    rm -f "$COOKIE_FILE"
    exit 0
  else
    echo "ERROR"
    rm -f "$COOKIE_FILE"
    exit 1
  fi
fi

echo "Unknown or unsupported action."
rm -f "$COOKIE_FILE"
exit 1
