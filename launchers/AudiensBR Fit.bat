@echo off
REM AudiensBR Fit - launcher Windows
REM Criado por Daniel Bastos - Data Design Inteligencia de Comunicacao (MIT)
REM AVISO: antivirus/SmartScreen podem alertar sobre este .bat - veja o README.
REM O instalador copia este arquivo para a RAIZ do destino (ao lado de
REM modelos\, runtime-win\ e audiens-fit\).
REM Arquivo em ASCII e CRLF de proposito (cmd e sensivel aos dois).
setlocal
set "RAIZ=%~dp0"
if "%RAIZ:~-1%"=="\" set "RAIZ=%RAIZ:~0,-1%"
set "RT=%RAIZ%\runtime-win"
set "APP=%RAIZ%\audiens-fit"
set "CURL=%SystemRoot%\System32\curl.exe"

REM Porta dedicada: isola de qualquer Ollama do sistema em uso por outro
REM programa (ex.: o AudiensBR completo)
set "OLLAMA_HOST=127.0.0.1:11435"
set "OLLAMA_URL=http://%OLLAMA_HOST%"
REM Forcado: um OLLAMA_MODELS herdado da maquina nao pode vazar ao pendrive
set "OLLAMA_MODELS=%RAIZ%\modelos"
set "PYTHONHOME="
set "PYTHONPATH="
set "PYTHONNOUSERSITE=1"
set "PYTHONUTF8=1"
REM Sem o modelo turbo baixado, usa o perfil normal mesmo com 16 GB de RAM
if not defined AUDIENS_FIT_PERFIL if not exist "%OLLAMA_MODELS%\manifests\registry.ollama.ai\library\qwen3\8b" set "AUDIENS_FIT_PERFIL=normal"

echo ================================================
echo   AudiensBR Fit - Data Design
echo   Durante a analise, evite abrir aplicativos
echo   pesados: o modelo usa a maior parte da RAM.
echo   Sem GPU compativel, a analise sera LENTA.
echo ================================================

REM Python do destino; o venv e de instalacoes antigas
set "PY=%RT%\python\python.exe"
if not exist "%PY%" set "PY=%RT%\venv\Scripts\python.exe"
if not exist "%PY%" echo ERRO: Python do destino nao encontrado. Rode o instalador primeiro.
if not exist "%PY%" goto falha
if not exist "%APP%\app\servidor.py" echo ERRO: aplicativo nao encontrado em "%APP%". Rode o instalador primeiro.
if not exist "%APP%\app\servidor.py" goto falha

REM Ja aberto: so reabre o navegador
"%CURL%" -s --max-time 2 http://127.0.0.1:5001/ >nul 2>&1
if not errorlevel 1 echo O AudiensBR Fit ja esta aberto. Abrindo o navegador...
if not errorlevel 1 start "" http://localhost:5001
if not errorlevel 1 exit /b 0

"%CURL%" -s --max-time 2 "%OLLAMA_URL%/api/tags" >nul 2>&1
if not errorlevel 1 goto servidor
echo Iniciando Ollama na porta dedicada 11435...
set "OLLAMA_EXE=%RT%\ollama\ollama.exe"
if not exist "%OLLAMA_EXE%" set "OLLAMA_EXE=ollama"
start "" /b "%OLLAMA_EXE%" serve >nul 2>&1
for /l %%i in (1,1,30) do "%CURL%" -s --max-time 1 "%OLLAMA_URL%/api/tags" >nul 2>&1 || ping -n 2 127.0.0.1 >nul
"%CURL%" -s --max-time 2 "%OLLAMA_URL%/api/tags" >nul 2>&1
if errorlevel 1 echo ERRO: o Ollama nao respondeu. Rode o instalador de novo.
if errorlevel 1 goto falha

:servidor
echo Iniciando AudiensBR Fit... a primeira carga pode levar minutos em pendrive
REM O navegador abre depois, com o servidor ja no ar
start "" /b cmd /c "ping -n 5 127.0.0.1 >nul & start http://localhost:5001"
cd /d "%APP%"
"%PY%" -m app.servidor
exit /b 0

:falha
pause
exit /b 1
