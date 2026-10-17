import { test } from 'node:test';
import assert from 'node:assert/strict';
import { branchStory, validateBranch, validateSubject } from './check_workflow.mjs';

test('each initial assignment accepts only its own story branch and scope', () => {
  for (const [story, branch] of [[2,'codex/story-2-rendering'],[3,'codex/story-3-physics'],[6,'codex/story-6-input']]) {
    assert.equal(branchStory(branch),story);
    assert.doesNotThrow(()=>validateBranch(branch,story));
    assert.doesNotThrow(()=>validateSubject(`feat(story-${story}): implement approved subsystem`,branch));
    assert.throws(()=>validateBranch(branch,story===2?3:2));
    assert.throws(()=>validateSubject('fix(story-7): alter integration',branch));
    assert.throws(()=>validateSubject('chore(team): bypass story scope',branch));
  }
});

test('main, detached and unrelated branches reject feature-story commits', () => {
  for(const branch of ['main','master','','feature/input']) {
    assert.throws(()=>validateBranch(branch,6));
    assert.throws(()=>validateSubject('feat(story-6): capture mouse input',branch));
  }
  assert.doesNotThrow(()=>validateSubject('chore(team): configure onboarding','main'));
});

test('subjects require a specific conventional description and valid story range', () => {
  for(const subject of ['update','feat(story-6): ','feat(story-13): beyond backlog','feat(story-6): '+ 'x'.repeat(100)]) {
    assert.throws(()=>validateSubject(subject,'codex/story-6-input'));
  }
  assert.throws(()=>validateBranch('codex/story-13-extra',13));
  assert.doesNotThrow(()=>validateSubject("Merge branch 'main' into codex/story-6-input",'codex/story-6-input'));
});
