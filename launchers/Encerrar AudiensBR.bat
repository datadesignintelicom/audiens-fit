@echo off
REM Encerra o AudiensBR Fit e libera a RAM, e SO o Fit: fecha apenas processos
REM cujo executavel esta na pasta runtime-win deste destino. Fecha tambem o
REM Ollama do Fit, que aberto impede ejetar o disco.
REM Criado por Daniel Bastos - Data Design Inteligencia de Comunicacao (MIT)
setlocal
set "RAIZ=%~dp0"
if "%RAIZ:~-1%"=="\" set "RAIZ=%RAIZ:~0,-1%"
set "RT=%RAIZ%\runtime-win"
powershell -NoProfile -Command "$r=$env:RT+'\'; $p=@(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($r,'OrdinalIgnoreCase') }); if(-not $p){ Write-Host 'O AudiensBR Fit nao esta aberto. Nada a encerrar.'; exit 0 }; $p | Stop-Process -Force -ErrorAction SilentlyContinue; $p | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue; if(@($p | Where-Object { -not $_.HasExited })){ Write-Host 'Aviso: ainda ha processos abertos. Aguarde e rode de novo.'; exit 1 }; Write-Host 'AudiensBR Fit encerrado e RAM liberada. Pode fechar esta janela.'"
ping -n 4 127.0.0.1 >nul
