Option Explicit

Dim fso, shell, batPath
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

batPath = fso.BuildPath(fso.GetParentFolderName(WScript.ScriptFullName), "Hello, Minimal Launcher.bat")

If Not fso.FileExists(batPath) Then
    MsgBox "Hello, Minimal Launcher not found!" & vbCrLf & _
           "Make sure Hello, Minimal Launcher.bat is in the same folder with HML Launcher (Double Click).vbs", _
           vbCritical, "HML Launcher Error"
    WScript.Quit 1
End If

shell.Run """" & batPath & """", 0, False
