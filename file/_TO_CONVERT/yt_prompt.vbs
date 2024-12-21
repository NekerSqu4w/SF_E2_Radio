Dim videoid
Dim objShell

videoid = InputBox("Enter video ID:", "YouTube DL")

' check if the input is empty
' if true inform user and quit script
If videoId = "" Then
    MsgBox "No video ID entered. Exiting.", vbExclamation, "Error"
    WScript.Quit
End If

Set objShell = WScript.CreateObject("WScript.Shell")

' build and run the yt-dlp command
command = "yt-dlp.exe -x --audio-format mp3 -o """ & videoId & """.mp3 " & videoId
objShell.Run command, 1, True