#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
document=$repo_root/incus/opencode.yaml
user_data_source=$repo_root/incus/cloud-init/user-data.yaml
work_dir=$(mktemp -d)
credentials_sent=false

# cloud-init only reads user-data on first boot, so dropping it is safe however
# that boot went; leaving it would keep the credentials in `incus config show`.
scrub_credentials() {
    local deployed_user_data value
    deployed_user_data=$(incus config get "$name" cloud-init.user-data 2>/dev/null) || return 0
    for value in "$BW_CLIENTID" "$BW_CLIENTSECRET" "$BW_PASSWORD"; do
        if [[ $deployed_user_data == *"$value"* ]]; then
            incus config unset "$name" cloud-init.user-data
            printf 'Removed the credentials from the incus config of %s.\n' "$name" >&2
            return 0
        fi
    done
}

cleanup() {
    rm -rf -- "$work_dir"
    if [[ $credentials_sent == true ]]; then
        scrub_credentials
    fi
}
trap cleanup EXIT

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: create-opencode-instance.sh <name> [--container] [--with-secrets] [--dry-run]

Creates or updates the opencode instance <name> through incus-apply. A VM by
default; --container gives a throwaway test container (no nested incus, no
in-guest OOM protection).

--with-secrets reads BW_CLIENTID, BW_CLIENTSECRET and BW_PASSWORD from the
environment, hands them to first boot, then scrubs them from the instance
config. Without it the instance installs everything non-secret, and secrets
are enabled at first connection with `bw login && chezmoi apply`.

--dry-run prints the incus-apply diff and changes nothing. It refuses
--with-secrets, because that preview would print the credentials.

INSTANCE_SSH_PUBKEY authorises one public key for the alex user; it defaults
to ~/.ssh/itsalex.pub when that file exists.
EOF
}

name=''
vm=true
with_secrets=false
dry_run=false

for argument in "$@"; do
    case $argument in
        --container) vm=false ;;
        --with-secrets) with_secrets=true ;;
        --dry-run) dry_run=true ;;
        -h|--help) usage; exit 0 ;;        -*) die "unknown option: $argument" ;;
        *)
            [[ -z $name ]] || die "one instance name at a time"
            name=$argument
            ;;
    esac
done

[[ -n $name ]] || { usage >&2; exit 1; }
[[ $name =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || die "invalid instance name: $name"

command -v incus >/dev/null || die "incus not found"
command -v incus-apply >/dev/null || die "incus-apply not found"
incus info >/dev/null 2>&1 || die "incus is not reachable (incus.socket up, user in incus-admin, re-login after adding it)"

[[ -r $document ]] || die "missing $document"
[[ -r $user_data_source ]] || die "missing $user_data_source"
grep -q '^write_files:$' "$user_data_source" || die "$user_data_source needs a write_files list for the credential injection"
for token in __NAME__ __VM__ __USER_DATA__; do
    grep -q "$token" "$document" || die "$document lost its $token placeholder"
done

if $with_secrets; then
    $dry_run && die "--dry-run cannot be combined with --with-secrets: the preview would print the credentials"
    for variable in BW_CLIENTID BW_CLIENTSECRET BW_PASSWORD; do
        [[ -n ${!variable:-} ]] || die "$variable must be set in the environment with --with-secrets"
        [[ ${!variable} != *$'\n'* ]] || die "$variable must be a single line"
    done
fi

ssh_key=${INSTANCE_SSH_PUBKEY:-}
if [[ -z $ssh_key && -r $HOME/.ssh/itsalex.pub ]]; then
    ssh_key=$(<"$HOME/.ssh/itsalex.pub")
fi

profile_document() {
    awk 'NR == 1 && /^---$/ { next } /^---$/ { exit } { print }' "$document"
}

render_user_data() {
    local secrets=$1

    INSTANCE_SSH_KEY=$ssh_key awk '
        BEGIN { key = ENVIRON["INSTANCE_SSH_KEY"] }
        key != "" && /^[[:space:]]+ssh_authorized_keys: \[\]$/ {
            print "    ssh_authorized_keys:"
            print "      - " key
            next
        }
        { print }
    ' "$user_data_source" >"$work_dir/user-data.yaml"

    if [[ $secrets == false ]]; then
        return 0
    fi

    {
        printf '  - path: /run/bw-bootstrap.env\n'
        printf '    owner: root:root\n'
        printf "    permissions: '0600'\n"
        printf '    content: |\n'
        printf '      BW_CLIENTID=%s\n' "$BW_CLIENTID"
        printf '      BW_CLIENTSECRET=%s\n' "$BW_CLIENTSECRET"
        printf '      BW_PASSWORD=%s\n' "$BW_PASSWORD"
    } >"$work_dir/secrets-entry.yaml"
    sed -e "/^write_files:\$/r $work_dir/secrets-entry.yaml" "$work_dir/user-data.yaml" >"$work_dir/user-data.staged"
    mv -- "$work_dir/user-data.staged" "$work_dir/user-data.yaml"
}

render_instance() {
    awk -v name="$name" -v vm="$vm" -v user_data="$work_dir/user-data.yaml" '
        NR == 1 && /^---$/ { next }
        /^---$/ { in_instance = 1; next }
        !in_instance { next }
        /^name: __NAME__$/ { print "name: " name; next }
        /^vm: __VM__$/ { print "vm: " vm; next }
        vm == "false" && /^  security\.secureboot: / { next }
        /__USER_DATA__/ {
            print "  cloud-init.user-data: |"
            while ((getline line < user_data) > 0) {
                if (line == "") print ""
                else print "    " line
            }
            close(user_data)
            next
        }
        { print }
    ' "$document"
}

apply_document() {
    render_user_data "$1"
    local flags=(--yes)
    if $dry_run; then
        flags=(--diff)
    fi
    {
        profile_document
        printf -- '---\n'
        render_instance
    } | incus-apply "${flags[@]}" -
}

kind=$([[ $vm == true ]] && echo VM || echo container)
printf 'Applying %s %s...\n' "$kind" "$name"
if $with_secrets; then
    credentials_sent=true
fi
if ! apply_document "$with_secrets"; then
    die "incus-apply failed, inspect the guest with: incus exec $name -- cloud-init status --long"
fi

if $dry_run; then
    printf '\nDry run: nothing was applied.\n'
    exit 0
fi

if [[ $(incus list "$name" --format csv --columns s) != "RUNNING" ]]; then
    incus start "$name"
fi

printf 'Waiting for the instance to answer...\n'
agent_ready=false
for _ in {1..90}; do
    if incus exec "$name" -- true >/dev/null 2>&1; then
        agent_ready=true
        break
    fi
    sleep 2
done
[[ $agent_ready == true ]] || die "$name did not answer within 180s, check the guest with: incus console $name --show-log"

printf 'Waiting for cloud-init...\n'
cloud_init_status=''
for _ in {1..120}; do
    cloud_init_status=$(incus exec "$name" -- cloud-init status 2>/dev/null | sed -n 's/^status: //p') || true
    if [[ $cloud_init_status == "done" || $cloud_init_status == "error" ]]; then
        break
    fi
    sleep 5
done
[[ $cloud_init_status == "done" ]] || die "cloud-init is '$cloud_init_status' in $name, inspect it with: incus exec $name -- cloud-init status --long"

if $with_secrets; then
    # incus-apply treats cloud-init.user-data as create-only, so re-applying the
    # secretless document would leave the credentials in place.
    printf 'Scrubbing the credentials from the instance config...\n'
    scrub_credentials

    deployed_user_data=$(incus config get "$name" cloud-init.user-data)
    for value in "$BW_CLIENTID" "$BW_CLIENTSECRET" "$BW_PASSWORD"; do
        if [[ $deployed_user_data == *"$value"* ]]; then
            die "credentials are still present in the cloud-init user-data of $name"
        fi
    done
    if ! incus exec "$name" -- sh -c 'test ! -e /run/bw-bootstrap.env'; then
        die "/run/bw-bootstrap.env is still present in $name"
    fi
fi

printf '\n%s %s is up.\n\n' "$kind" "$name"
if $with_secrets; then
    printf 'Secrets were provisioned and locked at first boot. Verify with:\n'
    printf '  incus exec %s -- su - alex -c %s\n' "$name" "'mise exec -- gopass ls bitwarden'"
    printf '  incus exec %s -- su - alex -c %s\n' "$name" "'bw status'"
    printf '\nThe master password transited through host incus config and instance metadata\n'
    printf 'during first boot; root on either side could read it then.\n'
    printf '\nThen:\n'
    printf '  incus exec %s -- su - alex    # on the host; exit comes back here\n' "$name"
    printf '  sudo tailscale up             # prints the auth URL\n'
    printf '\nRe-running this script diffs the live state; nothing is recreated.\n'
else
    printf 'First connection, to enable the secret parts:\n'
    printf '  incus exec %s -- su - alex    # on the host; exit comes back here\n' "$name"
    # shellcheck disable=SC2016  # literal text for the user's shell, not ours
    printf '  export PATH=$HOME/.local/bin:$PATH\n'
    printf '  bw login && chezmoi apply     # age identity, store clone, mirror seed, SSH/GPG keys\n'
    printf '  sudo tailscale up             # prints the auth URL\n'
    printf '  bw logout                     # optional: fully unattended applies afterwards\n'
fi
if [[ $vm == false ]]; then
    printf '\nContainer mode: podman needs security.nesting=true, and there is no\n'
    printf 'in-guest OOM protection. Use it for quick checks only.\n'
fi
