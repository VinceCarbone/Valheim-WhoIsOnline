# You will need to supply the path to the log file via -logfile "C:\somepath\logfile.txt"
# This will loop every 30 seconds by default, Push CTRL+C in the powershell window to exit the loop

param (    
    [Parameter(Mandatory=$true)][string]$logfile
)

# Makes sure the log file you pointed to is a valid path
If(-not(Test-Path $logfile)){Write-Host "'$logfile' does not appear to be a valid path." -ForegroundColor Red; Exit}

Do{
    $content = Get-Content $logfile
    # This builds an array containing only specific lines from the log file and then sorts them in order
    $contentTrimmed = @($content -match "Got connection SteamID") # steam player connection    
    $contentTrimmed += @($content -match "Got character ZDOID from") # character log in and deaths
    $contentTrimmed = @($contentTrimmed | Sort-Object)

    # This section finds all the unique steamIDs
    $steamIDs = @()
    $steamIDLines = @($contentTrimmed | Select-String "Got connection SteamID") # finds every line in the log file that has a player connecting
    ForEach($steamIDLine in $steamIDLines){$steamIDs += ($steamIDLine -split(' '))[-1]} # splits each line into a separate array, and selects the last item in the array (which is the steamid)
    $steamIDs = $steamIDs | Sort-Object | Get-Unique # removes duplicate steamIDs

    # This section finds all the details for each unique steamID
    $Players = @()
    ForEach($steamID in $steamIDs){
        $Players +=@(      
            $connection = $contentTrimmed.IndexOf((($contentTrimmed | Select-String "Got connection SteamID $steamID")[-1])) # finds the index of last time this steamID connected in the array
            $LoggedOn = Get-Date(((($contentTrimmed[$connection]).split(' ')[0,1]) -join " ") -replace ".$") # grabs the logon date from the relevant item in the array
            If($content | Select-string "Closing socket $steamID"){
                # Putting this in an IF statement prevents an issue with a first time player who hasn't logged off before
                $LoggedOff = Get-Date(((((($content | Select-string "Closing socket $steamID")[-1]) -split ' ')[0,1]) -join " ") -replace ".$") # finds the last time this steamid logged off and grabs the date
            }Else{$LoggedOff = $null}

            # This attempts to grab the player name from the logs
            If(($contentTrimmed[$connection + 1] -match "Got character ZDOID from")){                
                # this attempts to work around an issue where you run the script while a player isn't fully connected.               
                $Player = (($contentTrimmed[$connection + 1]).split(':')[3]) -replace ("Got character ZDOID FROM ")                
            }Else{$Player = $null}

            # Retrieves info from the interweb about who the steamID belongs to        
            If(Test-Connection "steamcommunity.com" -Count 1 -ErrorAction SilentlyContinue){
                $Response = Invoke-WebRequest -Uri "https://steamcommunity.com/profiles/$steamid"
                If($Response){
                    $SteamName = (((($response.content -split "`n") | Select-String "<title>") -replace "<title>Steam Community :: ","") -replace "</title>","").trim()
                    If($SteamName -eq "Error"){$SteamName = $null}
                }Else{$SteamName = $null}
            }Else{$SteamName = $null}            

            # Builds the output
            [PSCustomObject]@{
                Player = If($null -ne $player){$Player.trim()}Else{$null}
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