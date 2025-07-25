import * as fs from 'fs';
import * as path from 'path';
import {
    writeProgressMessage,
    setCopilotIssueAssignee,
    testRepoExists,
    newIssue,
    getCurrentRepo,
    testRepoFormat,
    openInBrowser
} from './utils';

export interface StartCopilotWorkOptions {
    repos?: string[];
    work?: string[];
    filePath?: string;
    assignCopilot?: boolean;
    show?: boolean;
}

/**
 * Main function to start Copilot work - creates Copilot-assigned issues in specified GitHub repos
 */
export async function startCopilotWork(options: StartCopilotWorkOptions): Promise<string[]> {
    let { repos, work, filePath, assignCopilot = false, show = false } = options;

    // Normalize input to arrays
    repos = repos ? repos.filter(r => r) : [];
    work = work ? work.filter(w => w) : [];

    // Auto-detect and swap if needed based on repo format
    if (repos.length > 0 && work.length > 0) {
        const allItems = [...repos, ...work];
        const repoLookingItems = allItems.filter(item => testRepoFormat(item));
        const workLookingItems = allItems.filter(item => !testRepoFormat(item));
        
        if (repoLookingItems.length > 0 && workLookingItems.length > 0) {
            // We have both repo-formatted and non-repo-formatted items, so reassign
            repos = repoLookingItems;
            work = workLookingItems;
        }
    }

    // If neither repos nor work is provided, and no file path, error
    if (repos.length === 0 && work.length === 0 && !filePath) {
        throw new Error("You must provide either work items, repositories, or a file path.");
    }

    // If repos is empty, try to get it from the current directory using gh CLI
    if (repos.length === 0) {
        writeProgressMessage("No repository specified, attempting to detect from current directory");
        const currentRepo = await getCurrentRepo();
        if (!currentRepo) {
            throw new Error("Not in a GitHub repository directory. Please specify repositories (owner/repo format) or run in a git repo directory.");
        }
        repos = [currentRepo];
        writeProgressMessage(`Repository detected: ${repos[0]}`);
    }

    // Validate all repos
    writeProgressMessage(`Validating ${repos.length} repository(ies)`);
    for (const repo of repos) {
        if (!testRepoFormat(repo)) {
            throw new Error(`Repository '${repo}' is not in the format owner/repo.`);
        }
        if (!(await testRepoExists(repo))) {
            throw new Error(`Repository '${repo}' does not exist.`);
        }
    }
    writeProgressMessage("All repositories validated successfully");

    const results: string[] = [];

    if (filePath) {
        if (!fs.existsSync(filePath)) {
            throw new Error(`File '${filePath}' does not exist.`);
        }
        
        writeProgressMessage(`Reading content from file: ${filePath}`);
        const content = fs.readFileSync(filePath, 'utf-8');
        const sections = content
            .split(/^---\s*$/m)
            .map(section => section.trim())
            .filter(section => section !== '');
        
        writeProgressMessage(`Found ${sections.length} section(s) in the file`);
        
        for (const repo of repos) {
            for (const section of sections) {
                const result = await newIssue(repo, "Copilot Request", section);
                if (assignCopilot && result) {
                    const urlMatch = result.match(/\/issues\/(\d+)$/);
                    if (urlMatch) {
                        const issueNumber = urlMatch[1];
                        await setCopilotIssueAssignee(repo, issueNumber);
                        writeProgressMessage(`Code agent assigned to issue #${issueNumber}`);
                    }
                }
                results.push(result);
            }
        }
        
        if (show && results.length > 0) {
            writeProgressMessage(`Opening ${results.length} issue(s) in browser`);
            for (const url of results) {
                openInBrowser(url);
            }
        }
        
        writeProgressMessage(`Completed processing all sections. Total issues created: ${results.length}`);
        return results;
    }
    else if (work.length > 0 && repos.length > 0) {
        writeProgressMessage(`Processing ${work.length} work item(s) across ${repos.length} repository(ies)`);
        
        for (const repo of repos) {
            for (const workItem of work) {
                const result = await newIssue(repo, "Copilot Request", workItem);
                if (assignCopilot && result) {
                    const urlMatch = result.match(/\/issues\/(\d+)$/);
                    if (urlMatch) {
                        const issueNumber = urlMatch[1];
                        await setCopilotIssueAssignee(repo, issueNumber);
                        writeProgressMessage(`Code agent assigned to issue #${issueNumber}`);
                    }
                }
                if (show && result) {
                    openInBrowser(result);
                }
                results.push(result);
            }
        }
        
        writeProgressMessage(`Completed processing all work items. Total issues created: ${results.length}`);
        return results;
    }
    else {
        throw new Error("You must provide either work items or a file path with content.");
    }
}