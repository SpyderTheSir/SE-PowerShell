param (
    [string]$mapPath = "C:\SpaceEngineers\Worlds\Jupiter\Saves\Map",
    [string]$steamCMD = "C:\SteamCMD",
	[string]$SEInstallPath = "C:\SpaceEngineers",
    [string]$startArgs = @("autosave=10", "autostart", "nowcf"),
    [switch]$cantStopTheMagic = $false,
    [string]$backupsPath = "C:\CloudBackups",
    [string]$7zipExe = "C:\Program Files\7-Zip\7z.exe"
)


if ($env:PROCESSOR_ARCHITECTURE -eq "AMD64") {
    $SESEPath = "$SEInstallPath\DedicatedServer64"
} else {
    $SESEPath = "$SEInstallPath\DedicatedServer"
}

function timeStamp {
    return ((Get-Date).ToString("yyyy-MM-dd hh:mm:ss"))
}

function startSE {
    $ServerActive = Get-Process SEServerExtender -ErrorAction SilentlyContinue
    if ($ServerActive -eq $null) {
	    Write-Output "$(timeStamp) Starting Server.."
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = "$SESEPath\SeServerExtender.exe"
        $pinfo.Arguments = $startArgs
        $pinfo.WorkingDirectory = $SESEPath
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = $pinfo
        $p.Start() | Out-Null
        $p.ProcessorAffinity=0x2
        $ProcessID = $p.Id
	    Write-Output "$(timeStamp) Server process launched, PID: $ProcessID.."
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
    $updateArgs = @("+login anonymous", "+force_install_dir $SEInstallPath", "+app_update 298740", "+quit")
    Start-Process -FilePath "$steamCMD\steamcmd.exe" -WorkingDirectory $steamCMD -ArgumentList $updateArgs -Wait
}

function backupSE {
    if ($($args[0]) -eq "daily") {
        Write-Output "$(timeStamp) Server performing daily backup.."
        Start-Process -FilePath $7zipExe -ArgumentList @("a", "$backupsPath\Daily-$(Get-Date -f yyyy-MM-dd).7z", $mapPath) -RedirectStandardOutput "$backupsPath\Latest7zip.log" -NoNewWindow
    } else {
        Write-Output "$(timeStamp) Server performing snapshot backup.."
        Start-Process -FilePath $7zipExe -ArgumentList @("a", "$backupsPath\$(Get-Date -f yyyy-MM-dd@HHmmss).7z", $mapPath) -RedirectStandardOutput "$backupsPath\Latest7zip.log" -NoNewWindow
    }
}

$count = 0
while ($cantStopTheMagic) {
    $ServerActive = Get-Process SEServerExtender -ErrorAction SilentlyContinue
    if($ServerActive -eq $null) {
        updateSE
        startSE
    } else {
        Write-Output "$(timeStamp) Server running.."
	    Write-Output "$(timeStamp) Checking memory usage.."
	    if ($ServerActive.WorkingSet64 -gt 3221225472) { #Exactly 3GB in bytes
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
            backupSE daily
            updateSE
            startSE
        }
    }
    Start-Sleep -Seconds 300 #Wait 5 minutes
    $count++
    if ($count -eq 6) { # Snapshot every 30 mins
        backupSE
        $count = 0
    }
}