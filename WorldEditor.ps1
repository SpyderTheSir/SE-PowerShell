<#

    Spyder's Space Engineers World Editor Script
    =====================================++++===
    
    DESCRIPTION:
    Turns things on! and off! (turn "on" "InteriorLight")
    Delete things! (wipe "Drill")
    Check for rule violations! (checkMaxAllowed "Drill" 36)
    Count things! (count "Drill")

    USAGE:
    Change the filePath below to suit.
    Scroll down the the section that says ACTIONS
    You'll see a lot of 'turn "on" "thing!"' entries. Usage is fairly plain english, in that turn "on" and turn "off" will both work.
    The third variable is the xsi:type in the save XML file but with the 'MyObjectBuilder_' removed.
    Valid block values are all written in down below and commented out!
    You need to uncomment saveIt at the end if you're modifying this for automated use

    **Without adjustment this script will not do anything!**
    
    I actually use it within the PowerShell ISE so I can hit play, issue commands directly, then saveIt
    
    In order to make an action trigger, delete the # in front of the line, this is a powershell comment.
    Don't delete the #'s in front of the -=Description=- lines tho, these are just for readability
    To stop it doing something, just add the # back!
    To turn on instead of off, change the "off" part to "on"

    LICENSE/DISCLAIMER:
    It's mine. Adjust it if you want, don't claim it's yours.
    If it breaks your save file, you should have made a backup :)

    Caveats!
    - Tested on Windows 8.1 and Server 2012 ONLY
    - Error reporting and change logging is minim... non existent.
    - Backup your stuff!

#>

Param(
    # This is the default location if you're running as local/console as the 'Administrator' user. Not the best example.
  [string]$mapPath = "C:\Users\Administrator\AppData\Roaming\SpaceEngineersDedicated\Saves\Map\SANDBOX_0_0_0_.sbs",          #SANDBOX_0_0_0_.sbs map file
  [string]$configPath = "C:\Users\Administrator\AppData\Roaming\SpaceEngineersDedicated\Saves\Map\Sandbox.sbc"               #Sandbox.sbc config file
)

function wipe {
    $desc = $args[0]; $confirm = $args[1]; $wiped = 0
    $objects = $($mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase/CubeBlocks/MyObjectBuilder_CubeBlock[@xsi:type='MyObjectBuilder_$desc']", $ns))

    if ($($objects.count) -gt 0) {
        if ($confirm) {
            #Just delete, don't ask
            foreach ($object in $objects) { $object.ParentNode.removeChild($object) }
            Write-Out "Confirm passed - Deleted $($objects.count) $desc items without prompt"
        } else {
            #Check
            Write-Output "I have found $($objects.count) $desc items for deletion."
            if ((Read-Host "Do you want to delete them? y/n").ToLower() -eq "y") {
                foreach ($object in $objects) { $object.ParentNode.removeChild($object) }
            }
        }
    } else {
        Write-Output "No $desc found"
    }
}

function countBlocks {
    $desc = $args[0];
    $objects = $($mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase/CubeBlocks/MyObjectBuilder_CubeBlock[@xsi:type='MyObjectBuilder_$desc']", $ns))
    Write-Output "You have $($objects.count) $desc in your world"
}

function checkMaxAllowed { #Work in Progress
    $desc = $args[0]; $maxAllowed = $args[1]
    $cubeGrids = $mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase[(@xsi:type='MyObjectBuilder_CubeGrid')]" ,$ns)
    foreach ($cubeGrid in $cubeGrids ){ # Scan thru Grids
        $blocks = $cubeGrid.SelectNodes("CubeBlocks/MyObjectBuilder_CubeBlock[@xsi:type='MyObjectBuilder_$desc']", $ns)
        if ($($blocks.count) -gt $maxAllowed) { # Check for Violation
            #Get owner of first drill
            $culprit = $configXML.SelectSingleNode("//AllPlayers/PlayerItem[PlayerId='$($blocks[0].Owner)']", $ns)
            Write-Output "EntityId $($cubeGrid.EntityID) has $($blocks.count) $desc. It belongs to $($culprit.Name)"
        }
    }
}

function turn {
    $desc = $args[1]; $onOff = $args[0] #Yeah, I know I could just use $args[x] thruout, but this is more readable. Deal.
    $changed = 0; $unchanged = 0; $onOff = $onOff.ToLower(); $count = 0
    $objects = $($mapXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase/CubeBlocks/MyObjectBuilder_CubeBlock[@xsi:type='MyObjectBuilder_$desc']", $ns))
    
    if ($onOff -eq "on") {
        foreach ($object in $objects) {
            if ($object.Enabled -eq "false") {
                $object.Enabled = "true"; $changed++
            } else {
                $unchanged++
            }
            $count++
        }
        Write-Output "Turned $onOff $changed of your $count $desc, $unchanged were already $onOff."
    } elseif ($onOff -eq "off") {
        foreach ($object in $objects) {
            if ($object.Enabled -eq "true") {
                $object.Enabled = "false"; $changed++
            } else {
                $unchanged++
            }
            $count++
        }
        Write-Output "Turned $onOff $changed of your $count $desc, $unchanged were already $onOff."
    } else {
        Write-Output "Didn't understand action command for $desc"
    }
}

function saveIt {
    $mapXML.Save($mapPath)
}

#Load files...
Write-Output "Loading Map XML $mapPath... Please hold caller"
if ([xml]$mapXML = Get-Content $mapPath) {
    Write-Output "Map loaded! Loading Config XML $mapPath... Please hold caller"
    if ([xml]$configXML = Get-Content $configPath) {
        Write-Output "Config loaded!"
        $ns = New-Object System.Xml.XmlNamespaceManager($mapXML.NameTable)
        $ns.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

<#
 ===========
 = ACTIONS =
 ===========
#>

# -=Lights=-
#turn "Off" "ReflectorLight"
#turn "On" "InteriorLight"

# -=Drills + Welders=-
#turn "off" "Drill"
#turn "off" "ShipWelder"
#turn "Off" "ShipGrinder"


# -=Pistons and Rotors=-
#turn "off" "MotorStator"
#turn "off" "PistonBase"

# -=Merge Blocks/Connectors=-
#turn "off" "MergeBlock"
#turn "off" "ShipConnector" #Station
#turn "Off" "Connector"     #Ship
#turn "off" "Collector"

# -=Guns Etc=-
#turn "off" "InteriorTurret"
#turn "off" "LargeGatlingTurret"
#turn "off" "LargeMissileTurret"
#turn "off" "Decoy"

# -=Factories=-
#turn "off" "Assembler"
#turn "off" "Refinery"

# -=Transmitters=-
#turn "off" "Beacon"
#turn "Off" "RadioAntenna"

# -=Power=-
#turn "off" "Reactor"
#turn "off" "BatteryBlock"
#turn "off" "SolarPanel"
#turn "off" "Door"

# -=Other Station Blocks=-
#turn "off" "GravityGenerator"
#turn "off" "GravityGeneratorSphere"
#turn "off" "MedicalRoom"
#turn "Off" "CameraBlock"
#turn "off" "SensorBlock"

# -=Ship things=-
#turn "off" "OreDetector"
#turn "off" "Gyro"
#turn "off" "LandingGear"
#turn "off" "Thrust"
#turn "off" "MotorSuspension"
#turn "off" "VirtualMass"
#turn "off" "Thrust"

# -=New Functions, use with care=-
#countBlocks "Drill"
#countBlocks "MotorStator"
#countBlocks "MotorRotor"

# Deletes blocks, default action is to prompt with a value. If you use 'wipe "MotorStator" $true' instead it will delete without warning!
#wipe "MotorStator"
#wipe "MotorRotor"
#wipe "SensorBlock"

# We have a rule on the server that only allows 36 drills per grid. I automated this :)
#checkMaxAllowed "Drill" 36

#Commit changes
#saveIt

    } else {
        Write-Output "Config Load failed :( Check your configPath is correct? I attempted to load:"
        Write-Output $configPath
    }
} else {
    Write-Output "Map Load failed :( Check your configPath is correct? I attempted to load:"
    Write-Output $mapPath
}
