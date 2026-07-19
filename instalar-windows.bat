@echo off
REM ---------------------------------------------------------------------------
REM Audiens Fit — instalador Windows (pendrive autossuficiente) — NAO TESTADO
REM A maquina que PREPARA o pendrive precisa de internet e de Python+Ollama
REM instalados (versao autossuficiente do runtime Windows chega em breve).
REM Uso: instalar-windows.bat E:\
REM AVISO: antivirus/SmartScreen podem alertar sobre este .bat — veja o README.
REM Criado por Daniel Bastos - Data Design Inteligencia de Comunicacao (MIT)
REM ---------------------------------------------------------------------------
setlocal
set DESTINO=%~1
if "%DESTINO%"=="" ( echo Uso: %~nx0 E:\  & exit /b 1 )
set ORIGEM=%~dp0
echo == Audiens Fit: instalando em %DESTINO% ==

mkdir "%DESTINO%\modelos" 2>nul
mkdir "%DESTINO%\runtime-win" 2>nul
robocopy "%ORIGEM%." "%DESTINO%\audiens-fit" /e /njh /njs /ndl /nc /ns /xd runtime-mac runtime-win .git >nul

where python >nul 2>&1 || ( echo ERRO: Python nao encontrado. Instale em https://python.org e rode de novo. & pause & exit /b 1 )
echo Criando ambiente Python no pendrive...
python -m venv "%DESTINO%\runtime-win\venv"
"%DESTINO%\runtime-win\venv\Scripts\pip" install -q -r "%ORIGEM%requirements.txt"

where ollama >nul 2>&1
if errorlevel 1 (
  echo AVISO: Ollama nao instalado. Baixe em https://ollama.com/download e rode este instalador de novo.
) else (
  echo Baixando o modelo do perfil normal para o pendrive...
  set OLLAMA_MODELS=%DESTINO%\modelos
  ollama pull qwen3:4b-instruct
)
copy "%ORIGEM%launchers\Audiens Fit.bat" "%DESTINO%\" >nul
echo == Pronto. Abra "Audiens Fit.bat" na raiz de %DESTINO% ==
pause
