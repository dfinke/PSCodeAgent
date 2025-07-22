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
    gh repo view $Name 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
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
    $output = gh issue create --repo $RepoName --title $Title --body $Body 2>&1
    if ($LASTEXITCODE -ne 0 -or -not $output) {
        throw "Failed to create issue using gh CLI. Output: $output"
    }
    # Try to extract the URL from the output (gh usually prints the URL on the last line)
    $url = $output | Select-String -Pattern 'https://github.com/.*/issues/\d+' -AllMatches | ForEach-Object { $_.Matches.Value } | Select-Object -Last 1
    if ($url) {
        return $url
    }
    else {
        throw "Issue created but URL not found in output. Raw output: $output"
    }
}

function Start-CopilotWork {
    <#
    .SYNOPSIS
        Creates Copilot-assigned issues in a specified GitHub repo.
    .DESCRIPTION
        Checks if the repo exists, creates one or more issues with the given prompt(s), assigns @copilot, and outputs the issue URLs.
        If -Path is provided, reads a markdown file and creates an issue for each section separated by '---'.
    .PARAMETER Repo
        The GitHub repository in the format owner/repo.
    .PARAMETER Work
        The issue body/prompt for Copilot.
    .PARAMETER Path
        Path to a markdown file containing one or more issues separated by '---'.
    .EXAMPLE
        Start-CopilotWork -Repo dfinke/trystuff 'need a greet fn in Rust'
        Start-CopilotWork -Repo dfinke/trystuff -Path .\issues.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Repo,
        [Parameter(Position = 1)]
        [string]$Work,
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

    # Allow Repo and Work to be provided in any order (positional or named)
    if ($Repo -and $Work) {
        if (Test-RepoFormat $Repo -and -not (Test-RepoFormat $Work)) {
            # $Repo and $Work are correct
        }
        elseif (Test-RepoFormat $Work -and -not (Test-RepoFormat $Repo)) {
            # Swap if user provided in reverse order
            $temp = $Repo
            $Repo = $Work
            $Work = $temp
        }
        elseif (-not (Test-RepoFormat $Repo) -and -not (Test-RepoFormat $Work)) {
            throw "One argument must be a repo in the format owner/repo."
        }
        # else: both look like repos, ambiguous, you can throw or pick one
    }
    elseif ($Repo -and -not $Work) {
        if (-not (Test-RepoFormat $Repo)) {
            # Only one arg, treat as Work, try to get repo from current dir
            $Work = $Repo
            $Repo = $null
        }
    }
    elseif ($Work -and -not $Repo) {
        if (-not (Test-RepoFormat $Work)) {
            # Only one arg, treat as Work, try to get repo from current dir
            # $Work is already set, $Repo is null
        }
        else {
            # Only one arg, and it's a repo, so need Work
            throw "You must provide a work string if you specify a repo."
        }
    }

    # If Repo is not provided, try to get it from the current directory using gh CLI
    if (-not $Repo) {
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Host "The GitHub CLI 'gh' is not installed or not in PATH. Please install it." -ForegroundColor Yellow
            return
        }
        $repoInfo = gh repo view --json 'owner,name' 2>$null | ConvertFrom-Json
        if (-not $repoInfo) {
            Write-Host "Not in a GitHub repository directory. Please specify -Repo (owner/repo) or run in a git repo directory." -ForegroundColor Yellow
            return
        }
        $Repo = "$($repoInfo.owner.login)/$($repoInfo.name)"
    }

    if (-not (Test-RepoExists -Name $Repo)) {
        throw "Repository '$Repo' does not exist."
    }

    $results = @()

    if ($Path) {
        if (-not (Test-Path $Path)) {
            throw "File '$Path' does not exist."
        }
        $content = Get-Content -Path $Path -Raw
        $sections = $content -split '(?m)^---\s*$' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
        foreach ($section in $sections) {
            $result = New-Issue -RepoName $Repo -Title "Copilot Request" -Body $section
            if ($AssignCopilot -and $result) {
                # Extract issue number from URL (assumes .../issues/<number>)
                if ($result -match '/issues/(\d+)$') {
                    $issueNumber = $matches[1]
                    Set-CopilotIssueAssignee -Repo $Repo -IssueNumber $issueNumber
                }
            }
            $results += $result
        }
        if ($Show -and $results.Count -gt 0) {
            foreach ($url in $results) {
                Start-Process $url
            }
        }
        return $results
    }
    elseif ($Work) {
        $result = New-Issue -RepoName $Repo -Title "Copilot Request" -Body $Work
        if ($AssignCopilot -and $result) {
            if ($result -match '/issues/(\d+)$') {
                $issueNumber = $matches[1]
                Set-CopilotIssueAssignee -Repo $Repo -IssueNumber $issueNumber
            }
        }
        if ($Show -and $result) {
            Start-Process $result
        }
        return $result
    }
    else {
        throw "You must provide either -Work or -Path with content."
    }
}
