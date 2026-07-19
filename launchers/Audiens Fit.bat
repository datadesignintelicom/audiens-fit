@echo off
REM Audiens Fit — launcher Windows
REM Criado por Daniel Bastos - Data Design Inteligencia de Comunicacao (MIT)
REM AVISO: antivirus/SmartScreen podem alertar sobre este .bat — veja o README.
cd /d "%~dp0.."
set RAIZ=%cd%
if "%OLLAMA_MODELS%"=="" set OLLAMA_MODELS=%RAIZ%\..\modelos

echo ================================================
echo   Audiens Fit - Data Design
echo   Durante a analise, evite abrir aplicativos
echo   pesados: o modelo usa a maior parte da RAM.
echo   Sem GPU compativel, a analise sera LENTA.
echo ================================================

curl -s --max-time 2 http://localhost:11434/api/tags >nul 2>&1
if errorlevel 1 (
  echo Iniciando Ollama...
  if exist "%RAIZ%\..\runtime-win\ollama\ollama.exe" (
    start /b "" "%RAIZ%\..\runtime-win\ollama\ollama.exe" serve
  ) else (
    start /b "" ollama serve
  )
  timeout /t 8 /nobreak >nul
)

set VENV=%RAIZ%\..\runtime-win\venv
if not exist "%VENV%\Scripts\python.exe" (
  echo ERRO: venv nao encontrado. Rode o instalador primeiro.
  pause & exit /b 1
)

echo Iniciando Audiens Fit... (primeira carga pode levar minutos em pendrive)
start "" http://localhost:5001
"%VENV%\Scripts\python.exe" -m app.servidor
pause
