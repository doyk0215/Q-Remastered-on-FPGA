import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
export function branchStory(branch) { const m=/^codex\/story-(\d+)(?:-[a-z0-9][a-z0-9-]*)?$/.exec(branch); return m?Number(m[1]):null; }
export function validateBranch(branch,story) {
  if(!Number.isInteger(story)||story<1||story>12)throw Error('Story must be an integer from 1 to 12');
  if(branchStory(branch)!==story)throw Error(`Story ${story} requires codex/story-${story}-<description>; current branch is ${branch||'(detached)'}`);
}
export function validateSubject(subject,branch) {
  if(/^Merge (branch|remote-tracking branch|pull request) /.test(subject))return;
  const m=/^(feat|fix|test|docs|refactor|chore|build|ci)\((story-(?:[1-9]|1[0-2])|team|bmad)\): \S.*$/.exec(subject);
  if(!m||subject.length>100)throw Error('Use type(story-N): specific change (<=100 characters), or team/bmad scope for coordinated maintenance');
  const story=branchStory(branch);
  if(story!==null&&m[2]!==`story-${story}`)throw Error(`Commit scope must match active story-${story} branch`);
  if((branch==='main'||branch==='master')&&m[2].startsWith('story-'))throw Error('Feature-story commits must use their own branch, not main');
  if(m[2].startsWith('story-')&&story===null)throw Error('Create/resume the matching codex/story-N branch before story commits');
}
function main() {
  const args=process.argv.slice(2), git=spawnSync('git',['branch','--show-current'],{cwd:root,encoding:'utf8'});
  if(git.status!==0)throw Error('Open a Git checkout of this repository');
  const branch=git.stdout.trim();
  if(args.includes('--commit-message-file')) {
    const file=args[args.indexOf('--commit-message-file')+1]; if(!file)throw Error('Missing commit message file');
    validateSubject(fs.readFileSync(path.resolve(process.cwd(),file),'utf8').split(/\r?\n/)[0],branch);
    console.log('Commit subject/branch check passed.'); return;
  }
  const i=args.indexOf('--story'); if(i<0)throw Error('Usage: node scripts/team/check_workflow.mjs --story <1..12>');
  const story=Number(args[i+1]); validateBranch(branch,story);
  for(const file of ['AGENTS.md','docs/parallel-start-checklist.md','_bmad-output/specs/spec-q-remastered-on-fpga/stories.yaml'])if(!fs.existsSync(path.join(root,file)))throw Error(`Missing handoff file: ${file}`);
  console.log(JSON.stringify({branch,story,status:'PASS',notice:'This checks assignment/branch structure, not human identity, skill installation, RTL correctness or permission to merge main.'},null,2));
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  try { main(); } catch(error) { console.error(error.message); process.exitCode=1; }
}
