@echo off
REM ---------------------------------------------------------------------------
REM AudiensBR Fit - instalador Windows (pendrive autossuficiente)
REM Baixa sozinho Python, Ollama e o modelo de IA para o destino. Nem a maquina
REM que prepara nem a que usa precisa ter nada instalado. Requer Windows 10
REM (1803 ou mais novo) ou 11, que ja trazem curl e tar.
REM Uso: duplo clique (pergunta o destino) ou instalar-windows.bat E:\
REM Variavel opcional: AUDIENS_INSTALAR_SEM_MODELOS=1 pula os modelos
REM AVISO: antivirus/SmartScreen podem alertar sobre este .bat - veja o README.
REM Criado por Daniel Bastos - Data Design Inteligencia de Comunicacao (MIT)
REM Arquivo em ASCII e CRLF de proposito (cmd e sensivel aos dois).
REM ---------------------------------------------------------------------------
setlocal
set "DESTINO=%~1"
if "%DESTINO%"=="" echo Onde instalar? Digite a letra do disco, como E:\ , ou o caminho de uma pasta.
if "%DESTINO%"=="" set /p "DESTINO=Destino [%USERPROFILE%\AudiensBR-Fit]: "
if "%DESTINO%"=="" set "DESTINO=%USERPROFILE%\AudiensBR-Fit"
REM Caminho colado entre aspas: remove as aspas
set "DESTINO=%DESTINO:"=%"
REM Caminho absoluto e sem barra no fim
for %%i in ("%DESTINO%\.") do set "DESTINO=%%~fi"
if "%DESTINO:~-1%"=="\" set "DESTINO=%DESTINO:~0,-1%"
set "ORIGEM=%~dp0"
set "RT=%DESTINO%\runtime-win"
set "CURL=%SystemRoot%\System32\curl.exe"
set "TAR=%SystemRoot%\System32\tar.exe"
if not exist "%TAR%" echo ERRO: este Windows nao tem o tar. Precisa do Windows 10 1803 ou mais novo.
if not exist "%TAR%" goto falha
REM Ambiente limpo: um Python da maquina nao pode interferir no do destino
set "PYTHONHOME="
set "PYTHONPATH="
set "PYTHONNOUSERSITE=1"
set "PYTHONUTF8=1"

echo == AudiensBR Fit: instalando em %DESTINO%\ ==
mkdir "%DESTINO%\modelos" 2>nul
mkdir "%RT%" 2>nul
if not exist "%RT%\" echo ERRO: nao foi possivel criar pastas em "%DESTINO%\".
if not exist "%RT%\" goto falha

echo Copiando o aplicativo...
for %%d in (app prompts docs launchers recursos) do robocopy "%ORIGEM%%%d" "%DESTINO%\audiens-fit\%%d" /e /xd __pycache__ /njh /njs /ndl /nc /ns /nfl /np >nul
for %%f in (requirements.txt README.md README.en.md LICENSE LICENSE-CONTEUDO NOTICE instalar-mac.command instalar-windows.bat) do if exist "%ORIGEM%%%f" copy /y "%ORIGEM%%%f" "%DESTINO%\audiens-fit\" >nul
if not exist "%DESTINO%\audiens-fit\app\servidor.py" echo ERRO: copia falhou. Confira se este arquivo esta na pasta descompactada do projeto.
if not exist "%DESTINO%\audiens-fit\app\servidor.py" goto falha

REM -- Python portatil (a mesma distribuicao usada no Mac) --
if exist "%RT%\python\python.exe" goto dependencias
echo Baixando Python portatil, cerca de 42 MB...
"%CURL%" -fL --retry 3 --progress-bar -o "%RT%\python.tgz" "https://github.com/astral-sh/python-build-standalone/releases/download/20241206/cpython-3.12.8%%2B20241206-x86_64-pc-windows-msvc-install_only.tar.gz"
if errorlevel 1 echo ERRO: download do Python falhou. Confira sua internet.
if errorlevel 1 goto falha
"%TAR%" -xzf "%RT%\python.tgz" -C "%RT%"
del "%RT%\python.tgz" 2>nul
if not exist "%RT%\python\python.exe" echo ERRO: Python nao encontrado apos a extracao.
if not exist "%RT%\python\python.exe" goto falha

:dependencias
echo Instalando dependencias no destino...
"%RT%\python\python.exe" -m pip install -q --disable-pip-version-check --no-warn-script-location -r "%DESTINO%\audiens-fit\requirements.txt"
if errorlevel 1 echo ERRO: instalacao das dependencias falhou. Confira sua internet.
if errorlevel 1 goto falha

REM -- Ollama portatil --
if exist "%RT%\ollama\ollama.exe" goto modelos
set "ARQ=amd64"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARQ=arm64"
echo Baixando Ollama portatil, pode passar de 1,7 GB...
"%CURL%" -fL --retry 3 --progress-bar -o "%RT%\ollama.zip" "https://github.com/ollama/ollama/releases/latest/download/ollama-windows-%ARQ%.zip"
if errorlevel 1 echo ERRO: download do Ollama falhou. Confira sua internet.
if errorlevel 1 goto falha
mkdir "%RT%\ollama" 2>nul
"%TAR%" -xf "%RT%\ollama.zip" -C "%RT%\ollama"
del "%RT%\ollama.zip" 2>nul
if not exist "%RT%\ollama\ollama.exe" echo ERRO: Ollama nao encontrado apos a extracao.
if not exist "%RT%\ollama\ollama.exe" goto falha

:modelos
copy /y "%ORIGEM%launchers\AudiensBR Fit.bat" "%DESTINO%\" >nul
copy /y "%ORIGEM%launchers\Encerrar AudiensBR.bat" "%DESTINO%\" >nul
if not exist "%DESTINO%\AudiensBR Fit.bat" echo ERRO: falha ao copiar os atalhos.
if not exist "%DESTINO%\AudiensBR Fit.bat" goto falha
if "%AUDIENS_INSTALAR_SEM_MODELOS%"=="1" goto pronto
REM Porta dedicada: nao reaproveita um Ollama da maquina, senao os modelos
REM iriam parar na pasta DELE, nao no destino
set "OLLAMA_HOST=127.0.0.1:11435"
set "OLLAMA_MODELS=%DESTINO%\modelos"
"%CURL%" -s --max-time 2 "http://%OLLAMA_HOST%/api/tags" >nul 2>&1
if not errorlevel 1 echo ERRO: a porta 11435 ja esta em uso. Feche o AudiensBR Fit e rode de novo.
if not errorlevel 1 goto falha
start "" /b "%RT%\ollama\ollama.exe" serve >nul 2>&1
for /l %%i in (1,1,30) do "%CURL%" -s --max-time 1 "http://%OLLAMA_HOST%/api/tags" >nul 2>&1 || ping -n 2 127.0.0.1 >nul
"%CURL%" -s --max-time 2 "http://%OLLAMA_HOST%/api/tags" >nul 2>&1
if errorlevel 1 echo ERRO: o Ollama do destino nao respondeu na porta 11435.
if errorlevel 1 goto falha_ollama
echo Baixando o modelo do perfil normal, qwen3:4b-instruct, cerca de 2,5 GB...
"%RT%\ollama\ollama.exe" pull qwen3:4b-instruct
if errorlevel 1 echo ERRO: download do modelo falhou. Confira sua internet e rode de novo.
if errorlevel 1 goto falha_ollama
set "R="
set /p "R=Baixar tambem o modelo turbo qwen3:8b, 5,2 GB, para maquinas de 16 GB ou mais? [s/N] "
if /i "%R%"=="s" "%RT%\ollama\ollama.exe" pull qwen3:8b
call :fechar_ollama

:pronto
echo == Pronto. Abra "AudiensBR Fit.bat" em %DESTINO%\ ==
pause
exit /b 0

:falha_ollama
call :fechar_ollama
:falha
echo A instalacao nao foi concluida.
pause
exit /b 1

:fechar_ollama
REM Encerra so processos cujo executavel esta no destino
powershell -NoProfile -Command "$r=$env:RT+'\ollama\'; Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($r,'OrdinalIgnoreCase') } | Stop-Process -Force -ErrorAction SilentlyContinue"
exit /b 0
