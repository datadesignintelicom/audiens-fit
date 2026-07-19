# ---------------------------------------------------------------------------
# Audiens Fit — config.py
# Perfil adaptativo por RAM, carga e validação do prompts.json.
#
# Criado por Daniel Bastos · Data Design Inteligência de Comunicação
# Código sob licença MIT; prompts e documentação sob CC-BY-NC-4.0.
# ---------------------------------------------------------------------------

import ctypes
import json
import os
import platform
import subprocess
import sys

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPTS_PATH = os.path.join(RAIZ, "prompts", "prompts.json")

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")
SEED = 42
BATCH_SIZE = 25
PORTA = int(os.getenv("AUDIENS_FIT_PORTA", "5001"))

# Posicionamentos são o bloco mais exigente do modelo compacto —
# desligáveis sem tocar em código (AUDIENS_FIT_POSICIONAMENTOS=0)
POSICIONAMENTOS_ATIVOS = os.getenv("AUDIENS_FIT_POSICIONAMENTOS", "1") != "0"


def _ram_gb():
    """RAM física total em GB, sem dependências externas."""
    try:
        if platform.system() == "Darwin":
            saida = subprocess.check_output(["sysctl", "-n", "hw.memsize"], timeout=5)
            return int(saida.strip()) / (1024 ** 3)
        if platform.system() == "Windows":
            class MEMORYSTATUSEX(ctypes.Structure):
                _fields_ = [("dwLength", ctypes.c_ulong), ("dwMemoryLoad", ctypes.c_ulong),
                            ("ullTotalPhys", ctypes.c_ulonglong), ("ullAvailPhys", ctypes.c_ulonglong),
                            ("ullTotalPageFile", ctypes.c_ulonglong), ("ullAvailPageFile", ctypes.c_ulonglong),
                            ("ullTotalVirtual", ctypes.c_ulonglong), ("ullAvailVirtual", ctypes.c_ulonglong),
                            ("ullAvailExtendedVirtual", ctypes.c_ulonglong)]
            stat = MEMORYSTATUSEX()
            stat.dwLength = ctypes.sizeof(MEMORYSTATUSEX)
            ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(stat))
            return stat.ullTotalPhys / (1024 ** 3)
        # Linux
        with open("/proc/meminfo") as f:
            for linha in f:
                if linha.startswith("MemTotal"):
                    return int(linha.split()[1]) / (1024 ** 2)
    except Exception:
        pass
    return 8.0  # fallback conservador


def _definir_perfil():
    """
    normal (< 16 GB): qwen3:4b-instruct, num_ctx de síntese 6144
    turbo (>= 16 GB): qwen3:8b, num_ctx de síntese 8192
    Override manual: AUDIENS_FIT_PERFIL=normal|turbo ou AUDIENS_FIT_MODELO=<tag>
    """
    ram = _ram_gb()
    forcado = os.getenv("AUDIENS_FIT_PERFIL", "").strip().lower()
    turbo = forcado == "turbo" if forcado in ("normal", "turbo") else ram >= 15.5
    perfil = {
        "nome":            "turbo" if turbo else "normal",
        "ram_gb":          round(ram, 1),
        # Tag EXPLÍCITA de variante: o tag genérico qwen3:4b aponta para a
        # variante "thinking", que ignora think:false e quebra classificadores
        "modelo":          "qwen3:8b" if turbo else "qwen3:4b-instruct",
        "num_ctx":         4096,
        "num_ctx_sintese": 8192 if turbo else 6144,
        "amostra_sintese": 120 if turbo else 100,
    }
    override = os.getenv("AUDIENS_FIT_MODELO", "").strip()
    if override:
        perfil["modelo"] = override
    return perfil


PERFIL = _definir_perfil()


def carregar_prompts():
    """
    Carrega e valida o prompts.json. Falha de sintaxe interrompe a partida
    com mensagem clara — melhor do que analisar com prompt corrompido.
    """
    obrigatorias = {"sentimento_lote", "sintese", "sintese_bloco_posicionamentos",
                    "percepcoes_lote", "temas_lote", "posicionamentos_lote", "perguntas"}
    try:
        with open(PROMPTS_PATH, encoding="utf-8") as f:
            prompts = json.load(f)
    except json.JSONDecodeError as e:
        sys.exit(f"[AUDIENS FIT] prompts/prompts.json inválido (linha {e.lineno}): {e.msg}\n"
                 f"Corrija o arquivo ou restaure a versão original do repositório.")
    except FileNotFoundError:
        sys.exit("[AUDIENS FIT] prompts/prompts.json não encontrado.")
    faltando = obrigatorias - set(prompts)
    if faltando:
        sys.exit(f"[AUDIENS FIT] prompts.json sem as chaves: {', '.join(sorted(faltando))}")
    return prompts


PROMPTS = carregar_prompts()
