#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
[ -z "$cwd" ] && cwd=$(pwd)

# --- Git branch (skip locks, suppress errors) ---
git_branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
           || git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && git_branch="($branch)"
fi

# --- Model ---
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# --- Context usage % ---
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  context_str="ctx ${used_int}%"
else
  context_str="ctx --"
fi

# --- Current call token breakdown: input + cache_read + cache_creation ---
in_tok=$(echo "$input"    | jq -r '.context_window.current_usage.input_tokens               // empty')
cache_r=$(echo "$input"   | jq -r '.context_window.current_usage.cache_read_input_tokens     // empty')
cache_c=$(echo "$input"   | jq -r '.context_window.current_usage.cache_creation_input_tokens // empty')
if [ -n "$in_tok" ]; then
  in_tok_fmt=$(printf "%dk"   "$(( ${in_tok:-0}   / 1000 ))")
  cache_r_fmt=$(printf "%dk"  "$(( ${cache_r:-0}  / 1000 ))")
  cache_c_fmt=$(printf "%dk"  "$(( ${cache_c:-0}  / 1000 ))")
  incache_str="in/cache ${in_tok_fmt}/${cache_r_fmt}+${cache_c_fmt}"
else
  incache_str="in/cache --"
fi

# --- Cumulative session totals ---
total_in=$(echo "$input"  | jq -r '.context_window.total_input_tokens  // empty')
total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // empty')
if [ -n "$total_in" ]; then
  total_in_fmt=$(printf  "%dk" "$(( total_in  / 1000 ))")
  total_out_fmt=$(printf "%dk" "$(( total_out / 1000 ))")
  totals_str="∑in ${total_in_fmt}  ∑out ${total_out_fmt}"
else
  totals_str="∑in --  ∑out --"
fi

# --- Render ---
# Format: (branch)  |  Model Name  |  ctx 42%  |  in/cache 12k/8k+2k  |  ∑in 45k  ∑out 6k
parts=()
[ -n "$git_branch" ] && parts+=("$git_branch")
parts+=("$model")
parts+=("$context_str")
parts+=("$incache_str")
parts+=("$totals_str")

output=""
for part in "${parts[@]}"; do
  [ -n "$output" ] && output="${output}  |  "
  output="${output}${part}"
done

printf "\033[2m%s\033[0m" "$output"
