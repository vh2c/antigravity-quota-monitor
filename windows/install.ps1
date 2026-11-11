# Instalação do Antigravity Quota Monitor no Windows
# Cria atalhos no Menu Iniciar e registro opcional no Startup

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$TargetVbs = Join-Path $ScriptDir "AntigravityQuota.vbs"

$WshShell = New-Object -ComObject WScript.Shell
$StartMenuPath = [System.Environment]::GetFolderPath('StartMenu')
$ShortcutPath = Join-Path $StartMenuPath "Programs\Antigravity Quota.lnk"

$Shortcut = $WshShell.CreateShortcut($ShortcutPath)
$Shortcut.TargetPath = "wscript.exe"
$Shortcut.Arguments = "`"$TargetVbs`""
$Shortcut.Description = "Verifique a cota de uso de IA do Antigravity"
$Shortcut.WorkingDirectory = $ScriptDir
$Shortcut.Save()

Write-Host "✅ Atalho criado no Menu Iniciar: Antigravity Quota" -ForegroundColor Green
Write-Host "Você já pode buscar por 'Antigravity Quota' no Iniciar do Windows ou fixar na Barra de Tarefas!" -ForegroundColor Cyan
