#NOTE: THIS PROGRAM IS ISOLATED FROM THE REST. THIS IS RUN ON LOGIN SO ADD TO
#TASK SCHEDULER

Set-ExecutionPolicy Unrestricted
# Get the array of filepaths
$filepaths = @(
# "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe",
# "C:\Users\nayeer\AppData\Local\Postman\Postman.exe",
# "D:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe",
# "C:\Program Files\Microsoft VS Code\Code.exe",
"C:\Program Files\Microsoft Office\root\Office16\OUTLOOK.EXE",
"C:\Program Files\Mozilla Firefox\firefox.exe",
# "C:\Program Files\Flameshot\bin\flameshot.exe",
"C:\Program Files\Notepad++\notepad++.exe"
)

# Loop through the array
foreach ($filepath in $filepaths) {

  # Start the process
  Start-Process $filepath -WindowStyle Hidden

}
exit
