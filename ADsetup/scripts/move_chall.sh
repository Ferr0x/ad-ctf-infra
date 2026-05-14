#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

CONF_PATH="${1:-${ROOT_DIR}/.env.ctf}"
SRC_ROOT="${ROOT_DIR}/../challenges"
CHALLENGES_DST="${ROOT_DIR}/challenges"
CHECKERS_DST="${ROOT_DIR}/checkers"

if [[ ! -f "$CONF_PATH" ]]; then
  echo "Config file not found: ${CONF_PATH}" >&2
  exit 1
fi

if [[ ! -d "$SRC_ROOT" ]]; then
  echo "Challenges source directory not found: ${SRC_ROOT}" >&2
  exit 1
fi

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

declare -a categories=()
declare -A seen=()

while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="$(trim "$line")"
  [[ -z "$line" ]] && continue

  if [[ "$line" == *=* ]]; then
    key="$(trim "${line%%=*}")"
    key="$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')"
    line="$(trim "${line#*=}")"
    [[ "$key" != "CATEGORIES" ]] && continue
  fi

  line="${line//,/ }"
  for token in $line; do
    token="$(trim "$token")"
    [[ -z "$token" ]] && continue
    seen_key="$(printf '%s' "$token" | tr '[:upper:]' '[:lower:]')"
    if [[ -z "${seen[$seen_key]+x}" ]]; then
      categories+=("$token")
      seen["$seen_key"]=1
    fi
  done
done < "$CONF_PATH"

if [[ ${#categories[@]} -eq 0 ]]; then
  echo "No categories found in ${CONF_PATH}" >&2
  exit 1
fi

mkdir -p "$CHALLENGES_DST" "$CHECKERS_DST"

find "$CHALLENGES_DST" -mindepth 1 -maxdepth 1 \
  ! -name '.gitkeep' ! -name '.gitignore' ! -name 'start.sh' \
  -exec rm -rf {} +

find "$CHECKERS_DST" -mindepth 1 -maxdepth 1 \
  ! -name '.gitkeep' ! -name '.gitignore' \
  -exec rm -rf {} +

tmp_requirements="$(mktemp)"
trap 'rm -f "$tmp_requirements"' EXIT

for category in "${categories[@]}"; do
  src_category="${SRC_ROOT}/${category}"
  services_dir="${src_category}/services"
  checkers_dir="${src_category}/checkers"

  if [[ ! -d "$services_dir" || ! -d "$checkers_dir" ]]; then
    echo "Invalid category layout for '${category}' in ${src_category}" >&2
    echo "Expected both services/ and checkers/ directories." >&2
    exit 1
  fi

  while IFS= read -r service_path; do
    cp -a "$service_path" "${CHALLENGES_DST}/"
  done < <(find "$services_dir" -mindepth 1 -maxdepth 1 -type d | sort)

  while IFS= read -r checker_path; do
    cp -a "$checker_path" "${CHECKERS_DST}/"
  done < <(find "$checkers_dir" -mindepth 1 -maxdepth 1 -type d | sort)

  if [[ -f "${checkers_dir}/requirements.txt" ]]; then
    cat "${checkers_dir}/requirements.txt" >> "$tmp_requirements"
    printf '\n' >> "$tmp_requirements"
  fi
done

if [[ -s "$tmp_requirements" ]]; then
  awk 'NF && !seen[$0]++ { print }' "$tmp_requirements" > "${CHECKERS_DST}/requirements.txt"
else
  : > "${CHECKERS_DST}/requirements.txt"
fi

echo "Selected categories: ${categories[*]}"
echo "Challenges copied to: ${CHALLENGES_DST}"
echo "Checkers copied to: ${CHECKERS_DST}"
