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

  log_status "Successfully loaded Java version '$(java -version | head -1)' from JAVA_HOME='$java_prefix'"
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

  local found_version
  local install_hint="install the correct JDK and run $ direnv reload"
  local java_vendors="${PROJECT_JAVA_VENDORS:-coretto liberica temurin openjdk azul}"

  # use JAVA_VERSIONS if set,
  if [[ -n "${JAVA_VERSIONS:-}" ]]; then
    export JAVA_VERSIONS="$JAVA_VERSIONS"

  # otherwise auto-detect `sdkman.io` java versions directory
  elif [[ -n "${SDKMAN_CANDIDATES_DIR:-}" ]]; then
    install_hint="run $ sdk install java ${JAVA_VERSION} && direnv reload"
    # check if it will work before exporting
    found_version="$(semver_search "$JAVA_VERSIONS" "$JAVA_VERSION_PREFIX" "$JAVA_VERSION")"
    if [[ -n "$found_version" ]]; then
      export JAVA_VERSION_PREFIX=""
      export JAVA_VERSIONS="${SDKMAN_CANDIDATES_DIR:-}/java"
    else
      unset JAVA_VERSIONS
    fi
  fi

  # otherwise, if on a Mac, check the Library (its where IntelliJ installs JDKs)
  if [[ -z "$found_version" && "$(uname)" = "Darwin" ]]; then
    export JAVA_VERSIONS="${HOME}/Library/Java/JavaVirtualMachines"
    for vendor in $java_vendors; do
      pkg_prefix="${vendor}-"
      found_version="$(semver_search "$JAVA_VERSIONS" "$pkg_prefix" "$JAVA_VERSION")"
      if [[ -n "$found_version" ]]; then
        export JAVA_VERSION_PREFIX="$pkg_prefix"
        break
      else
        unset JAVA_VERSIONS
      fi
    done
  fi

  # otherwise, check the linux default installation locations
  #  /usr/lib/jvm/java-17-oracle/bin/java
  if [[ -z "$found_version" && "$(uname)" = "Linux" ]]; then
    install_hint="run $ sdk install java ${JAVA_VERSION} && direnv reload"
    export JAVA_VERSIONS="/usr/lib/jvm/"
    pkg_prefix="java-"
    found_version="$(semver_search "$JAVA_VERSIONS" "$pkg_prefix" "$JAVA_VERSION")"
    if [[ -n "$found_version" ]]; then
      export JAVA_VERSION_PREFIX="$pkg_prefix"
    else
      unset JAVA_VERSIONS
    fi
  fi

  # use the built-in function to load java, but detect error to log an additional hint
  if ! use java "$JAVA_VERSION"; then
    log_status "HINT: ${install_hint}"
    return 1
  fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# public API

layout_project() {
  local project_env_file="${1:-TOOL_VERSIONS.env}"
  __set_tool_versions_from_envfile "$project_env_file"
  __use_node_from_env_vars_default_nvm
  __use_java_from_env_vars_default_sdkman

  # IMPORTANT: load the (optional) local .env files last, to make sure it cant interfer with the other config
  # (the .env file is only supposed to contain env vars for the application, not for tools and platforms).
  dotenv_if_exists .env
}