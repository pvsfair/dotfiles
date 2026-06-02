Something to make your life easier while working with IDP + teleport:

I made a small script + bash snippet that gives you **Tab autocomplete** for teleport commands like `compass-teleport` and `tlp-p-app` (tsh proxy app).

It caches the list of available apps/databases locally and refreshes every 24h, so you don't have to wait for `tsh` to fetch the list every time you hit Tab.

**What you get:**
- `compass-teleport <Tab>` → autocomplete with available mongo databases
- `tlp-p-app <Tab>` → autocomplete with available teleport apps
- `tlp-mgmt-open <Tab>` → autocomplete with mgmt cluster apps, opens the app URL in the browser
- If you have `fzf` installed, you get a fuzzy search picker. If not, it falls back to standard bash prefix matching.

**Setup:**

1. Drop the attached `tsh-cache.sh` script somewhere in your path (e.g. `~/scripts/tsh-cache.sh`) and make it executable:
```bash
chmod +x ~/scripts/tsh-cache.sh
```

2. Add the snippet below to your `.bashrc` (or wherever you keep aliases/functions). Update `$DOTFILES_PATH/scripts/tsh-cache.sh` to match wherever you placed the script.

3. Source your `.bashrc` or open a new terminal.

**Snippet:**

```bash
function compass-teleport(){
  mongodb-compass mongodb://localhost:27017/%2A?directConnection=true&serverSelectionTimeoutMS=5000
  tsh proxy db --tunnel --port 27017 --db-user role/teleport-write $1 --db-name "*"
}

function tlp-p-app(){
  tsh proxy app $1 --port $2
}

function tlp-mgmt-open(){
  local addr=$($HOME/scripts/tsh-cache.sh mgmt --resolve "$1")
  xdg-open "http://$addr"
}

declare -A _tsh_complete_map=(
  [compass-teleport]=db
  [tlp-p-app]=apps
  [tlp-mgmt-open]=mgmt
)

_tsh_fzf_complete() {
  if [[ $COMP_CWORD -eq 1 ]]; then
    local resource="${_tsh_complete_map[${COMP_WORDS[0]}]}"
    local apps
    apps=$($HOME/scripts/tsh-cache.sh "$resource")

    if command -v fzf &>/dev/null; then
      local selected
      selected=$(echo "$apps" | fzf --prompt="${COMP_WORDS[0]}> " --query="${COMP_WORDS[COMP_CWORD]}")
      if [[ -n "$selected" ]]; then
        COMPREPLY=("$selected")
      fi
    else
      COMPREPLY=($(compgen -W "$apps" -- "${COMP_WORDS[COMP_CWORD]}"))
    fi
  fi
}

complete -F _tsh_fzf_complete compass-teleport
complete -F _tsh_fzf_complete tlp-p-app
complete -F _tsh_fzf_complete tlp-mgmt-open
```

**Tips:**
- First run may take a moment (tsh needs to fetch the list and might trigger a login).
- After that it's instant — results are cached at `~/.cache/tsh/`.
- To force a cache refresh: `tsh-cache.sh --force apps` or `tsh-cache.sh --force db`.
- To add autocomplete to other tsh commands, just add an entry to `_tsh_complete_map` and a `complete -F` line.
- `tlp-mgmt-open` uses `--resolve` to look up the app's public address from the cache and opens it in the browser.

**Dependencies:**
- `jq` (required) — command-line JSON processor, used to parse tsh output
- `fzf` (optional) — fuzzy finder for the interactive search picker

```bash
sudo apt install jq fzf
```
