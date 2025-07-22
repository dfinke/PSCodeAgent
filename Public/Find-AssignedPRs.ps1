<#
.SYNOPSIS
Finds pull requests assigned to a specific user in the most recently updated repositories for a given GitHub owner (organization or user).

.DESCRIPTION
The Find-AssignedPRs function searches the latest updated repositories (default: 15) for a specified GitHub owner (organization or user) and lists up to 3 pull requests per repository that are assigned to a specified user (default: 'copilot'). It uses the GitHub GraphQL API and requires a valid GitHub personal access token set in the GITHUB_TOKEN environment variable.

.PARAMETER Owner
The GitHub organization or user name whose repositories will be searched.

.PARAMETER Arg2
Optional. If an integer, specifies the number of repositories to search (default: 15). If a string, specifies the assignee's GitHub username (default: 'copilot').

.PARAMETER Arg3
Optional. If an integer, specifies the number of repositories to search (overrides Arg2 if both are integers). If a string, specifies the assignee's GitHub username (overrides Arg2 if both are strings).

.EXAMPLE
Find-AssignedPRs -Owner "octocat"
Searches the 15 most recently updated repositories owned by "octocat" for pull requests assigned to "copilot".

.EXAMPLE
Find-AssignedPRs -Owner "octocat" 20 "alice"
Searches the 20 most recently updated repositories owned by "octocat" for pull requests assigned to "alice".

.NOTES
- Requires the GITHUB_TOKEN environment variable to be set with a valid GitHub personal access token.
- Uses the GitHub GraphQL API.
- Outputs a formatted table of matching pull requests, including URL, title, state, assignee, repository, number, creation and update dates, and author.

#>
function Find-AssignedPRs {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Owner,
    [Parameter(Position = 1)]
    [object]$Arg2,
    [Parameter(Position = 2)]
    [object]$Arg3
  )

  # Defaults
  $RepoCount = 15
  $Assignee = 'copilot'

  # Parse flexible arguments
  if ($null -ne $Arg2) {
    if ($Arg2 -is [int]) {
      $RepoCount = $Arg2
    }
    elseif ($Arg2 -is [string]) {
      $Assignee = $Arg2
    }
  }
  if ($null -ne $Arg3) {
    if ($Arg3 -is [int]) {
      $RepoCount = $Arg3
    }
    elseif ($Arg3 -is [string]) {
      $Assignee = $Arg3
    }
  }

  Write-Host "Searching for PRs assigned to '$Assignee' in the latest $RepoCount repos for owner '$Owner'..."

  if (-not $env:GITHUB_TOKEN) {
    throw "GITHUB_TOKEN environment variable is not set. Please set it to a valid GitHub personal access token."
  }

  $headers = @{ Authorization = "Bearer $($env:GITHUB_TOKEN)" }

  # Get the 15 most recently updated repos for the owner (org or user) using correct GraphQL
  $repos = @()
  $isOrg = $true
  try {
    $query = @"
      query {
        organization(login: "$Owner") {
          repositories(first: $RepoCount, orderBy: {field: UPDATED_AT, direction: DESC}, privacy: ALL) {
            nodes { name }
          }
        }
      }
"@
    $body = @{ query = $query } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri https://api.github.com/graphql -Headers $headers -Method Post -Body $body
    if ($null -eq $result.data.organization) { throw "Not an org" }
    $repos = $result.data.organization.repositories.nodes | ForEach-Object { $_.name }
  }
  catch {
    $isOrg = $false
    $query = @"
      query {
        user(login: "$Owner") {
          repositories(first: $RepoCount, orderBy: {field: UPDATED_AT, direction: DESC}, ownerAffiliations: [OWNER, COLLABORATOR, ORGANIZATION_MEMBER]) {
            nodes { name }
          }
        }
      }
"@
    $body = @{ query = $query } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri https://api.github.com/graphql -Headers $headers -Method Post -Body $body
    if ($null -eq $result.data.user) {
      throw "User or organization '$Owner' does not exist."
    }
    $repos = $result.data.user.repositories.nodes | ForEach-Object { $_.name }
  }

  # For each of the 15 most recently updated repos, get the 10 most recently updated PRs and pick the first 3 assigned to the user
  $allPRs = @()
  Write-Verbose "Checking these repos: $($repos -join ', ')"
  for ($i = 0; $i -lt $repos.Count; $i++) {
    $repo = $repos[$i]
    Write-Progress -Activity "Checking PRs" -Status "Repo: $repo ($($i+1)/$($repos.Count))" -PercentComplete (($i + 1) / $repos.Count * 100)
    Write-Verbose "--- Checking repo: $repo ---"
    $query = @"
      query {
        repository(owner: "$Owner", name: "$repo") {
          pullRequests(first: 10, orderBy: {field: UPDATED_AT, direction: DESC}) {
            nodes {
              number
              title
              url
              state
              createdAt
              updatedAt
              author { login }
              assignees(first: 10) {
                nodes { login }
              }
            }
          }
        }
      }
"@
    $body = @{ query = $query } | ConvertTo-Json
    $result = Invoke-RestMethod -Uri https://api.github.com/graphql -Headers $headers -Method Post -Body $body
    $prs = $result.data.repository.pullRequests.nodes
    if ($prs) {
      foreach ($pr in $prs) {
        $assignees = $pr.assignees.nodes | ForEach-Object { $_.login }
        Write-Verbose ("PR #$($pr.number): $($pr.title) | Assignees: $($assignees -join ', ')")
      }
      $matched = @()
      foreach ($pr in $prs) {
        $assignees = $pr.assignees.nodes | ForEach-Object { $_.login }
        if ($assignees -contains $Assignee) {
          $pr | Add-Member -NotePropertyName repo -NotePropertyValue $repo -Force
          $matched += $pr
          if ($matched.Count -ge 3) { break }
        }
      }
      $allPRs += $matched
    }
  }

  # Output results
  if ($allPRs.Count -eq 0) {
    Write-Host "No PRs assigned to $Assignee found in any of the latest $RepoCount repos for owner $Owner."
  }
  else {
    $allPRs | ForEach-Object {
      $_ | Add-Member -NotePropertyName assignee -NotePropertyValue (($_.assignees.nodes | ForEach-Object { $_.login }) -join ', ') -Force
      $_
    } |
    Sort-Object updatedAt -Descending |
    Select-Object url, title, state, assignee, repo, number, createdAt, updatedAt, author |
    Format-Table -AutoSize
  }
}