#!/bin/bash
# Ralph Log Prettifier
# Formats ralph-log.json output in a Claude Code-like human-readable view
# Usage: tail -f ralph-log.json | ./prettify-ralph.sh
#        cat ralph-log.json | ./prettify-ralph.sh

# ANSI color codes
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'
BOLD='\033[1m'

# Track tool calls by ID for matching with results
declare -A TOOL_CALLS

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ "$bytes" -ge 1048576 ]; then
        printf "%.1fMB" "$(echo "scale=1; $bytes / 1048576" | bc)"
    elif [ "$bytes" -ge 1024 ]; then
        printf "%.1fKB" "$(echo "scale=1; $bytes / 1024" | bc)"
    else
        printf "%dB" "$bytes"
    fi
}

# Format milliseconds to human readable duration
format_duration() {
    local ms=$1
    local seconds=$((ms / 1000))
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [ $hours -gt 0 ]; then
        printf "%dh %dm %ds" $hours $minutes $secs
    elif [ $minutes -gt 0 ]; then
        printf "%dm %ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

# Truncate string with ellipsis
truncate() {
    local str="$1"
    local max_len="${2:-50}"
    if [ ${#str} -gt $max_len ]; then
        echo "${str:0:$max_len}..."
    else
        echo "$str"
    fi
}

# Print session header banner
print_session_banner() {
    local model="$1"
    local version="$2"
    local cwd="$3"

    echo ""
    printf "${CYAN}${BOLD}═══ RALPH SESSION ═══════════════════════════════════════════════════${RESET}\n"
    printf "${DIM}Model: ${RESET}%s ${DIM}| Version: ${RESET}%s\n" "$model" "$version"
    printf "${DIM}Working dir: ${RESET}%s\n" "$cwd"
    printf "${CYAN}══════════════════════════════════════════════════════════════════════${RESET}\n"
    echo ""
}

# Print completion banner
print_completion_banner() {
    local duration_ms="$1"
    local cost="$2"
    local turns="$3"

    local duration=$(format_duration "$duration_ms")

    echo ""
    printf "${GREEN}${BOLD}═══ SESSION COMPLETE ════════════════════════════════════════════════${RESET}\n"
    printf "Duration: %s | Turns: %s | Cost: \$%.2f\n" "$duration" "$turns" "$cost"
    printf "${GREEN}══════════════════════════════════════════════════════════════════════${RESET}\n"
    echo ""
}

# Get tool display info (what to show after tool name)
get_tool_display() {
    local name="$1"
    local input="$2"

    case "$name" in
        Bash)
            local cmd=$(echo "$input" | jq -r '.command // ""' 2>/dev/null)
            truncate "$cmd" 60
            ;;
        Read)
            local path=$(echo "$input" | jq -r '.file_path // ""' 2>/dev/null)
            basename "$path"
            ;;
        Write)
            local path=$(echo "$input" | jq -r '.file_path // ""' 2>/dev/null)
            basename "$path"
            ;;
        Edit)
            local path=$(echo "$input" | jq -r '.file_path // ""' 2>/dev/null)
            basename "$path"
            ;;
        TodoWrite)
            local count=$(echo "$input" | jq '.todos | length' 2>/dev/null)
            echo "$count items"
            ;;
        Grep)
            local pattern=$(echo "$input" | jq -r '.pattern // ""' 2>/dev/null)
            local path=$(echo "$input" | jq -r '.path // "."' 2>/dev/null)
            printf '"%s" in %s' "$(truncate "$pattern" 20)" "$(basename "$path")"
            ;;
        Glob)
            local pattern=$(echo "$input" | jq -r '.pattern // ""' 2>/dev/null)
            echo "$pattern"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Read JSON lines from stdin
while IFS= read -r line; do
    # Skip empty lines
    [ -z "$line" ] && continue

    # Get message type
    type=$(echo "$line" | jq -r '.type // empty' 2>/dev/null)
    [ -z "$type" ] && continue

    case "$type" in
        system)
            # Show session banner with model, version, cwd
            subtype=$(echo "$line" | jq -r '.subtype // empty')
            if [ "$subtype" = "init" ]; then
                model=$(echo "$line" | jq -r '.model // "unknown"')
                version=$(echo "$line" | jq -r '.claude_code_version // "unknown"')
                cwd=$(echo "$line" | jq -r '.cwd // "unknown"')
                print_session_banner "$model" "$version" "$cwd"
            fi
            ;;

        assistant)
            content_type=$(echo "$line" | jq -r '.message.content[0].type // empty')

            case "$content_type" in
                text)
                    # Print Claude's message
                    text=$(echo "$line" | jq -r '.message.content[0].text // ""')
                    if [ -n "$text" ]; then
                        printf "${GREEN}[CLAUDE]${RESET} %s\n" "$text"
                        echo ""
                    fi
                    ;;

                tool_use)
                    # Extract and store tool info
                    tool_id=$(echo "$line" | jq -r '.message.content[0].id // ""')
                    tool_name=$(echo "$line" | jq -r '.message.content[0].name // ""')
                    tool_input=$(echo "$line" | jq -c '.message.content[0].input // {}')

                    # Store for later matching with result
                    TOOL_CALLS["$tool_id"]="$tool_name"

                    # Get display text for the tool
                    display=$(get_tool_display "$tool_name" "$tool_input")

                    if [ -n "$display" ]; then
                        printf "${YELLOW}[TOOL]${RESET} ${CYAN}%s${RESET} ${DIM}→${RESET} %s\n" "$tool_name" "$display"
                    else
                        printf "${YELLOW}[TOOL]${RESET} ${CYAN}%s${RESET}\n" "$tool_name"
                    fi
                    ;;
            esac
            ;;

        user)
            # Handle tool results
            tool_use_id=$(echo "$line" | jq -r '.message.content[0].tool_use_id // empty')
            is_error=$(echo "$line" | jq -r '.message.content[0].is_error // false')
            content_len=$(echo "$line" | jq -r '.message.content[0].content | length // 0')

            # Get rich metadata if available (tool_use_result can be object or string)
            result_type=$(echo "$line" | jq -r '.tool_use_result.type // empty' 2>/dev/null)

            # Get tool name from our stored map
            tool_name="${TOOL_CALLS[$tool_use_id]:-unknown}"

            if [ "$is_error" = "true" ]; then
                # Error case - show truncated error message
                error_msg=$(echo "$line" | jq -r '.message.content[0].content // ""' | head -c 100)
                printf "  ${RED}✗${RESET} ${DIM}%s${RESET}\n" "$(truncate "$error_msg" 80)"
            else
                # Success case - format based on result type
                case "$result_type" in
                    text)
                        # File read
                        file_path=$(echo "$line" | jq -r '.tool_use_result.file.filePath // ""')
                        printf "  ${GREEN}✓${RESET} ${DIM}%s (%s)${RESET}\n" "$(basename "$file_path")" "$(format_bytes $content_len)"
                        ;;
                    create)
                        # File write
                        file_path=$(echo "$line" | jq -r '.tool_use_result.filePath // ""')
                        printf "  ${GREEN}✓${RESET} ${DIM}Created %s${RESET}\n" "$(basename "$file_path")"
                        ;;
                    update)
                        # File edit
                        file_path=$(echo "$line" | jq -r '.tool_use_result.filePath // ""')
                        printf "  ${GREEN}✓${RESET} ${DIM}Edited %s${RESET}\n" "$(basename "$file_path")"
                        ;;
                    *)
                        # Generic success (Bash, TodoWrite, etc.)
                        if [ "$content_len" -gt 0 ]; then
                            printf "  ${GREEN}✓${RESET} ${DIM}(%s)${RESET}\n" "$(format_bytes $content_len)"
                        else
                            printf "  ${GREEN}✓${RESET}\n"
                        fi
                        ;;
                esac
            fi
            ;;

        result)
            # Show final stats banner
            subtype=$(echo "$line" | jq -r '.subtype // empty')
            if [ "$subtype" = "success" ]; then
                duration_ms=$(echo "$line" | jq -r '.duration_ms // 0')
                cost=$(echo "$line" | jq -r '.total_cost_usd // 0')
                turns=$(echo "$line" | jq -r '.num_turns // 0')
                print_completion_banner "$duration_ms" "$cost" "$turns"
            fi
            ;;
    esac
done
