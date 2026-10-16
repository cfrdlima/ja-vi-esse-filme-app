#!/usr/bin/env bash
# Configura o Claude Code deste projeto: plugins/skills, MCP e checagens de ambiente.
# Idempotente: pode rodar de novo sem duplicar nada.
set -euo pipefail
cd "$(dirname "$0")"

ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

echo "1/4 Pré-requisitos"
for cmd in claude jq git flutter dart; do
  command -v "$cmd" >/dev/null && ok "$cmd" || { warn "$cmd não encontrado"; MISSING=1; }
done
command -v gitleaks >/dev/null && ok gitleaks || warn "gitleaks ausente (sudo dnf install gitleaks)"
[ "${MISSING:-0}" = 1 ] && { echo "Instale o que falta e rode de novo."; exit 1; }

DART_VER=$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
if [ "$(printf '%s\n3.9\n' "$DART_VER" | sort -V | head -1)" = "3.9" ]; then
  ok "Dart $DART_VER (MCP do Flutter exige 3.9+)"
else
  warn "Dart $DART_VER < 3.9 — rode 'flutter upgrade' para o MCP do Flutter funcionar"
fi

echo "2/4 Plugins do projeto (.claude/settings.json)"
SETTINGS=.claude/settings.json
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"
tmp=$(mktemp)
jq '
  .extraKnownMarketplaces += {
    "dart-flutter":        { "source": { "source": "github", "repo": "flutter/agent-plugins" } },
    "claude-code-plugins": { "source": { "source": "github", "repo": "anthropics/claude-code" } }
  }
  | .enabledPlugins += {
    "dart-flutter@dart-flutter": true,
    "frontend-design@claude-code-plugins": true
  }
' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
ok "dart-flutter (skills Flutter + Dart + MCP do Flutter)"
ok "frontend-design (Anthropic)"

echo "3/4 MCP do projeto (.mcp.json)"
[ -f .mcp.json ] || echo '{"mcpServers":{}}' > .mcp.json
tmp=$(mktemp)
jq '.mcpServers += { "context7": { "type": "http", "url": "https://mcp.context7.com/mcp" } }' .mcp.json > "$tmp" && mv "$tmp" .mcp.json
ok "context7 (docs atualizadas de pacotes)"

echo "4/4 Skills próprias (.claude/skills/)"
for s in .claude/skills/*/SKILL.md; do [ -f "$s" ] && ok "$(basename "$(dirname "$s")")"; done

if ! grep -q "skills instaladas" CLAUDE.md 2>/dev/null; then
  cat >> CLAUDE.md <<'MD'

## Skills e plugins

Plugins declarados em `.claude/settings.json` (`dart-flutter`, `frontend-design`), MCP em `.mcp.json` (`context7`; o MCP do Flutter vem com o plugin) e skills próprias em `.claude/skills/` (`tmdb-endpoint`, `nova-feature-clean`, `tela-4-estados`).
**Em conflito com skills instaladas, a arquitetura e as convenções deste CLAUDE.md prevalecem** (ex.: `flutter-apply-architecture-best-practices` propõe outra divisão de camadas — siga a Clean Architecture por feature daqui).
MD
  ok "seção 'Skills e plugins' adicionada ao CLAUDE.md"
fi

cat <<'MSG'

Pronto. Agora:
  1. Rode `claude` nesta pasta e aceite instalar os plugins/marketplaces e o MCP do projeto quando ele perguntar.
  2. Confira com /plugin (instalados), /mcp (dart e context7 conectados) e /agents.
  3. git add .claude .mcp.json CLAUDE.md setup-claude.sh && git commit -m "chore: plugins, MCP e skills do Claude Code"

Se o Claude não oferecer a instalação, rode manualmente:
  claude plugin marketplace add flutter/agent-plugins
  claude plugin install dart-flutter@dart-flutter
  claude plugin marketplace add anthropics/claude-code
  claude plugin install frontend-design@claude-code-plugins   # se o nome mudou, veja em /plugin
MSG
