**POSIX shells (`zsh` / `bash`)**

```bash
# ~/.zshrc or ~/.bashrc
safe() { safehouse --add-dirs-ro=~/mywork "$@"; }

# Sandboxed — the default. Just type the command name.
claude()   { safe claude --dangerously-skip-permissions "$@"; }
codex()    { safe codex --dangerously-bypass-approvals-and-sandbox "$@"; }
amp()      { safe amp --dangerously-allow-all "$@"; }
gemini()   { NO_BROWSER=true safe gemini --yolo "$@"; }

# Unsandboxed — bypass the function with `command`
# command claude               — plain interactive session
```

**`fish`**

```fish
# ~/.config/fish/config.fish
function safe
    safehouse --add-dirs-ro="$HOME/mywork" $argv
end

# Sandboxed helpers without overriding the original binary names.
function sandbox-claude
    safe claude --dangerously-skip-permissions $argv
end

function sandbox-codex
    safe codex --dangerously-bypass-approvals-and-sandbox $argv
end

function sandbox-amp
    safe amp --dangerously-allow-all $argv
end

function sandbox-gemini
    set -lx NO_BROWSER true
    safe gemini --yolo $argv
end
```
