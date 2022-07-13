@echo off
echo "DOCS PUSH BAT"

echo "1. Move to working directory" 
D:
cd D:\developer\logseq
 
echo "2. Start GitAutoCommit.ps1"

PowerShell.exe -file Start-GitAutoCommit.ps1 -s origin -b main -i 30 -p
 
echo "Auto Commit Start"