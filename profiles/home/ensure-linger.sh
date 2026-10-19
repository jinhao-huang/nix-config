user_uid="$(id -u)"

read_linger() {
  loginctl --no-ask-password show-user "$user_uid" --property=Linger --value
}

if ! linger="$(read_linger)"; then
  echo "Cannot read linger for UID $user_uid; a working systemd-logind is required." >&2
  exit 1
fi

case "$linger" in
  yes) ;;
  no)
    echo "Enabling linger for UID $user_uid."
    if ! loginctl --no-ask-password enable-linger "$user_uid"; then
      echo "Cannot enable linger for UID $user_uid. Ask the administrator to enable it; activation aborted." >&2
      exit 1
    fi
    if ! linger="$(read_linger)" || [ "$linger" != yes ]; then
      echo "Cannot verify enabled linger for UID $user_uid; activation aborted." >&2
      exit 1
    fi
    ;;
  *)
    echo "Unexpected linger state '$linger' for UID $user_uid; activation aborted." >&2
    exit 1
    ;;
esac

if ! systemctl --user show-environment >/dev/null; then
  echo "Linger is enabled, but the systemd user manager is unavailable; activation aborted." >&2
  exit 1
fi
