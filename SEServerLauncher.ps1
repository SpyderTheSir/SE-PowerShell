param (
    [string]$mapPath = "C:\SpaceEngineers\Worlds\Jupiter\Saves\Map",
    [string]$steamCMD = "C:\SteamCMD",
	[string]$SEInstallPath = "C:\SpaceEngineers",
    [string]$startArgs = @("autosave=10", "autostart", "nowcf"),
    [switch]$cantStopTheMagic = $false,
    [string]$backupsPath = "C:\CloudBackups",
    [int]$serverPort = 27016, #Set to 0 to skip connection test, or to the port your server is running on
    [int64]$memTest = 3221225472, #Set to 0 to skip memtest, or to the value the server proccess can not exceed
    [int]$launchDelay = 120, #Delay after launch to allow server to come online properly
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
	    Write-Output "$(timeStamp) Server process launched, PID: $ProcessID.. Starting Launch Delay."
        Start-Sleep -Seconds $launchDelay
	    Write-Output "$(timeStamp) Launch Delay completed."
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
        Start-Process -FilePath $7zipExe -ArgumentList @("a", "$backupsPath\Daily-$(Get-Date -f yyyy-MM-dd).7z", $mapPath) -RedirectStandardOutput "$backupsPath\Latest7zip.log" -NoNewWindow -Wait
    } else {
        Write-Output "$(timeStamp) Server performing snapshot backup.."
        Start-Process -FilePath $7zipExe -ArgumentList @("a", "$backupsPath\$(Get-Date -f yyyy-MM-dd@HHmmss).7z", $mapPath) -RedirectStandardOutput "$backupsPath\Latest7zip.log" -NoNewWindow -Wait
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
        if ($memTest -gt 0) { #do server memory test
	        if ($ServerActive.WorkingSet64 -gt $memTest) { #Check for excessive memory usage
	            Write-Output "$(timeStamp) Server over 3GB of memory usage."
                stopSE
                updateSE
	            startSE
	        } else {
	            Write-Output "$(timeStamp) Server memory usage passed tests. Usage is $([int]$($ServerActive.WorkingSet64 /1024/1024))MB."
            }
        }
        if ($serverPort -gt 0) { #do connection test

            $udpobject = new-Object system.Net.Sockets.Udpclient #Create object for connecting to port
            $udpobject.client.ReceiveTimeout = 100 #Set a timeout on receiving message, as it's localhost this can be quite low.
            $udpobject.Connect("localhost",$serverPort) #Connect to servers machine's port
            $a = new-object system.text.asciiencoding
            $byte = $a.GetBytes("$(Get-Date)") 
            [void]$udpobject.Send($byte,$byte.length)  #Sends the date to the SE server. 
            #We're not expecting a response from sending the date to the SE Server, but we have to handle it if it happens
            $remoteendpoint = New-Object system.net.ipendpoint([system.net.ipaddress]::Any,0) 

            Try { 
                #Blocks until a message returns on this socket from a remote host or timeout occurs.
                $receivebytes = $udpobject.Receive([ref]$remoteendpoint) 
                [string]$returndata = $a.GetString($receivebytes)
                If ($returndata) {
                    Write-Output "Server is online, Received response from UDP port $serverPort" 
                    $udpobject.close()   
                }                       
            } Catch { 
                If ($Error[0].ToString() -match "\bRespond after a period of time\b") { 
                    $udpobject.Close()
                    #We won't get false positives as this is being run from the localhost, so if we haven't 'forcibly closed' by now the port is up
                    Write-Output "Server is online, Received response from UDP port $serverPort" 
                } ElseIf ($Error[0].ToString() -match "forcibly closed by the remote host" ) { 
                    $udpobject.Close()
                    #Well, the server shut the port on us, that mean's it's online but there is no Space Engineers listening :(
                    Write-Output "Server is offline! UDP port $serverPort refused by server"
                    stopSE #attempt to kill process as it's probably crashed
                    startSE #no update, this was a crash, lets get back up and running ASAP
                } Else {
                    #We should never get here...      
                    $udpobject.close() 
                } 
            }
            
        }
        if ((Get-date).Hour -eq 6 -and ((Get-Date).Minute -lt 10 -and (Get-Date).Minute -gt 0)) { # 6am Maintenance
            stopSE
            backupSE daily
            updateSE
            startSE
        }
    }
    $count++
    if ($count -eq 6) { # Snapshot every 30 mins
        backupSE
        $count = 0
    }
    Start-Sleep -Seconds 300 #Wait 5 minutes
}