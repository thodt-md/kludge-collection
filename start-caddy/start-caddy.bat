@echo off

powershell.exe -nologo -noprofile -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12" >NUL 2>&1
if not "%ERRORLEVEL%" == "0" goto :fail

powershell.exe -nologo -noprofile -command "Add-Type -AssemblyName System.IO.Compression.FileSystem" >NUL 2>&1
if not "%ERRORLEVEL%" == "0" goto :fail

echo Launching PowerShell script...
powershell.exe -nologo -noprofile -ExecutionPolicy RemoteSigned -file ./%~n0.ps1 %*
goto :eof

:fail
echo "Please upgrade to PowerShell to version 3.0 or newer and .NET Framework to 4.5.1 or newer"
exit /b 1