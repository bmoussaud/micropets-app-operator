

SSH_KEY_FILE=${SSH_KEY_FILE:-~/.ssh/id_rsa}
SSH_KNOWN_HOST_FILE=${SSH_KNOWN_HOST_FILE:-~/.ssh/known_hosts_github}
SECRET_OUTPUT_FILE=${SECRET_OUTPUT_FILE:-$(mktemp -t benoit)}
echo "SSH_KEY_FILE:        ${SSH_KEY_FILE}"
echo "SSH_KNOWN_HOST_FILE: ${SSH_KNOWN_HOST_FILE}"
echo "SECRET_OUTPUT_FILE:  ${SECRET_OUTPUT_FILE}"


ssh_key=$(cat ${SSH_KEY_FILE} | base64)
known_hosts_key=$(cat ${SSH_KNOWN_HOST_FILE} | base64)
printf "git_writer:\n" >> ${SECRET_OUTPUT_FILE}
printf "  base64_encoded_ssh_key: %s\n" "$ssh_key ">> ${SECRET_OUTPUT_FILE}
printf "  base64_encoded_known_hosts: %s\n" "$known_hosts_key">> ${SECRET_OUTPUT_FILE}
#cat ${SECRET_OUTPUT_FILE}
echo "${SECRET_OUTPUT_FILE}"