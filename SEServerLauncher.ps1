param (
    [string]$mapPath = "C:\Users\Administrator.MEDIABOX\AppData\Roaming\SpaceEngineersDedicated\Saves\Map",
	[string]$SESEPath = "E:\Software\SpaceEngineers\Game\DedicatedServer64"
)

$ServerActive = Get-Process SEServerExtender -ErrorAction SilentlyContinue
if($ServerActive -eq $null) {
	Write-Output "Starting Server.."
	Start-Process -FilePath "$SESEPath\SeServerExtender.exe" -ArgumentList @("autosave=5", "autostart") -WorkingDirectory $SESEPath
} else {
	Write-Output "Server running, checking memory usage.."
	if ($ServerActive.WS -gt 3221225472) { #Exactly 3GB in bytes
	    Write-Output "Server over 3GB of memory usage, restarting."
		Taskkill /IM SeServerExtender.exe
	    Start-Process -FilePath "$SESEPath\SeServerExtender.exe" -ArgumentList @("autosave=5", "autostart") -WorkingDirectory $SESEPath
	} else {
	    Write-Output "Server looks good."
    }
}