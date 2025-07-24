# Helper: Write progress message with timestamp
function Write-ProgressMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor Green
}

# Helper: Assign @copilot to a GitHub issue using gh CLI
function Set-CopilotIssueAssignee {
    param(
        [Parameter(Mandatory)]
        [string]$Repo,
        [Parameter(Mandatory)]
        [string]$IssueNumber
    )
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "The GitHub CLI 'gh' is not installed or not in PATH. Please install it to assign @copilot."
    }
    Write-ProgressMessage "Assigning @copilot to issue #$IssueNumber in $Repo"
    gh issue edit $IssueNumber --repo $Repo --add-assignee "@copilot" | Out-Null
}
# Helper: Check if a GitHub repo exists
function Test-RepoExists {
    param(
        [Parameter(Mandatory)]
        [string]$Name  # owner/repo
    )
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "The GitHub CLI 'gh' is not installed or not in PATH. Please install it."
    }
    Write-ProgressMessage "Checking if repository $Name exists"
    gh repo view $Name 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-ProgressMessage "Repository $Name located successfully"
        return $true
    }
    else {
        return $false
    }
}

# Helper: Create a new GitHub issue
function New-Issue {
    param(
        [Parameter(Mandatory)]
        [string]$RepoName,  # owner/repo
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [string]$Body
    )
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "The GitHub CLI 'gh' is not installed or not in PATH. Please install it."
    }
    Write-ProgressMessage "Creating issue in $RepoName with title: '$Title'"
    $output = gh issue create --repo $RepoName --title $Title --body $Body 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $output) {
        throw "Failed to create issue using gh CLI. Output: $output"
    }
    # Try to extract the URL from the output (gh usually prints the URL on the last line)
    $url = $output | Select-String -Pattern 'https://github.com/.*/issues/\d+' -AllMatches | ForEach-Object { $_.Matches.Value } | Select-Object -Last 1
    if ($url) {
        Write-ProgressMessage "Issue created successfully: $url"
        return $url
    }
    else {
        throw "Issue created but URL not found in output. Raw output: $output"
    }
}

function Start-CopilotWork {
    <#
    .SYNOPSIS
        Creates Copilot-assigned issues in specified GitHub repos.
    .DESCRIPTION
        Checks if the repo(s) exist, creates one or more issues with the given prompt(s), assigns @copilot, and outputs the issue URLs.
        If -Path is provided, reads a markdown file and creates an issue for each section separated by '---'.
        Both -Repo and -Work can accept arrays to create issues for all combinations.
    .PARAMETER Repo
        The GitHub repository or repositories in the format owner/repo. Can be a single repo or an array of repos.
    .PARAMETER Work
        The issue body/prompt(s) for Copilot. Can be a single string or an array of strings.
    .PARAMETER Path
        Path to a markdown file containing one or more issues separated by '---'.
    .EXAMPLE
        Start-CopilotWork -Repo dfinke/trystuff -Work 'need a greet fn in Rust'
    .EXAMPLE
        Start-CopilotWork 'do it', 'do it x' dfinke/agenttodo, dfinke/trystuff
    .EXAMPLE
        Start-CopilotWork -Repo dfinke/trystuff -Path .\issues.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string[]]$Repo,
        [Parameter(Position = 1)]
        [string[]]$Work,
        [Parameter()]
        [string]$Path,
        [Parameter()]
        [switch]$AssignCopilot,
        [Parameter()]
        [switch]$Show
    )

    function Test-RepoFormat($str) {
        return $str -match '^[^/]+/[^/]+$'
    }

    # Normalize input to arrays
    $Repo = @($Repo) | Where-Object { $_ }
    $Work = @($Work) | Where-Object { $_ }

    # Auto-detect and swap if needed based on repo format
    if ($Repo -and $Work) {
        $repoLookingItems = @($Repo) + @($Work) | Where-Object { Test-RepoFormat $_ }
        $workLookingItems = @($Repo) + @($Work) | Where-Object { -not (Test-RepoFormat $_) }
        
        if ($repoLookingItems.Count -gt 0 -and $workLookingItems.Count -gt 0) {
            # We have both repo-formatted and non-repo-formatted items, so reassign
            $Repo = $repoLookingItems
            $Work = $workLookingItems
        }
    }

    # If neither Repo nor Work is provided, error
    if (-not $Repo -and -not $Work -and -not $Path) {
        throw "You must provide either -Work, -Repo, or -Path."
    }

    # If Repo is empty, try to get it from the current directory using gh CLI
    if (-not $Repo -or $Repo.Count -eq 0) {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Host "The GitHub CLI 'gh' is not installed or not in PATH. Please install it." -ForegroundColor Yellow
            return
        }
        Write-ProgressMessage "No repository specified, attempting to detect from current directory"
        $repoInfo = gh repo view --json 'owner,name' 2>$null | ConvertFrom-Json
        if (-not $repoInfo) {
            Write-Host "Not in a GitHub repository directory. Please specify -Repo (owner/repo) or run in a git repo directory." -ForegroundColor Yellow
            return
        }
        $Repo = @("$($repoInfo.owner.login)/$($repoInfo.name)")
        Write-ProgressMessage "Repository detected: $($Repo[0])"
    }

    # Validate all repos
    Write-ProgressMessage "Validating $($Repo.Count) repository(ies)"
    foreach ($r in $Repo) {
        if (-not (Test-RepoFormat $r)) {
            throw "Repo '$r' is not in the format owner/repo."
        }
        if (-not (Test-RepoExists -Name $r)) {
            throw "Repository '$r' does not exist."
        }
    }
    Write-ProgressMessage "All repositories validated successfully"

    $results = @()

    if ($Path) {
        if (-not (Test-Path $Path)) {
            throw "File '$Path' does not exist."
        }
        Write-ProgressMessage "Reading content from file: $Path"
        $content = Get-Content -Path $Path -Raw
        $sections = $content -split '(?m)^---\s*$' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        Write-ProgressMessage "Found $($sections.Count) section(s) in the file"
        foreach ($r in $Repo) {
            foreach ($section in $sections) {
                $result = New-Issue -RepoName $r -Title "Copilot Request" -Body $section
                if ($AssignCopilot -and $result) {
                    if ($result -match '/issues/(\d+)$') {
                        $issueNumber = $matches[1]
                        Set-CopilotIssueAssignee -Repo $r -IssueNumber $issueNumber
                        Write-ProgressMessage "Code agent assigned to issue #$issueNumber"
                    }
                }
                $results += $result
            }
        }
        if ($Show -and $results.Count -gt 0) {
            Write-ProgressMessage "Opening $($results.Count) issue(s) in browser"
            foreach ($url in $results) {
                Start-Process $url
            }
        }
        Write-ProgressMessage "Completed processing all sections. Total issues created: $($results.Count)"
        return $results
    }
    elseif ($Work -and $Repo) {
        Write-ProgressMessage "Processing $($Work.Count) work item(s) across $($Repo.Count) repository(ies)"
        foreach ($r in $Repo) {
            foreach ($w in $Work) {
                $result = New-Issue -RepoName $r -Title "Copilot Request" -Body $w
                if ($AssignCopilot -and $result) {
                    if ($result -match '/issues/(\d+)$') {
                        $issueNumber = $matches[1]
                        Set-CopilotIssueAssignee -Repo $r -IssueNumber $issueNumber
                        Write-ProgressMessage "Code agent assigned to issue #$issueNumber"
                    }
                }
                if ($Show -and $result) {
                    Start-Process $result
                }
                $results += $result
            }
        }
        Write-ProgressMessage "Completed processing all work items. Total issues created: $($results.Count)"
        return $results
    }
    else {
        throw "You must provide either -Work or -Path with content."
    }
}
