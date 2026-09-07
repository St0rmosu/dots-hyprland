# Google Tasks 2-Way Sync per Quickshell

Questo modulo sincronizza bidirezionalmente i promemoria del widget To-Do di Quickshell (`~/.local/state/quickshell/user/todo.json`) con Google Tasks.

## File di configurazione
- `credentials.json`: Scaricato da Google Cloud Console (OAuth Desktop Client).
- `token.json`: Generato automaticamente al primo login con `--auth`.
- `state.json`: Mantiene lo stato dell'ultima sincronizzazione per calcolare le modifiche locali/remote.
- `sync.py`: Script di sincronizzazione bidirezionale.
- `sync.sh`: Wrapper con gestione lock e virtualenv.

## Come autenticarsi la prima volta
```bash
~/.config/google-tasks-sync/sync.sh --auth
```
