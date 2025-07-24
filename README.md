<p a## Introduction

The **PSCodeAgent** PowerShell module makes it easy to use the new GitHub Copilot Code ## Notes
- The repository must already exist.
- For multiple issues, separate each issue in your markdown file with a line containing only `---`.
- Both `-Work` and `-Repo` parameters accept arrays. When both are arrays, issues are created for all combinations (e.g., 2 work items × 3 repos = 6 issues).
- The function automatically detects which parameters are repositories (owner/repo format) and which are work items, even when using positional parameters.
- The module uses the GitHub CLI (`gh`) for all operations—no REST API calls or manual token setup required.
- The module will output the URLs of the created issues. directly from the command line. With this module, you can create issues in any GitHub repository and assign them to the Copilot Code Agent, enabling Copilot to automatically pick up, work on, and deliver solutions for your requests.

The module supports creating multiple issues across multiple repositories in a single command using array parameters, making it efficient for batch operations and managing work across multiple projects.

**What is the GitHub Copilot Code Agent?**

The Copilot Code Agent is an AI-powered automation tool from GitHub that can be assigned to issues in your repositories. When assigned, Copilot will analyze the issue, implement the requested changes or features, and open a pull request with the solution—all automatically. This module streamlines the process of creating and assigning issues to Copilot, so you can leverage AI-driven development workflows from your terminal or scripts.enter">
  <img src="media/startCopilotWork.png" alt="startCopilotWork screenshot" width="300"/>
</p>

## Introduction

The **PSCodeAgent** PowerShell module makes it easy to use the new GitHub Copilot Code Agent directly from the command line. With this module, you can create issues in any GitHub repository and assign them to the Copilot Code Agent, enabling Copilot to automatically pick up, work on, and deliver solutions for your requests.

**What is the GitHub Copilot Code Agent?**

The Copilot Code Agent is an AI-powered automation tool from GitHub that can be assigned to issues in your repositories. When assigned, Copilot will analyze the issue, implement the requested changes or features, and open a pull request with the solutionΓÇöall automatically. This module streamlines the process of creating and assigning issues to Copilot, so you can leverage AI-driven development workflows from your terminal or scripts.

<br/>

## In Action
Use `Start-CopilotWork` to kick off the code agent. Click on the GitHub link returned to see the issue, pull request, and github action in progress.

![alt text](media/PSCodeAgent.gif)

<br/>

# How to Install and Use PSCodeAgent Module

To use the `Start-CopilotWork` PowerShell module for creating Copilot-assigned issues in a GitHub repository, follow these steps:

## Prerequisites

1. **Install PowerShell** (if not already installed).
2. **Install the GitHub CLI (`gh`)** and ensure it is available in your system PATH.  
   [Download and install GitHub CLI](https://cli.github.com/)

3. **Authenticate with the GitHub CLI (`gh`)**
  - Run `gh auth login` and follow the prompts to authenticate with your GitHub account.
  - No need to set a `GITHUB_TOKEN` environment variable; all authentication is handled by the `gh` CLI.

## Usage


1. Open a PowerShell terminal.
2. Install from the PowerShell Gallery:
   ```powershell
   Install-Module -Name PSCodeAgent
   Import-Module PSCodeAgent
   ```
3. Call the `Start-CopilotWork` function with the required parameters:



   - **Single Issue (Flexible Usage):**
     You can provide the repository and work string in any order, either positionally or with named parameters:
     ```powershell
     # Positional (either order):
     Start-CopilotWork 'Describe your Copilot request here.' owner/repo
     Start-CopilotWork owner/repo 'Describe your Copilot request here.'

     # Named parameters (order does not matter):
     Start-CopilotWork -Work 'Describe your Copilot request here.' -Repo owner/repo
     Start-CopilotWork -Repo owner/repo -Work 'Describe your Copilot request here.'
     ```
     With Copilot assignment:
     ```powershell
     Start-CopilotWork 'Describe your Copilot request here.' owner/repo -AssignCopilot
     Start-CopilotWork -Work 'Describe your Copilot request here.' -Repo owner/repo -AssignCopilot
     ```

   - **Multiple Issues and Repositories (Array Support):**
     Create issues for all combinations of work items and repositories using arrays:
     ```powershell
     # Multiple work items, multiple repositories (creates 4 issues):
     Start-CopilotWork 'Add login feature', 'Fix bug in user profile' owner/repo1, owner/repo2

     # Named parameters with arrays:
     Start-CopilotWork -Work 'Task 1', 'Task 2' -Repo owner/repo1, owner/repo2

     # Mix of single and multiple:
     Start-CopilotWork -Work 'Single task' -Repo repo1, repo2, repo3
     Start-CopilotWork -Work 'Task A', 'Task B' -Repo owner/single-repo
     ```
     With Copilot assignment:
     ```powershell
     Start-CopilotWork 'Task 1', 'Task 2' repo1, repo2 -AssignCopilot
     ```
   - **Multiple Issues from Markdown File:**
     ```powershell
     Start-CopilotWork -Repo owner/repo -Path .\issues.md
     ```
     With Copilot assignment:
     ```powershell
     Start-CopilotWork -Repo owner/repo -Path .\issues.md -AssignCopilot
     ```

   - **Open Issue(s) Automatically with -Show:**
     Use the `-Show` switch to automatically open the created issue(s) in your browser:
     ```powershell
     Start-CopilotWork -Repo owner/repo -Work "Describe the feature or bug here" -Show
     Start-CopilotWork -Repo owner/repo -Path .\issues.md -Show
     ```
   - **Assign @copilot:**
     Add `-AssignCopilot` to assign the issue(s) to @copilot (see examples above).



## Notes
- The repository must already exist.
- For multiple issues, separate each issue in your markdown file with a line containing only `---`.
- The module uses the GitHub CLI (`gh`) for all operationsΓÇöno REST API calls or manual token setup required.
- The module will output the URLs of the created issues.


## Example: Multi-Issue Markdown File

```markdown
Implement a PowerShell function that reads a CSV file and outputs the total sales by region.

---

Create a script that lists all open issues in a given GitHub repository and exports them to a JSON file.

---

Write a PowerShell function that takes a list of email addresses and validates their format.
```
