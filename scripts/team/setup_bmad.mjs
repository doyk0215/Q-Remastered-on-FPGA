// Recover the pinned official BMAD skills omitted from the initial checkout.
// Never execute the downloaded installer or overwrite project planning/config.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const args = process.argv.slice(2);
const option = name => { const i = args.indexOf(name); if (i < 0) return null; if (!args[i+1] || args[i+1].startsWith('--')) throw Error(`Missing value for ${name}`); return args[i+1]; };
if (args.includes('--help')) { console.log('node scripts/team/setup_bmad.mjs [--name "Your name"] [--skills-dir .agents/skills] [--check] [--hooks]\nInstalls only missing official runtime/skill files, preserves existing files, and verifies package integrity. Node >=20.12, Git/tar, uv and Python >=3.11 are required for the full workflow.'); process.exit(0); }
const lock = JSON.parse(fs.readFileSync(path.join(root,'scripts/team/bmad-runtime.lock.json'),'utf8'));
const [major, minor] = process.versions.node.split('.').map(Number);
if (major < 20 || (major === 20 && minor < 12)) throw Error('Node.js 20.12+ required');
const relativeTarget = option('--skills-dir') || '.agents/skills';
const target = path.resolve(root, relativeTarget);
if (!target.startsWith(root + path.sep) || !relativeTarget.endsWith('skills')) throw Error('Skill directory must be a project-local skills folder');
function safeParents(targetPath) {
  for (let p = path.dirname(targetPath); p.startsWith(root + path.sep); p = path.dirname(p)) {
    if (fs.existsSync(p) && fs.lstatSync(p).isSymbolicLink()) throw Error(`Refusing symlinked target: ${p}`);
  }
}
function writeMissing(dest, bytes) {
  safeParents(dest);
  if (fs.existsSync(dest)) return false;
  fs.mkdirSync(path.dirname(dest),{recursive:true}); fs.writeFileSync(dest,bytes,{flag:'wx'}); return true;
}
function copyMissing(from,to) {
  let copied = 0;
  for (const entry of fs.readdirSync(from,{withFileTypes:true})) {
    if (entry.name.startsWith('.') || entry.name === '__pycache__') continue;
    const src = path.join(from,entry.name), dst = path.join(to,entry.name);
    if (entry.isSymbolicLink()) throw Error(`Unexpected upstream symlink: ${src}`);
    if (entry.isDirectory()) copied += copyMissing(src,dst);
    else copied += Number(writeMissing(dst,fs.readFileSync(src)));
  }
  return copied;
}
function csv(text) {
  const rows = []; let row = [], cell = '', quoted = false;
  for (let i=0;i<text.length;i++) {
    const c=text[i];
    if (c==='"') { if (quoted && text[i+1]==='"') { cell+='"'; i++; } else quoted=!quoted; }
    else if (!quoted && (c===',' || c==='\n')) { row.push(cell.replace(/\r$/,'')); cell=''; if (c==='\n') { if(row.some(Boolean))rows.push(row); row=[]; } }
    else cell+=c;
  }
  if(cell || row.length){row.push(cell.replace(/\r$/,''));rows.push(row);}
  const header=rows.shift(); return rows.map(r=>Object.fromEntries(header.map((h,i)=>[h,r[i]||''])));
}
const skills = csv(fs.readFileSync(path.join(root,'_bmad/_config/skill-manifest.csv'),'utf8'));
const versionText = fs.readFileSync(path.join(root,'_bmad/_config/manifest.yaml'),'utf8');
if (!versionText.includes(`version: ${lock.version}`)) throw Error('Tracked BMAD version differs from pinned recovery package; coordinate an upgrade instead');
let installedFiles = 0;
if (!args.includes('--check')) {
  const cache=path.join(root,'build',`bmad-runtime-${lock.version}`), archive=path.join(cache,'package.tgz');
  fs.mkdirSync(cache,{recursive:true});
  const valid = bytes => `sha512-${crypto.createHash('sha512').update(bytes).digest('base64')}` === lock.integrity;
  let bytes=fs.existsSync(archive)?fs.readFileSync(archive):null;
  if (!bytes || !valid(bytes)) {
    console.log(`Downloading pinned ${lock.package}@${lock.version}...`);
    const response=await fetch(lock.tarball); if(!response.ok)throw Error(`Download failed: HTTP ${response.status}`);
    bytes=Buffer.from(await response.arrayBuffer()); if(!valid(bytes))throw Error('Package integrity mismatch');
    fs.writeFileSync(archive,bytes);
  }
  const listing=spawnSync('tar',['-tzf',archive],{encoding:'utf8'});
  if(listing.status!==0)throw Error('tar is required; install Git/system tar and retry');
  for(const entry of listing.stdout.split(/\r?\n/).filter(Boolean)) if(!entry.startsWith('package/') || entry.split(/[\\/]/).includes('..'))throw Error(`Unsafe package entry: ${entry}`);
  const unpack=spawnSync('tar',['-xzf',archive,'-C',cache],{encoding:'utf8'}); if(unpack.status!==0)throw Error(`Package extraction failed: ${unpack.stderr}`);
  for(const [source,module] of [['core-skills','core'],['bmm-skills','bmm']]) installedFiles+=copyMissing(path.join(cache,'package/src',source),path.join(root,'_bmad',module));
  installedFiles+=Number(writeMissing(path.join(root,'_bmad/UPSTREAM-LICENSE'),fs.readFileSync(path.join(cache,'package/LICENSE'))));
  for(const skill of skills) {
    if(!/^bmad-[a-z0-9-]+$/.test(skill.canonicalId))throw Error('Invalid skill manifest identifier');
    const source=path.resolve(root,skill.path);
    if(!source.startsWith(path.join(root,'_bmad')+path.sep) || !fs.existsSync(source))throw Error(`Canonical skill missing: ${skill.path}`);
    installedFiles+=copyMissing(path.dirname(source),path.join(target,skill.canonicalId));
  }
  const name=option('--name');
  if(name) {
    const personal=path.join(root,'_bmad/custom/config.user.toml');
    if(writeMissing(personal,Buffer.from(`[core]\nuser_name = ${JSON.stringify(name)}\n`)))console.log('Created ignored personal BMAD name override.');
    else console.log('Existing personal override retained; edit _bmad/custom/config.user.toml if your name needs changing.');
  }
  if(args.includes('--hooks')) {
    const hooked=spawnSync('git',['config','--local','core.hooksPath','.githooks'],{cwd:root,encoding:'utf8'});
    if(hooked.status!==0)throw Error(`Cannot enable local commit-message hook: ${hooked.stderr}`);
  }
}
const missing=skills.filter(s=>!fs.existsSync(path.join(root,s.path)) || !fs.existsSync(path.join(target,s.canonicalId,'SKILL.md'))).map(s=>s.canonicalId);
const uv=spawnSync('uv',['--version'],{encoding:'utf8'});
console.log(JSON.stringify({version:lock.version,skills:skills.length,skillsDirectory:relativeTarget,installedFiles,missing,uv:uv.status===0?uv.stdout.trim():'MISSING: install uv and ensure it is on PATH; BMAD build cannot run without it',python:'uv-managed Python >=3.11; renderer script declares this requirement',notice:'Existing runtime/skill files are preserved. Coordinate changes or upgrades rather than overwriting local customizations.'},null,2));
if(missing.length || uv.status!==0)process.exitCode=1;
