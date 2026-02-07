$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$flagFile = Join-Path $scriptDir "set_up_flag_delete_to_restore"
$markerFile = Join-Path $scriptDir "original_azul_zulu_do_not_delete"
$logFile = Join-Path $scriptDir "setup_log.hml"
$arch = $env:PROCESSOR_ARCHITECTURE
$archWow = $env:PROCESSOR_ARCHITEW6432

if (Test-Path $logFile) { Remove-Item $logFile -Force }

function Write-Log($message, $isError = $false) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $message"
    if ($isError) {
        Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
    }
    Write-Host $logMessage
}

if ($arch -eq "ARM64") {
    $platform = "arm"
} elseif ($arch -eq "AMD64" -or $archWow -eq "AMD64") {
    $platform = "64"
} else {
    $platform = "32"
}

switch ($platform) {
    "64" {
        $zuluUrl = "https://www.dropbox.com/scl/fi/svyisqcd671k1gv0k6pek/zulu17.62.17_-64_bit.zip?rlkey=qpdq3io06fartnwldxwia7cp0&st=443lvdgz&dl=1"
    }
    "32" {
        $zuluUrl = "https://www.dropbox.com/scl/fi/lw4ub3mtco1z0czrrojk9/zulu17.64.17_-32_bit.zip?rlkey=pjrq3gm5oacd8il4tpoi3gs7w&st=2572mhap&dl=1"
    }
    "arm" {
        $zuluUrl = "https://www.dropbox.com/scl/fi/6mtezcp3vgjaps3olzx4k/zulu17.64.17_-arm.zip?rlkey=44y7ug7mmkhvp4z436adqcvd7&st=emjoek5z&dl=1"
    }
}

$launcherUrl = "https://raw.githubusercontent.com/Dinhhokhanhnhat/Hello-Minimal-Launcher-HML/main/CoreLauncher..jar"
$zuluZip = Join-Path $scriptDir "zulu17.zip"
$launcherJar = Join-Path $scriptDir "launcher.jar"
$launcherVbs = Join-Path $scriptDir "HML_Launcher..vbs"

function Show-Message($text, $autoClose = $false) {
    Add-Type -AssemblyName System.Windows.Forms
    $global:msgBoxForm = New-Object System.Windows.Forms.Form
    $global:msgBoxForm.Text = "Launcher Setup"
    $global:msgBoxForm.Size = New-Object System.Drawing.Size(360,150)
    $global:msgBoxForm.StartPosition = "CenterScreen"
    
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $text
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(20,40)
    $global:msgBoxForm.Controls.Add($label)
    $global:msgBoxForm.Topmost = $true
    
    if ($autoClose) {
        $timer = New-Object System.Windows.Forms.Timer
        $timer.Interval = 5000
        $timer.Add_Tick({
            $global:msgBoxForm.Close()
            $timer.Stop()
        })
        $timer.Start()
    }
    
    $global:msgBoxForm.Show()
}

function Close-Message() {
    if ($global:msgBoxForm) { $global:msgBoxForm.Close() }
}

if (-Not (Test-Path $flagFile)) {
    $setupSuccess = $true
    
    try {
        New-Item -Path $flagFile -ItemType File | Out-Null
        
        Show-Message "Downloading Azul Zulu 17 ($platform-bit)..."
        Write-Log "Starting download Azul Zulu 17 ($platform-bit)"
        
        try {
            Invoke-WebRequest -Uri $zuluUrl -OutFile $zuluZip -UseBasicParsing
        } catch {
            Write-Log "Invoke-WebRequest failed, trying BitsTransfer: $_" -isError $true
            Start-BitsTransfer -Source $zuluUrl -Destination $zuluZip
        }
        
        Close-Message
        
        Show-Message "Extracting Azul Zulu 17..."
        Write-Log "Extracting Zulu archive"
        
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zuluZip, $scriptDir)
        Remove-Item $zuluZip
        
        Close-Message
        
        $zuluFolder = Get-ChildItem $scriptDir -Directory |
            Where-Object { $_.Name -like "zulu17*" } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        
        if ($zuluFolder) {
            Set-Content -Path $markerFile -Value $zuluFolder.Name -Encoding UTF8
            Write-Log "Zulu folder marked: $($zuluFolder.Name)"
        } else {
            throw "Zulu folder not found after extraction"
        }
        
        Show-Message "Downloading Launcher..."
        Write-Log "Downloading launcher."
        
        Invoke-WebRequest -Uri $launcherUrl -OutFile $launcherJar -UseBasicParsing
        
        Close-Message
        
        Write-Log "Setup completed successfully."
        Show-Message "Setup completed! Launcher is ready." -autoClose $true
        
    } catch {
        $setupSuccess = $false
        Write-Log "SETUP FAILED: $_" -isError $true
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -isError $true
        
        Close-Message
        [System.Windows.Forms.MessageBox]::Show("Setup failed! Check setup_log.hml for details.", "Error", "OK", "Error")
    }
    
    if ($setupSuccess -and (Test-Path $logFile)) {
        Remove-Item $logFile -Force
    }
    
} else {
    if (Test-Path $launcherVbs) {
        Start-Process "wscript.exe" -ArgumentList "`"$launcherVbs`""
    }
}
