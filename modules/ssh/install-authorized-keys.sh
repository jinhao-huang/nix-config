sourceFile=$1
sshDirectory=$2/.ssh

install -d -m 0700 -- "$sshDirectory"
temporaryFile=$(mktemp "$sshDirectory/.authorized_keys.XXXXXX")
trap 'rm -f -- "$temporaryFile"' EXIT

install -m 0600 -- "$sourceFile" "$temporaryFile"
mv -fT -- "$temporaryFile" "$sshDirectory/authorized_keys"
