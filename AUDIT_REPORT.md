# Audit Report: AzerothCore Rebuild & Management Script

## 1. Executive Summary
The "AzerothCore Rebuild & Management Script" is a well-organized, modular Bash project designed to simplify the management of AzerothCore WoW servers. It successfully abstracts complex Docker and TMUX operations into a user-friendly menu system. However, the audit identified several critical and high-priority issues related to logic robustness, argument parsing, and environment assumptions that could lead to failed operations or infinite loops.

**Overall Risk Level:** 🟡 **Medium**

---

## 2. Prioritized Findings

### 🔴 Critical Priority

#### C1: Infinite Recursion in Error Handling (`lib/core.sh`)
- **Issue:** The `handle_error` function calls `build_and_install_with_spinner` if a user chooses to retry. If that rebuild fails, it calls `handle_error` again, creating an infinite recursion of prompts.
- **Impact:** System hang/stack overflow if builds repeatedly fail; poor user experience.
- **Recommendation:** Implement a retry counter or move the retry logic into a loop within the build function rather than using recursion.

#### C2: Broken Argument Parsing in Command Wrapper (`lib/core.sh`)
- **Issue:** `run_command` uses `read -r -a cmd_parts <<< "$command_str"` to split commands. This does not respect quotes (e.g., `"Fixed bug"` becomes `["Fixed", "bug"]`).
- **Impact:** Commands like `git commit -m "message"` or modules with spaces in paths will fail.
- **Recommendation:** Pass commands as arrays or avoid the string-to-array conversion wrapper.

#### C3: Redundant Initialization (`ACrebuild.sh`)
- **Issue:** All library files are sourced at the top of the script AND again inside the `initialize` function.
- **Impact:** Variables may be reset unexpectedly; overhead; potential for function redefinition issues.
- **Recommendation:** Source libraries once, preferably inside `initialize`.

---

### 🟠 High Priority

#### H1: Path Inconsistency with Modern AzerothCore (`lib/variables.sh`)
- **Issue:** The script hardcodes `env/dist/bin` and `env/dist/etc`. Recent AC versions have moved these to `env/bin` and `env/etc`.
- **Impact:** Script fails to find executables or configs on modern AC installations.
- **Recommendation:** Implement dynamic path detection (check for both `dist/bin` and `bin`).

#### H2: Tilde (`~`) Expansion Failure (`lib/variables.sh` / `lib/wizard.sh`)
- **Issue:** User-entered paths containing `~` are stored as literal strings. Bash does not expand `~` inside quotes in variables like `[ -d "$VAR" ]`.
- **Impact:** Backup or installation directories starting with `~` will be reported as "not found".
- **Recommendation:** Sanitize user input by replacing `~` with `$HOME`.

#### H3: Unsafe Directory Selection in Restore (`lib/backup.sh`)
- **Issue:** `EXTRACTED_CONTENT_DIR=$(find ... -type d)` assumes only one directory is returned.
- **Impact:** If multiple directories exist (e.g., hidden folders), the variable contains multiple lines, causing `[ -d ]` tests to crash the script.
- **Recommendation:** Use `head -n 1` or a more specific glob pattern.

---

### 🟡 Medium Priority

#### M1: Missing MySQL Client Dependency Check (`lib/dependencies.sh`)
- **Issue:** Standard mode uses the `mysql` command for the console, but it isn't checked in `check_dependencies`.
- **Impact:** "Command not found" errors when a user tries to access the DB console.
- **Recommendation:** Add `mysql-client` to the dependency list.

#### M2: Persistent Docker Detection Prompt (`lib/ui.sh`)
- **Issue:** `check_and_prompt_for_docker_usage` triggers every time the main menu is shown if Docker is detected but not enabled.
- **Impact:** Annoying UX for users who intentionally want to run in non-Docker mode despite having a `docker-compose.yml`.
- **Recommendation:** Add a "Don't ask again" flag in the config.

---

### 🔵 Low Priority

#### L1: Hardcoded Port Checks (`lib/server.sh`)
- **Issue:** Script waits for ports 3724/8085 regardless of actual server config.
- **Impact:** False "failure" reports if users change their ports.
- **Recommendation:** Parse `.conf` files for actual port values.

---

## 3. UI/UX Recommendations
1. **Colorized Logs:** Integrate `ccze` or similar if available for the log viewer.
2. **Contextual Menus:** Hide "Cores for Build" when in Docker mode.
3. **Atomic Config Saving:** The `save_config` function overwrites everything; consider using `sed` more surgicaly to preserve manual comments.
4. **Graceful Exit:** `run_tmux_session` exits the script entirely; consider returning to the menu after TMUX is launched (though it's a background process).

---

## 4. Overall Assessment
**Quality Score:** 7/10
The script is highly functional and uses good modular practices. With the fixes for Critical and High issues, it will be extremely reliable.
