#!/usr/bin/env bash

# run in strict mode unless env var is set to toggle it off
if [[ -z "${PROJECTENV_NO_STRICT:-}" ]]; then
  strict_env
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# extend direnv-stdlib with a "use java" implementation based on the built-in "use node"

use_java() {
  local version=${1:-}
  local java_version_prefix=${JAVA_VERSION_PREFIX:-}
  local search_version
  local java_prefix

  if [[ -z ${JAVA_VERSIONS:-} || ! -d $JAVA_VERSIONS ]]; then
    log_error "You must specify a \$JAVA_VERSIONS environment variable and the directory specified must exist!"
    return 1
  fi

  if [[ -z $version ]]; then
    log_error "I do not know which Java version to load because one has not been specified!"
    return 1
  fi

  # Search for the highest version matching $version in the folder
  search_version="$(semver_search "$JAVA_VERSIONS" "${java_version_prefix}" "${version}")"
  java_prefix="${JAVA_VERSIONS}/${java_version_prefix}${search_version}"

  if [[ ! -d "$java_prefix" ]]; then
    log_error "Unable to find Java version ($version) in ($JAVA_VERSIONS)!"
    return 1
  fi

  if [[ ! -x "$java_prefix/bin/java" ]]; then
    log_error "Unable to load Java binary (java) for version ($version) in ($JAVA_VERSIONS)!"
    return 1
  fi

  load_prefix "$java_prefix"
  export JAVA_HOME="$java_prefix"

  log_status "Successfully loaded Java $(java --version), from JAVA_HOME='$java_prefix'"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# interal helpers

__set_tool_versions_from_envfile() {
  local tool_versions_env_file="${1:-}"
  if [[ -f "$tool_versions_env_file" ]]; then
    if [[ -f ".nvmrc" ]]; then
      log_error "WARN: both .nvmrc and TOOL_VERSIONS.env files are present, .nvmrc will be ignored!"
    fi
    watch_file "$tool_versions_env_file"
    dotenv "$tool_versions_env_file"
  fi
}

__use_node_from_env_vars_default_nvm() {
  if [[ -z "${NODE_VERSION:-}" ]]; then
    log_error "project error: no \$NODE_VERSION set!"
    return 1
  fi

  # use NODE_VERSIONS if set, otherwise auto-detect `nvm` node versions directory
  if [[ -n "${NODE_VERSIONS:-}" ]]; then
    export NODE_VERSIONS="$NODE_VERSIONS"
  elif [[ -n "$NVM_DIR" ]]; then
      export NODE_VERSION_PREFIX="v"
    export NODE_VERSIONS="${NVM_DIR}/versions/node"
  fi

  # use the built-in function to load node, but detect error to log an additional hint
  if ! use node "$NODE_VERSION"; then
    log_status "HINT: run $ nvm install ${NODE_VERSION} && direnv reload"
    return 1
  fi

  # put ./node_modules/.bin in PATH
  layout node
}

__use_java_from_env_vars_default_sdkman() {
  if [[ -z "${JAVA_VERSION:-}" ]]; then
    log_error "project error: no \$JAVA_VERSION set!"
    return 1
  fi

  # use JAVA_VERSIONS if set, otherwise auto-detect `sdkman.io` java versions directory
  if [[ -n "${JAVA_VERSIONS:-}" ]]; then
    export JAVA_VERSIONS="$JAVA_VERSIONS"
  elif [[ -n "$SDKMAN_CANDIDATES_DIR" ]]; then
    export JAVA_VERSION_PREFIX=""
    export JAVA_VERSIONS="${SDKMAN_CANDIDATES_DIR}/java"
  fi

  # use the built-in function to load java, but detect error to log an additional hint
  if ! use java "$JAVA_VERSION"; then
    log_status "HINT: run $ sdk install java ${JAVA_VERSION} && direnv reload"
    return 1
  fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# public API

layout_project() {
  local project_env_file="${1:-TOOL_VERSIONS.env}"
  __set_tool_versions_from_envfile "$project_env_file"

  if [[ -f "package.json" ]]; then
  __use_node_from_env_vars_default_nvm
  fi

  if [[ -f "pom.xml" ]]; then
  __use_java_from_env_vars_default_sdkman
  fi

  # IMPORTANT: load the (optional) local .env files last, to make sure it cant interfer with the other config
  # (the .env file is only supposed to contain env vars for the application, not for tools and platforms).
  dotenv_if_exists .env
}