# You will need to supply the path to the log file via -logfile "C:\somepath\logfile.txt"
# This will loop every 30 seconds by default, Push CTRL+C in the powershell window to exit the loop

param (    
    [Parameter(Mandatory=$true)][string]$logfile
)

# Makes sure the log file you pointed to is a valid path
If(-not(Test-Path $logfile)){Write-Host "'$logfile' does not appear to be a valid path." -ForegroundColor Red; Exit}

Do{
    $content = Get-Content $logfile

    # This section finds all the unique steamIDs in the log file
    $steamIDs = @()
    $steamIDLines = @($content | Select-String "Got connection SteamID") # finds every line in the log file that has a player connecting
    ForEach($steamIDLine in $steamIDLines){$steamIDs += ($steamIDLine -split(' '))[-1]} # splits each line into a separate array, and selects the last item in the array (which is the steamid)
    $steamIDs = $steamIDs | Sort-Object | Get-Unique # removes duplicate steamIDs

    # This section finds all the details for each unique steamID
    $Players = @()
    ForEach($steamID in $steamIDs){
        $Players +=@(      
            $connection = (($content | Select-String "Got connection SteamID $steamID")[-1]).LineNumber # finds the last time this steamID connected
            $LoggedOn = Get-Date((($content[$connection]).split(' ')[0] + " " + ($content[$connection]).split(' ')[1]) -replace ".$") # grabs the logon date from the line
            If($content | Select-string "Closing socket $steamID"){
                # Putting this in an IF statement prevents an issue with a first time player who hasn't logged off before
                $LoggedOff = Get-Date((((($content | Select-string "Closing socket $steamID")[-1]) -split ' ')[0]) + " " + (((($content | Select-string "Closing socket $steamID")[-1]) -split ' ')[1]) -replace ".$") # finds the last time this steamid logged off and grabs the date
            }Else{$LoggedOff = $null}

            # This attempts to grab the player name from the logs
            If($content[$connection + 4] -match "I HAVE ARRIVED!"){
                # this attempts to work around an issue where you run the script while a player isn't fully connected.
                $Player = (($content[$connection + 4]).split('>')[1]).replace("</color","")
            }Else{$Player = $null}

            # retrieves info from the interweb about who the steamID belongs to
            $response = Invoke-WebRequest -Uri "https://steamid.io/lookup/$steamid"
            If(($response -split "`n") | Select-String '                "name":'){
                $SteamName = ((((($response -split "`n") | Select-String '                "name":') -split ",")[0] -replace '"name": "','') -replace '"','').trim()# gets the steam username from the $response variable
            }Else{$SteamName = $null}

            # Builds the output
            [PSCustomObject]@{
                Player = $Player
                SteamID = $steamID
                SteamName = $SteamName
                Status = If($LoggedOn -gt $LoggedOff){"Online"}Else{"Offline"}
                LastLogon = $LoggedOn
            }        
        )
    }

    # Outputs the info to the screen if it's changed
    Clear-Host
    $Players | Sort-object Status -Descending | Format-Table -AutoSize

    # Sleep
    Start-Sleep -Seconds 30

}While(1)