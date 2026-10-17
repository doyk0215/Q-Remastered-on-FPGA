// Included inside numerical modules. All callers widen before invoking.
function signed [127:0] q_rne_shift;
 input signed [127:0] value;
 input integer shift;
 reg signed [127:0] base;
 reg [127:0] residue, halfway;
 begin
  // Euclidean remainder relative to the signed floor works for both signs:
  // -1.5 -> floor -2 (even), -0.5 -> floor -1 (odd) -> 0.
  base=value>>>shift; residue=$unsigned(value)&((128'd1<<shift)-1); halfway=128'd1<<(shift-1);
  if(shift>0 && (residue>halfway || (residue==halfway && base[0]))) base=base+1;
  q_rne_shift=base;
 end
endfunction
