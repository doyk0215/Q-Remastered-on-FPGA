"""Exact integer oracle for HDL tests; artifacts are written only under build/."""
from pathlib import Path
import random
import math
import hashlib

root = Path(__file__).resolve().parents[2]
out = root / 'build' / 'story3'
out.mkdir(parents=True, exist_ok=True)
rng = random.Random(33017)

def rne(n, d):
    sign = -1 if n < 0 else 1
    q, r = divmod(abs(n), d)
    return sign * (q + (2*r > d or (2*r == d and q % 2)))

def pack(fields):
    word = 0
    for value, bits in fields:
        word = (word << bits) | (value & ((1 << bits)-1))
    return word

def stroke(points, count=None):
    word = len(points) if count is None else count
    word |= 512 << 4
    for i, (x, y) in enumerate(points):
        word |= (x & 0x3ffff) << (22 + i*36)
        word |= (y & 0x3ffff) << (40 + i*36)
    return word

def lengths(points):
    return [math.isqrt((b[0]-a[0])**2+(b[1]-a[1])**2) for a,b in zip(points, points[1:])]

paths = [[], [(0,0)], [(0,0),(1023,0)], [(0,0),(1024,0)], [(0,0),(1025,0)],
         [(0,0),(0,0),(1024,0)], [(0,0),(1024,0),(0,0)],
         [(-131072,-131072),(131071,131071)]]
for _ in range(120):
    paths.append([(rng.randrange(-131072,131072),rng.randrange(-131072,131072)) for _ in range(rng.randrange(2,9))])
path_words = [pack([(stroke(p),310),(sum(lengths(p)),24),(any(lengths(p)),1),(0,1)]) for p in paths]
path_words.append(pack([(stroke([(0,0),(1024,0)],9),310),(0,24),(0,1),(1,1)]))
(out/'length_vectors.mem').write_text(''.join(f'{w:084x}\n' for w in path_words))

shapes = [[(0,0),(1024,0)], [(-1024,-1024),(0,-1024)],
          [(0,0),(1024,0),(0,0)], [(0,0),(0,0),(1024,0)],
          [(0,0),(639*64,479*64)]*4]
for _ in range(35):
    shapes.append([(rng.randrange(640)*64,rng.randrange(480)*64) for _ in range(rng.randrange(2,9))])
shapes += [[(0,0),(a,0),(1024,b)] for a in (1,3) for b in (-1,1)]
body_words = []
transforms = []
sine_path = root/'rtl/physics/q_sine_q16.mem'
assert hashlib.sha256(sine_path.read_bytes()).hexdigest() == 'a4403745ef38325f06470f0d21f78775c74957b77cc7f798964f3aeba02dfec1', 'sine ROM provenance/hash changed'
sine = [int(line,16) for line in sine_path.read_text().splitlines()]
sine = [v-(1<<18) if v&(1<<17) else v for v in sine]
for p in shapes:
    ls=lengths(p); length=sum(ls); mass=length<<4
    cx=rne(sum(l*(a[0]+b[0])*1024 for l,a,b in zip(ls,p,p[1:])),2*length)
    cy=rne(sum(l*(a[1]+b[1])*1024 for l,a,b in zip(ls,p,p[1:])),2*length)
    if len(p)==3 and p[0]==(0,0) and p[-1][0]==1024 and abs(p[-1][1])==1:
        assert cy == (1 if p[-1][1]>0 else -1)*(512 if p[1][0]==1 else 510), "directed odd/even COM tie"
    local=[(x*1024-cx,y*1024-cy) for x,y in p]
    local_word=sum((x&0xffffffff)<<(32*i) | (y&0xffffffff)<<(256+32*i) for i,(x,y) in enumerate(local))
    moment=sum((l<<4)*(a[0]*a[0]+a[0]*b[0]+b[0]*b[0]+a[1]*a[1]+a[1]*b[1]+b[1]*b[1]) for l,a,b in zip(ls,local,local[1:]))
    inertia=max(rne(moment,3<<32),4096)
    extent=max(math.isqrt(x*x+y*y)+(math.isqrt(x*x+y*y)**2 != x*x+y*y)+(512<<10) for x,y in local)
    body_words.append(pack([(stroke(p),310),(length,24),(mass,32),(cx<<8,48),(cy<<8,48),(local_word,512),(extent,32),(inertia,64),(rne(1<<48,mass),48),(rne(1<<48,inertia),48)]))
    for phase in [0,1<<30,rng.randrange(1<<32)]:
        def trig(phase):
            index=phase>>20;fraction=phase&0xfffff
            return rne(sine[index]*(1<<20)+(sine[(index+1)%4096]-sine[index])*fraction,1<<20)
        s=trig(phase);c=trig((phase+(1<<30))&0xffffffff)
        result=[]
        for x,y in local:
            xq=rne(rne(c*x-s*y,256)+(cx<<8),1<<18)
            yq=rne(rne(s*x+c*y,256)+(cy<<8),1<<18)
            result.append((xq,yq))
            theta=phase/(1<<32)*2*math.pi
            exact_x=(cx+x*math.cos(theta)-y*math.sin(theta))/65536
            exact_y=(cy+x*math.sin(theta)+y*math.cos(theta))/65536
            assert math.hypot(xq/64-exact_x,yq/64-exact_y)<0.0625
        transforms.append(pack([(len(p),4),(512,18),(local_word,512),(cx<<8,48),(cy<<8,48),(phase,32),(stroke(result),310)]))
# Directed maximum-extent rotation and exact signed-Q6 output endpoints.
for local, center, phase in [([(-(1016<<16),0),(1016<<16,0)],(0,0),0x20000000),
                              ([(0,0),(0,0)],(131071<<18,-131072<<18),0),
                              ([(0,0),(0,0)],(-131072<<18,131071<<18),0)]:
    word=sum((x&0xffffffff)<<(32*i) | (y&0xffffffff)<<(256+32*i) for i,(x,y) in enumerate(local))
    sn=trig(phase);cs=trig((phase+(1<<30))&0xffffffff)
    result=[(rne(rne(cs*x-sn*y,256)+center[0],1<<18),rne(rne(sn*x+cs*y,256)+center[1],1<<18)) for x,y in local]
    transforms.append(pack([(2,4),(512,18),(word,512),(center[0],48),(center[1],48),(phase,32),(stroke(result),310)]))
phases=sorted(set([0x00280000,0x40280000,0x80280000,0xc0280000,0xffffffff]+[(boundary+delta)&0xffffffff for boundary in (0,1<<30,1<<31,3<<30) for delta in (-1,0,1)]))
assert trig(0x00280000)==252 and trig(0x80280000)==-252
assert trig((0xc0280000+(1<<30))&0xffffffff)==252
(out/'trig_vectors.mem').write_text(''.join(f'{pack([(phase,32),(trig(phase),18),(trig((phase+(1<<30))&0xffffffff),18)]):017x}\n' for phase in phases))

def limiter(x,y,vx,vy,w,phase,extent,ball):
    # Exact integer reference: independently recompute every conservative bound.
    vy+=1179648
    attempts=0
    while True:
        rotational=(abs(w)*extent+65535)//65536
        norm2=vx*vx+vy*vy; norm=math.isqrt(norm2)+(math.isqrt(norm2)**2!=norm2)
        demand=norm+(0 if ball else rotational)
        angular=ball and rotational>134217728
        if not angular and demand<=113246208: break
        assert attempts<2
        factor=((134217728-1024 if angular else 113246208-2048)<<24)//(rotational if angular else demand)
        assert 0<factor<(1<<24)
        w=rne(w*factor,1<<24)
        if not angular: vx=rne(vx*factor,1<<24);vy=rne(vy*factor,1<<24)
        attempts+=1
    return x+rne(vx,2),y+rne(vy,2),vx,vy,w,(phase+rne(w*683565276,1<<25))&0xffffffff,demand
motion=[]
for ball in (0,1):
    for vx,vy,w,extent in [(134217728,-134217728,16777216,1024<<16),(-549755813888,134217728,-2147483648,1024<<16),(0,0,2147483647,12<<16),(0,0,8380640,1049573)]:
        args=(123456789,-987654321,vx,vy,w,0xfffffff0,extent,ball)
        expected=limiter(*args)
        motion.append(pack([(ball,1),(args[0],48),(args[1],48),(vx,40),(vy,40),(w,32),(args[5],32),(extent,32)]+list(zip(expected,(48,48,40,40,32,32,50)))))
(out/'motion_vectors.mem').write_text(''.join(f'{word:0141x}\n' for word in motion))
(out/'body_vectors.mem').write_text(''.join(f'{w:0292x}\n' for w in body_words))
(out/'transform_vectors.mem').write_text(''.join(f'{w:0243x}\n' for w in transforms))
bank_geometry = []
for body in range(1, 6):
    phase = (42722830 if body == 1 else -42722830 if body == 2 else 0) & 0xffffffff
    s = trig(phase)
    c = trig((phase+(1<<30)) & 0xffffffff)
    result = []
    for point in range(8):
        x = 524288 if point % 2 else -524288
        result.append((rne(rne(c*x,256)+((100+body*32)<<24),1<<18),
                       rne(rne(s*x,256)+(100<<24)+1769472,1<<18)))
    bank_geometry.append(stroke(result))
(out/'bank_geometry.mem').write_text(''.join(f'{w:078x}\n' for w in bank_geometry))
(out/'vector_counts.vh').write_text(f'`define LENGTH_CASES {len(path_words)}\n`define BODY_CASES {len(body_words)}\n`define TRANSFORM_CASES {len(transforms)}\n`define TRIG_CASES {len(phases)}\n`define MOTION_CASES {len(motion)}\n')
print(f'{len(path_words)} path, {len(body_words)} property, {len(transforms)} transform golden vectors')
