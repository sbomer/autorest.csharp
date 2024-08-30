$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$autoRestBinary = "npx --no-install autorest"
$AutoRestPluginProject = Resolve-Path (Join-Path $repoRoot 'src' 'AutoRest.CSharp')

function Invoke($command, $executePath=$repoRoot)
{
    write-host "------------------ INSIDE Invoke command $command ------------------ in dir $executePath"
    Write-Host "> $command"
    Push-Location $executePath
    if ($IsLinux -or $IsMacOs)
    {
        sh -c "$command 2>&1"
    }
    else
    {
        cmd /c "$command 2>&1"
    }
    Pop-Location
    
    if($LastExitCode -ne 0)
    {
        Write-Error "Command failed to execute: $command"
    }
    write-host "----------------- DONE invoke command -----"
}

function Invoke-AutoRest($baseOutput, $projectName, $autoRestArguments, $sharedSource, $fast, $debug)
{
    write-host "---------- INSIDE Invoke-AutoRest $projectName, baseoutput $baseOutput ----------"
    $outputPath = $baseOutput
    if(Test-Path "$outputPath/*.sln") {
        $outputPath = Join-Path $outputPath "src"
    }

    $outputPath = Join-Path $outputPath "Generated"
    if ($projectName -eq "TypeSchemaMapping")
    {
        $outputPath = Join-Path $baseOutput "SomeFolder" "Generated"
    }

    if ($fast)
    {
        $dotnetArguments = $debug ? "--no-build --debug" : "--no-build" 
        $command = "dotnet run --project $script:AutoRestPluginProject $dotnetArguments --standalone $outputPath"
    }
    else
    {
        $namespace = $projectName.Replace('-', '_')
        $command = "$script:autoRestBinary $autoRestArguments  --skip-upgrade-check  --namespace=$namespace --output-folder=$outputPath"
    }

    Invoke $command
    $buildDir = $baseOutput
    if($buildDir.EndsWith("src")) {
        $buildDir = $buildDir -replace ".{4}$"
    }
    Invoke "dotnet build $buildDir --verbosity quiet /nologo"
}

function AutoRest-Reset()
{
    Invoke "$script:autoRestBinary --reset"
}

function Invoke-TypeSpec($baseOutput, $projectName, $mainFile, $arguments="", $sharedSource="", $fast="", $debug="")
{
    if (!(Test-Path $baseOutput)) {
        New-Item $baseOutput -ItemType Directory
    }

    $baseOutput = Resolve-Path -Path $baseOutput
    $baseOutput = $baseOutput -replace "\\", "/"
    $outputPath = $baseOutput

    if(Test-Path "$outputPath/*.sln") {
        $outputPath = "$outputPath/src"
    }

    if ($fast)
    {
        $outputPath = Join-Path $baseOutput "Generated"
        $dotnetArguments = $debug ? "--no-build --debug" : "--no-build" 
        Invoke "dotnet run --project $script:AutoRestPluginProject $dotnetArguments --standalone $outputPath"
    }
    else
    {
        # emit typespec json
        $repoRootPath = Join-Path $PSScriptRoot ".."
        $repoRootPath = Resolve-Path -Path $repoRootPath
        Push-Location $repoRootPath
        $autorestCsharpBinPath = Join-Path $repoRootPath "artifacts/bin/AutoRest.CSharp/Debug/net8.0/AutoRest.CSharp.dll"
        Try
        {
            $typespecFileName = $mainFile ? $mainFile : "$baseOutput/$projectName.tsp"
            $emitCommand = "npx tsp compile $typespecFileName --trace @azure-tools/typespec-csharp --emit @azure-tools/typespec-csharp --option @azure-tools/typespec-csharp.emitter-output-dir=$outputPath --option @azure-tools/typespec-csharp.csharpGeneratorPath=$autorestCsharpBinPath $arguments"
            Invoke $emitCommand $outputPath
        }
        Finally 
        {
            Pop-Location
        }        
    }

    $buildDir = $baseOutput
    if($buildDir.EndsWith("src")) {
        $buildDir = $buildDir -replace ".{4}$"
    }
    Invoke "dotnet build $buildDir --verbosity quiet /nologo"
    write-host "----------------- DONE Invoke-TypeSpec -----"
}

function Invoke-TypeSpecSetup()
{
    write-host "------------------ INSIDE Invoke-TypeSpecSetup ------------------"
    # build emitter
    $emitterPath = Join-Path $PSScriptRoot ".." "src" "TypeSpec.Extension" "Emitter.Csharp"
    $emitterPath = Resolve-Path -Path $emitterPath
    Push-Location $emitterPath

    Try 
    {
        write-host " ------------- running command npm run build ----- in dir ------ $emitterPath"
        npm run build
    }
    Finally 
    {
        Pop-Location
    }
    write-host "----------------- DONE Invoke-TypeSpecSetup -----"
}

function Get-AutoRestProject()
{
    $AutoRestPluginProject;
}

Export-ModuleMember -Function "Invoke"
Export-ModuleMember -Function "Invoke-AutoRest"
Export-ModuleMember -Function "AutoRest-Reset"
Export-ModuleMember -Function "Get-AutoRestProject"
Export-ModuleMember -Function "Invoke-TypeSpec"
Export-ModuleMember -Function "Invoke-TypeSpecSetup"
