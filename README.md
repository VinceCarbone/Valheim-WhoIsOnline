# Valheim-WhoIsOnline
If you're running a Valheim dedicated server on a Windows box, this script will let you quickly identify who's online

![Alt text](https://www.vincecarbone.com/images/Valheim-WhoIsOnline.png)

The first step is to update the dedicated server bat file. Your bat file probably looks something like this today
```valheim_server -nographics -batchmode -name "Vince's Server" -port 2456 -world "boring" -password "lolfart" -public 0```

You'll need to append something like this to the end of it so that it outputs the console info to a log file instead of the console window
```valheim_server -nographics -batchmode -name "Vince's Server" -port 2456 -world "boring" -password "lolfart" -public 0 >> dedicted_server_log.txt```

**By dumping the console window to a log file, it could possibly result in a very large file getting created over time. This obviously depends on how busy your server is. I'd say keep an eye on the file and see how much it's growing. Worst case is you may need to delete the file periodically.**

Once you've updated your bat file and restarted your dedicated server, you should now see a log file in the same directory as the bat file. Nice.

To see who's online, simply run this powershell script with the logfile parameter pointing to your new log file. Obviously you'll need to substitute your own correct path here.
```Valheim-WhoIsOnline.ps1 -logfile "C:\Path\to\logfile\dedicated_server_log.txt"```

A powershell window will open and refresh every 30 seconds. It will show you any player who has connected since you started outputting the log file. It will show you their player name, their steamID, their steam username (retrieved via https://steamid.io) their online/offline status, and the last time they logged on.

You can exit this script by pushing CTRL+C in the powershell window.
