

SSH_KEY_FILE=${SSH_KEY_FILE:-~/.ssh/id_rsa}
SSH_KNOWN_HOST_FILE=/tmp/known_hosts

SECRET_OUTPUT_FILE=${SECRET_OUTPUT_FILE:-$(mktemp -t benoit)}

echo "SSH_KEY_FILE:        ${SSH_KEY_FILE}"
echo "SSH_KNOWN_HOST_FILE: ${SSH_KNOWN_HOST_FILE}"
echo "SECRET_OUTPUT_FILE:  ${SECRET_OUTPUT_FILE}"

ssh-keyscan github.com > ${SSH_KNOWN_HOST_FILE}

identity_b64=$(cat ${SSH_KEY_FILE} | base64)

known_hosts_key=$(cat ${SSH_KNOWN_HOST_FILE} | base64)
printf "git_writer:\n" >> ${SECRET_OUTPUT_FILE}
printf "  base64_encoded_identity: %s\n" "$identity_b64 ">> ${SECRET_OUTPUT_FILE}
printf "  base64_encoded_known_hosts: %s\n" "$known_hosts_key">> ${SECRET_OUTPUT_FILE}
cat ${SECRET_OUTPUT_FILE}
echo "${SECRET_OUTPUT_FILE}"
rm ${SSH_KNOWN_HOST_FILE}