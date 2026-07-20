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
REM robocopy usa codigos de saida proprios (0-7 = sucesso, so 8+ e erro real)
if not exist "%DESTINO%\audiens-fit\app\servidor.py" (
  echo ERRO: copia falhou — "%DESTINO%\audiens-fit\app\servidor.py" nao existe.
  echo Confira se "%ORIGEM%" e a pasta descompactada do projeto e tente de novo.
  pause & exit /b 1
)

where python >nul 2>&1 || ( echo ERRO: Python nao encontrado. Instale em https://python.org e rode de novo. & pause & exit /b 1 )
echo Criando ambiente Python no pendrive...
python -m venv "%DESTINO%\runtime-win\venv"
if not exist "%DESTINO%\runtime-win\venv\Scripts\python.exe" (
  echo ERRO: criacao do ambiente Python falhou.
  pause & exit /b 1
)
"%DESTINO%\runtime-win\venv\Scripts\pip" install -q -r "%ORIGEM%requirements.txt"
if errorlevel 1 (
  echo ERRO: instalacao das dependencias Python falhou — confira sua internet.
  pause & exit /b 1
)

where ollama >nul 2>&1
if errorlevel 1 (
  echo AVISO: Ollama nao instalado. Baixe em https://ollama.com/download e rode este instalador de novo.
) else (
  echo Baixando o modelo do perfil normal para o pendrive...
  REM Porta dedicada: nao reaproveita um Ollama do sistema ja em uso por
  REM outro programa — senao os modelos iriam parar na pasta DELE, nao aqui.
  set OLLAMA_HOST=127.0.0.1:11435
  set OLLAMA_MODELS=%DESTINO%\modelos
  start /b "" ollama serve
  timeout /t 8 /nobreak >nul
  ollama pull qwen3:4b-instruct
  if errorlevel 1 (
    echo AVISO: download do modelo falhou ou foi interrompido — confira sua
    echo internet e rode o instalador de novo antes de usar o Audiens Fit.
  )
)
copy "%ORIGEM%launchers\Audiens Fit.bat" "%DESTINO%\" >nul
if not exist "%DESTINO%\Audiens Fit.bat" (
  echo ERRO: falha ao copiar o launcher para "%DESTINO%".
  pause & exit /b 1
)
echo == Pronto. Abra "Audiens Fit.bat" na raiz de %DESTINO% ==
pause
