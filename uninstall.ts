import prompts from 'prompts';
import ora from 'ora';
import chalk from 'chalk';
import { execSync } from 'child_process';
import { existsSync, rmSync, rmdirSync } from 'fs';
import { homedir } from 'os';
import path from 'path';

interface AssistantConfig {
  name: string;
  id: string;
  configPath: string;
  exists: boolean;
}

function printBox(text: string) {
  const width = 60;
  const padding = Math.floor((width - text.length) / 2);
  console.log('');
  console.log(chalk.cyan('╔' + '═'.repeat(width) + '╗'));
  console.log(chalk.cyan('║') + ' '.repeat(padding) + chalk.bold(text) + ' '.repeat(width - padding - text.length) + chalk.cyan('║'));
  console.log(chalk.cyan('╚' + '═'.repeat(width) + '╝'));
  console.log('');
}

async function checkExistingConfigs(): Promise<AssistantConfig[]> {
  const configs: AssistantConfig[] = [];
  
  // Check Claude Code
  const claudePath = path.join(homedir(), '.claude', 'CLAUDE.md');
  if (existsSync(claudePath)) {
    const content = require('fs').readFileSync(claudePath, 'utf-8');
    if (content.includes('qmd-claude-history')) {
      configs.push({ name: 'Claude Code', id: 'claude', configPath: claudePath, exists: true });
    }
  }
  
  // Check Amp
  const ampPath = path.join(homedir(), '.config', 'amp', 'AGENTS.md');
  if (existsSync(ampPath)) {
    const content = require('fs').readFileSync(ampPath, 'utf-8');
    if (content.includes('qmd-history')) {
      configs.push({ name: 'Amp', id: 'amp', configPath: ampPath, exists: true });
    }
  }
  
  // Check Opencode
  const opencodePath = path.join(homedir(), '.config', 'opencode', 'agents', 'qmd-history.md');
  if (existsSync(opencodePath)) {
    configs.push({ name: 'Opencode', id: 'opencode', configPath: opencodePath, exists: true });
  }
  
  return configs;
}

async function main() {
  // Clear screen for clean output
  process.stdout.write('\x1Bc');
  
  printBox('QMD History Search Uninstaller');
  
  console.log(chalk.cyan.bold('What Will Be Removed'));
  console.log('  ' + chalk.red('✗') + ' LaunchAgent (auto-updates)');
  console.log('  ' + chalk.red('✗') + ' Converter script');
  console.log('  ' + chalk.red('✗') + ' Skill files');
  console.log('  ' + chalk.yellow('?') + ' AI assistant configurations (optional)');
  console.log('  ' + chalk.yellow('?') + ' Converted history (optional)');
  console.log('');
  
  console.log(chalk.cyan.bold('What Will Be Preserved'));
  console.log('  ' + chalk.green('✓') + ' Original JSONL files in ~/.claude/projects/');
  console.log('  ' + chalk.green('✓') + ' QMD collections (manual removal required)');
  console.log('');
  
  const { proceed } = await prompts({
    type: 'confirm',
    name: 'proceed',
    message: 'Continue with uninstallation?',
    initial: false
  });
  
  if (!proceed) {
    console.log(chalk.yellow('Uninstallation cancelled.'));
    process.exit(0);
  }
  
  // Stop services
  console.log('');
  console.log(chalk.cyan.bold('Step 1: Stopping Services'));
  console.log('');
  
  const launchAgentPath = path.join(homedir(), 'Library', 'LaunchAgents', 'com.user.qmd-claude-history.plist');
  if (existsSync(launchAgentPath)) {
    const spinner = ora('Stopping LaunchAgent...').start();
    try {
      execSync('launchctl list | grep -q com.user.qmd-claude-history && launchctl unload ~/Library/LaunchAgents/com.user.qmd-claude-history.plist 2>/dev/null || true', { stdio: 'pipe' });
      spinner.succeed('LaunchAgent stopped');
    } catch {
      spinner.warn('LaunchAgent not running');
    }
  } else {
    console.log(chalk.yellow('⚠ LaunchAgent not found'));
  }
  
  // Remove files
  console.log('');
  console.log(chalk.cyan.bold('Step 2: Removing Files'));
  console.log('');
  
  const filesToRemove = [
    { path: launchAgentPath, name: 'LaunchAgent plist' },
    { path: path.join(homedir(), '.local', 'bin', 'convert-claude-history.sh'), name: 'Converter script' },
    { path: path.join(homedir(), '.claude', 'skills', 'qmd-claude-history'), name: 'Skill directory' }
  ];
  
  for (const file of filesToRemove) {
    if (existsSync(file.path)) {
      const spinner = ora(`Removing ${file.name}...`).start();
      try {
        if (require('fs').statSync(file.path).isDirectory()) {
          rmSync(file.path, { recursive: true });
        } else {
          rmSync(file.path);
        }
        spinner.succeed(`${file.name} removed`);
      } catch (err) {
        spinner.fail(`Failed to remove ${file.name}`);
      }
    } else {
      console.log(chalk.yellow(`⚠ ${file.name} not found`));
    }
  }
  
  // Check for AI assistant configs
  const configs = await checkExistingConfigs();
  if (configs.length > 0) {
    console.log('');
    console.log(chalk.cyan.bold('Step 3: AI Assistant Configurations'));
    console.log('');
    
    const { removeConfigs } = await prompts({
      type: 'multiselect',
      name: 'removeConfigs',
      message: 'Select which AI assistant configurations to remove:',
      choices: configs.map(c => ({
        title: `${c.name} (${c.configPath})`,
        value: c.id
      })),
      hint: '- Space to select. Return to submit'
    });
    
    if (removeConfigs && removeConfigs.length > 0) {
      for (const configId of removeConfigs) {
        const config = configs.find(c => c.id === configId);
        if (config) {
          const spinner = ora(`Removing ${config.name} configuration...`).start();
          
          // Create backup
          const backupPath = `${config.configPath}.backup.${Date.now()}`;
          try {
            copyFileSync(config.configPath, backupPath);
          } catch {}
          
          // Remove qmd section from the file
          try {
            const content = require('fs').readFileSync(config.configPath, 'utf-8');
            const lines = content.split('\n');
            const newLines: string[] = [];
            let inQmdSection = false;
            
            for (const line of lines) {
              if (line.includes('Memory & Context Retrieval') || line.includes('QMD History Search')) {
                inQmdSection = true;
              } else if (inQmdSection && line.startsWith('## ') && !line.includes('QMD') && !line.includes('Memory')) {
                inQmdSection = false;
              }
              
              if (!inQmdSection) {
                newLines.push(line);
              }
            }
            
            require('fs').writeFileSync(config.configPath, newLines.join('\n'));
            spinner.succeed(`${config.name} configuration removed`);
          } catch (err) {
            spinner.fail(`Failed to remove ${config.name} configuration`);
          }
        }
      }
    }
  }
  
  // Ask about converted history
  const convertedHistoryPath = path.join(homedir(), '.claude', 'converted-history');
  if (existsSync(convertedHistoryPath)) {
    console.log('');
    console.log(chalk.cyan.bold('Step 4: Converted History'));
    console.log('');
    
    const { removeHistory } = await prompts({
      type: 'confirm',
      name: 'removeHistory',
      message: `Remove converted history at ~/.claude/converted-history?`,
      initial: false
    });
    
    if (removeHistory) {
      const spinner = ora('Removing converted history...').start();
      try {
        rmSync(convertedHistoryPath, { recursive: true });
        spinner.succeed('Converted history removed');
      } catch (err) {
        spinner.fail('Failed to remove converted history');
      }
    } else {
      console.log(chalk.green('✓') + ' Preserving converted history');
    }
  }
  
  // Completion
  console.log('');
  printBox('Uninstallation Complete!');
  
  console.log(chalk.cyan.bold('What Was Removed'));
  console.log('  ' + chalk.green('✓') + ' LaunchAgent (auto-updates)');
  console.log('  ' + chalk.green('✓') + ' Converter script');
  console.log('  ' + chalk.green('✓') + ' Skill files');
  console.log('');
  
  console.log(chalk.cyan.bold('Reminder'));
  console.log('To remove QMD collections manually:');
  console.log('  qmd collection list');
  console.log('  qmd collection remove <name>');
  console.log('');
  
  console.log(chalk.cyan.bold('To Reinstall'));
  console.log('  ./install.sh');
  console.log('');
}

main().catch(err => {
  console.error(chalk.red('Error:'), err);
  process.exit(1);
});

function copyFileSync(src: string, dest: string) {
  require('fs').copyFileSync(src, dest);
}
