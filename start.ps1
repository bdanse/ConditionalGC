
# $env:PSModulePath = $env:PSModulePath + ";" + "$pwd\Modules"
# $env:PSModulePath
# #Import-module DscClasses -Verbose -Debug -Force
# Get-DscResource -Module DscClasses

# break

# Configuration PolicyDscClass {

#     Import-DscResource -ModuleName DscClass

#     Node localhost {
#         DscClass RefName {
#             Path   = 'C:\Users\admbada\Code\local\Concept\start.ps1'
#             Ensure = 'Present'
#             #OsFilter = 'OSVersion: [WS2019, WS2016]'
#         }
#     }
# }
# PolicyDscClass -OutputPath .\MOF

# New-GuestConfigurationPackage -Name PolicyDscClass -Configuration .\MOF\localhost.mof

#Test-GuestConfigurationPackage -Path .\PolicyDscClass\PolicyDscClass.zip


Invoke-DscResource -Name DscClass -ModuleName DscClass -Method Get -Property @{
    Path   = "$pwd\start.ps1"
    Ensure = 'Present'
}


Invoke-DscResource -Name DscClass -ModuleName DscClass -Method Test -Property @{
    Path   = "$pwd\start.ps1"
    Ensure = 'Present'
}

Invoke-DscResource -Name GC_DscClass -ModuleName DscClass -Method Get -Property @{
    Path   = "$pwd\start.ps1"
    Ensure = 'Present'
    OsFilterYml = 'OSVersion: [WS2019, WS2016]'
}
$r

Invoke-DscResource -Name GC_DscClass -ModuleName DscClass -Method Test -Property @{
    Path   = "$pwd\start.ps1"
    Ensure = 'Present'
    OsFilterYml = 'OSVersion: [WS2019, WS2016]'
}
