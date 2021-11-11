#$env:PSModulePath = $env:PSModulePath + ";" +
# $env:PSModulePath

# $r = Invoke-DscResource -Name GC_DscClass -ModuleName DscClass -Method Get -Property @{
#     Path   = "$pwd\start.ps1"
#     Ensure = 'Present'
#     OsFilterYml = 'OSVersion: [WS2019, WS2016]'
# } -Debug -Verbose
# $r

# $dscProperties = @{
#     Path   = "$PSScriptRoot\..\start.ps1"
#     Ensure = 'Present'
# }

# $r = Invoke-DscResource -Name GC_DscClass -ModuleName DscClass -Method Get -Property @{
#     Path   = "$pwd\start.ps1"
#     Ensure = 'Present'
#     OsFilterYml = 'OSVersion: [WS2019, WS2016]'
# } -Debug -Verbose
# $r

#$vscodeModule = ($env:PSModulePath -split ";") | Where-Object { $_ -match 'extensions\\ms-vscode.powershell-'}
$vscodeModule = 'C:\Users\admbada\Documents\PowerShell\Modules'
$junction = Join-Path -Path $vscodeModule -ChildPath 'DscClass'
if(-not(Test-Path $junction)){
    New-Item -Path $junction -ItemType Junction -Value $pwd\Modules\DscClass
}


Describe "DscClass" {
    BeforeAll {

        $resourceProperties = @{
            Path   = "$PSScriptRoot\..\start.ps1"
            Ensure = 'Present'
        }
    }

    It "DscClass Get should return Status True" {
        $r = Invoke-DscResource -Name DscClass -ModuleName DscClass -Method Get -Property $resourceProperties
        $r.Status | Should -Be $true
    }

    It "DscClass Test should return True" {
        $r = Invoke-DscResource -Name DscClass -ModuleName DscClass -Method Test -Property $resourceProperties
        $r | Should -Be $true
    }



}
