@echo off
REM Audiens Fit — launcher Windows
REM Criado por Daniel Bastos - Data Design Inteligencia de Comunicacao (MIT)
REM AVISO: antivirus/SmartScreen podem alertar sobre este .bat — veja o README.
REM O instalador copia este arquivo para a RAIZ do destino (ao lado de
REM modelos\, runtime-win\ e audiens-fit\) — a base e a propria pasta do
REM launcher, sem subir nivel algum (evita depender de "E:\.." virar "E:\").
set RAIZ=%~dp0
if "%RAIZ:~-1%"=="\" set RAIZ=%RAIZ:~0,-1%

REM Porta dedicada: isola de qualquer Ollama do sistema ja em uso por outro
REM programa (ex.: o Audiens completo) — nunca reaproveita silenciosamente
set OLLAMA_HOST=127.0.0.1:11435
set OLLAMA_URL=http://%OLLAMA_HOST%
REM Forcado (nao apenas "se ainda nao definido"): a maquina pode ja ter
REM OLLAMA_MODELS herdado para outro fim e isso nao pode vazar ao pendrive
set OLLAMA_MODELS=%RAIZ%\modelos

echo ================================================
echo   Audiens Fit - Data Design
echo   Durante a analise, evite abrir aplicativos
echo   pesados: o modelo usa a maior parte da RAM.
echo   Sem GPU compativel, a analise sera LENTA.
echo ================================================

curl -s --max-time 2 http://%OLLAMA_HOST%/api/tags >nul 2>&1
if errorlevel 1 (
  echo Iniciando Ollama (porta dedicada 11435)...
  if exist "%RAIZ%\runtime-win\ollama\ollama.exe" (
    start /b "" "%RAIZ%\runtime-win\ollama\ollama.exe" serve
  ) else (
    start /b "" ollama serve
  )
  timeout /t 8 /nobreak >nul
)

set VENV=%RAIZ%\runtime-win\venv
if not exist "%VENV%\Scripts\python.exe" (
  echo ERRO: venv nao encontrado. Rode o instalador primeiro.
  pause & exit /b 1
)

set APP=%RAIZ%\audiens-fit
if not exist "%APP%\app\servidor.py" (
  echo ERRO: codigo do aplicativo nao encontrado em "%APP%". Rode o instalador primeiro.
  pause & exit /b 1
)

echo Iniciando Audiens Fit... (primeira carga pode levar minutos em pendrive)
start "" http://localhost:5001
cd /d "%APP%"
"%VENV%\Scripts\python.exe" -m app.servidor
pause
