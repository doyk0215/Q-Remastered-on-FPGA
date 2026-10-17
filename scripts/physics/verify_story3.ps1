param([string]$VivadoBin = "", [string]$Python = "python", [switch]$SkipCadence)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
if (!$VivadoBin) {
    $vivadoCommand = Get-Command vivado -ErrorAction SilentlyContinue
    if (!$vivadoCommand) { throw 'Vivado is not on PATH. Supply -VivadoBin pointing to the Vivado 2025.2 bin directory.' }
    $VivadoBin = Split-Path $vivadoCommand.Source
}
& $Python (Join-Path $PSScriptRoot 'generate_vectors.py')
if ($LASTEXITCODE) { throw 'Vector generation failed' }
$outputDirectory = Join-Path $projectRoot 'build/story3'
Push-Location $outputDirectory
try {
    $rtl = @('../../rtl/common/q_isqrt.v','../../rtl/common/q_udiv_rne.v','../../rtl/common/q_path_length.v',
        '../../rtl/physics/q_body_properties.v','../../rtl/physics/q_sincos.v','../../rtl/physics/q_transform.v',
        '../../rtl/physics/q_integrate.v','../../rtl/physics/q_outer_tick.v','../../rtl/physics/q_motion_bank.v','../../rtl/physics/q_ball_properties.v','../../rtl/physics/q_extent_check.v')
    # Application RTL is deliberately parsed as Verilog-2001, benches as SV.
    & (Join-Path $VivadoBin 'xvlog.bat') --include ../../rtl/include --include ../../rtl/physics @rtl
    if ($LASTEXITCODE) { throw 'Verilog compilation failed' }
    & (Join-Path $VivadoBin 'xvlog.bat') --sv --include ../../rtl/include --include ../../rtl/physics --include . ../../sim/physics/tb_story3.sv ../../sim/physics/tb_cadence.sv ../../sim/physics/tb_arithmetic.sv
    if ($LASTEXITCODE) { throw 'Testbench compilation failed' }
    $benches = ,@('tb_story3','story3','PASS story3:')
    $benches += ,@('tb_arithmetic','arithmetic','PASS arithmetic:')
    if (!$SkipCadence) { $benches += ,@('tb_cadence','cadence','PASS cadence:') }
    foreach ($bench in $benches) {
        & (Join-Path $VivadoBin 'xelab.bat') $bench[0] -s $bench[1] -timescale 1ns/1ps
        if ($LASTEXITCODE) { throw "Elaboration failed: $($bench[0])" }
        $simulationLog = "$($bench[1]).log"
        & (Join-Path $VivadoBin 'xsim.bat') $bench[1] -runall -log $simulationLog
        if ($LASTEXITCODE) { throw "Simulation failed: $($bench[0])" }
        $simulationText = Get-Content -Raw $simulationLog
        if ($simulationText.Contains('Fatal:') -or !$simulationText.Contains($bench[2])) { throw "Missing pass marker or assertion failed: $simulationLog" }
    }
} finally { Pop-Location }
