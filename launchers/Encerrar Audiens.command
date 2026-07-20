#!/bin/bash
# Encerra o Audiens Fit e descarrega os modelos da RAM.
# Porta dedicada 11435: nunca manda descarregar modelos do Ollama de outro
# app (ex.: o Audiens completo, que pode estar em análise nesse momento).
pkill -f "app.servidor" 2>/dev/null
curl -s http://127.0.0.1:11435/api/generate -d '{"model":"qwen3:4b-instruct","keep_alive":0}' >/dev/null 2>&1
curl -s http://127.0.0.1:11435/api/generate -d '{"model":"qwen3:8b","keep_alive":0}' >/dev/null 2>&1
echo "Audiens Fit encerrado e RAM liberada. Pode fechar esta janela."
