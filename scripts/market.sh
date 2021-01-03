#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

get_crypto() {
  local units=$(get_tmux_option "@tmux-market-units" "USD")
  local api_key=$(get_tmux_option "@tmux-market-api-key"\
    "b54bcf4d-1bca-4e8e-9a24-22ff2c3d462c")

  if [ "$units" != "USD" ] && [ "$units" != "CNY" ]; then
    units="USD"
  fi

  resp=`curl -H "X-CMC_PRO_API_KEY: $api_key"   \
    -H "Accept: application/json" -d "start=1&limit=2&convert=$units"       \
    -G "https://pro-api.coinmarketcap.com/v1/cryptocurrency/listings/latest"`
  vals=`echo $resp | jq ".data | .[0,1].quote.$units.price" | cut -d'.' -f1`

  # Ƀ: \u0243, Ξ: \u039e, ¥: \u00a5. vim insert mode press C-v u[code point].
  local declare -a symbols=("Ƀ" "Ξ")
  local i=0
  local prices="| "
  for val in $vals; do
    if [ "$units" == "USD" ]; then
       prices="$prices ${symbols[$i]} \$$val |"
    else
       prices="$prices ${symbols[$i]} ¥$val |"
    fi
    i=$(($i+1))
  done

  echo -n $prices
}

main() {
  local update_interval=$((60 * $(get_tmux_option "@tmux-market-interval" 15)))
  local current_time=$(date "+%s")
  local previous_update=$(get_tmux_option "@market-previous-update-time")
  local delta=$((current_time - previous_update))

  if [ -z "$previous_update" ] || [ $delta -ge $update_interval ]; then
    price=$(get_crypto)
    if [ "$?" -eq 0 ]; then
      $(set_tmux_option "@market-previous-update-time" "$current_time")
      $(set_tmux_option "@market-previous-value" "$price")
    fi
  fi

  echo -n $(get_tmux_option "@market-previous-value")
}

main
