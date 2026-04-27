# Code Reviewer

An automated production-readiness reviewer for code repositories, powered by a locally running [Ollama](https://ollama.com/) model (You can run it via a API but it is not recommended).

Point it at any repository and it will scan every text file, ask the LLM to assess each one for production readiness, and aggregate the findings into a final verdict with a prioritised task list.

---

## How It Works

1. **Shell script** (`GitHubAnaylizer.sh`) — uses the `gh` CLI to list your GitHub repositories, lets you pick one, and clones it locally. I am thinking about moving past this version.
2. **Analysis script** (`CodeAnaylisis.py`) — walks the cloned repository, sends each text file to an Ollama model for review, and writes two output files:
   - `PRODUCTION_TASKS.md` — deduplicated list of required tasks across all reviewed files.
   - `FINAL_REVIEW.md` — high-level production-readiness verdict with critical issues, architectural concerns, and a suggested execution order.

### Review Pipeline

```
Repository root
       │
       ▼
 review_project_tree()  ← LLM identifies modules and file groupings
       │
       ▼
 review_file() × N      ← per-file LLM review with JSON output + repair loop
       │
       ▼
 review_final()         ← final aggregated verdict
       │
       ▼
 PRODUCTION_TASKS.md  +  FINAL_REVIEW.md
```

Results are cached by SHA-256 hash of each file's content so unchanged files are skipped on subsequent runs.

---

## Requirements

- Python 3.10+
- [Ollama](https://ollama.com/) running locally (default: `http://localhost:11434`)
- `gh` CLI authenticated (`gh auth login`) — only needed for the shell script
- Python packages: `ollama`, `jsonschema`

Install Python dependencies:

```bash
pip install ollama jsonschema
```

---

## Usage

### 1. Clone a repo with the shell script (optional)

```bash
bash GitHubAnaylizer.sh
```

Follow the prompts to pick a repository. It will be cloned to the configured directory.

### 2. Run the analysis

```bash
python CodeAnaylisis.py [ROOT] [OPTIONS]
```

| Argument | Default | Description |
|---|---|---|
| `ROOT` | `.` | Path to the repository to review |
| `--model` | `gemma4:latest` | Ollama model to use |
| `--host` | `http://localhost:11434` | Ollama host URL |
| `--max-chars` | `12000` | Max characters per file sent to the model |
| `--limit` | `0` (no limit) | Max number of files to review |
| `--force` | off | Re-review all files, ignoring cache |

**Example:**

```bash
python CodeAnaylisis.py /path/to/my-repo --model gemma3:12b --limit 20
```

---

## Output Files

| File | Description |
|---|---|
| `PRODUCTION_TASKS.md` | All required tasks extracted from per-file reviews, deduplicated and tagged with source file |
| `FINAL_REVIEW.md` | Final verdict (Ready / Conditionally Ready / Not Ready), critical issues, architectural concerns, and a suggested fix order |
| `.repo_review_memory.md` | Review cache — do not edit manually |

---

## Project Structure

```
GitHubAnaylizer/
├── CodeAnaylisis.py          # Main analysis script
├── GitHubAnaylizer.sh        # Shell helper to clone repos from GitHub
├── Data/
│   └── FileTypes.json        # File extension → metadata mapping
├── Drafts/
│   └── Playground.py         # Scratch / experimentation
└── ExampleOutput/            # Sample output from a real run
```

---

## Notes

- Binary files are detected by null-byte scan and skipped automatically.
- Common noise directories (`.git`, `node_modules`, `venv`, `dist`, etc.) are excluded.
- If the model returns malformed JSON, the script attempts an automatic repair pass before falling back to an error record.
- The `--force` flag is useful when tuning prompts to ensure fresh results.

## Next Tasks.
- This system is still not well suited to reading large files and repositories. 
- Modual Detection
- Text and Document Support.
- An Object Oriented layout is required past this point as the complexity and responsibilities are getting hard to manage. 

### Long Term
- Spreadsheets and Databases - This is possible but how this should be handled is still up to debate, if you have a need for it please let me know. 
