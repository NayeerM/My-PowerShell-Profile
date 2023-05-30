Set-ExecutionPolicy Unrestricted
# Get the array of filepaths
$filepaths = @("C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe",
"C:\Users\nayeer\AppData\Local\Postman\Postman.exe",
"D:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\Ssms.exe",
"D:\Program Files\Microsoft VS Code\Code.exe"
)

# Loop through the array
foreach ($filepath in $filepaths) {

  # Start the process
  start-process $filepath

}
