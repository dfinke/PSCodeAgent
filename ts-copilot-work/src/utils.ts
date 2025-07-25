import { execSync, exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

/**
 * Write progress message with timestamp
 */
export function writeProgressMessage(message: string): void {
    const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
    console.log(`\x1b[32m[${timestamp}] ${message}\x1b[0m`);
}

/**
 * Check if GitHub CLI is available
 */
export function checkGitHubCLI(): boolean {
    try {
        execSync('gh --version', { stdio: 'ignore' });
        return true;
    } catch {
        return false;
    }
}

/**
 * Assign @copilot to a GitHub issue using gh CLI
 */
export async function setCopilotIssueAssignee(repo: string, issueNumber: string): Promise<void> {
    if (!checkGitHubCLI()) {
        throw new Error("The GitHub CLI 'gh' is not installed or not in PATH. Please install it to assign @copilot.");
    }
    
    writeProgressMessage(`Assigning @copilot to issue #${issueNumber} in ${repo}`);
    try {
        await execAsync(`gh issue edit ${issueNumber} --repo ${repo} --add-assignee "@copilot"`);
    } catch (error) {
        throw new Error(`Failed to assign @copilot to issue #${issueNumber}: ${error}`);
    }
}

/**
 * Check if a GitHub repo exists
 */
export async function testRepoExists(name: string): Promise<boolean> {
    if (!checkGitHubCLI()) {
        throw new Error("The GitHub CLI 'gh' is not installed or not in PATH. Please install it.");
    }
    
    writeProgressMessage(`Checking if repository ${name} exists`);
    try {
        await execAsync(`gh repo view ${name} 2>/dev/null`);
        writeProgressMessage(`Repository ${name} located successfully`);
        return true;
    } catch {
        return false;
    }
}

/**
 * Create a new GitHub issue
 */
export async function newIssue(repoName: string, title: string, body: string): Promise<string> {
    if (!checkGitHubCLI()) {
        throw new Error("The GitHub CLI 'gh' is not installed or not in PATH. Please install it.");
    }
    
    writeProgressMessage(`Creating issue in ${repoName} with title: '${title}'`);
    try {
        const { stdout } = await execAsync(`gh issue create --repo ${repoName} --title "${title}" --body "${body}"`);
        
        // Extract URL from output
        const urlMatch = stdout.match(/https:\/\/github\.com\/.*\/issues\/\d+/);
        if (urlMatch) {
            const url = urlMatch[0];
            writeProgressMessage(`Issue created successfully: ${url}`);
            return url;
        } else {
            throw new Error(`Issue created but URL not found in output. Raw output: ${stdout}`);
        }
    } catch (error) {
        throw new Error(`Failed to create issue using gh CLI. Error: ${error}`);
    }
}

/**
 * Get current repository info from current directory
 */
export async function getCurrentRepo(): Promise<string | null> {
    if (!checkGitHubCLI()) {
        return null;
    }
    
    try {
        const { stdout } = await execAsync('gh repo view --json "owner,name"');
        const repoInfo = JSON.parse(stdout);
        return `${repoInfo.owner.login}/${repoInfo.name}`;
    } catch {
        return null;
    }
}

/**
 * Test if a string is in repo format (owner/repo)
 */
export function testRepoFormat(str: string): boolean {
    return /^[^/]+\/[^/]+$/.test(str);
}

/**
 * Open URL in browser
 */
export function openInBrowser(url: string): void {
    const { exec } = require('child_process');
    const platform = process.platform;
    
    let command: string;
    if (platform === 'darwin') {
        command = `open "${url}"`;
    } else if (platform === 'win32') {
        command = `start "${url}"`;
    } else {
        command = `xdg-open "${url}"`;
    }
    
    exec(command, (error: any) => {
        if (error) {
            writeProgressMessage(`Failed to open browser: ${error.message}`);
        }
    });
}