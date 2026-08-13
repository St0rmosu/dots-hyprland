# dots-hyprland — Dotfiles per Hyprland (end-4's)

[![Hyprland](https://img.shields.io/badge/Hyprland-0.55+-4B9CD3?style=for-the-badge&logo=hyprland&logoColor=white)](https://hyprland.org/)
[![QML](https://img.shields.io/badge/QtQuick%20(QML)-41CD52?style=for-the-badge&logo=qt&logoColor=white)](https://doc.qt.io/qt-6/qtquick-index.html)
[![Lua](https://img.shields.io/badge/Lua-2C2D72?style=for-the-badge&logo=lua&logoColor=white)](https://www.lua.org/)
[![GPLv3](https://img.shields.io/badge/Licenza-GPLv3-blue?style=for-the-badge)](LICENSE)

Fork di [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) (stile "illogical-impulse"). Configurazione completa per un desktop Hyprland che include un **graphical shell custom in QtQuick/Quickshell**: barre, launcher, notifiche, controllo media, integrazione AI (Gemini/Ollama), temi Material Design 3 generati dal wallpaper e decine di servizi. Non è uno script di setup di sistema: installa solo le configurazioni e le dipendenze, non driver GPU o altre componenti di sistema.

## Caratteristiche

- **Shell custom "illogical-impulse"**: pannelli, launcher, notifiche e dialog scritti in QML con QtQuick/Quickshell.
- **AI integrata**: assistente Gemini/Ollama, traduzione dello schermo, ricerca Google Lens, OCR.
- **Material-Design-3 dinamico**: palette colori generata dal wallpaper (via Matugen/kde-material-you-colors) applicata a tutto il desktop.
- **Stato del sistema**: audio, batteria, rete, clima, risorse, aggiornamenti, rilevazione brani (SongRec).
- **Estensibilità**: ~50 servizi modulari in `services/` e 2 "panel families" (IllogicalImpulseFamily, WaffleFamily).
- **Setup trasparente**: lo script `setup` mostra ogni comando prima di eseguirlo.
- **Utility di diagnostica**: script `diagnose` che raccoglie log di sistema per le issue.

## Tech Stack

| Componente | Ruolo |
|---|---|
| Hyprland (compositor) | Compositor Wayland + finestre |
| Quickshell / QtQuick QML | Shell desktop e widgets |
| Lua | Configurazione Hyprland (0.55 "Luaification") |
| Bash | Script `setup`/`diagnose` e script di servizio |
| Python (venv uv) | Script dei servizi (es. AI, wallpaper) |
| Matugen / kde-material-you-colors | Tema Material 3 dal wallpaper |
| fish / foot / fuzzel / kitty / mpv / wlogout | Applicazioni configurate |
| Systemd user units | Servizi e demoni utente |
| Git submodules | Componenti QML condivisi (rounded-polygon-qmljs) |

## Architettura

I file rispecchiano la gerarchia di `$HOME`: `dots/` contiene `~/.config` e `~/.local/share`, `dots-extra/` i componenti opzionali, `sdata/` i dati dello script di installazione.

```
        dots/  (rispecchia $HOME)
        │
        ├── .config/
        │   ├── hypr/            # Compositor: hyprland.lua, custom/, hyprlock, hypridle
        │   └── quickshell/ii/   # Shell grafica: shell.qml, services/, panelFamilies/, scripts/
        ├── .local/share/        # Icone, profili konsole
        │
        dots-extra/              # Config opzionali (emacs, fcitx5, fedora, swaylock, nix)
        sdata/                   # Engine dello script setup (lib/, subcmd-*, dist-*)
        setup                    # Dispatcher: install / update / uninstall / ...
        diagnose                 # Raccolta log di diagnosi
```

```
                 ┌─────────────────────────────┐
                 │         Hyprland            │
                 │   hyprland.lua (config Lua) │
                 └──────────────┬──────────────┘
                                │ Wayland
              ┌─────────────────┴─────────────────┐
              ▼                                   ▼
    ┌──────────────────────┐            ┌──────────────────────┐
    │  Quickshell (QML)    │            │  App / systemd user  │
    │  shell.qml           │            │  servi, keyring, ... │
    │  panelFamilies/      │            └──────────────────────┘
    │  services/ (~50)     │
    └──────────┬───────────┘
               │ (submodule)
               ▼
    ┌──────────────────────────────┐
    │ rounded-polygon-qmljs        │
    │ (widgets condivisi)          │
    └──────────────────────────────┘
```

## Project Structure

```
dots-hyprland/
├── dots/
│   ├── .config/hypr/           # Config del compositor (Lua) + hyprlock/hypridle
│   ├── .config/quickshell/ii/  # Shell QML: modules/, services/, panelFamilies/, scripts/
│   └── .local/share/           # Icone e profili applicativi
├── dots-extra/                 # Emacs, fcitx5, fedora, fontsets, swaylock, via-nix
├── sdata/                      # Dati setup: lib/, subcmd-*, dist-{arch,fedora,gentoo,nix}
├── setup                       # Script di installazione (subcomandi)
├── diagnose                    # Script di diagnostica per le issue
├── .github/                    # README upstream, workflows (AI moderator), issue template
└── .gitmodules                 # Submodule rounded-polygon-qmljs
```

## Installation & Setup

```bash
# Opzione rapida (documentata upstream)
bash <(curl -s https://ii.clsty.link/get)

# Oppure da questo fork
git clone https://github.com/St0rmosu/dots-hyprland.git
cd dots-hyprland
git submodule update --init --recursive
./setup install
```

Il comando `./setup install` esegue 4 fasi: saluto → installazione dipendenze per distro (`1.deps-router.sh`) → permessi/servizi (`2.setups.sh`: gruppi `video/i2c/input`, systemd user units, moduli uinput/i2c-dev, venv python via `uv`) → copia configurazioni in `~/.config`/`~/.local/share` (`3.files.sh`, con backup dei file in conflitto). Rifiuta l'esecuzione come root.

`./setup` accetta anche: `install-deps`, `install-setups`, `install-files`, `resetfirstrun`, `uninstall`, `exp-update`, `exp-merge`, `virtmon`, `checkdeps`, `help`.

## Usage

1. Al primo avvio, la shell mostra una finestra di benvenuto e il setup della prima esperienza.
2. Le scorciatoie principali sono definite in `dots/.config/hypr/hyprland/custom/keybinds.lua` (o `custom/keybinds.lua`).
3. La palette cambia automaticamente col wallpaper; modificala dai settings della shell.
4. Per la diagnostica, esegui `./diagnose` e incolla l'output nel template di issue.

## Screenshots / Demo

> Screenshot e demo upstream: consulta il [README originale](https://github.com/end-4/dots-hyprland). Documentazione completa su [ii.clsty.link](https://ii.clsty.link).

## API Documentation

Nessuna API pubblica: il progetto è una configurazione locale. Le uniche integrazioni sono quelle dei servizi (es. Ollama su `localhost:11434` per l'AI, API di servizi di sistema locali).

## Engineering Decisions

- **Configurazione dichiarativa + script**: `setup` separa nettamente dipendenze (`1`), permessi/servizi (`2`) e file (`3`), rendendo il processo idempotente e trasparente.
- **Rifiuto del root**: lo script si rifiuta di girare come root per evitare file di proprietà errata in `$HOME`.
- **Backup su conflitto**: i file già esistenti vengono salvati prima di essere sovrascritti, con tracciamento dei file installati.
- **Submodule per componenti condivisi**: `rounded-polygon-qmljs` è mantenuto separatamente e referenziato via git submodule.
- **Multi-distro**: `sdata/dist-{arch,fedora,gentoo,nix}` con relativi PKGBUILD/ebuild fornisce supporto cross-distro senza duplicare la logica.

## Testing

- `./diagnose` raccoglie lo stato completo (remote git, status/submodule, distro, versioni di Hyprland/Quickshell) per il debug.
- `./setup checkdeps` (dev) verifica le dipendenze.
- `./setup virtmon` (dev) crea monitor virtuali per testare la shell.
- Test manuali consigliati: avvio sessione, cambio wallpaper (tema), connessione audio/rete, esecuzione di servizi AI.

## Limitations & Future Improvements

- Fork del progetto upstream `end-4/dots-hyprland`: le modifiche sono destinate a riallinearsi all'upstream; consultare il [README upstream](https://github.com/end-4/dots-hyprland) per roadmap e annunci.
- Richiede Hyprland 0.55+ con la nuova configurazione Lua: chi usa versioni precedenti può avere incompatibilità.
- Le dipendenze variano per distro: consultare `sdata/deps-info.md`.
- Prossimi passi: riallineamento periodico con upstream, test della configurazione Fedora/Nix, estensione dei servizi della shell.

---

*Fork di [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) — vedi LICENSE (GPL-3.0).*
