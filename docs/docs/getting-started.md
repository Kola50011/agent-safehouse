# Getting Started

## Install

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/eugene1g/agent-safehouse/main/dist/safehouse.sh \
  -o ~/.local/bin/safehouse
chmod +x ~/.local/bin/safehouse
```

## Optional Local Overrides

For single files, prefer a direct path grant instead of an appended profile:

```bash
safehouse --add-dirs-ro=~/.gitignore -- claude --dangerously-skip-permissions
```

Create a local profile file only for recurring machine-specific exceptions:

```bash
mkdir -p ~/.config/agent-safehouse
cat > ~/.config/agent-safehouse/local-overrides.sb <<'EOF2'
;; Local user overrides
(allow file-read*
  (home-literal "/.lldbinit")
  (home-subpath "/Library/Application Support/CleanShot/media")
)
EOF2
```

## Shell Functions (Recommended)

POSIX shells (`zsh` / `bash`):

```bash
# ~/.bashrc or ~/.zshrc
SAFEHOUSE_APPEND_PROFILE="$HOME/.config/agent-safehouse/local-overrides.sb"

safe() { safehouse --add-dirs-ro=~/mywork --append-profile="$SAFEHOUSE_APPEND_PROFILE" "$@"; }
safeenv() { safe --env "$@"; }
safekeys() { safe --env-pass=OPENAI_API_KEY,ANTHROPIC_API_KEY "$@"; }
claude()   { safe claude --dangerously-skip-permissions "$@"; }
codex()    { safe codex --dangerously-bypass-approvals-and-sandbox "$@"; }
amp()      { safe amp --dangerously-allow-all "$@"; }
opencode() { OPENCODE_PERMISSION='{"*":"allow"}' safeenv opencode "$@"; }
gemini()   { NO_BROWSER=true safeenv gemini --yolo "$@"; }
goose()    { safe goose "$@"; }
kilo()     { safe kilo "$@"; }
pi()       { safe pi "$@"; }
```

`fish`:

```fish
# ~/.config/fish/config.fish
set -gx SAFEHOUSE_APPEND_PROFILE "$HOME/.config/agent-safehouse/local-overrides.sb"

function safe
    safehouse --add-dirs-ro="$HOME/mywork" --append-profile="$SAFEHOUSE_APPEND_PROFILE" $argv
end

function safeenv
    safe --env $argv
end

function safekeys
    safe --env-pass=OPENAI_API_KEY,ANTHROPIC_API_KEY $argv
end

function claude
    safe claude --dangerously-skip-permissions $argv
end

function codex
    safe codex --dangerously-bypass-approvals-and-sandbox $argv
end

function amp
    safe amp --dangerously-allow-all $argv
end

function opencode
    set -lx OPENCODE_PERMISSION '{"*":"allow"}'
    safeenv opencode $argv
end

function gemini
    set -lx NO_BROWSER true
    safeenv gemini --yolo $argv
end

function goose
    safe goose $argv
end

function kilo
    safe kilo $argv
end

function pi
    safe pi $argv
end
```

Run the real unsandboxed binary with `command <agent>` when needed.

## First Commands

```bash
# Generate policy for current repo and print policy path
safehouse

# Run an agent inside sandbox
cd ~/projects/my-app
safehouse claude --dangerously-skip-permissions
```

## One-File Claude Desktop Launcher (No CLI Install)

Safehouse ships self-contained launchers:

- `dist/Claude.app.sandboxed.command` (downloads latest apps policy at runtime)
- `dist/Claude.app.sandboxed-offline.command` (embedded policy; no runtime download)

```bash
# Online launcher
curl -fsSL https://raw.githubusercontent.com/eugene1g/agent-safehouse/main/dist/Claude.app.sandboxed.command \
  -o ~/Downloads/Claude.app.sandboxed.command
chmod +x ~/Downloads/Claude.app.sandboxed.command

# Offline launcher
curl -fsSL https://raw.githubusercontent.com/eugene1g/agent-safehouse/main/dist/Claude.app.sandboxed-offline.command \
  -o ~/Downloads/Claude.app.sandboxed-offline.command
chmod +x ~/Downloads/Claude.app.sandboxed-offline.command
```

Equivalent launch behavior:

```bash
safehouse --workdir="<folder-containing-Claude.app.sandboxed.command>" --enable=electron -- /Applications/Claude.app/Contents/MacOS/Claude --no-sandbox
```

If you use Claude Desktop "Allow bypass permissions mode", launching through the sandboxed command keeps tool execution constrained by the outer Safehouse policy.

Launcher policy controls:

- `SAFEHOUSE_CLAUDE_POLICY_URL`: override policy download source (online launcher)
- `SAFEHOUSE_CLAUDE_POLICY_SHA256`: pin expected policy checksum
