#!/bin/sh
# echo a string, handling different types
safe_echo() {
    # $1 = value
    if [ -z "$1" ]; then
        printf 'null'
    else
        encoded_value="$(jq -cn --arg value "$1" '$value')"
        printf '%s' "$encoded_value"
    fi
}

#  handle boolean
bool() {
    # $1 = value
    # Accepts true/false, t/f, yes/no, y/n and 1/0, case-insensitively.
    # Returns non-zero (printing nothing) for any other value.
    case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
        true | t | yes | y | 1)
            printf 'true' ;;
        false | f | no | n | 0)
            printf 'false' ;;
        *)
            return 1 ;;
    esac
}

# handle array values
array() {
    # $1 = value
    # $2 = arraytype
    if [ -z "$1" ]; then
        printf '[]'
    else
        # A full JSON array (e.g. '[{"label":"a","url":"b"}]') is used as-is,
        # which allows arrays of objects.
        case "$(printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')" in
            \[*\])
                printf '%s' "$1"
                ;;
            *)
                case "$2" in
                    string)
                        encoded_value="$(jq -cn --arg value "$1" '$value | split(",")')"
                        printf '%s' "$encoded_value"
                        ;;
                    *)
                        printf '[%s]' "$1"
                        ;;
                esac
                ;;
        esac
    fi
}

# handle object values
object() {
    # $1 = value
    if [ -z "$1" ]; then
        printf 'null'
    else
        printf '%s' "$1"
    fi
}

STAC_PATH_PREFIX=$(printf '%s' "${SB_pathPrefix:-/}" | sed -e 's|^/*|/|' -e 's|/*$|/|')

# Allow only URL path-safe characters so values cannot break nginx/sed/envsubst.
if ! printf '%s' "$STAC_PATH_PREFIX" | grep -Eq '^[A-Za-z0-9/_.~-]+$'; then
    echo "Err: SB_pathPrefix contains unsupported characters: ${SB_pathPrefix}" >&2
    exit 1
fi

export SB_pathPrefix="$STAC_PATH_PREFIX"
export STAC_PATH_PREFIX

barePrefix=$(printf '%s' "$STAC_PATH_PREFIX" | sed 's|/*$||')
if [ -n "$barePrefix" ] && [ "$barePrefix" != "/" ]; then
    STAC_PREFIX_REDIRECT="location = ${barePrefix} { return 301 ${STAC_PATH_PREFIX}\$is_args\$args; }"
else
    STAC_PREFIX_REDIRECT=""
fi
export STAC_PREFIX_REDIRECT

# Single-quoted so the shell does not expand; envsubst expands these names.
# shellcheck disable=SC2016
envsubst '$STAC_PATH_PREFIX $STAC_PREFIX_REDIRECT' \
    < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Point <base> at the runtime path prefix (Vite builds with base "./").
if [ -f /usr/share/nginx/html/index.html ]; then
    sed -i "s|<base href=\"[^\"]*\" id=\"stac-browser-base\">|<base href=\"${STAC_PATH_PREFIX}\" id=\"stac-browser-base\">|" \
        /usr/share/nginx/html/index.html
fi

config_schema=$(cat /etc/nginx/conf.d/config.schema.json)
runtime_config_tmp=/usr/share/nginx/html/runtime-config.js.tmp
runtime_config=/usr/share/nginx/html/runtime-config.js

# Resolve a JSON Schema "type" keyword to a single type name. The keyword may be
# a string ("array") or an array of strings (["array", "null"]); take the first.
schema_type() {
    # $1 = jq path expression pointing at the "type" keyword
    printf '%s\n' "$config_schema" | jq -r "$1 | if type == \"array\" then .[0] else . end"
}

# Succeed if a JSON Schema "type" keyword is or includes "string".
schema_allows_string() {
    # $1 = jq path expression pointing at the "type" keyword
    printf '%s\n' "$config_schema" | jq -e "$1 | if type == \"array\" then index(\"string\") != null else . == \"string\" end" > /dev/null
}

# Iterate over environment variables with "SB_" prefix.
# The brace group is the last element of the pipeline, so it runs in a subshell
# and the pipeline's exit status is its exit status: an `exit 1` inside it only
# ends that subshell. Check the status explicitly so an invalid value never
# installs a partially written runtime-config.js.
if ! env -0 | tr '\0' '\n' | cut -f1 -d= | grep "^SB_" | {
    echo "window.STAC_BROWSER_CONFIG = {"
    while IFS='=' read -r name; do
        # Strip the prefix
        argname="${name#SB_}"
        # Read the variable's value
        value="$(printenv "$name")"

        # Get the argument type from the schema
        argtype="$(schema_type ".properties.\"$argname\".type")"
        arraytype="$(schema_type ".properties.\"$argname\".items.type")"

        # Encode key/value
        printf '  %s: ' "$argname"
        case "$argtype" in
            string)
                safe_echo "$value"
                ;;
            boolean)
                if bool "$value"; then
                    :
                elif schema_allows_string ".properties.\"$argname\".type"; then
                    # e.g. preferredAssets: ["boolean", "string"]
                    safe_echo "$value"
                else
                    printf 'Err: %s has unknown boolean value "%s" (expected true/false, yes/no, y/n, t/f or 1/0)\n' \
                        "$name" "$value" >&2
                    exit 1
                fi
                ;;
            integer | number | object)
                object "$value"
                ;;
            array)
                array "$value" "$arraytype"
                ;;
            *)
                safe_echo "$value"
                ;;
        esac
        echo ","
    done
    echo "}"
} > "$runtime_config_tmp"; then
    rm -f "$runtime_config_tmp"
    echo "Err: failed to generate $runtime_config from SB_* environment variables" >&2
    exit 1
fi
mv -f "$runtime_config_tmp" "$runtime_config"
