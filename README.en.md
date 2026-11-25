# AudiensBR Fit

**Qualified audience listening — offline, portable and auditable.**

*Leia em [Português](README.md).*

> **Name change:** the project is now called AudiensBR, with the country suffix, to avoid confusion with a foreign tool working in the same segment.

## Why not just paste your spreadsheet into a paid AI chat?

You could paste a thousand comments into an LLM chat and ask for a summary.
What you get back: text with no method, no verifiable numbers, made-up
percentages that look precise, no report layout — and your data handed to a
third-party server. AudiensBR Fit does the opposite:

- **Real social listening methodology**: sentiment measured against the
  content (a protest written in positive words counts as opposed),
  perceptions and topics with percentages computed by **actual counting**,
  declared coverage, and never-forced labeling
- **Auditable end to end**: export the classified universe comment by
  comment and check every number; same corpus + same context = same result
  (fixed seed)
- **A ready report**, not a loose paragraph
- **100% offline**: your data never leaves the machine — it even runs from
  a USB drive

Created by **Daniel Bastos · Data Design Inteligência de Comunicação**.

Free, no ads, no tracking. If it saved you work, support its development:
**https://ko-fi.com/audiensbrasil** (international) ·
**https://apoia.se/audiensbrasil** (Brazil)

---

## What it does

- **Spreadsheet analysis** (XLSX/CSV) with automatic comment-column detection
- **Contextual receptivity** with favorable/opposed/unclear distribution
- **Overall interpretation** that starts with what is most frequent and states
  the weight of each claim in words ("many", "some", "a few"), with
  **minority voices** in a separate block
- **Perceptions, topics and stances** with real counts and verbatim quotes.
  Repeated comments always get the same classification
- **Ask the corpus**: "what do they say about pricing?" → answers with real
  quoted excerpts. Works without running the analysis — and unlike asking
  an online AI chat, your comments never leave the machine
- **XLSX export** as a single file with two sheets: classified universe +
  summary with coverage funnel and minority voices
- **Print** the report straight from the browser (Print button)

## Requirements and what to expect

| Host machine | Profile | Model | Expectation |
|---|---|---|---|
| Mac Apple Silicon 8 GB | normal | qwen3:4b-instruct | ~1,000 comments/hour (measured: 1,017 in 58 min on a MacBook M1) |
| Mac Apple Silicon 16 GB+ | turbo (automatic) | qwen3:8b | More accurate, similar pace |
| Intel/Windows without dedicated GPU | normal | qwen3:4b-instruct | ~100-250 comments/hour (estimate): plan hours for large corpora |

Pace depends more on the processor than on RAM: on Apple Silicon the model
runs on the integrated GPU (Metal); on an average Intel machine without a
dedicated GPU it runs CPU-only, roughly 4-8x slower — the table's estimate
has not yet been measured on real hardware.

**During analysis**: the model takes most of the RAM. On 8 GB machines,
close heavy apps and browsers with many tabs; the machine stays usable for
light tasks. A fast USB 3+ drive speeds up startup and model loading
(1-3 min); the analysis itself runs in RAM and does not depend on drive
speed.

## Installation

**Visual guides, with illustrated screens (in Portuguese):**

- 🍎 [**Visual step-by-step guide for Mac (PDF)**](docs/guia-instalacao-mac.pdf)
- 🪟 [**Visual step-by-step guide for Windows (PDF)**](docs/guia-instalacao-windows.pdf)
  — ⚠️ installation **not yet tested on a real Windows machine**; the guide shows
  the expected behavior. Tried it and something's off? Tell us:
  audiensbrasil@proton.me

**What each system needs:**

| | Mac | Windows |
|---|---|---|
| Machine that **prepares** the drive | Internet | Internet, with Python and Ollama installed |
| Machine that **uses** the drive | Nothing installed | Python and Ollama installed |
| Turbo model | Offered by the installer | Not downloaded by the installer |
| To open | **AudiensBR Fit** app ("Af" icon) | **AudiensBR Fit.bat** |

On Mac, the installer downloads Ollama, Python and the AI models onto the drive.
A drive prepared on a Mac does not run on Windows unless the Windows installer is
run on it too. Between Macs, the drive runs on the processor family it was
prepared on (Apple Silicon or Intel); to cover both, run the installer once on
each.

**Before you start, on either system:**

1. Download this repository (Code → Download ZIP) and unzip
2. Choose where to install: an **exFAT** external or USB drive (factory
   default), preferably a fast one, or a folder on the computer, with 16 GB
   free (24 GB to include the turbo model, on Mac)

### Install on Mac

1. Double-click `instalar-mac.command` and choose the destination when asked
   (or, in Terminal, `./instalar-mac.command /Volumes/YOUR_DRIVE`). If the Mac
   blocks it, see the Gatekeeper notice below
2. Open the **AudiensBR Fit** app (the "Af" icon) at the chosen destination —
   the browser opens by itself
3. To quit, open the **Encerrar AudiensBR** app (red icon). It frees the RAM
   and closes Fit's Ollama, so the drive can be ejected

Both apps are created by the installer on the machine itself, so they open
without the Gatekeeper warning.

### Install on Windows

1. Install [Python](https://www.python.org/downloads/) and
   [Ollama](https://ollama.com/download)
2. Double-click `instalar-windows.bat` and enter the destination when asked
   (or, in Command Prompt, `instalar-windows.bat E:\`)
3. Open **AudiensBR Fit.bat** at the chosen destination — the browser opens by
   itself

### System security notices

> ⚠️ **macOS notice (Gatekeeper)**: on first launch, the Mac may say the
> item *"can't be opened because Apple cannot check it for malicious
> software"* — standard for any script downloaded from the internet. Fix:
> System Settings → Privacy & Security → **"Open Anyway"** (shown right
> after the blocked attempt); or in Terminal:
> `xattr -d com.apple.quarantine instalar-mac.command "AudiensBR Fit.command"`.
>
> ⚠️ **Antivirus notice (Windows)**: `.bat` files may be flagged by
> SmartScreen or antivirus software, since batch scripts are a format
> malware also uses. Ours are open text — right-click → Edit to read
> exactly what they do before running. If SmartScreen blocks: "More info" →
> "Run anyway".

## Customize the methodology

Every interpretation prompt lives in **`prompts/prompts.json`** — editable
text, no code involved. Adjust tone, rules and definitions for your use
case; keep the `{placeholders}`. If the JSON breaks, the server reports the
error line at startup. Method details in
[`docs/metodologia.md`](docs/metodologia.md) (Portuguese).

## Want more? Meet the full AudiensBR

AudiensBR Fit is the portable, open edition of **AudiensBR**, Data Design's
listening platform, which goes much further: direct multi-platform
collection (Instagram, Facebook, YouTube, TikTok, X, Threads, Bluesky,
Reddit and LinkedIn), with per-post volume subject to the plan contracted with
the collection service on networks that require an intermediary; multi-layer
analysis with larger models; engagement authenticity auditing
(coordinated/inorganic activity detection) and full communication-intelligence
reports.

**Interested in professional analyses or licensing the technology?**
Contact Data Design Inteligência de Comunicação: **audiensbrasil@proton.me**

## Licenses

- **Code**: [MIT](LICENSE)
- **Prompts, methodology and documentation**: [CC-BY-NC-4.0](LICENSE-CONTEUDO) —
  free for **non-commercial** use with attribution; commercial use requires
  a license from Data Design
- The "Criado por Daniel Bastos · Data Design" credit in the interface and
  in these files is an attribution condition and must be preserved
