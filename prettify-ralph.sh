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

# Format token counts to human readable (41000 → "41K", 7253957 → "7.3M")
format_tokens() {
    local tokens=$1
    if [ "$tokens" -ge 1000000 ]; then
        printf "%.1fM" "$(echo "scale=1; $tokens / 1000000" | bc)"
    elif [ "$tokens" -ge 1000 ]; then
        printf "%.0fK" "$(echo "scale=0; $tokens / 1000" | bc)"
    else
        printf "%d" "$tokens"
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
    local output_tokens="$4"
    local cache_read="$5"
    local cache_written="$6"

    local duration=$(format_duration "$duration_ms")

    # Calculate cache hit rate
    local total_cache=$((cache_read + cache_written))
    local hit_rate=0
    if [ "$total_cache" -gt 0 ]; then
        hit_rate=$(echo "scale=1; $cache_read * 100 / $total_cache" | bc)
    fi

    echo ""
    printf "${GREEN}${BOLD}═══ SESSION COMPLETE ════════════════════════════════════════════════${RESET}\n"
    printf "Duration: %s | Turns: %s | Cost: \$%.2f\n" "$duration" "$turns" "$cost"
    printf "Tokens: %s out | Cache: %s read, %s written (%.1f%% hit rate)\n" \
        "$(format_tokens "$output_tokens")" \
        "$(format_tokens "$cache_read")" \
        "$(format_tokens "$cache_written")" \
        "$hit_rate"
    printf "${GREEN}══════════════════════════════════════════════════════════════════════${RESET}\n"
    echo ""
}

# Get tool display info (what to show after tool name)
get_tool_display() {
    local name="$1"
    local input="$2"

    case "$name" in
        Bash)
            local desc=$(echo "$input" | jq -r '.description // ""' 2>/dev/null)
            local cmd=$(echo "$input" | jq -r '.command // ""' 2>/dev/null)
            if [ -n "$desc" ]; then
                printf '"%s" %s' "$desc" "$cmd"
            else
                echo "$cmd"
            fi
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
                        num_lines=$(echo "$line" | jq -r '.tool_use_result.file.numLines // 0')
                        printf "  ${GREEN}✓${RESET} ${DIM}%s (%s lines, %s)${RESET}\n" "$(basename "$file_path")" "$num_lines" "$(format_bytes $content_len)"
                        ;;
                    create)
                        # File write
                        file_path=$(echo "$line" | jq -r '.tool_use_result.filePath // ""')
                        file_content=$(echo "$line" | jq -r '.tool_use_result.content // ""')
                        line_count=$(echo "$file_content" | wc -l)
                        printf "  ${GREEN}✓${RESET} ${DIM}Created %s (%s lines)${RESET}\n" "$(basename "$file_path")" "$line_count"
                        ;;
                    update)
                        # File edit - calculate +/- lines from structuredPatch
                        file_path=$(echo "$line" | jq -r '.tool_use_result.filePath // ""')
                        old_lines=$(echo "$line" | jq '[.tool_use_result.structuredPatch[]?.oldLines // 0] | add // 0')
                        new_lines=$(echo "$line" | jq '[.tool_use_result.structuredPatch[]?.newLines // 0] | add // 0')
                        printf "  ${GREEN}✓${RESET} ${DIM}Edited %s (+%s/-%s lines)${RESET}\n" "$(basename "$file_path")" "$new_lines" "$old_lines"
                        ;;
                    *)
                        # Generic success (Bash, TodoWrite, etc.)
                        # Check if this is a Bash result with stdout
                        stdout=$(echo "$line" | jq -r '.tool_use_result.stdout // empty' 2>/dev/null)
                        if [ -n "$stdout" ]; then
                            line_count=$(echo "$stdout" | wc -l)
                            byte_count=${#stdout}
                            printf "  ${GREEN}✓${RESET} ${DIM}(%s lines, %s)${RESET}\n" "$line_count" "$(format_bytes $byte_count)"
                        elif [ "$content_len" -gt 0 ]; then
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
                output_tokens=$(echo "$line" | jq -r '.usage.output_tokens // 0')
                cache_read=$(echo "$line" | jq -r '.usage.cache_read_input_tokens // 0')
                cache_written=$(echo "$line" | jq -r '.usage.cache_creation_input_tokens // 0')
                print_completion_banner "$duration_ms" "$cost" "$turns" "$output_tokens" "$cache_read" "$cache_written"
            fi
            ;;
    esac
done
