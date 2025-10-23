---
mode: agent
---
# Bash guidelines and best practices

- Start every script with a shebang and strict mode:
    - `#!/bin/bash`

- Include the following functions in every script for logging:
    ```bash
    function log_info() {
        echo "$(date +'%Y-%m-%d %H:%M:%S') [INFO] $*"
    }

    function log_error() {
        echo "$(date +'%Y-%m-%d %H:%M:%S') [ERROR] $*" >&2
    }

    function log_header() {
        echo "==================== $* ===================="
    }
    ```
- Use `set -euo pipefail` for better error handling.
- Use `IFS=$'\n\t'` to handle word splitting safely.
- Use log_info, log_error, and log_header for logging messages.
- Organize code into functions. Always use the `function` keyword at the beginning of function definitions for readability and consistency:
    - `function my_func() { ... }`
- Use a `main` function and call it at the end: `main "$@"`
- Keep functions short and single-responsibility. Prefer small, testable functions over monolithic scripts.
- Provide a `usage()`/`help()` function and validate inputs early.
- Quote expansions and use `--` for commands that accept options (e.g., `rm -- "$file"`).
- Use `readonly` for constants and `local` for function-scoped variables.
- Use `trap` for cleanup and to handle signals (SIGINT, EXIT).
- Check for required external commands early (`command -v <cmd> >/dev/null || ...`).
- Prefer `mktemp` for temporary files/dirs. Clean them up in `trap`.
- Return status codes (non-zero on error). Avoid using `exit` inside library-like functions; use `return`.
- Use arrays for lists of values rather than space-separated strings.
- Document functions with a short comment and examples if needed.
- Keep portability in mind: if portability is required, avoid Bash-only features or document the dependency on Bash.
- Use `shellcheck` to lint scripts and catch common issues. 

