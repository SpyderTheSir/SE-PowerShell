param(
    [string]$saveLocation = "$env:APPDATA\SpaceEngineersDedicated\Saves\Map"
)


if ([xml]$configXML = Get-Content $saveLocation\Sandbox.sbc) {
    $ns = New-Object System.Xml.XmlNamespaceManager($mapXML.NameTable)
    $ns.AddNamespace("xsi", "http://www.w3.org/2001/XMLSchema-instance")
    # Loaded stuffs and ready to work

    $mods = $configXML.SelectNodes("//Mods/ModItem", $ns)
    foreach ($mod in $mods) {
        $modURI = "http://steamcommunity.com/sharedfiles/filedetails/?id=$($mod.PublishedFileId)"
        $HTML = Invoke-WebRequest -Uri $modURI
        $modTitle = @($html.parsedHTML.getElementsByTagName('title'))[0].innerText.Replace('Steam Workshop :: ','')
        # Steam Code
        Write-Output "[url=$modURI]$modTitle[/url]"
        # HTML
        #Write-Output "<a href=`"$modURI`">$modTitle</a>"
    }

} else {
    Write-Ouptut "Unable to load $saveLocation\Sandbox.sbc."
}