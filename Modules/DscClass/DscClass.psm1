enum Ensure {
    Absent
    Present
}

enum OSLabel {
    WS2008 = 6003 # No support
    WS2008R2 = 7601 # No support
    WS2012 = 9200 # No support
    WS2012R2 = 9600
    WS2016 = 14393
    WS2019 = 17763
}

enum ProductType {
    DomainController = 2
    Server = 3
    Unknown = 0
    WorkStation = 1
}

class Reason {
    [DscProperty()]
    [string] $Code

    [DscProperty()]
    [string] $Phrase
}

[DscResource()]
class DscClass {

    [DscProperty(Key)]
    [string] $Path

    [DscProperty(Mandatory)]
    [Ensure] $Ensure

    [DscProperty(NotConfigurable)]
    [Reason[]] $Reason

    [DscProperty(NotConfigurable)]
    [bool] $Status

    # Gets the resource's current state.
    [DscClass] Get() {
        $currentState = Get-State -Path $this.Path -Ensure $this.Ensure
        return $currentState
    }

    # Sets the desired state of the resource.
    [void] Set() {
        throw 'not implemented'
    }

    # Tests if the resource is in the desired state.
    [bool] Test() {
        return [bool]($this.Get().Status)
    }
}

[DscResource()]
class GC_DscClass : DscClass {
    [DscProperty()]
    [string] $OsFilterYml = 'OSVersion: [Unknown]'

    [DscProperty()]
    [string] $ServerTypeFilterYml = 'ServerType: [Unknown]'

    [DscProperty(NotConfigurable)]
    [string[]]$AllowedOS = @()

    [DscProperty(NotConfigurable)]
    [string[]]$AllowedServerTypes = @()

    [DscProperty(NotConfigurable)]
    [bool]$ShouldProcess


    GC_DscClass() {

    }

    # Attributes returned by base class need to be mapped back to parent class.
    # Else they will not show in result
    GC_DscClass([DscClass]$Base) {
        $this.Path = $Base.Path
        $this.Ensure = $Base.Ensure
        $this.Reason = $Base.Reason
        $this.Status = $Base.Status
    }


    # Gets the resource's current state.
    [GC_DscClass] Get() {

        $this.ConvertOsFilterYmlContentToStringArray()
        $this.ConvertServerTypeYmlContentToStringArray()

        $this.ShouldProcess = $true

        $conditions = @()
        $conditions += Test-DscRuntimePlatform
        $conditions += Test-DscRuntimeOS -AllowedOSVersions $this.AllowedOS
        $conditions += Test-DscRuntimeServerType -AllowedServerTypes $this.AllowedServerTypes

        foreach ($condition in $conditions) {
            if ($condition.Status -ne $true) {
                $this.Reason += $condition.Reason
                $this.ShouldProcess = $false
            }
        }

        if($this.ShouldProcess) {
            # Call to base class Get
            $get = ([GC_DscClass]([DscClass]$this).Get())
        }
        else {
            $get = $this
        }

        $get.ShouldProcess = $this.ShouldProcess
        $get.AllowedOS = $this.AllowedOS
        $get.AllowedServerTypes = $this.AllowedServerTypes
        $get.OsFilterYml = $this.OsFilterYml
        $get.ServerTypeFilterYml = $this.ServerTypeFilterYml

        return $get

    }

    # Sets the desired state of the resource.
    [void] Set() {
        throw 'not implemented'
    }

    # Tests if the resource is in the desired state.
    [bool] Test() {
        $get = $this.Get()
        if ($get.ShouldProcess) {
            return $get.Status
        }
        else {
            return $true
        }

        #return ([DscClass]$this).Test()
    }

    [void] ConvertOsFilterYmlContentToStringArray() {
        $commaDelimited = $this.OsFilterYml -replace 'OSVersion:\s*\[|^\[|\]$'
        $this.AllowedOS = $commaDelimited -split "\s*,\s"
    }

    [void] ConvertServerTypeYmlContentToStringArray() {
        $commaDelimited = $this.ServerTypeFilterYml -replace 'ServerType:\s*\[|^\[|\]$'
        $this.AllowedServerTypes = $commaDelimited -split "\s*,\s"
    }
}

function Get-State {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Ensure
    )

    Write-Debug "Entering Get-State"

    $reasons = @()
    $fileExists = Test-Path -Path $Path

    if (($fileExists -and $Ensure -eq 'Present') -or (!$fileExists -and $Ensure -eq 'Absent')) {
        $status = $true
    }
    else {
        $status = $false
        $reasons += @{
            Code   = 'DscClass:DscClass:FileExists'
            Phrase = 'Explain why the setting is not compliant'
        }
    }

    # Return this instance or construct a new instance.
    return @{
        Status = $status
        Path   = $Path
        Reason = $reasons
        Ensure = $Ensure
    }

}

function Test-DscRuntimePlatform {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter()]
        [string[]]
        $AllowedPlatforms = 'Windows'
    )

    If('Windows' -in $AllowedPlatforms -and $IsWindows -eq $true) {
        $result = $IsWindows
    }

    if($result -eq $false) {
        $reason = @{
            Code   = 'GC_DscClass:GC_DscClass:RuntimePlatformNotMatched'
            Phrase = 'Current OS platform is supported'
        }
    }
    return @{
        Status = $result
        Reason = $reason
    }
}

function Get-DscRuntimeOS {
    [CmdletBinding()]
    [OutputType([string])]
    param (
    )

    $osVersion = [System.Environment]::OSVersion
    return [OSLabel].GetEnumName($osVersion.Version.Build)
}

function Test-DscRuntimeOS {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter()]
        [string[]]
        $AllowedOSVersions
    )

    $result = ((Get-DscRuntimeOS) -in $AllowedOSVersions )
    if ($result -eq $false) {
        $reason = @{
            Code   = 'GC_DscClass:GC_DscClass:RuntimeOSNotMatched'
            Phrase = 'Current OS is not matched with OSFilter'
        }
    }
    return @{
        Status = $result
        Reason = $reason
    }
}

function Get-DscRuntimeServerType {
    [CmdletBinding()]
    [OutputType([string])]
    param (
    )

    $cimComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
    $cimOperatingSystem = Get-CimInstance -ClassName Win32_OperatingSystem
    $ProductType = [ProductType].GetEnumName($cimOperatingSystem.ProductType)
    if ($ProductType -eq [ProductType]::DomainController) {
        $result = 'Domain Controller'
    }
    else {
        if ($cimComputerSystem.PartOfDomain -eq $true) {
            $result = 'Domain Member'
        }
        else {
            $result = 'Workgroup Member'
        }
    }

    return $result
}

function Test-DscRuntimeServerType {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter()]
        [string[]]
        $AllowedServerTypes
    )

    $result = ((Get-DscRuntimeServerType) -in $AllowedServerTypes )
    if ($result -eq $false) {
        $reason = @{
            Code   = 'GC_DscClass:GC_DscClass:RuntimeOSNotMatched'
            Phrase = 'Current ServerType is not matched with ServerTypeFilter'
        }
    }
    return @{
        Status = $result
        Reason = $reason
    }
}
