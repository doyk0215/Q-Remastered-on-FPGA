// Repair checkout newline conversion only when it restores the recorded hash.
// Validate every source first; never normalize unknown/content-modified input.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'hardware/source-manifest.json'), 'utf8'));
const sha = bytes => crypto.createHash('sha256').update(bytes).digest('hex');
const repairs = [];
for (const source of manifest.sources) {
  const target = path.resolve(root, source.path);
  if (!target.startsWith(root + path.sep)) throw new Error(`Out-of-project source: ${source.path}`);
  const bytes = fs.readFileSync(target);
  if (sha(bytes) === source.sha256) continue;
  const lf = Buffer.from(bytes.toString('utf8').replace(/\r\n/g, '\n'), 'utf8');
  const crlf = Buffer.from(lf.toString('utf8').replace(/\n/g, '\r\n'), 'utf8');
  const repaired = [lf, crlf].find(candidate => sha(candidate) === source.sha256);
  if (!repaired) throw new Error(`Content differs from approved source, refusing repair: ${source.path}`);
  repairs.push({ target, repaired, name: source.path });
}
for (const repair of repairs) fs.writeFileSync(repair.target, repair.repaired);
console.log(JSON.stringify({ sourcesChecked: manifest.sources.length, newlineRepairs: repairs.map(p => p.name) }, null, 2));
