"""Generate the owned 4096-entry Q16 sine ROM, RNE, with exact axis entries.

Use Decimal precision 100, a pinned 80-decimal-place pi and 50 Taylor terms
after reducing to [0,pi/2]. The first omitted term is below 1e-140; the pi
error dominates below 1e-79 before Q16 scaling. No platform libm dependence
or downloaded/third-party HDL/table data is used.
"""
from pathlib import Path
import hashlib
from decimal import Decimal, localcontext, ROUND_HALF_EVEN

root = Path(__file__).resolve().parents[2]
with localcontext() as context:
    context.prec = 100
    pi = Decimal('3.14159265358979323846264338327950288419716939937510582097494459230781640628620899')
    quarter = []
    for i in range(1025):
        x = pi * i / 2048
        term = total = x
        for k in range(1, 50):
            term = -term * x * x / ((2*k)*(2*k+1))
            total += term
        quarter.append(int((total * 65536).to_integral_value(rounding=ROUND_HALF_EVEN)))
    values = []
    for i in range(4096):
        j = i % 2048
        if j > 1024:
            j = 2048-j
        values.append(quarter[j] if i < 2048 else -quarter[j])
for i, value in {0: 0, 1024: 65536, 2048: 0, 3072: -65536}.items():
    values[i] = value
data = ''.join(f'{value & 0x3ffff:05x}\n' for value in values).encode('ascii')
path = root / 'rtl' / 'physics' / 'q_sine_q16.mem'
path.write_bytes(data)
print(f'{path}: sha256={hashlib.sha256(data).hexdigest()}')
