#!/bin/bash
# Path to your manually downloaded .deb packages
DEB_DIR="${DEB_DIR:-$HOME/deb-updates}"
INSTALLED_TAG="installed-"
CONFIRM=false
[[ "$1" == "--confirm" ]] && CONFIRM=true

# Interactive TUI only when attached to a terminal and not in headless mode.
INTERACTIVE=false
if [[ -t 0 && -t 1 && "$CONFIRM" == false ]]; then
    INTERACTIVE=true
fi

# ── Terminal helpers ──────────────────────────────────────────────────────────

COLS=80
LINE=""

update_termsize() {
    COLS=$(tput cols 2>/dev/null || true)
    [[ "$COLS" =~ ^[0-9]+$ ]] || COLS=80
    (( COLS < 20 )) && COLS=20
    LINE=$(printf '═%.0s' $(seq 1 "$COLS"))
}

cursor_on()  { printf '\e[?25h'; }
cursor_off() { printf '\e[?25l'; }
clear_screen() { printf '\e[H\e[2J'; }

cleanup() {
    cursor_on
}

header() {
    update_termsize
    printf '%s\e[K\n' "$LINE"
    printf '  %s\e[K\n' "$1"
    if [[ -n "${2:-}" ]]; then
        printf '  %s\e[K\n' "$2"
    fi
    printf '%s\e[K\n' "$LINE"
}

truncate_str() {
    local s="$1" max="$2"
    if (( ${#s} > max )); then
        printf '%s…' "${s:0:max-1}"
    else
        printf '%s' "$s"
    fi
}

# Read one key. Arrow keys arrive as ESC [ A/B and are normalized to
# up/down/enter. Plain letters are lowercased so shortcuts are case-insensitive.
read_key() {
    KEY=""
    IFS= read -rsn1 KEY || return 1
    if [[ "$KEY" == $'\x1b' ]]; then
        local rest=""
        IFS= read -rsn2 -t 0.05 rest || true
        KEY+="$rest"
    fi
    case "$KEY" in
        $'\x1b[A'|$'\x1bOA') KEY=up ;;
        $'\x1b[B'|$'\x1bOB') KEY=down ;;
        $'\x1b')            KEY=back ;;
        ''|$'\n'|$'\r'|' ') KEY=enter ;;
        *)
            KEY=${KEY,,}
            [[ "$KEY" == "k" ]] && KEY=up
            [[ "$KEY" == "j" ]] && KEY=down
            ;;
    esac
    return 0
}

render_menu() {
    local title="$1" subtitle="$2" sel="$3" arr_name="$4" footer="$5"
    local -n __menu_items="$arr_name"
    local i label max

    cursor_off
    # Move home and overwrite lines instead of clearing the whole screen:
    # ESC[2J blanks the screen and causes a visible flash on every keypress.
    printf '\e[H'
    header "$title" "$subtitle"
    printf '\e[K\n'

    max=$(( COLS - 8 ))
    (( max < 20 )) && max=20

    for i in "${!__menu_items[@]}"; do
        label=$(truncate_str "${__menu_items[$i]}" "$max")
        if (( i == sel )); then
            printf '  \e[7m ▶ %s \e[0m\e[K\n' "$label"
        else
            printf '    %s\e[K\n' "$label"
        fi
    done

    # Blank line before the footer: erase it explicitly, otherwise text from
    # the previous screen can remain visible on this row.
    printf '\e[K\n'
    printf '  \e[2m%s\e[0m\e[K\n' "$footer"
    # Erase anything left over from a previous, longer menu.
    printf '\e[J'
}

# confirm_screen TITLE [--yes] LINES...
# Without --yes, Enter defaults to no ([y/N]). With --yes, Enter defaults to
# yes ([Y/n]). The batch "install debs" confirmation intentionally stays
# default-no.
confirm_screen() {
    local title="$1"; shift
    local default_yes=false
    local line ans prompt

    if [[ "${1:-}" == "--yes" ]]; then
        default_yes=true
        shift
    fi

    cursor_on
    clear_screen
    header "$title"
    printf '\n'
    for line in "$@"; do
        printf '  %s\n' "$line"
    done

    if $default_yes; then
        prompt='[Y/n]'
    else
        prompt='[y/N]'
    fi
    printf '\n  Proceed? %s ' "$prompt"

    IFS= read -r ans || return 1
    if [[ -z "$ans" ]]; then
        $default_yes
        return
    fi
    [[ "$ans" == [yY] || "${ans,,}" == "yes" ]]
}

pause_key() {
    cursor_on
    printf '\n  Press any key to continue...'
    IFS= read -rsn1 _ || true
    cursor_off
}

show_message() {
    local title="$1"; shift
    local line

    cursor_on
    clear_screen
    header "$title"
    printf '\n'
    for line in "$@"; do
        printf '  %s\n' "$line"
    done
    pause_key
}

# ── Package discovery ─────────────────────────────────────────────────────────

# Fill DEBS with untagged packages first, then tagged ones, alphabetical
# within each group.
load_debs() {
    local -a untagged=() tagged=()
    local f base
    DEBS=()

    shopt -s nullglob
    for f in "$DEB_DIR"/*.deb; do
        base=${f##*/}
        if [[ "$base" == "$INSTALLED_TAG"* ]]; then
            tagged+=("$f")
        else
            untagged+=("$f")
        fi
    done
    shopt -u nullglob

    if (( ${#untagged[@]} )); then
        mapfile -d '' -t untagged < <(printf '%s\0' "${untagged[@]}" | sort -z)
    fi
    if (( ${#tagged[@]} )); then
        mapfile -d '' -t tagged < <(printf '%s\0' "${tagged[@]}" | sort -z)
    fi

    DEBS=("${untagged[@]}" "${tagged[@]}")
}

is_tagged() {
    [[ "${1##*/}" == "$INSTALLED_TAG"* ]]
}

# ── Actions ───────────────────────────────────────────────────────────────────

do_remove() {
    local path="$1" base
    base=${path##*/}

    if [[ ! -f "$path" ]]; then
        show_message "REMOVE DEB" "❌ File not found:" "$path"
        return 1
    fi

    confirm_screen "REMOVE DEB" --yes \
        "Delete '$base' permanently?" \
        "File: $path" || return 1

    if rm -- "$path"; then
        printf '\n  ✅ Removed: %s\n' "$base"
    else
        printf '\n  ❌ Failed to remove: %s\n' "$base"
    fi
    pause_key
    return 0
}

do_mark_installed() {
    local path="$1" base target
    base=${path##*/}
    target="$DEB_DIR/${INSTALLED_TAG}${base}"

    if [[ ! -f "$path" ]]; then
        show_message "MARK INSTALLED" "❌ File not found:" "$path"
        return 1
    fi
    if [[ -e "$target" ]]; then
        show_message "MARK INSTALLED" "❌ Target already exists:" "$target"
        return 1
    fi

    confirm_screen "MARK INSTALLED" --yes \
        "Rename this package?" \
        "$base" \
        "→ ${INSTALLED_TAG}${base}" || return 1

    if mv -- "$path" "$target"; then
        printf '\n  ✅ Marked as installed: %s\n' "$target"
    else
        printf '\n  ❌ Failed to rename: %s\n' "$base"
    fi
    pause_key
    return 0
}

do_mark_not_installed() {
    local path="$1" base newbase target
    base=${path##*/}
    newbase=${base#"$INSTALLED_TAG"}
    target="$DEB_DIR/$newbase"

    if [[ ! -f "$path" ]]; then
        show_message "MARK NOT INSTALLED" "❌ File not found:" "$path"
        return 1
    fi
    if [[ -z "$newbase" ]]; then
        show_message "MARK NOT INSTALLED" "❌ Cannot remove prefix, resulting name is empty."
        return 1
    fi
    if [[ -e "$target" ]]; then
        show_message "MARK NOT INSTALLED" "❌ Target already exists:" "$target"
        return 1
    fi

    confirm_screen "MARK NOT INSTALLED" --yes \
        "Rename this package?" \
        "$base" \
        "→ $newbase" || return 1

    if mv -- "$path" "$target"; then
        printf '\n  ✅ Marked as not installed: %s\n' "$target"
    else
        printf '\n  ❌ Failed to rename: %s\n' "$base"
    fi
    pause_key
    return 0
}

do_install_now() {
    local path="$1" base status dep_status target
    base=${path##*/}

    if [[ ! -f "$path" ]]; then
        show_message "INSTALL NOW" "❌ File not found:" "$path"
        return 1
    fi

    confirm_screen "INSTALL NOW" --yes \
        "Install '$base' and resolve dependencies?" \
        "sudo dpkg -i $path" \
        "sudo apt-get install -f -y" || return 1

    cursor_on
    clear_screen
    header "INSTALLING" "$base"
    printf '\n'

    sudo dpkg -i "$path"
    status=$?

    printf '\n'
    header "DEPENDENCIES"
    printf '\n'
    sudo apt-get install -f -y
    dep_status=$?

    printf '\n'
    if (( status == 0 )); then
        if ! is_tagged "$path"; then
            target="$DEB_DIR/${INSTALLED_TAG}${base}"
            if [[ -e "$target" ]]; then
                printf '  ⚠️  Installed, but target already exists: %s\n' "$target"
            elif mv -- "$path" "$target"; then
                printf '  ✅ Installed and marked: %s\n' "$base"
            else
                printf '  ⚠️  Installed, but rename failed: %s\n' "$base"
            fi
        else
            printf '  ✅ Installed: %s\n' "$base"
        fi
    else
        printf '  ❌ dpkg failed for: %s (exit %d)\n' "$base" "$status"
    fi
    (( dep_status != 0 )) && printf '  ⚠️  apt-get install -f exited with %d\n' "$dep_status"

    pause_key
    return 0
}

# Run one action against a package. The mark action resolves to install/uninstall
# depending on the current filename tag.
apply_action() {
    local path="$1" act="$2"

    case "$act" in
        r) do_remove "$path" ;;
        i) do_install_now "$path" ;;
        m)
            if is_tagged "$path"; then
                do_mark_not_installed "$path"
            else
                do_mark_installed "$path"
            fi
            ;;
        *) return 1 ;;
    esac
}

# ── Menus ─────────────────────────────────────────────────────────────────────

deb_actions() {
    local path="$1"
    local sel=0 act
    local -a actions=() keys=()

    while true; do
        local base=${path##*/}
        local tagged=false
        is_tagged "$path" && tagged=true

        actions=("[r] Remove deb" "[i] Install now")
        keys=(r i)
        if $tagged; then
            actions+=("[m] Mark not installed")
        else
            actions+=("[m] Mark installed")
        fi
        keys+=(m)
        actions+=("[b] Go back")
        keys+=(b)

        render_menu "DEB ACTIONS" "$base" "$sel" actions \
            "↑/↓/j/k move • Enter/Space select • r/i/m/b actions • Esc back"

        read_key || return

        act=""
        case "$KEY" in
            up)
                (( sel-- ))
                (( sel < 0 )) && sel=$(( ${#actions[@]} - 1 ))
                continue
                ;;
            down)
                (( sel++ ))
                (( sel >= ${#actions[@]} )) && sel=0
                continue
                ;;
            enter) act=${keys[$sel]} ;;
            r|i|m) act=$KEY ;;
            b|back) return ;;
            q) cleanup; exit 0 ;;
        esac

        case "$act" in
            r|i|m) apply_action "$path" "$act" && return ;;
        esac
        # Cancelled confirmation: redraw the same action menu.
    done
}

manage_menu() {
    local sel=0
    local -a labels=()
    local f base

    while true; do
        load_debs

        if (( ${#DEBS[@]} == 0 )); then
            show_message "MANAGE DEBS" \
                "ℹ️  No .deb files found in $DEB_DIR"
            return
        fi

        (( sel >= ${#DEBS[@]} )) && sel=$(( ${#DEBS[@]} - 1 ))

        labels=()
        for f in "${DEBS[@]}"; do
            base=${f##*/}
            if is_tagged "$f"; then
                labels+=("✅ $base")
            else
                labels+=("📦 $base")
            fi
        done

        render_menu "MANAGE DEBS" "$DEB_DIR" "$sel" labels \
            "↑/↓/j/k move • r/i/m actions • Enter menu • Esc/b back • q quit"

        read_key || return

        case "$KEY" in
            up)
                (( sel-- ))
                (( sel < 0 )) && sel=$(( ${#DEBS[@]} - 1 ))
                ;;
            down)
                (( sel++ ))
                (( sel >= ${#DEBS[@]} )) && sel=0
                ;;
            enter) deb_actions "${DEBS[$sel]}" ;;
            r|i|m) apply_action "${DEBS[$sel]}" "$KEY" ;;
            b|back) return ;;
            q) cleanup; exit 0 ;;
        esac
    done
}

main_menu() {
    local sel=0
    local -a items=("[m] Manage debs" "[i] Install debs" "[e] Exit")

    while true; do
        render_menu "DEB UPDATE" "$DEB_DIR" "$sel" items \
            "↑/↓/j/k move • Enter/Space select • m/i/e letters • Esc/q quit"

        read_key || break

        case "$KEY" in
            up)
                (( sel-- ))
                (( sel < 0 )) && sel=$(( ${#items[@]} - 1 ))
                ;;
            down)
                (( sel++ ))
                (( sel >= ${#items[@]} )) && sel=0
                ;;
            enter)
                case "$sel" in
                    0) manage_menu ;;
                    1) install_all_flow ;;
                    2) break ;;
                esac
                ;;
            m) manage_menu ;;
            i) install_all_flow ;;
            e|q|back) break ;;
        esac
    done
}

# ── Installation flow ─────────────────────────────────────────────────────────

install_all_flow() {
    local f base status target ans
    local -a pending=() names=()

    load_debs
    for f in "${DEBS[@]}"; do
        is_tagged "$f" || pending+=("$f")
    done

    if (( ${#pending[@]} == 0 )); then
        if $INTERACTIVE; then
            show_message "INSTALL DEBS" \
                "ℹ️  No new .deb packages found in $DEB_DIR"
        else
            update_termsize
            printf '\n%s\n  ℹ️  No new .deb packages found in %s\n%s\n\n' \
                "$LINE" "$DEB_DIR" "$LINE"
        fi
        return
    fi

    if $INTERACTIVE; then
        names=()
        for f in "${pending[@]}"; do
            names+=("📦 ${f##*/}")
        done
        confirm_screen "INSTALL DEBS" \
            "Install ${#pending[@]} package(s)?" \
            "${names[@]}" || return
        clear_screen
        header "INSTALL DEBS" "$DEB_DIR"
        printf '\n'
    fi

    for f in "${pending[@]}"; do
        base=${f##*/}

        if ! $INTERACTIVE && $CONFIRM; then
            read -p "Install $base? [y/N] " ans
            [[ "$ans" != [yY] ]] && continue
        fi

        update_termsize
        printf '\n%s\n  📦 Installing: %s\n%s\n' "$LINE" "$base" "$LINE"

        sudo dpkg -i "$f"
        status=$?

        if (( status == 0 )); then
            if ! is_tagged "$f"; then
                target="$DEB_DIR/${INSTALLED_TAG}${base}"
                if [[ -e "$target" ]]; then
                    printf '  ⚠️  Installed, but target already exists: %s\n' "$target"
                elif mv -- "$f" "$target"; then
                    printf '  ✅ %s installed successfully\n' "$base"
                else
                    printf '  ⚠️  Installed, but rename failed: %s\n' "$base"
                fi
            else
                printf '  ✅ %s installed successfully\n' "$base"
            fi
        else
            printf '  ❌ dpkg failed for: %s (exit %d)\n' "$base" "$status"
        fi
    done

    update_termsize
    printf '\n%s\n  🔧 Fixing missing dependencies...\n%s\n' "$LINE" "$LINE"
    sudo apt-get install -f -y
    if (( $? == 0 )); then
        printf '%s\n  ✅ Dependencies resolved\n%s\n\n' "$LINE" "$LINE"
    else
        printf '%s\n  ⚠️  apt-get install -f failed\n%s\n\n' "$LINE" "$LINE"
    fi

    $INTERACTIVE && pause_key
    return 0
}

# ── Entry point ───────────────────────────────────────────────────────────────

update_termsize

if $INTERACTIVE; then
    trap cleanup EXIT
    trap 'exit 130' INT TERM
    main_menu
    cleanup
else
    # Headless behavior: install every untagged package, prompting per file
    # when --confirm was passed.
    install_all_flow
fi
