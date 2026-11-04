# Kinetra Poller

Monitorea jobs de Kinetra en Virtuals Protocol y envía notificaciones a Telegram.

## Setup

### 1. Crear repositorio en GitHub

Crea un repo **público** (los repos públicos tienen minutos ilimitados en Actions).

### 2. Subir estos archivos

```bash
cd kinetra-github
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/TU_USUARIO/kinetra-poller.git
git push -u origin main
```

### 3. Configurar Secrets

En GitHub: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Valor | Cómo obtenerlo |
|---|---|---|
| `ACP_CONFIG_JSON` | Contenido de `~/.config/acp/config.json` | `cat ~/.config/acp/config.json` |
| `ACP_SIGNER_KEYS_JSON` | Contenido de `~/.config/acp-cli/signer-keys.json` | `cat ~/.config/acp-cli/signer-keys.json` |
| `TELEGRAM_BOT_TOKEN` | `7737047102:AAFGAcbUCIhOhxSRAOezcT-J4L3xHJISbzc` | Ya lo tienes |
| `TELEGRAM_CHAT_ID` | `1222225964` | Ya lo tienes |

### 4. Verificar

Ve a **Actions → Kinetra Poller → Run workflow** para ejecutar manualmente y verificar que funciona.

### Notas

- El workflow corre cada 5 minutos automáticamente.
- Si el servidor de ACP devuelve 500, el poller lo registra y reintenta en el siguiente ciclo.
- El estado de jobs conocidos se guarda en `state/known_jobs.json` y se commitea automáticamente.
- Los repos públicos tienen minutos ilimitados en GitHub Actions.