param (
    [string]$mapPath = "C:\Users\Administrator.MEDIABOX\AppData\Roaming\SpaceEngineersDedicated\Saves\Map",
	[string]$SESEPath = "C:\games\SpaceEngineers\DedicatedServer64",
    [string]$startArgs = @("autosave=10", "autostart", "nowcf"),
    [switch]$cantStopTheMagic = $true                 #Switch this to false for testing and true for live script
)

function timeStamp {
    return ((Get-Date).ToString("yyyy-MM-dd hh:mm:ss"))
}

function startSE {
    $ServerActive = Get-Process SEServerExtender -ErrorAction SilentlyContinue
    if ($ServerActive -eq $null) {
	    Write-Output "$(timeStamp) Starting Server.."
	    #Start-Process -FilePath "$SESEPath\SeServerExtender.exe" -ArgumentList $startArgs -WorkingDirectory $SESEPath
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = "$SESEPath\SeServerExtender.exe"
        $pinfo.Arguments = $startArgs
        $pinfo.WorkingDirectory = $SESEPath
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $p.ProcessorAffinity=0x2
	    Write-Output "$(timeStamp) Server process launched.."
    } else {
	    Write-Output "$(timeStamp) Server is already started.."
    }        
}

function stopSE {
    $ServerActive = Get-Process SEServerExtender -ErrorAction SilentlyContinue
    if ($ServerActive -ne $null) {
	    Write-Output "$(timeStamp) Stopping Server.."
        while ($ServerActive -ne $null) {
	        Taskkill /IM SeServerExtender.exe
            Start-Sleep -Seconds 2
            $ServerActive = Get-Process SEServerExtender -ErrorAction SilentlyContinue
        }
	    Write-Output "$(timeStamp) Server stopped.."
    } else {
	    Write-Output "$(timeStamp) Server is already stopped.."
    }        
}

function updateSE {
	Write-Output "$(timeStamp) Updating Server.."
    Start-Process -FilePath C:\Scripts\UpdateSE.cmd -WorkingDirectory c:\scripts -Wait
}

while ($cantStopTheMagic) {
    $ServerActive = Get-Process SEServerExtender -ErrorAction SilentlyContinue
    if($ServerActive -eq $null) {
        updateSE
        startSE
    } else {
	    Write-Output "$(timeStamp) Server running, checking memory usage.."
	    if ($ServerActive.WorkingSet64 -gt 3221225472 -or $ServerActive.WorkingSet64 -lt 0) { #Exactly 3GB in bytes
	        Write-Output "$(timeStamp) Server over 3GB of memory usage."
            stopSE
            updateSE
	        startSE
	    } else {
	        Write-Output "$(timeStamp) Server memory usage passed tests. Usage is $([int]$($ServerActive.WorkingSet64 /1024/1024))MB."
        }
        if ((Get-date).Hour -eq 6 -and ((Get-Date).Minute -lt 10 -and (Get-Date).Minute -gt 0)) {
            # Time for a restart and an update check!
            stopSE
            updateSE
            startSE
        }
    }
    Start-Sleep -Seconds 600 #Wait 10 minutes
}