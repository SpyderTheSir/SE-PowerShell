<#

    Spyder's Space Engineers Switcher Script
    ========================================
    
    DESCRIPTION:
    Turns things on! and off!

    USAGE:
    Change the filePath below to suit, or just copy this script and your SANDBOX file into C:\Temp
    Scroll down the the section that says ACTIONS
    You'll see a lot of 'turn "on" "thing!"' entries. Usage is fairly plain english, in that turn "on" and turn "off" will both work.
    The third variable is the xsi:type in the save XML file but with the 'MyObjectBuilder_' removed.

    Valid options are:
    ... all written in down below!

    Without adjustment all this script will now do is turn off all the spotlights in your world.
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
  [string]$filePath = "C:\Temp\SANDBOX_0_0_0_.sbs"          #Save file goes here.
)

Write-Output "Loading XML $filePath... Please hold caller"
[xml]$myXML = Get-Content $filePath
$ns = New-Object System.Xml.XmlNamespaceManager($myXML.NameTable)
$ns.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

function turn {
    $desc = $args[1]; $onOff = $args[0] #Yeah, I know I could just use $args[x] thruout, but this is more readable. Deal.
    $changed = 0; $unchanged = 0; $onOff = $onOff.ToLower(); $count = 0
    $objects = $($myXML.SelectNodes("//SectorObjects/MyObjectBuilder_EntityBase/CubeBlocks/MyObjectBuilder_CubeBlock[@xsi:type='MyObjectBuilder_$desc']", $ns))
    
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

<#
 ===========
 = ACTIONS =
 ===========
#>

# -=Lights=-
turn "Off" "ReflectorLight"
#turn "Off" "InteriorLight"

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



#Commit changes
$myXML.Save($filePath)
