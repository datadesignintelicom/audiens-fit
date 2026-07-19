@echo off
REM Audiens Fit — instalador Windows
REM Uso: instalar-pendrive.bat E:\
REM AVISO: antivirus/SmartScreen podem alertar sobre este .bat — veja o README.
setlocal
set DESTINO=%~1
if "%DESTINO%"=="" ( echo Uso: %~nx0 E:\  & exit /b 1 )
set ORIGEM=%~dp0..
echo -- Audiens Fit: instalando em %DESTINO% --

mkdir "%DESTINO%\modelos" 2>nul
mkdir "%DESTINO%\runtime-win" 2>nul
xcopy /e /i /q /y "%ORIGEM%" "%DESTINO%\audiens-fit" /exclude:%~dp0excluir.txt

where python >nul 2>&1 || ( echo ERRO: Python nao encontrado. Instale em https://python.org & exit /b 1 )
echo Criando venv...
python -m venv "%DESTINO%\runtime-win\venv"
"%DESTINO%\runtime-win\venv\Scripts\pip" install -q -r "%ORIGEM%\requirements.txt"

where ollama >nul 2>&1
if errorlevel 1 (
  echo AVISO: Ollama nao instalado. Baixe em https://ollama.com/download e rode de novo.
) else (
  echo Baixando modelo do perfil normal...
  set OLLAMA_MODELS=%DESTINO%\modelos
  ollama pull qwen3:4b-instruct
)
copy "%ORIGEM%\launchers\Audiens Fit.bat" "%DESTINO%\" >nul
echo -- Pronto. Abra "Audiens Fit.bat" na raiz de %DESTINO% --
pause
