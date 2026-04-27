#!/bin/bash
set -e

# --- Configuration ---
AMOUNT_OF_REPOS_TO_SHOW_MAX=200
GIT_REPO_DIRECTORY=/media/thomas/HardStorage/Github/MyRepos
GIT_HUB_ACCOUNT_URL=https://github.com/tomishninja/
MODEL=gemma4:latest
OLLAMA_HOST=http://localhost:11434

# Directory this script lives in (so Python can resolve its own files)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"  

# --- Requirements notice ---
echo "Requirements:"
echo "  - Login to GitHub with: gh auth login"
echo "  - Ollama must be running at $OLLAMA_HOST"
echo ""

# --- List repositories ---
echo "Pulling repositories from GitHub..."
gh repo list --limit $AMOUNT_OF_REPOS_TO_SHOW_MAX --json name,url,visibility \
    --jq '.[] | "\(.name)  [\(.visibility)]"'

echo ""
echo "Please choose one of these repositories to review (repo name, not URL):"
read -r REPO

if [[ -z "$REPO" ]]; then
    echo "Error: no repository name entered." >&2
    exit 1
fi

CLONE_TARGET="$GIT_REPO_DIRECTORY/$REPO"

# --- Clone ---
if [[ -d "$CLONE_TARGET" ]]; then
    echo "Directory $CLONE_TARGET already exists — pulling latest changes instead."
    git -C "$CLONE_TARGET" pull
else
    echo "Cloning $REPO into $CLONE_TARGET ..."
    mkdir -p "$GIT_REPO_DIRECTORY"
    git clone "${GIT_HUB_ACCOUNT_URL}${REPO}" "$CLONE_TARGET"
fi

echo ""
echo "Repository ready at: $CLONE_TARGET"
echo ""

# --- Run analysis ---
echo "Starting production-readiness analysis with model: $MODEL"
cd "$SCRIPT_DIR"
python3 CodeAnaylisis.py "$CLONE_TARGET" --model "$MODEL" --host "$OLLAMA_HOST"

echo ""
echo "Analysis complete. Output files written to: $CLONE_TARGET"
echo "  - PRODUCTION_TASKS.md"
echo "  - FINAL_REVIEW.md"
