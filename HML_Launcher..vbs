Option Explicit

Dim fso, shell, folderPath
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
folderPath = fso.GetParentFolderName(WScript.ScriptFullName)

Dim configFile, NotificationEnabled, DebugEnabled
NotificationEnabled = True
DebugEnabled = False

configFile = folderPath & "\HML_config.txt"
If Not fso.FileExists(configFile) Then
    On Error Resume Next
    Dim cfg
    Set cfg = fso.CreateTextFile(configFile, True)
    If Err.Number <> 0 Then
        MsgBox "FATAL: Cannot create config file!", vbCritical, "HML Error!"
        WScript.Quit 1
    End If
    On Error GoTo 0
    cfg.WriteLine "Notification = true"
    cfg.WriteLine "Debug = false"
    cfg.WriteLine "HML Version = 1.0.1"
    cfg.WriteLine "HML Signature = BDQnS0gABabJAgpfVD8IAA1BQT9NLQ0ZTiAJEVJySFAJHQZFJUVOLA4HA1lWKB0cB08sRVBNWAB9Vw"
    cfg.Close
End If

Dim cfgText, line, key, value
Set cfgText = fso.OpenTextFile(configFile, 1)
Do Until cfgText.AtEndOfStream
    line = Trim(cfgText.ReadLine)
    If InStr(line, "=") > 0 Then
        key = LCase(Trim(Split(line, "=")(0)))
        value = LCase(Trim(Split(line, "=")(1)))
        If key = "notification" And value = "false" Then NotificationEnabled = False
        If key = "debug" And value = "true" Then DebugEnabled = True
    End If
Loop
cfgText.Close

Class Logger
    Private logFilePath
    Private fsoLocal
    Public Sub Init(fsoObj, path)
        Set fsoLocal = fsoObj
        logFilePath = path
        On Error Resume Next
        Dim f
        Set f = fsoLocal.CreateTextFile(logFilePath, True)
        If Err.Number <> 0 Then
            MsgBox "FATAL: Cannot create log file!", vbCritical, "HML Error!"
            WScript.Quit 1
        End If
        On Error GoTo 0
        f.WriteLine "[INFO][" & FormatDateTime(Now, 4) & "] HML Logger initialized."
        f.Close
    End Sub
    Private Sub Write(level, msg)
        On Error Resume Next
        Dim ts, f
        ts = Year(Now) & "-" & Right("0" & Month(Now),2) & "-" & Right("0" & Day(Now),2) & " " & _
             Right("0" & Hour(Now),2) & ":" & Right("0" & Minute(Now),2) & ":" & Right("0" & Second(Now),2)
        Set f = fsoLocal.OpenTextFile(logFilePath, 8, True)
        f.WriteLine "[" & ts & "][" & UCase(level) & "] " & msg
        f.Close
        On Error GoTo 0
    End Sub
    Public Sub Info(msg)
        Call Write("INFO", msg)
    End Sub
    Public Sub Error(msg)
        Call Write("ERROR", msg)
    End Sub
    Public Sub Warn(msg)
        Call Write("WARN", msg)
    End Sub
    Public Sub Debug(msg)
        Call Write("DEBUG", msg)
    End Sub
    Public Sub Fatal(msg)
        Call Write("FATAL", msg)
    End Sub
End Class

Dim logFile, LoggerObj
logFile = folderPath & "\HML_Log-" & Replace(Replace(Now, ":", "-"), "/", "-") & ".lykkemanestrand"
Set LoggerObj = New Logger
LoggerObj.Init fso, logFile

Sub ShowNotification(title, text)
    If Not NotificationEnabled Then Exit Sub
    On Error Resume Next
    Dim batPath, bat, ps
    batPath = fso.GetSpecialFolder(2) & "\hml_notify.bat"
    ps = "powershell -NoProfile -ExecutionPolicy Bypass -Command " & _
         """Add-Type -AssemblyName System.Windows.Forms;" & _
         "Add-Type -AssemblyName System.Drawing;" & _
         "$n=New-Object System.Windows.Forms.NotifyIcon;" & _
         "$n.Icon=[System.Drawing.SystemIcons]::Information;" & _
         "$n.BalloonTipTitle='" & title & "';" & _
         "$n.BalloonTipText='" & text & "';" & _
         "$n.Visible=$true;" & _
         "$n.ShowBalloonTip(4000);" & _
         "Start-Sleep -Milliseconds 4500;" & _
         "$n.Dispose()"""
    Set bat = fso.CreateTextFile(batPath, True)
    If Err.Number <> 0 Then
        LoggerObj.Fatal "Cannot create notification batch file!"
        WScript.Quit 1
    End If
    bat.WriteLine "@echo off"
    bat.WriteLine "start """" /b " & ps
    bat.Close
    shell.Run "cmd /c """ & batPath & """", 0, False
    WScript.Sleep 200
    fso.DeleteFile batPath, True
    On Error GoTo 0
End Sub

On Error Resume Next
Dim file
For Each file In fso.GetFolder(folderPath).Files
    If LCase(fso.GetExtensionName(file.Name)) = "lykkemanestrand" And file.Path <> logFile Then
        fso.DeleteFile file.Path, True
        If Err.Number <> 0 Then
            LoggerObj.Error "Cannot delete old log file: " & file.Name
            Err.Clear
        End If
    End If
Next
On Error GoTo 0

ShowNotification "Hello, Minimal Launcher version 1.0.1.", "Thank you for trusting HML!" 

Dim folder, javaPath
javaPath = ""
For Each folder In fso.GetFolder(folderPath).SubFolders
    If LCase(Left(folder.Name, 6)) = "zulu17" Then
        If fso.FileExists(folder.Path & "\bin\java.exe") Then
            javaPath = folder.Path & "\bin\java.exe"
            Exit For
        End If
    End If
Next

LoggerObj.Info "Hello, Minimal Launcher started."
LoggerObj.Info "Version: 1.0.1."
LoggerObj.Info "Signature: BDQnS0gABabJAgpfVD8IAA1BQT9NLQ0ZTiAJEVJySFAJHQZFJUVOLA4HA1lWKB0cB08sRVBNWAB9Vw"

If javaPath = "" Then
    LoggerObj.Fatal "Java not found! If you didn't modify the folder, please send this to Lykke Månestrand."
    WScript.Quit 1
End If

LoggerObj.Info "Using Java 17 in: " & javaPath

Dim hmclJar, jarCount, jarFile
hmclJar = ""
jarCount = 0
For Each jarFile In fso.GetFolder(folderPath).Files
    If LCase(fso.GetExtensionName(jarFile.Name)) = "jar" Then
        jarCount = jarCount + 1
        hmclJar = jarFile.Path
    End If
Next

If jarCount = 0 Then
    LoggerObj.Fatal "No jar found!"
    WScript.Quit 1
ElseIf jarCount > 1 Then
    LoggerObj.Fatal "Too many jars! Please keep the folder clean."
    WScript.Quit 1
End If

LoggerObj.Info "Using HMCL jar: " & hmclJar

If DebugEnabled Then
    LoggerObj.Info "Launcher started (Debug mode)."
    LoggerObj.Debug "Debug mode enabled."
    
    On Error Resume Next
    Dim batPath, batFile
    batPath = folderPath & "\HML_Debug_Mode.bat"
    Set batFile = fso.CreateTextFile(batPath, True)
    If Err.Number <> 0 Then
        LoggerObj.Fatal "Cannot create debug batch file!"
        WScript.Quit 1
    End If
    On Error GoTo 0
    
    batFile.WriteLine "@echo off"
    batFile.WriteLine """" & javaPath & """ -jar """ & hmclJar & """ >> """ & logFile & """ 2>&1"
    batFile.WriteLine "echo [%DATE% %TIME%][INFO] Hello, Minimal Launcher shutting down. >> """ & logFile & """"
    batFile.Close
    
    On Error Resume Next
    shell.Run "cmd /c """ & batPath & """", 0, True
    If Err.Number <> 0 Then
        LoggerObj.Error "Failed to execute debug batch."
    End If
    fso.DeleteFile batPath, True
    On Error GoTo 0
Else
    LoggerObj.Info "Launcher started (Normal mode)."
    
    On Error Resume Next
    Dim cmd
    cmd = """" & javaPath & """ -jar """ & hmclJar & """"
    shell.Run cmd, 0, False
    If Err.Number <> 0 Then
        LoggerObj.Error "Failed to launch HMCL."
    End If
    On Error GoTo 0
End If
