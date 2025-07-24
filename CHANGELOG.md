# Changelog

All notable changes to the PSCodeAgent PowerShell module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v0.2.0

### Added
- **Array Support for Work and Repo Parameters**: The `Start-CopilotWork` function now accepts arrays for both `-Work` and `-Repo` parameters, enabling batch creation of issues across multiple repositories
  - Create multiple issues from multiple work items across multiple repositories in a single command
  - All combinations are processed (e.g., 2 work items × 3 repos = 6 issues)
  - Automatic parameter detection: function intelligently identifies which parameters are repositories (owner/repo format) vs work items
  - Backward compatibility: still works with single values as before

### Enhanced
- **Improved Parameter Handling**: Enhanced parameter parsing to handle arrays in any positional order
- **Documentation**: Updated README.md with comprehensive examples of array usage
- **Help Documentation**: Updated function help with new array examples and usage patterns

### Examples
```powershell
# Create issues for all combinations
Start-CopilotWork 'Add login feature', 'Fix user profile bug' owner/repo1, owner/repo2

# Mixed usage
Start-CopilotWork -Work 'Single task' -Repo repo1, repo2, repo3

# Auto-detection works with positional parameters
Start-CopilotWork 'do it', 'do it x' dfinke/agenttodo, dfinke/trystuff
```

### Added
- **Progress Reporting**: Added timestamped progress messages throughout `Start-CopilotWork` function execution
  - Progress messages now display with date and time in format: `[yyyy-MM-dd HH:mm:ss]`
  - Messages shown for key operations: repository validation, issue creation, and Copilot assignment
  - Progress indicators include:
    - Repository location and validation status
    - Issue creation confirmation with URLs
    - Copilot assignment status
    - Summary of completed operations

### Enhanced
- **User Experience**: Improved visibility into script execution progress with real-time status updates
- **Debugging**: Easier troubleshooting with timestamped operation logs

## v0.1.0] - Initial Release

### Added
- Initial release of PSCodeAgent module
- `Start-CopilotWork` function for creating GitHub issues assigned to Copilot
- Support for single issue creation with flexible parameter ordering
- Markdown file support for multiple issues separated by `---`
- GitHub CLI integration for authentication and operations
- `-AssignCopilot` switch for automatic Copilot assignment
- `-Show` switch for automatically opening created issues in browser
- `Find-AssignedPRs` function for finding pull requests assigned to Copilot

### Features
- Automatic repository detection from current directory when not specified
- Flexible parameter ordering (repo and work can be in any order)
- Support for both positional and named parameters
- Integration with GitHub CLI (`gh`) for seamless authentication
- Error handling and validation for repository existence
