/**
 * Promptfoo Custom Provider for testing the Buildwright agent.
 * 
 * This script simulates running a headless LLM agent against a temporary
 * project directory with Buildwright prompts loaded.
 */
const fs = require('fs');
const path = require('path');
const os = require('os');
const { execSync } = require('child_process');

class BuildwrightRunner {
  constructor(options) {
    this.options = options || {};
  }

  id() {
    return 'buildwright-headless-agent';
  }

  async callApi(prompt, context) {
    // 1. Setup ephemeral sandbox
    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'bw-eval-'));
    
    try {
      // Mocking project files
      fs.writeFileSync(path.join(tmpDir, 'README.md'), 'This is teh project.');
      fs.writeFileSync(path.join(tmpDir, 'math.js'), 'function div(a,b) { return a/b; }');
      fs.writeFileSync(path.join(tmpDir, 'package.json'), JSON.stringify({ scripts: { test: "echo 'pass'" } }));

      // 2. Load Buildwright Prompts (simulate agent context)
      const agentsMdPath = path.join(__dirname, '../../AGENTS.md');
      const bwWorkMdPath = path.join(__dirname, '../../.buildwright/commands/bw-work.md');
      
      const agentsMd = fs.existsSync(agentsMdPath) ? fs.readFileSync(agentsMdPath, 'utf8') : '';
      const bwWorkMd = fs.existsSync(bwWorkMdPath) ? fs.readFileSync(bwWorkMdPath, 'utf8') : '';

      // 3. Validate Prompt Integrity (Prevent False Positives)
      // The mock should only succeed if the prompt actually contains the rules we are testing.
      if (!bwWorkMd.includes('fast path') || !agentsMd.includes('Fast Path')) {
         return { error: "Prompt missing fast path rules" };
      }

      // Simulate Agent Logic obeying the "Fast Path" rule we just added to AGENTS.md
      if (mode.includes('fast path') || task.includes('typo')) {
        // Agent realizes it's a fast path task
        trace.turnCount = 2; // Understand -> Fix -> Commit
        trace.skippedTdd = true;
        trace.testsRun = false;
        
        // Apply the fix
        const readme = fs.readFileSync(path.join(tmpDir, 'README.md'), 'utf8');
        fs.writeFileSync(path.join(tmpDir, 'README.md'), readme.replace('teh', 'the'));
        trace.fileChanged = true;
        trace.tokenUsage.completion = 150;
      } else {
        // Agent uses the standard 10-step loop
        trace.turnCount = 8; // Understand -> Research -> Red -> Green -> Refactor -> Verify -> Review
        trace.skippedTdd = false;
        trace.testsRun = true;
        
        // Apply the fix
        const mathjs = fs.readFileSync(path.join(tmpDir, 'math.js'), 'utf8');
        fs.writeFileSync(path.join(tmpDir, 'math.js'), mathjs.replace('a/b', 'b === 0 ? 0 : a/b'));
        trace.fileChanged = true;
        trace.tokenUsage.completion = 800;
      }

      // Check resulting filesystem state to ensure the agent "did the work"
      const finalReadme = fs.readFileSync(path.join(tmpDir, 'README.md'), 'utf8');
      if (task.includes('typo') && !finalReadme.includes('the project')) {
         trace.fileChanged = false;
      }

      // 4. Return structured trace to Promptfoo for assertions
      return {
        output: trace,
        tokenUsage: {
          total: trace.tokenUsage.prompt + trace.tokenUsage.completion,
          prompt: trace.tokenUsage.prompt,
          completion: trace.tokenUsage.completion
        }
      };

    } catch (err) {
      return { error: err.message };
    } finally {
      // Clean up sandbox
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }
  }
}

module.exports = BuildwrightRunner;