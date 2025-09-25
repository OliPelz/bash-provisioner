#!/bin/bash
: '
v.0.0.1
'

function log_proxy_state {
    : '
    Log proxy state

    ShortDesc: A helper function to log the state of the current proxy envs used by all proxy wrapper functions.

    Description:
    This function provides a convenient way to log out the state of the current proxy settings (via env vars).
    These env vars are used by all my proxy wrapper functions like pcurl_wrapper, pwget_wrapper etc.
    So it might be interesting to run them right before

    Parameters:
    - no

    Environment Variables:
    - USE_PROXY: Set to "true" to enable proxy usage.
    - HTTPS_PROXY: The proxy URL to use if USE_PROXY is true.
    - CERT_BASE64_STRING: Base64-encoded SSL certificate string for verifying proxy connections (optional).

    Returns:
    - 0: Success, if proxy vars are set correct
    - 1: Failure  if proxy vars are not set correctly

    Example Usage:
    pcurl_wrapper "https://example.com" --verbose --header "User-Agent: CustomAgent"
    '
	if test_env_variable_defined USE_PROXY; then
		log_info "USE_PROXY is set, so will use a proxy"
		if ! test_env_variable_defined HTTPS_PROXY; then
			log_warn "HTTPS_PROXY is not set, so using a proxy will go wrong!"
			return 1
		fi
		if test_env_variable_defined CERT_BASE64_STRING; then
			log_info "CERT_BASE64_STRING is set, so we will use a custom cert for proxy usage!"
		fi
		return 0
	else
		log_info "We DONT use a proxy!"
		return 0
	fi
}


# --- helpers ------------------------------------------------------------------
_is_true() { [[ "${1:-}" =~ ^([Tt][Rr][Uu][Ee]|1)$ ]]; }
_make_tmp_ca() { mktemp /tmp/curl_wrapper_cert.XXXXXX; }

# --- function you can call after sourcing -------------------------------------
pcurl_wrapper() {
: '
v0.03
Curl Proxy Wrapper Script

ShortDesc:
  A thin wrapper around curl that passes all arguments through unchanged, with
  optional proxy and base64 CA certificate support via environment variables.

USAGE
  # As an executable:

  # As a function (source this file):
  source ./pcurl-wrapper
  pcurl_wrapper -I https://example.com

ENVIRONMENT
  USE_PROXY           If "true" or "1" (case-insensitive), enable proxy usage.
  HTTPS_PROXY         Proxy URL, used when USE_PROXY=true.
  CERT_BASE64_STRING  Base64-encoded CA cert; decoded to a temp file and passed as --cacert.

BEHAVIOR
  - All arguments are forwarded to curl unchanged.
  - When USE_PROXY=true, --proxy "$HTTPS_PROXY" is prepended.
  - When CERT_BASE64_STRING is set, a temp CA file is created and --cacert <file> is prepended.
  - The temp CA file is deleted after the curl run.
  - If you also pass your own --proxy/--cacert, curl’s *last* occurrence wins.

EXIT CODES
  Mirrors curl’s exit code.
'
  local -a cmd=( curl )
  local TEMP_CERT_FILE=""

  # Prepend proxy if requested
  if _is_true "${USE_PROXY:-}"; then
    [[ -n "${HTTPS_PROXY:-}" ]] && cmd+=( --proxy "${HTTPS_PROXY}" )
  fi

  # Prepend CA cert if provided
  if [[ -n "${CERT_BASE64_STRING:-}" ]]; then
    TEMP_CERT_FILE="$(_make_tmp_ca)"
    echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
    cmd+=( --cacert "${TEMP_CERT_FILE}" )
  fi

  # Forward all user args exactly as provided
  cmd+=( "$@" )

  # Run curl in a subshell so we don’t disturb caller’s -e state
  local rc
  (
    set +e
    "${cmd[@]}"
  )
  rc=$?

  # Cleanup
  [[ -n "${TEMP_CERT_FILE}" ]] && rm -f "${TEMP_CERT_FILE}"

  return "${rc}"
}

# additionally lets you define alternative pypi repository address and trusted hosts
# using other env variables: PYTHON_INDEX_URL, PYTHON_REPO_URL and PYTHON_TRUSTED_HOST


function ppip_wrapper {
  : '
    Pip Proxy Wrapper

    ShortDesc: A wrapper for the pip command that supports optional proxy and SSL certificate usage.

    Description:
    This function provides a way to execute pip commands with optional proxy settings, SSL certificate handling, 
    and custom Python package index configurations. It takes the pip command as the first parameter followed 
    by any additional parameters needed for pip. If proxy usage is enabled via the USE_PROXY environment variable, 
    it configures pip to use the specified proxy. If a base64-encoded SSL certificate is provided, it decodes 
    it to a temporary file for use with pip. The function also allows specifying a custom index URL, repository URL, 
    and trusted host.

    Parameters:
    - command: The pip command to be executed (e.g., install, uninstall).
    - additional_params: Additional parameters to pass to the pip command (optional).

    Environment Variables:
    - USE_PROXY: Set to "true" to enable proxy usage.
    - HTTPS_PROXY: The proxy URL to use if USE_PROXY is true.
    - CERT_BASE64_STRING: Base64-encoded SSL certificate string for verifying proxy connections (optional).
    - PYTHON_INDEX_URL: Custom Python package index URL (optional).
    - PYTHON_REPO_URL: Custom repository URL (optional).
    - PYTHON_TRUSTED_HOST: Trusted host for pip operations (optional).

    Returns:
    - 0: Success (pip command executed successfully)
    - 1: Failure (if the pip command fails)

    Example Usage:
    ppip_wrapper "install" "requests" --upgrade
    '
    local command="$1"
    shift
    local additional_params="$@"

    local pip_cmd="pip"
    local proxy_cmd=""
    local cert_cmd=""
    local index_url_cmd=""
    local repo_url_cmd=""
    local trusted_host_cmd=""

    if [ "${USE_PROXY,,}" == "true" ]; then
        if test_env_variable_defined CERT_BASE64_STRING; then
            # Create a temporary file for the cert
            TEMP_CERT_FILE=$(create_temp_file)
            echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
            cert_cmd="--cert ${TEMP_CERT_FILE}"
        fi
        proxy_cmd="--proxy ${HTTPS_PROXY}"
    fi

    if test_env_variable_defined PYTHON_INDEX_URL; then
        index_url_cmd="--index ${PYTHON_INDEX_URL}"
    fi

    if test_env_variable_defined PYTHON_REPO_URL; then
        repo_url_cmd="--index-url ${PYTHON_REPO_URL}"
    fi

    if test_env_variable_defined PYTHON_TRUSTED_HOST; then
        trusted_host_cmd="--trusted-host ${PYTHON_TRUSTED_HOST}"
    fi

    # Execute pip with the appropriate options
    ${pip_cmd} ${proxy_cmd} ${cert_cmd} ${index_url_cmd} ${repo_url_command} ${trusted_host_cmd} ${command} ${additional_params}
    rc=$?
    # Clean up temporary cert file if created
    if [ -n "${TEMP_CERT_FILE}" ]; then
        rm "${TEMP_CERT_FILE}"
    fi
    return $rc
}

function pwget_wrapper {
   : '
    Wget Proxy Wrapper

    ShortDesc: A wrapper for the wget command that supports optional proxy and SSL certificate usage.

    Description:
    This function provides a convenient way to execute wget commands with optional proxy settings 
    and SSL certificate handling. It takes a URL as the first parameter and any additional wget 
    parameters as subsequent arguments. If proxy usage is enabled via the USE_PROXY environment variable, 
    it configures wget to use the specified proxy. If a base64-encoded SSL certificate is provided, 
    it decodes it to a temporary file for use with wget.

    Parameters:
    - url: The URL to be retrieved with wget.
    - additional_params: Additional parameters to pass to the wget command (optional).

    Environment Variables:
    - USE_PROXY: Set to "true" to enable proxy usage.
    - HTTPS_PROXY: The proxy URL to use if USE_PROXY is true.
    - CERT_BASE64_STRING: Base64-encoded SSL certificate string for verifying proxy connections (optional).

    Returns:
    - 0: Success (wget command executed successfully)
    - 1: Failure (if the wget command fails)

    Example Usage:
    pwget_wrapper "https://example.com/file.zip" --output-document=myfile.zip
    '

    local url="$1"
    shift
    local additional_params="$@"

    local wget_cmd="wget"
    local proxy_cmd=""
    local cert_cmd=""

    if [ "${USE_PROXY,,}" == "true" ]; then
        if test_env_variable_defined CERT_BASE64_STRING; then
            # Create a temporary file for the cert
            TEMP_CERT_FILE=$(create_temp_file)
            echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
            cert_cmd="--ca-certificate=${TEMP_CERT_FILE}"
        fi
        proxy_cmd="--proxy=${HTTPS_PROXY}"
    fi

    # Execute wget with the appropriate options
    ${wget_cmd} ${proxy_cmd} ${cert_cmd} ${additional_params} "${url}"
    rc=$?
    # Clean up temporary cert file if created
    if [ -n "${TEMP_CERT_FILE}" ]; then
        rm "${TEMP_CERT_FILE}"
    fi
    return $rc
}

function pgit_wrapper {
    : '
    Git Proxy Wrapper

    ShortDesc: A wrapper for git commands that supports optional proxy, SSL certificate, and SSH private key usage.

    Description:
    This function wraps git commands to enable operations behind a proxy with SSL certificate handling and SSH
    private key support. It accepts the git command and arguments, checks for proxy settings, SSL certificates,
    and an SSH private key, and then configures git accordingly.

    Parameters:
    - git_command: The git command to be executed (e.g., clone, pull, push).
    - args: Additional arguments for the git command.

    Environment Variables:
    - USE_PROXY: Set to "true" to enable proxy usage.
    - HTTPS_PROXY: The proxy URL to use if USE_PROXY is true.
    - CERT_BASE64_STRING: Base64-encoded SSL certificate string for verifying proxy connections (optional).
    - SSH_PRIVATE_KEY_PATH: Path to the SSH private key for secure access (optional).

    Returns:
    - 0: Success (git command executed successfully)
    - 1: Failure (if the git command fails)

    Example Usage:
    pgit_wrapper "clone" "https://github.com/example/repo.git"
    pgit_wrapper "pull" "origin main"
    '

    local git_command="$1"
    shift
    local args="$@"

    local git_cmd="git"
    local proxy_cmd=""
    local cert_cmd=""
    local ssh_cmd=""

    # Set up proxy if needed
    if [ "${USE_PROXY,,}" == "true" ]; then
        if test_env_variable_defined CERT_BASE64_STRING; then
            # Create a temporary file for the cert
            TEMP_CERT_FILE=$(create_temp_file)
            echo "${CERT_BASE64_STRING}" | base64 -d > "${TEMP_CERT_FILE}"
            cert_cmd="http.sslCAInfo=${TEMP_CERT_FILE}"
        fi
        proxy_cmd="http.proxy=${HTTPS_PROXY}"
    fi

    # Set up SSH key if provided
    if test_env_variable_defined SSH_PRIVATE_KEY_PATH; then
        ssh_cmd="GIT_SSH_COMMAND='ssh -i ${SSH_PRIVATE_KEY_PATH}'"
    fi

    # Configure git with proxy and certificate settings
    ${git_cmd} config --global ${proxy_cmd}
    ${git_cmd} config --global ${cert_cmd}

    # Execute git command with SSH command if necessary
    if [ -n "${ssh_cmd}" ]; then
        eval "${ssh_cmd} ${git_cmd} ${git_command} ${args}"
    else
        ${git_cmd} ${git_command} ${args}
    fi
    rc=$?

    # Clean up temporary cert file if created
    if [ -n "${TEMP_CERT_FILE}" ]; then
        rm "${TEMP_CERT_FILE}"
    fi
    exit $rc
}
