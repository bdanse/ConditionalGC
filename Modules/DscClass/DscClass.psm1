enum Ensure {
    Absent
    Present
}

enum OSLabel {
    WS2008 = 6003 # Not supported anymore
    WS2008R2 = 7601 # Not supported anymore
    WS2012 = 9200
    WS2012R2 = 9600
    WS2016 = 14393
    WS2019 = 17763
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

    [DscProperty(NotConfigurable)]
    [string[]]$AllowedOS = @()

    [DscProperty(NotConfigurable)]
    [string]$CurrentOS

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
        $this.GetCurrentOS()
        $get = $this
        if (!($this.AllowedOS -contains $this.CurrentOS)) {
            $this.Reason += @{
                Code   = 'GC_DscClass:GC_DscClass:OSFilter'
                Phrase = 'OsFilter {0} does not contain current OS {1}' -f $this.CurrentOs, ($this.AllowedOS -join ",")
            }
        }
        else {
            # Call to base class Get
            $get = ([GC_DscClass]([DscClass]$this).Get())
        }
        $get.Ensure = $this.Ensure
        $get.AllowedOS = $this.AllowedOS
        $get.CurrentOS = $this.CurrentOS
        $get.OsFilterYml = $this.OsFilterYml

        return $get

    }

    # Sets the desired state of the resource.
    [void] Set() {
        throw 'not implemented'
    }

    # Tests if the resource is in the desired state.
    [bool] Test() {
        $get = $this.Get()
        if ($get.AllowedOS -contains $get.CurrentOS) {
            return $get.Status
        }
        else {
            return $true
        }

        #return ([DscClass]$this).Test()
    }

    [void] ConvertOsFilterYmlContentToStringArray() {
        $OsArray = $this.OsFilterYml -replace 'OSVersion:\s*\[|^\[|\]$'
        $this.AllowedOS = $OsArray -split "\s*,\s"
        $this.AllowedOS | OUT-File -FilePath C:\Users\admbada\Code\local\Concept\Output.txt -Force
    }

    [void] GetCurrentOS() {
        $osVersion = [System.Environment]::OSVersion
        $this.CurrentOS = [OSLabel].GetEnumName($osVersion.Version.Build)
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
    }

}
