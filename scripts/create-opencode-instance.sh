#!/usr/bin/env bash
set -euo pipefail

repo_root=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
document=$repo_root/incus/opencode.yaml
user_data_source=$repo_root/incus/cloud-init/user-data.yaml
upstream_repo=https://github.com/Its-Alex/dotfiles.git
repo_mountpoint=/mnt/dotfiles
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
Usage: create-opencode-instance.sh <name> [--container] [--with-secrets] [--repo-mount <dir>] [--dry-run]

Creates or updates the opencode instance <name> through incus-apply. A VM by
default; --container gives a throwaway test container (no nested incus, no
in-guest OOM protection).

--with-secrets reads BW_CLIENTID, BW_CLIENTSECRET and BW_PASSWORD from the
environment, hands them to first boot, then scrubs them from the instance
config. Without it the instance installs everything non-secret, and secrets
are enabled at first connection with `bw login && chezmoi apply`.

--repo-mount shares <dir> read-only at /mnt/dotfiles and bootstraps chezmoi from
it instead of the network, so CI builds the commit of the pull request rather
than the upstream branch. Git's owner check is relaxed for that path only,
because the mount keeps the host's owner inside the instance.

CHEZMOI_REPO overrides the repository chezmoi clones: the upstream URL by
default, or /mnt/dotfiles with --repo-mount.

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
repo_mount=''

while [[ $# -gt 0 ]]; do
    case $1 in
        --container) vm=false ;;
        --with-secrets) with_secrets=true ;;
        --dry-run) dry_run=true ;;
        --repo-mount)
            [[ $# -ge 2 ]] || die "--repo-mount needs a directory"
            repo_mount=$2
            shift
            ;;
        -h|--help) usage; exit 0 ;;
        -*) die "unknown option: $1" ;;
        *)
            [[ -z $name ]] || die "one instance name at a time"
            name=$1
            ;;
    esac
    shift
done

[[ -n $name ]] || { usage >&2; exit 1; }
[[ $name =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] || die "invalid instance name: $name"

if [[ -n $repo_mount ]]; then
    [[ -d $repo_mount ]] || die "--repo-mount needs an existing directory: $repo_mount"
    repo_mount=$(CDPATH='' cd -- "$repo_mount" && pwd)
    [[ $repo_mount != *'"'* ]] || die "--repo-mount cannot contain a double quote"
fi

repo_url=${CHEZMOI_REPO:-}
if [[ -z $repo_url ]]; then
    repo_url=$upstream_repo
    if [[ -n $repo_mount ]]; then
        repo_url=$repo_mountpoint
    fi
fi
# The URL goes into a single-quoted shell assignment in the user-data.
[[ $repo_url != *"'"* ]] || die "CHEZMOI_REPO cannot contain a single quote"

command -v incus >/dev/null || die "incus not found"
command -v incus-apply >/dev/null || die "incus-apply not found"
incus info >/dev/null 2>&1 || die "incus is not reachable (incus.socket up, user in incus-admin, re-login after adding it)"

[[ -r $document ]] || die "missing $document"
[[ -r $user_data_source ]] || die "missing $user_data_source"
grep -q '^write_files:$' "$user_data_source" || die "$user_data_source needs a write_files list for the credential injection"
grep -q '__CHEZMOI_REPO__' "$user_data_source" || die "$user_data_source lost its __CHEZMOI_REPO__ placeholder"
for token in __NAME__ __VM__ __USER_DATA__ __DEVICES__; do
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

insert_write_files_entry() {
    sed -e "/^write_files:\$/r $1" "$work_dir/user-data.yaml" >"$work_dir/user-data.staged"
    mv -- "$work_dir/user-data.staged" "$work_dir/user-data.yaml"
}

render_user_data() {
    local secrets=$1

    INSTANCE_SSH_KEY=$ssh_key CHEZMOI_REPO_VALUE=$repo_url awk '
        BEGIN {
            key = ENVIRON["INSTANCE_SSH_KEY"]
            repo = ENVIRON["CHEZMOI_REPO_VALUE"]
            quote = sprintf("%c", 39)
        }
        key != "" && /^[[:space:]]+ssh_authorized_keys: \[\]$/ {
            print "    ssh_authorized_keys:"
            print "      - " key
            next
        }
        /^[[:space:]]*chezmoi_repo=__CHEZMOI_REPO__$/ {
            prefix = $0
            sub(/chezmoi_repo=.*/, "", prefix)
            print prefix "chezmoi_repo=" quote repo quote
            next
        }
        { print }
    ' "$user_data_source" >"$work_dir/user-data.yaml"

    if [[ -n $repo_mount ]]; then
        # The mount keeps the host owner, which the instance does not know: git
        # sees a foreign owner and refuses to clone without safe.directory. Both
        # paths: a local clone checks the git directory, other commands the
        # worktree. The path is read-only and holds the commit under test.
        {
            printf '  - path: /etc/gitconfig\n'
            printf '    owner: root:root\n'
            printf "    permissions: '0644'\n"
            printf '    content: |\n'
            printf '      [safe]\n'
            printf '          directory = %s\n' "$repo_mountpoint"
            printf '          directory = %s/.git\n' "$repo_mountpoint"
        } >"$work_dir/repo-entry.yaml"
        insert_write_files_entry "$work_dir/repo-entry.yaml"
    fi

    if [[ $secrets == false ]]; then
        return 0
    fi

    {
        # %q: the bootstrap sources this file, and a client secret or password
        # containing $, spaces or quotes would otherwise be silently mangled.
        printf '  - path: /run/bw-bootstrap.env\n'
        printf '    owner: root:root\n'
        printf "    permissions: '0600'\n"
        printf '    content: |\n'
        printf '      BW_CLIENTID=%q\n' "$BW_CLIENTID"
        printf '      BW_CLIENTSECRET=%q\n' "$BW_CLIENTSECRET"
        # The password goes in its own file: --passwordfile removes the shell
        # from the path entirely, and it never needs to be an env var.
        printf '  - path: /run/bw-bootstrap.pw\n'
        printf '    owner: root:root\n'
        printf "    permissions: '0600'\n"
        printf '    content: |\n'
        printf '      %s\n' "$BW_PASSWORD"
    } >"$work_dir/secrets-entry.yaml"
    insert_write_files_entry "$work_dir/secrets-entry.yaml"
}

render_instance() {
    awk -v name="$name" -v vm="$vm" -v user_data="$work_dir/user-data.yaml" \
        -v repo_mount="$repo_mount" -v repo_mountpoint="$repo_mountpoint" '
        NR == 1 && /^---$/ { next }
        /^---$/ { in_instance = 1; next }
        !in_instance { next }
        /^name: __NAME__$/ { print "name: " name; next }
        /^vm: __VM__$/ { print "vm: " vm; next }
        vm == "false" && /^  security\.secureboot: / { next }
        /^devices: __DEVICES__$/ {
            if (repo_mount != "") {
                print "devices:"
                print "  repo:"
                print "    type: disk"
                print "    source: \"" repo_mount "\""
                print "    path: " repo_mountpoint
                print "    readonly: \"true\""
            }
            next
        }
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
printf 'Bootstrapping chezmoi from %s\n' "$repo_url"
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
    if ! incus exec "$name" -- sh -c 'test ! -e /run/bw-bootstrap.env -a ! -e /run/bw-bootstrap.pw'; then
        die "/run/bw-bootstrap.env or /run/bw-bootstrap.pw is still present in $name"
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
