$file = "$pwd\start.ps1"

# Configuration GC_Policy {
#     Import-DscResource -ModuleName DscClass
#     Node localhost {
#         DscClass RefName {
#             Path   = $file
#             Ensure = 'Present'
#             #OsFilter = 'OSVersion: [WS2019, WS2016]'
#         }
#     }
# }
# GC_Policy -OutputPath .\MOF
# New-GuestConfigurationPackage -Name GC_Policy -Configuration .\MOF\localhost.mof
# Test-GuestConfigurationPackage -Path .\GC_Policy\GC_Policy.zip


Invoke-DscResource -Name DscClass -ModuleName DscClass -Method Get -Property @{
    Path   = "$pwd\start.ps1"
    Ensure = 'Present'
} -Debug

Invoke-DscResource -Name DscClass -ModuleName DscClass -Method Test -Property @{
    Path   = "$pwd\start.ps1"
    Ensure = 'Present'
} -Debug

Invoke-DscResource -Name GC_DscClass -ModuleName DscClass -Method Get -Property @{
    Path   = "$pwd\start.ps1"
    Ensure = 'Present'
    OsFilterYml = 'OSVersion: [WS2019, WS2016]'
} -Debug

Invoke-DscResource -Name GC_DscClass -ModuleName DscClass -Method Test -Property @{
    Path   = "$pwd\start.ps1"
    Ensure = 'Present'
    OsFilterYml = 'OSVersion: [WS2019, WS2016]'
} -Debug
