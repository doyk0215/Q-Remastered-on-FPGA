// Reference/design checks only. This is not HDL simulation or board acceptance.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
let checks = 0;
const check = (value, message) => { checks++; assert.ok(value, message); };
const same = (a, b, message) => { checks++; assert.deepEqual(a, b, message); };
const floorDiv = (n, d) => { assert(d > 0n); const q = n / d, r = n % d; return q - (r < 0n ? 1n : 0n); };
const ceilDiv = (n, d) => -floorDiv(-n, d);
const sqrt = n => {
  assert(n >= 0n); let lo = 0n, hi = n + 1n;
  while (hi - lo > 1n) { const m = (lo + hi) / 2n; if (m * m <= n) lo = m; else hi = m; }
  return lo;
};
const rne = (n, d) => {
  const sign = n < 0n ? -1n : 1n; n *= sign;
  const q = n / d, r = n % d;
  return sign * (q + (2n * r > d || (2n * r === d && q % 2n === 1n) ? 1n : 0n));
};
const length = points => points.slice(1).reduce((s, p, i) => {
  const dx = p[0] - points[i][0], dy = p[1] - points[i][1]; return s + sqrt(dx * dx + dy * dy);
}, 0n);
const vectors = [
  { name: 'minimum-horizontal', points: [[0n, 0n], [1024n, 0n]], expected: 1024n },
  { name: 'below-minimum', points: [[0n, 0n], [1023n, 0n]], expected: 1023n },
  { name: 'three-four-five', points: [[0n, 0n], [192n, 256n]], expected: 320n },
  { name: 'closed-backtracking', points: [[0n, 0n], [640n, 0n], [0n, 0n]], expected: 1280n },
  { name: 'duplicate-segment', points: [[0n, 0n], [0n, 0n], [1024n, 0n]], expected: 1024n },
  { name: 'floor-segments', points: [[0n, 0n], [1n, 1n], [2n, 2n]], expected: 2n },
];
for (const v of vectors) same(length(v.points), v.expected, v.name);
for (let n = 0n; n < 4096n; n++) { const s = sqrt(n); check(s * s <= n && (s + 1n) ** 2n > n, 'integer sqrt invariant'); }
for (const n of [0n, 1n, 3n, 5n, 7n, -1n, -3n, -5n, -7n]) same(rne(-n, 2n), -rne(n, 2n), 'symmetric RNE');
same(rne(1n, 2n), 0n, 'even zero tie'); same(rne(3n, 2n), 2n, 'even two tie');
same(rne(1n << 48n, 16384n), 4n << 32n, 'quarter-mass inverse');
same(rne(1n << 48n, 65536n), 1n << 32n, 'unit-mass inverse');
same((1024n << 4n), 16384n, 'length to quarter mass');
const dot = (a, b) => a[0] * b[0] + a[1] * b[1];
const sub = (a, b) => [a[0] - b[0], a[1] - b[1]];
const error = (a, b, c) => {
  const u = sub(b, a), v = sub(c, a), d = dot(v, v), t = dot(u, v);
  if (d === 0n || t <= 0n) return [dot(u, u), 1n];
  if (t >= d) { const w = sub(b, c); return [dot(w, w), 1n]; }
  return [(u[0] * v[1] - u[1] * v[0]) ** 2n, d];
};
function capture(reports) {
  let p = [];
  for (const current of reports) {
    const q = current.map(BigInt);
    if (!p.length) p = [q];
    else if (q[0] !== p.at(-1)[0] || q[1] !== p.at(-1)[1]) {
      if (p.length === 1) p.push(q);
      else { const u = sub(q, p.at(-2)); if (dot(u, u) < 4n) p[p.length - 1] = q; else p.push(q); }
      p = p.filter((v, i, all) => !i || v[0] !== all[i - 1][0] || v[1] !== all[i - 1][1]);
      if (p.length === 9) {
        let winner = 1, best = error(p[0], p[1], p[2]);
        for (let i = 2; i < 8; i++) { const e = error(p[i - 1], p[i], p[i + 1]); if (e[0] * best[1] < best[0] * e[1]) { winner = i; best = e; } }
        p.splice(winner, 1);
      }
    }
    check(p.length <= 8, 'published vertex bound');
    same(p[0], reports[0].map(BigInt), 'start protected'); same(p.at(-1), q, 'endpoint protected');
  }
  return p;
}
const slow = Array.from({ length: 80 }, (_, i) => [i, 20]);
check(capture(slow).length > 2, 'slow one-pixel motion must retain sampling');
same(capture(slow), capture(slow), 'deterministic simplifier');
capture([[5, 5], [5, 5], [15, 5], [15, 15], [5, 15], [5, 5]]);
capture(Array.from({ length: 160 }, (_, i) => [i % 80, (i * 7) % 90]));
const rects = {
  lobby: [[48,160,208,352], [240,160,400,352], [432,160,592,352]],
  active: [[12,12,44,44]],
  paused: [[192,168,448,216], [192,232,448,280], [192,296,448,344]],
  victory: [[192,208,448,256], [192,280,448,328]],
  final: [[192,240,448,288]],
};
const hit = (r, x, y) => x >= r[0] && x < r[2] && y >= r[1] && y < r[3];
for (const list of Object.values(rects)) {
  for (const r of list) {
    check(r[0] >= 0 && r[1] >= 0 && r[2] <= 640 && r[3] <= 480, 'screen bounds');
    check(hit(r, r[0], r[1]) && !hit(r, r[2], r[1]) && !hit(r, r[0], r[3]), 'half-open rectangle');
  }
  for (let i = 0; i < list.length; i++) for (let j = i + 1; j < list.length; j++) {
    const a = list[i], b = list[j]; check(a[2] <= b[0] || b[2] <= a[0] || a[3] <= b[1] || b[3] <= a[1], 'same-view controls disjoint');
  }
}
for (const [text, advance, width] of [['Stage 1',12,160], ['Back to Lobby',12,256], ['Stroke overlaps an object',12,544], ['Touch the left',6,96], ['Strokes left: 5',6,96]]) check(text.length * advance <= width, `text fit: ${text}`);
// Verify exact incremental signed edge division against direct floor division.
for (const [n0, delta, d] of [[-99n,13n,7n], [10n,-19n,11n], [-13n,-12n,3n], [0n,1n,17n]]) {
  let q = floorDiv(n0,d), r = n0 - q*d; const dq = floorDiv(delta,d), dr = delta-dq*d;
  for (let row = 0n; row < 96n; row++) {
    same(q, floorDiv(n0+row*delta,d), 'incremental floor edge'); check(r >= 0n && r < d, 'normalized edge remainder');
    q += dq; r += dr; if (r >= d) { q++; r -= d; }
  }
}
function interval(a,b,lo,hi) {
  if (a === 0n) return b >= lo && b <= hi ? [-1000000n,1000000n] : null;
  if (a < 0n) return interval(-a,-b,-hi,-lo);
  const l = ceilDiv(lo-b,a), h = floorDiv(hi-b,a); return l <= h ? [l,h] : null;
}
function capsuleSpans(a,b,r,y) {
  const result = [], v = sub(b,a), d = dot(v,v);
  for (const c of [a,b]) { const h = r*r-(y-c[1])**2n; if (h >= 0n) { const k = sqrt(h); const lo = ceilDiv(c[0]-k,64n), hi = floorDiv(c[0]+k,64n); if (lo <= hi) result.push([lo,hi]); } }
  if (d) {
    const k = sqrt(r*r*d);
    const t = interval(64n*v[0], (y-a[1])*v[1]-a[0]*v[0], 0n, d);
    const c = interval(64n*v[1], -a[0]*v[1]-(y-a[1])*v[0], -k,k);
    if (t && c) { const lo = t[0] > c[0] ? t[0] : c[0], hi = t[1] < c[1] ? t[1] : c[1]; if (lo <= hi) result.push([lo,hi]); }
  }
  return result;
}
function capsulePoint(a,b,r,p) {
  const v = sub(b,a), u = sub(p,a), d = dot(v,v), t = dot(u,v);
  if (d === 0n || t <= 0n) return dot(u,u) <= r*r;
  if (t >= d) { const w = sub(p,b); return dot(w,w) <= r*r; }
  return (u[0]*v[1]-u[1]*v[0])**2n <= r*r*d;
}
const capsules = [
  [[64n,64n],[512n,320n],128n], [[-32n,128n],[500n,128n],64n],
  [[128n,-80n],[128n,600n],96n], [[256n,256n],[256n,256n],128n],
  [[700n,500n],[-90n,-30n],64n], [[31n,65n],[515n,129n],65n],
];
for (const [a,b,r] of capsules) for (let y = -8n; y < 24n; y++) {
  const spans = capsuleSpans(a,b,r,64n*y);
  for (let x = -8n; x < 24n; x++) same(spans.some(s=>x>=s[0]&&x<=s[1]), capsulePoint(a,b,r,[64n*x,64n*y]), 'scanline/direct capsule coverage');
}
const ticks = Array.from({length:61},(_,k)=>Math.ceil(k*100000000/60));
const periods = ticks.slice(1).map((t,i)=>t-ticks[i]);
check(periods.every(n=>n===1666666||n===1666667), 'rational tick intervals'); same(ticks[60],100000000,'60 ticks per second');
same(20*480,9600,'words per bank'); same(Math.ceil(9600/1024)*2,20,'framebank BRAM allocation'); same(20+2+1+20+7,50,'aggregate BRAM reservation');
const rasterCycles = 9600+50*512+50*480*64+50*2*17*24+20480;
same(rasterCycles,1632480,'renderer arithmetic design budget'); check(rasterCycles < Math.min(...periods),'radius-eight target below shortest tick');
const coefficientError = (2*Math.PI/4096)**2/8 + 1/65536;
const twoPoseError = 2*(2*1024*coefficientError + Math.SQRT2/128 + 0.00001);
check(twoPoseError > 1/16 && twoPoseError < 1/8,'revised motion error reserve');
same(27/8+1/2+1/8,4,'substep motion allocations');
const draftConstants = new Map();
for (const header of ['q_ui_layout_draft.vh','q_numeric_params_draft.vh']) {
  const text = fs.readFileSync(path.join(root,'rtl/include',header),'utf8');
  for (const m of text.matchAll(/^`define\s+(Q_DRAFT_\w+)\s+(?:(?:\d+)'d)?(\d+)\s*$/gm)) draftConstants.set(m[1], Number(m[2]));
}
const constant = suffix => { const name = `Q_DRAFT_${suffix}`; check(draftConstants.has(name),`draft constant exists: ${name}`); return draftConstants.get(name); };
same(constant('INTEGRATION_BUDGET_Q6')+constant('CORRECTION_BUDGET_Q6')+constant('TRANSFORM_GUARD_Q6'),256,'draft header movement sum');
same(constant('TRANSFORM_GUARD_Q6'),8,'corrected draft motion guard');
same(constant('MASS_FLOOR_Q16'),65536/4,'draft mass floor'); same(constant('INERTIA_FLOOR_Q16'),65536/16,'draft inertia floor');
same(constant('BALL_INERTIA_Q16'),72*65536,'draft ball inertia'); same(constant('GRAVITY_SUBSTEP_Q24'),9*2**24/128,'exact substep gravity');
same(constant('UI_SAMPLE_DISTANCE_SQUARED'),4,'sampling threshold');
same([constant('UI_PAUSE_X0'),constant('UI_PAUSE_Y0'),constant('UI_PAUSE_X1'),constant('UI_PAUSE_Y1')],rects.active[0],'pause header matches proposed rectangle');
for (let i=0;i<3;i++) same([constant(`UI_STAGE${i}_X0`),constant('UI_STAGE_Y0'),constant(`UI_STAGE${i}_X1`),constant('UI_STAGE_Y1')],rects.lobby[i],'stage header matches proposed rectangle');
for (const [key,rect] of [['RESUME',rects.paused[0]],['RESET',rects.paused[1]],['PAUSED_LOBBY',rects.paused[2]],['NEXT',rects.victory[0]],['VICTORY_LOBBY',rects.victory[1]],['FINAL_LOBBY',rects.final[0]]]) same([constant('UI_BUTTON_X0'),constant(`UI_${key}_Y0`),constant('UI_BUTTON_X1'),constant(`UI_${key}_Y1`)],rect,'button header matches proposed rectangle');
const manifest = JSON.parse(fs.readFileSync(path.join(root,'hardware/source-manifest.json'),'utf8'));
for (const source of manifest.sources) same(crypto.createHash('sha256').update(fs.readFileSync(path.join(root,source.path))).digest('hex'),source.sha256,`source bytes: ${source.path}`);
const spec = '_bmad-output/specs/spec-q-remastered-on-fpga';
const docs = ['docs/parallel-development-plan.md','docs/story-ownership.md','docs/reviews/parallel-readiness-review.md','docs/parallel-start-checklist.md','docs/reviews/planning-validation-results.md', ...['core-wiring-proposal.md','numerical-design-proposal.md','input-ui-design-proposal.md','renderer-design-proposal.md','stories/2-render-coherent-buffered-vga-scenes.md','stories/3-implement-bounded-rigid-body-arithmetic-and-motion.md','stories/6-capture-mouse-gestures-and-the-visible-stroke-preview.md'].map(s=>`${spec}/${s}`)];
for (const doc of docs) {
  const text = fs.readFileSync(path.join(root,doc),'utf8');
  for (const m of text.matchAll(/\]\(([^)]+)\)/g)) if (!/^(https?:|#)/.test(m[1])) check(fs.existsSync(path.resolve(root,path.dirname(doc),m[1])),`local link: ${doc} -> ${m[1]}`);
}
const report = { classification: 'reference/design checks; no RTL or hardware acceptance', generatedAt: new Date().toISOString(), node: process.version, checks, status: 'PASS', sourceHashes: manifest.sources.length, rasterCyclesRadiusEight: rasterCycles, proposedTwoPoseErrorUpperPixels: twoPoseError, scope: ['length/sqrt/RNE/inverse reference vectors','endpoint-preserving simplifier invariants','UI bounds/borders/label widths','signed incremental edge division','exact scanline vs direct capsule membership','cadence/resource/motion arithmetic','approved source bytes','planning links'] };
fs.mkdirSync(path.join(root,'build'),{recursive:true});
fs.writeFileSync(path.join(root,'build/planning-validation.json'),JSON.stringify(report,null,2)+'\n');
fs.writeFileSync(path.join(root,'build/planning-reference-vectors.json'),JSON.stringify(vectors,(_,v)=>typeof v==='bigint'?v.toString():v,2)+'\n');
console.log(JSON.stringify(report,null,2));
