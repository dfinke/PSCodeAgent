#!/usr/bin/env node

import { Command } from 'commander';
import { startCopilotWork } from './index';
import { writeProgressMessage } from './utils';

const program = new Command();

program
    .name('start-copilot-work')
    .description('Create GitHub issues and assign them to Copilot')
    .version('1.0.0');

program
    .argument('[items...]', 'Repository names (owner/repo) and work descriptions - order is auto-detected')
    .option('-r, --repo <repos...>', 'GitHub repositories in owner/repo format')
    .option('-w, --work <work...>', 'Work descriptions/issue bodies')
    .option('-f, --file <path>', 'Path to markdown file with issues separated by ---')
    .option('-a, --assign-copilot', 'Assign @copilot to created issues')
    .option('-s, --show', 'Open created issues in browser')
    .action(async (items: string[], options) => {
        try {
            let repos = options.repo || [];
            let work = options.work || [];
            
            // If we have positional arguments, combine them with explicit options
            if (items && items.length > 0) {
                // Add items to both repos and work arrays, the function will sort them out
                repos = [...repos, ...items];
                work = [...work, ...items];
            }
            
            const results = await startCopilotWork({
                repos: repos.length > 0 ? repos : undefined,
                work: work.length > 0 ? work : undefined,
                filePath: options.file,
                assignCopilot: options.assignCopilot,
                show: options.show
            });
            
            if (results.length > 0) {
                console.log('\nCreated issues:');
                results.forEach((url, index) => {
                    console.log(`${index + 1}. ${url}`);
                });
            }
            
        } catch (error) {
            console.error(`Error: ${error instanceof Error ? error.message : error}`);
            process.exit(1);
        }
    });

// Add examples to help
program.on('--help', () => {
    console.log('');
    console.log('Examples:');
    console.log('  $ start-copilot-work "Add login feature" owner/repo');
    console.log('  $ start-copilot-work -w "Fix bug" -r owner/repo1 owner/repo2');
    console.log('  $ start-copilot-work -f ./issues.md -r owner/repo --assign-copilot');
    console.log('  $ start-copilot-work "Task 1" "Task 2" repo1 repo2 --show');
    console.log('');
    console.log('The tool auto-detects which arguments are repositories (owner/repo format)');
    console.log('and which are work descriptions, so order doesn\'t matter for positional args.');
});

if (require.main === module) {
    program.parse();
}

export { startCopilotWork };