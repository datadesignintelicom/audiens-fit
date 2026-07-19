#!/bin/bash
# Encerra o Audiens Fit e descarrega os modelos da RAM.
pkill -f "app.servidor" 2>/dev/null
curl -s http://localhost:11434/api/generate -d '{"model":"qwen3:4b-instruct","keep_alive":0}' >/dev/null 2>&1
curl -s http://localhost:11434/api/generate -d '{"model":"qwen3:8b","keep_alive":0}' >/dev/null 2>&1
echo "Audiens Fit encerrado e RAM liberada. Pode fechar esta janela."
