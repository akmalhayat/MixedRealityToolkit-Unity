param(
    # Path to Unity project
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateScript({Test-Path $_ -PathType ‘Container’})]
    $projectPath,
    $logRoot = "$PSScriptRoot/out/",
    # Path to Unity Executable
    [ValidateScript({[System.IO.File]::Exists($_) -and $_.EndsWith(".exe") })]
    $unityExePath = "C:\Program Files\Unity\Hub\Editor\2018.4.1f1\Editor\Unity.exe"
)
$dateStr = Get-Date -format "yyyy_MM_dd-HHmmss"
if (-not (Test-Path $logRoot))
{
    New-Item -ItemType Directory $logRoot
}
$logPath = "$logRoot\playmode_tests_log-$dateStr.log"
$testResultPath = "$logRoot\playmode_tests_result-$dateStr.xml"

$timer = [System.Diagnostics.Stopwatch]::StartNew()
Write-Host "Starting test run" -ForegroundColor Cyan
Write-Host "Writing test output to $logPath..."

# To output unity logs to console, use '-'
# https://docs.unity3d.com/Manual/CommandLineArguments.html
$args = @(
    "-runTests",
    "-testPlatform playmode"
    "-batchmode",
    "-editorTestsResultFile $testResultPath",
    "-logFile $logPath",
    "-projectPath $projectPath"
    )
    Write-Host $unityExePath $args
    $handle = Start-Process -FilePath $unityExePath -PassThru -ArgumentList $args
    
    Start-Sleep 1
    Start-Process powershell -ArgumentList @(
        "-command", 
        "Get-Content $logPath -Wait")

Write-Host
Write-Host "Opening new window to view test output..."
while (-not $handle.HasExited)
{
    Write-Host -NoNewLine "Test run time: $($timer.Elapsed)"
    Start-Sleep 5
}

Write-Host
Write-Host "Test completed! Results written to $testResultPath"
Write-Host
Write-Host "Test results:" -ForegroundColor Cyan
Write-Host "Total test run time: $($timer.Elapsed)"

[xml]$cn = Get-Content $testResultPath
$cnx = $cn["test-run"]
Write-Host "passed: $($cnx.passed) failed: $($cnx.failed)"
if ($cnx.failed -gt 0)
{
    Write-Host
    Write-Host "Failed tests:"
    $testcases = $cnx.GetElementsByTagName("test-case")
    foreach ($item in $testcases) {
        if($item.result -ne "Passed")
        {
            Write-Host "$($item.classname)::$($item.name)"
        }
    }
}
