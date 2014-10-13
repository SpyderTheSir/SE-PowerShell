<#

    Spyder's Space Engineers World Editor Script
    ============================================
    
    DESCRIPTION:
    Turns things on! and off! (turn on InteriorLight)
    Delete things! (wipe Drill)
    Check for rule violations! (checkMaxAllowed Drill 36)
    Count things! (count Drill)
    Find things near X Y Z! (findThingsNear 100 100 100 500)
    Find things near Asteroids! (findThingsNearRoids 500) Thanks psycore!

    INFO:
    Without adjustment this script will not do anything!
    I normally use it within the PowerShell ISE so I can hit play, issue commands directly, then saveIt

    GENERAL USAGE:
    First, change the saveLocation below this comment block to suit your server's save path.
    Whenever a block type is expected, the variable is the xsi:type in the save XML file but with the 'MyObjectBuilder_' removed.
    Valid block values are all written in as examples in the ACTION section below and commented out

    COMMAND USAGE:
    Wipe Command. This deletes all of a given type of block in your map.
    Syntax:    wipe [Block Type] [Confirm}
    Example:   wipe MotorStator                         -Delete all Rotor bases, prompting for confirmation
               wipe MotorRotor $true                    -Delete all Rotor tops, without prompt

    Count Blocks Command. This counts all instances of a given Block Type.
    Syntax:    countBlocks [Block type]
    Example:   countBlocks Beacon                       -Count all beacons on your map, small and large ship
               countBlocks RadioAntenna                 -Count all Antennas on your map, small and large ship

    Check Max Allowed Command. This will check each Ship/Station for the given block, reporting if it is over the maximum and giving you the owners name of the first Drill.
    Syntax:    checkMaxAllowed [Block Type] [Maximum Allowed]
    Example:   checkMaxAllowed Drill 36                 -Return any ship/station with over 36 Drills, including player name
               checkMaxAllowed LargeMissileTurret 10    -Return and ship/station with over 10 Missile Turrets, including player name

    Turn On/Off Command. This turns on or off a given block type.
    Syntax:    turn [on/off] [Block Type]
    Example:   turn on InteriorLight                    -Turn on every InteriorLight in the world
               turn off Assembler                       -Turn off every Assembler in the world

    Finds Things Near Command. This will return the XML object of any ship/station within the provided distance of the provided coordinates. Does NOT return asteroids.
    Syntax:    findThingsNear [x coord] [y coord] [z coord] [search distance[
    Example:   findThingsNear 0 0 0 1000                -Return any ship/station within 1000m of 0,0,0
               findThingsNear -1000 1000 -1000 100      -Return any ship/station within 100m of -1000 1000 -1000

    Find Things Near Roids Command. This will return any ship/station with the stated distance of all Asteroids. Thanks Psycore!
                                    Note, This command does not take into account the asteroids size!
    Syntax:    findThingsNearRoids [distance]
    Example    findThingsNearRoids 100                   -Return any object within 100m of the zeropoint of all asteroids.
               findThingsNearRoids 1000                  -Return any object within 1000m of the zeropoint of all asteroids.

    Remove Junk Command. This will remove any cubegrids of any size that doesn't have a Beacon, Antenna, Piston Top, Rotor Top or Wheel (Piston Tops, Rotor Tops and wheels are seperate grids)
    Syntax:    removeJunk [command] [action]
    Example:   removeJunk list bad                       -Return a list of all cubegrids that will fail tests
               removeJunk list good                      -Return a list of all cubegrids that will pass tests
               removeJunk delete                         -Go thru each failed cubegrids and prompt for deletion
               removeJunk delete noconfirm               -Delete all failed cubegrids (Use with care, no prompts)

    Remove Floaters Command. This will remove all floating objects
    Syntax:    removeFloaters [confirm]
    Example:   removeFloaters $true                      -Removes all floating objects without prompt
    Example:   removeFloaters                            -Counts all floating objects and prompts for removal

    Refresh Roids command. This will replace the .vox files of asteroids that do not have items within the stated distance all all asteroids.
                                    Note, This command does not take into account the asteroids size!
                                    Note2, Make sure you have the backup roids saved in the folder specified below as $origLocation
    Syntax:    refreshRoids [distance]
    Example:   refreshRoids 500                          -Replaces all the asteroids that do not have anything within 500m of them

    Save it Command. This commits changes you have made to the save file.
    Syntax:    saveIt
    Example:   ....Really?!

    AUTOMATED USAGE
    Make sure you've change the filePath and configPath
    Scroll down the the section that says ACTIONS
    The # in front of the line denotes a powershell comment. Anything commented out will be ignored.
    Add the commands you wish to perform in here as per the usage section above, there are lots of examples to get you started
    Uncomment saveIt at the end of the Action section

    LICENSE/DISCLAIMER:
    It's mine. Adjust it if you want, don't claim it's yours.
    If it breaks your save file, you should have made a backup :)

    Caveats!
    - Backup your stuff!
    - Tested on Windows 8.1 and Server 2012 ONLY
    - Error reporting is minimal, but improving.
    - Backup your stuff!!

#>

Param(
    # I've changed how this works. Now you just need to point it to your entire save folder. It is assumed that all your .vx2, .sbc and .sbs files are in here
    [string]$saveLocation = "$env:APPDATA\SpaceEngineersDedicated\Saves\Map",
    [string]$origLocation = "$env:APPDATA\SpaceEngineersDedicated\Backups\Map\"
)

function wipe {
    $desc = $args[0]; $confirm = $args[1]; $wiped = 0 #Set and Clear Variables
    if ($desc -eq $null) {
        Write-Output "No Block type passed to wipe command.."
    } else {
        $objects = $($mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase/CubeBlocks/MyObjectBuilder_CubeBlock[@xsi:type='MyObjectBuilder_$desc']", $mapNS))

        if ($($objects.count) -gt 0) {
            if ($confirm -eq $true) {
                # Just delete, don't ask
                foreach ($object in $objects) { $object.ParentNode.removeChild($object) | Out-Null } # Coz nobody CARES!
                Write-Output "Confirm passed - Deleted $($objects.count) $desc items without prompt.`n"
            } else {
                # Check first
                Write-Output "I have found $($objects.count) $desc items for deletion."
                if ((Read-Host "Do you want to delete them all? y/n").ToLower() -eq "y") {
                    foreach ($object in $objects) { $object.ParentNode.removeChild($object) | Out-Null } # Coz nobody CARES!
                }
            }
        } else {
            Write-Output "No $desc found.`n"
        }
    }
}

function countBlocks {
    $desc = $args[0]; #Set and Clear Variables
    if ($desc -eq $null) {
        Write-Output "No Block type passed to countBlocks command.."
    } else {
        $objects = $($mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase/CubeBlocks/MyObjectBuilder_CubeBlock[@xsi:type='MyObjectBuilder_$desc']", $mapNS))
        Write-Output "You have $($objects.count) $desc in your world.`n"
    }
}

function checkMaxAllowed {
    $desc = $args[0]; $maxAllowed = $args[1]; $violations = 0 #Set and Clear Variables
    if ($desc -eq $null) {
        Write-Output "No Block type passed to checkMaxAllowed command.."
    } elseif ($maxAllowed -eq $null) {
        Write-Output "No Max Allowed passed to checkMaxAllowed command.."
    } else {
        $cubeGrids = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_CubeGrid')]" ,$mapNS)
        foreach ($cubeGrid in $cubeGrids ){ # Scan thru Grids
            $blocks = $cubeGrid.SelectNodes("CubeBlocks/MyObjectBuilder_CubeBlock[@xsi:type='MyObjectBuilder_$desc']", $mapNS)
            if ($($blocks.count) -gt $maxAllowed) { # Check for Violation
                #Get owner of first drill
                $culprit = $configXML.SelectSingleNode("//AllPlayers/PlayerItem[PlayerId='$($blocks[0].Owner)']", $confNS)
                Write-Output "$($cubeGrid.DisplayName) has $($blocks.count) $desc. It belongs to $($culprit.Name)"
                $violations++
            }
        }
        Write-Output "Check complete, $violations violations found.`n"
    }
}

function turn {
    $desc = $args[1] ; $onOff = $args[0]  #Set and Clear Variables
    if ($desc -eq $null) {
        Write-Output "No Block type passed to turn command.."
    } elseif ($onOff -eq $null) {
        Write-Output "No action passed to turn command.."
    } else {
        $changed = 0; $unchanged = 0; $onOff = $onOff.ToLower(); $count = 0
        $objects = $($mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase/CubeBlocks/MyObjectBuilder_CubeBlock[@xsi:type='MyObjectBuilder_$desc']", $mapNS))
    
        if ($onOff -eq "on") {
            foreach ($object in $objects) {
                if ($object.Enabled -eq "false") {
                    $object.Enabled = "true"; $changed++
                } else {
                    $unchanged++
                }
                $count++
            }
            Write-Output "Turned $onOff $changed of your $count $desc, $unchanged were already $onOff.`n"
        } elseif ($onOff -eq "off") {
            foreach ($object in $objects) {
                if ($object.Enabled -eq "true") {
                    $object.Enabled = "false"; $changed++
                } else {
                    $unchanged++
                }
                $count++
            }
            Write-Output "Turned $onOff $changed of your $count $desc, $unchanged were already $onOff.`n"
        } else {
            Write-Output "Didn't understand action command for $desc`n"
        }
    }
}

function findThingsNear {
    $x = $args[0]; $y = $args[1]; $z = $args[2]; $dist = $args[3] #Set and Clear Variables
    $desc = $args[1] ; $onOff = $args[0]  #Set and Clear Variables
    if ($x -eq $null) {
        Write-Output "No X passed to findThingsNear command.."
    } elseif ($y -eq $null) {
        Write-Output "No Y passed to findThingsNear command.."
    } elseif ($z -eq $null) {
        Write-Output "No Z passed to findThingsNear command.."
    } elseif ($dist -eq $null) {
        Write-Output "No distance passed to findThingsNear command.."
    } else {
        $cubeGrids = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_CubeGrid')]" ,$mapNS)
        foreach ($cubeGrid in $cubeGrids) {
            #Just for readability sake, not really nessessary...
            [int]$checkX = $cubeGrid.PositionAndOrientation.Position.x; $xLo = ($x - $dist); $xHi = ($dist + $x)
            [int]$checkY = $cubeGrid.PositionAndOrientation.Position.y; $yLo = ($y - $dist); $yHi = ($dist + $y)
            [int]$checkZ = $cubeGrid.PositionAndOrientation.Position.z; $zLo = ($z - $dist); $zHi = ($dist + $z)
            if ($checkX -gt $xLo -and $checkX -lt $xHi) {
                # X coord in range
                if ($checkY -gt $yLo -and $checkY -lt $yHi) {
                    # Y coord in range
                    if ($checkZ -gt $zLo -and $checkZ -lt $zHi) {
                        #Z coord in range - we have a winner!
                        $cubeGrid
                    }
                }
            }
        }
    }
}

function findThingsNearRoids {
    $roids = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_VoxelMap')]" ,$mapNS)
    foreach ($roid in $roids) {
        $response = findThingsNear $roid.PositionAndOrientation.Position.x $roid.PositionAndOrientation.Position.y $roid.PositionAndOrientation.Position.z $args[0]
        if ($($response.count) -eq 0) {
            "Nothing found near $($roid.StorageName)`n"
        } else {
            "Things found near $($roid.StorageName), listing:"
            foreach ($r in $response) {
                Write-Output "$($r.DisplayName) found at X:$($r.PositionAndOrientation.Position.x) Y:$($r.PositionAndOrientation.Position.y) Z:$($r.PositionAndOrientation.Position.z)"
            }
        }
    }
}

function refreshRoids {
    $dist = $args[0] #Set and Clear Variables
    if ($dist -gt 0) {
        $roids = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_VoxelMap')]" ,$mapNS)
        foreach ($roid in $roids) {
            $response = findThingsNear $roid.PositionAndOrientation.Position.x $roid.PositionAndOrientation.Position.y $roid.PositionAndOrientation.Position.z $args[0]
            if ($($response.count) -eq 0) {
                Write-Output "Nothing found near $($roid.StorageName)"
                $removeRoid = "$saveLocation\$($roid.StorageName).vx2"
                $originalRoid = "$origLocation\$($roid.StorageName).vx2"
                if (Test-Path $originalRoid) {
                    Write-Output "Replacing Roid $($roid.StorageName) with Original from $originalRoid"
                    #Copy-Item $originalRoid $removeRoid -Force
                }
            } else {
                Write-Output "Blocking structures found, skipped $($roid.StorageName)"
            }
        }
    } else {
        Write-Output "No Distance passed to refreshRoids command"
    }
}

function removeFloaters {
    $flush = $args[0] #Set and Clear Variables
    $floaters = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_FloatingObject')]" ,$mapNS)
    if ($($floaters.count) -gt 0) {
        if ($flush -eq $true) {
            #Just delete, don't ask
            foreach ($floater in $floaters) { $floater.ParentNode.removeChild($floater) | Out-Null }
            Write-Output "Confirm passed - Deleted $($floaters.count) $desc items without prompt.`n"
        } else {
            #Check first
            Write-Output "I have found $($floaters.count) $desc items for deletion."
            if ((Read-Host "Do you want to delete them all? y/n").ToLower() -eq "y") {
                foreach ($floater in $floaters) { $floater.ParentNode.removeChild($floater) | Out-Null }
            }
        }
    } else {
        Write-Output "No Floaters found.`n"
    }

}

function removeJunk {
    $command = $args[0].ToLower(); $action = $args[1].ToLower() #Set and Clear Variables
    if ($command -eq $null) {
        Write-Output "No Command passed to removeJunk"
    } else {
        $cubeGrids = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_CubeGrid')]" ,$mapNS)
        if ($($cubeGrids.count) -gt 0) {
            foreach ($cubeGrid in $cubeGrids) {
                #Select all Beacons, Antennas, PistonTops and MotorRotors (Rotor Tops)
                $blocksOfInterest = $cubeGrid.SelectNodes("CubeBlocks/MyObjectBuilder_CubeBlock[(@xsi:type='MyObjectBuilder_Beacon') or (@xsi:type='MyObjectBuilder_RadioAntenna') or (@xsi:type='MyObjectBuilder_MotorRotor') or (@xsi:type='MyObjectBuilder_PistonTop') or (@xsi:type='MyObjectBuilder_Wheel')]", $mapNS)
                if ($blocksOfInterest.count -gt 0) {
                    #This cubegrid passed tests
                    if ($command -eq "list" -and ($action -eq "all" -or $action -eq "good")) {
                        Write-Output "$($cubeGrid.DisplayName) has a Beacon/Antenna (Or Rotor/Piston Top)"
                    }
                } else {
                    #This cubegrid failed tests
                    if ($command -eq "delete") {
                        if ($action -eq "noconfirm") {
                            Write-Output "Confirm passed - Deleted $($cubeGrid.DisplayName) without prompt.`n"
                            $cubeGrid.ParentNode.removeChild($cubeGrid) | Out-Null
                        } else {
                            # Assume confirmation required
                            if ((Read-Host "$($cubeGrid.DisplayName) has no Beacon/Antenna (Or Rotor/Piston Top) - Do you want to delete it? y/n").ToLower() -eq "y") {
                                $cubeGrid.ParentNode.removeChild($cubeGrid) | Out-Null
                            }
                        }
                    } elseif ($command -eq "list" -and ($action -eq "all" -or $action -eq "bad")) {
                        # Default Command - 'list bad'
                        Write-Output "$($cubeGrid.DisplayName) has no Beacon/Antenna (Or Rotor/Piston Top)"
                    } else {
                        Write-Host "Action not recognised"
                    }
                }
            }
        } else {
            Write-Output "No CubeGrids found in map.`n"
        }
    }

}

function saveIt {
    $saveFile = "$saveLocation\SANDBOX_0_0_0_.sbs"
    $mapXML.Save($saveFile)
}

#Load files...
Write-Output "Loading Map XML from $saveLocation... Please hold"
$mapXML = $null #Ditch previous map 
if ([xml]$mapXML = Get-Content $saveLocation\SANDBOX_0_0_0_.sbs) {
    $mapNS = New-Object System.Xml.XmlNamespaceManager($mapXML.NameTable)
    $mapNS.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    Write-Output "Map loaded! Loading Config XML from $saveLocation... Please hold"
    $configXML = $null #Ditch previous config 
    if ([xml]$configXML = Get-Content $saveLocation\Sandbox.sbc) {
        $confNS = New-Object System.Xml.XmlNamespaceManager($configXML.NameTable)
        $confNS.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
        Write-Output "Config loaded! Ready to work`n"

<#
 ==================================
 = BEGIN AUTOMATIC ACTION SECTION =
 ==================================
 Make your changes from here
#>

#I've left this section in as it lists most of the current block types

# -=Lights=-
#turn off ReflectorLight
#turn On InteriorLight

# -=Drills + Welders=-
#turn off Drill
#turn off ShipWelder
#turn off ShipGrinder


# -=Pistons and Rotors=-
#turn off MotorStator
#turn off PistonBase

# -=Merge Blocks/Connectors=-
#turn off MergeBlock
#turn off ShipConnector #Station
#turn Off Connector     #Ship
#turn off Collector

# -=Guns Etc=-
#turn off InteriorTurret
#turn off LargeGatlingTurret
#turn off LargeMissileTurret
#turn off Decoy

# -=Factories=-
#turn off Assembler
#turn off Refinery

# -=Transmitters=-
#turn off Beacon
#turn off RadioAntenna

# -=Power=-
#turn off Reactor
#turn off BatteryBlock
#turn off SolarPanel
#turn on Door

# -=Other Station Blocks=-
#turn off GravityGenerator
#turn off GravityGeneratorSphere
#turn off MedicalRoom
#turn off CameraBlock
#turn off SensorBlock

# -=Ship things=-
#turn off OreDetector
#turn off Gyro
#turn off LandingGear
#turn off Thrust
#turn off MotorSuspension
#turn off VirtualMass
#turn off Thrust

#Check the top section for more function Examples

#removeFloaters $true
#refreshRoids 500

#Commit changes, uncomment this if you want changes to be saved when the script is run
#saveIt

<#
  ================================
  = END AUTOMATED ACTION SECTION =
  ================================
  Make no changes past this point
#>


    } else {
        Write-Output "Config Load failed :( Check your saveLocation is correct? I attempted to load:"
        Write-Output "$saveLocation\Sandbox.sbc"
    }
} else {
    Write-Output "Map Load failed :( Check your saveLocation is correct? I attempted to load:"
    Write-Output "$saveLocation\SANDBOX_0_0_0_.sbs"
}
