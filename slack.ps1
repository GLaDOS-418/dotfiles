Write-Host "started at: $(Get-Date -Format g)"
$wshell = New-Object -ComObject WScript.Shell
Add-Type -AssemblyName System.Windows.Forms
$screen = [System.Windows.Forms.SystemInformation]::VirtualScreen
$i=-1 #'0' to move mouse. '-1' to disable mouse movement.
while(1){
	if($i -ge 0){
	    if($i -eq 0){[Windows.Forms.Cursor]::Position = "$($screen.Width/2-$screen.Width/4), $($screen.Height/2)"}
	    else{[Windows.Forms.Cursor]::Position = "$($screen.Width/2+$screen.Width/4), $($screen.Height/2)"}
        $i=($i+1)%2
    }
    $wshell.SendKeys('{NUMLOCK}')
    Start-Sleep -s 10
    Write-Host -NoNewline "."
}

