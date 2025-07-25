# start-copilot-work

A CLI tool to create GitHub issues and assign them to Copilot. This is the TypeScript/Node.js port of the PowerShell `Start-CopilotWork` function from the PSCodeAgent module.

## Installation

### Global Installation (recommended)

```bash
npm install -g start-copilot-work
```

### Using npx (without installation)

```bash
npx start-copilot-work [options] [items...]
```

## Prerequisites

- **GitHub CLI (`gh`)**: This tool uses the GitHub CLI for all GitHub operations
  - Install: https://cli.github.com/
  - Authenticate: `gh auth login`
- **Node.js 16+**

## Usage

The tool auto-detects which arguments are repositories (owner/repo format) and which are work descriptions, so order doesn't matter for positional arguments.

### Basic Examples

```bash
# Create an issue in a repository
start-copilot-work "Add login feature" owner/repo

# Multiple work items and repos (creates all combinations)
start-copilot-work "Task 1" "Task 2" owner/repo1 owner/repo2

# Using explicit flags
start-copilot-work -w "Fix bug" -r owner/repo1 owner/repo2

# From markdown file with sections separated by '---'
start-copilot-work -f ./issues.md -r owner/repo

# Assign @copilot automatically
start-copilot-work "Add feature" owner/repo --assign-copilot

# Open created issues in browser
start-copilot-work "Fix bug" owner/repo --show

# Run from within a git repository (auto-detects repo)
start-copilot-work "Add feature"
```

### Advanced Examples

```bash
# Multiple issues with Copilot assignment and browser opening
start-copilot-work "Task 1" "Task 2" repo1 repo2 --assign-copilot --show

# Process markdown file across multiple repositories
start-copilot-work -f ./sprint-tasks.md -r team/frontend team/backend --assign-copilot
```

## Command Line Options

- `-r, --repo <repos...>`: GitHub repositories in owner/repo format
- `-w, --work <work...>`: Work descriptions/issue bodies  
- `-f, --file <path>`: Path to markdown file with issues separated by `---`
- `-a, --assign-copilot`: Assign @copilot to created issues
- `-s, --show`: Open created issues in browser
- `-h, --help`: Display help
- `-V, --version`: Display version

## Markdown File Format

When using the `-f` option, separate multiple issues with `---`:

```markdown
Implement a login system with OAuth support.

---

Add unit tests for the user authentication module.

---

Fix the responsive design issues on mobile devices.
```

## Features

- ✅ Auto-detection of repository vs work item arguments
- ✅ Multiple repositories and work items support  
- ✅ Markdown file processing with `---` separators
- ✅ Automatic @copilot assignment
- ✅ Browser opening for created issues
- ✅ Current repository detection when run from git directories
- ✅ Progress logging with timestamps
- ✅ Comprehensive error handling

## Repository Detection

If no repository is specified, the tool will attempt to detect the current repository from the working directory using `gh repo view`.

## Error Handling

The tool provides clear error messages for common issues:
- Missing GitHub CLI
- Invalid repository format
- Non-existent repositories  
- Authentication problems
- File not found errors

## Development

```bash
git clone <repository>
cd ts-copilot-work
npm install
npm run build
npm test
```

## License

MIT

## Related

This tool is the TypeScript port of the PowerShell `Start-CopilotWork` function from the [PSCodeAgent](https://github.com/dfinke/PSCodeAgent) module.