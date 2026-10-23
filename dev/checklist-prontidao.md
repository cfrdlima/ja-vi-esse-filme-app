# Checklist de prontidão do projeto — Já Vi Esse Filme

> Instruções para o Claude Code. É uma **auditoria somente leitura**: **não altere nenhum arquivo**, não instale pacotes e não faça commits.
> No fim, entregue o relatório no formato da seção "Formato do relatório".

## Como avaliar

O projeto está no **início** (Fase 0 do `dev/PLANO.md`). Por isso, classifique cada item em uma de quatro categorias:

| Status | Significado |
|---|---|
| ✅ OK | Já está correto. |
| ❌ Bloqueante | Precisa estar certo **antes** da primeira sessão de código. |
| ⚠️ Atenção | Não bloqueia o início, mas está errado ou arriscado. |
| 📅 Planejado | Ainda não existe e **é esperado**, porque está previsto numa fase do `PLANO.md`. Indique qual fase. |

Regras:
- **Comprove cada item** com o comando que rodou ou com o arquivo e a linha que leu. Não marque ✅ por suposição.
- Se não der para verificar (ex.: ferramenta ausente), marque ⚠️ e diga por quê.
- Se algo for 📅 mas **não estiver** no `PLANO.md`, marque ⚠️ e sugira em qual fase entrar.
- **Nunca** leia `env/dev.json`, `env/prod.json`, `android/key.properties`, `*.jks` ou `*.keystore`. Verifique a existência e o versionamento desses arquivos só com `ls` e `git ls-files`.

Leia antes de começar: `CLAUDE.md`, `dev/PLANO.md`, `dev/decisoes/`, `docs/DESIGN.md`, `design-system/` (se existir) e `pubspec.yaml`.

---

## 1. Ambiente de desenvolvimento
- [ ] `flutter --version` e `dart --version`: Flutter estável e **Dart ≥ 3.9** (exigido pelo MCP do Flutter).
- [ ] `flutter doctor -v`: Android toolchain e licenças OK. Ignore iOS/web/desktop se não forem alvo, mas relate.
- [ ] Emulador ou dispositivo disponível (`flutter devices`).
- [ ] Ferramentas presentes: `git`, `jq`, `gitleaks`, `python3`, `gh`.
- [ ] O `sdk:` do `pubspec.yaml` é compatível com o Dart instalado.

## 2. Repositório e Git
- [ ] Branch atual é `main`, e `git status` está limpo.
- [ ] Remote configurado (`git remote -v`) apontando para o repo **novo**, não o antigo do Next.js.
- [ ] O `.gitignore` cobre: `build/`, `.dart_tool/`, `env/*.json` com exceção de `env/example.json`, `android/key.properties`, `*.jks`, `*.keystore`, `coverage/`, `.env*` e arquivos de IDE.
- [ ] `git ls-files env/ android/key.properties` lista **só** `env/example.json`.
- [ ] **Histórico sem segredos**: `gitleaks detect --no-banner` (varre todos os commits) e `git log -p --all -S "api_key"` sem chave real.
- [ ] `env/example.json` contém só placeholder, sem chave real.
- [ ] O `env/dev.json` existe localmente. Verifique só com `ls`.
- [ ] Há um `README.md` do projeto novo, não o template do `flutter create` nem o do projeto antigo.

## 3. Configuração do Claude Code
- [ ] `CLAUDE.md` existe, é coerente com o estado atual (stack, comandos, estrutura) e não tem placeholders `[...]`.
- [ ] Comandos em `.claude/commands/`: `sessao`, `fechar-sessao`, `status`, `decisao`, `tarefa`, `revisar`.
- [ ] Subagentes em `.claude/agents/`: `code-reviewer`, `security-auditor`.
- [ ] `.claude/settings.json` é JSON válido (`jq . .claude/settings.json`) e contém:
  - o `deny` de leitura de segredos e de comandos destrutivos;
  - o hook `PostToolUse` de `dart format`;
  - os plugins `dart-flutter` e o de design habilitados.
- [ ] `.mcp.json` é válido e contém `context7`.
- [ ] Skills em `.claude/skills/`: `tmdb-endpoint`, `nova-feature-clean`, `tela-4-estados`, `ui-ux-pro-max`.
- [ ] Não há instruções contraditórias entre `CLAUDE.md`, skills, `docs/DESIGN.md` e `PLANO.md` (ex.: dois arquivos se dizendo fonte de design, ou pacote de estado diferente). Liste cada contradição.
- [ ] As skills de terceiros foram revisadas: nenhum script faz chamada de rede ou instala pacotes sem avisar.

## 4. Estrutura e arquitetura
- [ ] `pubspec.yaml`: nome `ja_vi_esse_filme`, descrição real, `publish_to: none` e versão `0.1.0+1` ou similar.
- [ ] As dependências declaradas batem com a stack do `CLAUDE.md`. Nada extra sem decisão registrada.
- [ ] Não há pastas vazias criadas por antecipação em `lib/`.
- [ ] `lib/main.dart` é mínimo, com um único `MaterialApp`, e sem lógica de negócio.
- [ ] Se já houver código em `lib/features/`: `domain/` não importa `flutter`, `http` nem storage. Verifique com `grep -rn "package:flutter\|package:http\|shared_preferences\|secure_storage" lib/features/*/domain`.
- [ ] Testes espelham `lib/`. Os arquivos de teste estão em `test/` com sufixo `_test.dart`.

## 5. Qualidade de código
- [ ] `flutter analyze` sem issues.
- [ ] `dart format --output=none --set-exit-if-changed lib/ test/` sem alterações pendentes.
- [ ] `analysis_options.yaml` é **estrito**. Ele deve incluir `strict-casts`, `strict-inference`, `strict-raw-types` e regras como `prefer_const_constructors`, `always_declare_return_types`, `avoid_dynamic_calls`, `unawaited_futures` e `avoid_print`. Se ainda for o padrão do `flutter create`, marque 📅 (Fase 0).
- [ ] Não há `// ignore:` nem `ignore_for_file` sem justificativa.

## 6. Testes
- [ ] `flutter test` passa. O teste padrão do template, se ainda existir, deve passar ou ser removido.
- [ ] `test/fixtures/` existe ou está previsto para o cliente TMDB.
- [ ] Nenhum teste acessa rede real. Verifique com `grep -rn "api.themoviedb.org" test/`, que deve aparecer só em fixtures ou asserções de URL.
- [ ] `flutter test --coverage` gera `coverage/lcov.info`.

## 7. Segurança (OWASP MASVS)
- [ ] **Chave do TMDB**: lida só via `String.fromEnvironment` em `core/config`. Não aparece em nenhum arquivo versionado (`git grep -n "<parte de chave>"` não é possível sem a chave; use `gitleaks` e `git grep -nE "api_key\s*[:=]\s*['\"][a-f0-9]{32}"`).
- [ ] A decisão 001 sobre chave e proxy existe e está com status claro.
- [ ] **Rede**: só HTTPS. `android:usesCleartextTraffic` está ausente ou é `false`. Não há `network_security_config` permitindo cleartext.
- [ ] **Manifest** (`android/app/src/main/AndroidManifest.xml`): só a permissão `INTERNET`, sem permissões a mais. `android:allowBackup="false"` (ou regras de backup que excluem dados sensíveis). Activities exportadas só quando necessário.
- [ ] **Storage**: o plano prevê `session_id` só no `flutter_secure_storage` (verifique `CLAUDE.md` e a decisão 001).
- [ ] **Logs**: não há `print(` em `lib/`. O plano de logging não registra chave nem sessão.
- [ ] **Release**: há plano para `--obfuscate --split-debug-info` e assinatura com keystore fora do git. Marque 📅 Fase 4 se ainda não existe.
- [ ] **Dependências**: `dart pub outdated` sem pacotes descontinuados. Todas as dependências são de publishers verificados ou muito usadas no pub.dev. Relate qualquer exceção.
- [ ] **Deep link do login TMDB** (Fase 2): o plano prevê validar a origem do retorno.
- [ ] **Privacidade/LGPD**: o app não coleta dado pessoal além do necessário. Há previsão de uma tela "Sobre" com política e atribuição ao TMDB. A política fica em `docs/PRIVACIDADE.md` (decisão 006). Confira se ela descreve o que o código trata hoje se não sobrou nenhum marcador "A REVISAR" antes do release e se as permissões do manifest mesclado (com os plugins) batem com a seção "Segurança" dela.

## 8. Android e build
- [ ] `applicationId` em `android/app/build.gradle(.kts)` é definitivo (ex.: `io.github.cfrdlima.ja_vi_esse_filme`), não `com.example`.
- [ ] `minSdk`, `targetSdk` e `compileSdk` são adequados: `targetSdk` atende o mínimo exigido hoje pela Play Store, e `minSdk` está justificado.
- [ ] O nome visível do app (`android:label`) é "Já Vi Esse Filme", não o nome do pacote.
- [ ] `flutter build apk --debug --dart-define-from-file=env/dev.json` compila.
- [ ] `flutter run --dart-define-from-file=env/dev.json` sobe sem erro no emulador. Só confirme que abre.
- [ ] Ícone e splash: 📅 Fase 4, se ainda forem os padrão.

## 9. Design, UI e UX
- [ ] Há **uma única fonte da verdade** de design: `design-system/ja-vi-esse-filme/MASTER.md`, com `docs/DESIGN.md` como ponteiro e regras de adaptação. Se o `MASTER.md` ainda não existe, marque 📅 Fase 0.
- [ ] O `MASTER.md` (se existir) define paleta do tema escuro, tipografia, escala de espaçamento, raios, estilo e anti-padrões, **com stack Flutter**.
- [ ] Fontes: o plano é empacotar em `assets/fonts/`, sem o pacote `google_fonts`.
- [ ] Tokens em `lib/core/theme/` (se existirem): Material 3, `ColorScheme` escuro, `ThemeExtension`, e nenhuma cor hard-coded fora do tema. Verifique com `grep -rn "Color(0x" lib/ --include=*.dart | grep -v core/theme`.
- [ ] O padrão dos **4 estados de tela** (carregando/vazio/erro/sucesso) está documentado e é exigido pela skill `tela-4-estados`.
- [ ] A navegação planejada está clara: abas Descobrir / Buscar / Minha estante / Perfil com `go_router`.
- [ ] O plano prevê micro-interações coerentes, como Hero do pôster para detalhes e feedback de toque.

## 10. Acessibilidade
- [ ] Contraste AA exigido no `CLAUDE.md` e testável (teste de contraste previsto nos tokens).
- [ ] Alvo de toque ≥ 48dp, `Semantics` em elementos clicáveis e teste com fonte grande (`textScaler` 1.5) previstos.
- [ ] Textos de UI preparados para leitor de tela: pôster com label, não só imagem.

## 11. Performance
- [ ] O plano prevê `ListView`/`GridView.builder`, `cached_network_image` com tamanho de imagem do TMDB adequado e `const` constructors.
- [ ] Efeitos pesados (blur, glassmorphism) restritos a pontos isolados, conforme `docs/DESIGN.md`.
- [ ] Paginação infinita feita no repositório, com debounce na busca.

## 12. Internacionalização e conteúdo
- [ ] Idioma das requisições ao TMDB é `pt-BR`, com fallback definido.
- [ ] Decidir se as strings de UI ficam centralizadas (`flutter_localizations` + ARB) desde já ou em constantes. Marque ⚠️ se não houver decisão.
- [ ] Formatação de datas e números em pt-BR (`intl`) prevista.

## 13. Tratamento de erros e observabilidade
- [ ] Falhas tipadas previstas em `core/network`: sem rede, 401, 404, 429 e 5xx.
- [ ] Mensagens amigáveis na UI, sem exceção crua.
- [ ] `FlutterError.onError` e `PlatformDispatcher.instance.onError` previstos no `main.dart`.
- [ ] Crash reporting (Crashlytics ou Sentry): 📅 até a Fase 4. Se não estiver no plano, marque ⚠️.

## 14. CI/CD
- [ ] Workflow do GitHub Actions em `.github/workflows/` rodando format, analyze, test e gitleaks em PRs e pushes na `main`. Marque 📅 Fase 0 se ainda não existe.
- [ ] O workflow fixa a versão do Flutter, para usar a mesma de dev.
- [ ] O CI não precisa da chave real: os testes usam fakes.

## 15. Processo e documentação
- [ ] `dev/PLANO.md` tem as fases com itens claros, e a Fase 0 cobre tudo o que este checklist marcou como 📅 Fase 0.
- [ ] `dev/BACKLOG.md` e `dev/decisoes/` existem, e as decisões têm status.
- [ ] Os comandos do `CLAUDE.md` funcionam de verdade. Rode os que não alteram arquivos.
- [ ] Atribuição ao TMDB prevista (logo e aviso), como exigem os termos da API.

---

## Formato do relatório

Responda **em PT-BR**, nesta ordem:

1. **Veredito**, em uma linha: `PRONTO PARA INICIAR`, `PRONTO COM RESSALVAS` ou `NÃO PRONTO`.
2. **Placar por área**: uma tabela com as 15 áreas e a contagem de ✅ / ❌ / ⚠️ / 📅.
3. **Bloqueantes (❌)**: cada um com evidência (comando e saída, ou arquivo:linha), risco e correção proposta.
4. **Atenção (⚠️)**: mesmo formato, mais curto.
5. **Planejados (📅)**: lista agrupada por fase. Indique os que **faltam** no `PLANO.md`.
6. **Contradições de configuração** encontradas entre `CLAUDE.md`, skills, design e plano.
7. **Plano de correção priorizado**: passos numerados, na ordem em que eu devo fazer, separando "antes da primeira sessão" de "durante a Fase 0".

**Não aplique nenhuma correção.** Ao final, pergunte quais itens devo autorizar. Os aprovados viram itens via `/tarefa` ou entram na próxima `/sessao`.
