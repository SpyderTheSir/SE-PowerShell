param(
    [string]$saveLocation = "$env:APPDATA\SpaceEngineersDedicated\Saves\Map",
    [string]$format
)

$format = $format.ToLower()
if ([xml]$configXML = Get-Content $saveLocation\Sandbox.sbc) {
    # Loaded stuffs and ready to work
    $ns = New-Object System.Xml.XmlNamespaceManager($configXML.NameTable)
    $ns.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")

    $mods = $configXML.SelectNodes("//Mods/ModItem", $ns)

    Write-Output "You are running $($mods.count) server mods, listing in $(if ($format) { $format } else { 'list' }) format:"
    foreach ($mod in $mods) {
        $modURI = "http://steamcommunity.com/sharedfiles/filedetails/?id=$($mod.PublishedFileId)"
        $HTML = Invoke-WebRequest -Uri $modURI
        $modTitle = @($html.parsedHTML.getElementsByTagName('title'))[0].innerText.Replace('Steam Workshop :: ','')
        if ($format -eq 'steam') {
            Write-Output "[url=$modURI]$modTitle[/url]"
        } elseif ($format -eq 'html') {
            Write-Output "<a href=`"$modURI`">$modTitle</a>"
        } else {
            Write-Output "Mod $($mod.PublishedFileId): $modTitle"
        }
    }
} else {
    Write-Ouptut "Unable to load $saveLocation\Sandbox.sbc."
}