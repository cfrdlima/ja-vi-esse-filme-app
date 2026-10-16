# Tarefa: integrar a skill `ui-ux-pro-max` como fonte de design do projeto

> Instruções para o Claude Code. Leia tudo antes de começar e siga a ordem.
> Respeite o `CLAUDE.md` (TDD, Clean Architecture, sistema `dev/`, commits em PT-BR).

## Contexto

A skill de terceiros **UI UX Pro Max** (`nextlevelbuilder/ui-ux-pro-max-skill`, MIT) foi instalada em `.claude/skills/ui-ux-pro-max/`. Ela traz estilos, paletas, pares de fontes e diretrizes de UX com orientação específica para **Flutter**. Com `--persist`, ela gera `design-system/<projeto>/MASTER.md` (fonte global) e, opcionalmente, `design-system/<projeto>/pages/<tela>.md` (overrides por tela).

Hoje o projeto aponta para `docs/DESIGN.md` e para a skill `frontend-design`. Precisamos de **uma única fonte da verdade de design**: o `MASTER.md` gerado por essa skill.

O trabalho tem duas partes:
- **Parte A**: ajustes de configuração e documentação, sem código Dart. Faça agora, num commit só.
- **Parte B**: gerar o design system e traduzi-lo para `lib/core/theme/`. Isso é código: **só dentro de uma sessão aberta com `/sessao`**, seguindo TDD.

---

## Parte A — Configuração e documentação

### A1. Revisar a skill instalada (segurança)
1. Confirme que a skill está em `.claude/skills/ui-ux-pro-max/` e liste o conteúdo.
2. Leia o `SKILL.md` e os scripts em `scripts/`. Confirme e me relate:
   - se algum script faz chamada de rede (`urllib`, `requests`, `http`, `socket`, `subprocess` com `curl`/`wget`);
   - se algum script instala pacotes ou escreve fora do projeto.
3. **Se encontrar algo suspeito, pare e me mostre antes de continuar.**
4. Confirme que `python3` está disponível (`python3 --version`).

### A2. `docs/DESIGN.md` vira ponteiro
Substitua todo o conteúdo por:

```markdown
# Design — Já Vi Esse Filme

A fonte da verdade de design é **`design-system/ja-vi-esse-filme/MASTER.md`**, gerado pela skill `ui-ux-pro-max` com stack **Flutter**.

- Overrides por tela: `design-system/ja-vi-esse-filme/pages/<tela>.md`. Se existir, ele vale para aquela tela; senão, vale o `MASTER.md`.
- Tokens em código: `lib/core/theme/` (`ThemeData` Material 3 + `ThemeExtension`). Widgets nunca usam cor, fonte ou espaçamento fora desses tokens.
- Para alterar o design: atualize o `MASTER.md` (ou o override da tela) **primeiro** e só depois o código.

## Regras de adaptação para Flutter
- **Fontes empacotadas** em `assets/fonts/` e declaradas no `pubspec.yaml`. Não use o pacote `google_fonts` (ele baixa a fonte em tempo de execução).
- **Efeitos pesados** (glassmorphism, blur, sombras grandes) só em pontos isolados, como o topo da tela de detalhes. Nunca em itens de lista ou grade.
- **Contraste mínimo AA** em texto sobre pôster/backdrop: use gradiente ou scrim.
- **Tema escuro** é o padrão; claro é opcional.
```

### A3. Ajustar o `CLAUDE.md`
Faça estas edições e mantenha o resto intacto:

1. Na seção **O produto**, troque a linha
   `- Design: \`docs/DESIGN.md\` (tokens, tipografia e padrões de tela).`
   por
   `- Design: \`design-system/ja-vi-esse-filme/MASTER.md\` (fonte da verdade, gerado pela skill \`ui-ux-pro-max\`). Regras de adaptação em \`docs/DESIGN.md\`.`

2. Na seção **Design / UI**:
   - Troque o primeiro item (`Siga \`docs/DESIGN.md\`...`) por:
     `- Siga o \`MASTER.md\` do design system e as regras de \`docs/DESIGN.md\`. Cores, tipografia e espaçamento vêm de \`core/theme/\` (\`ThemeData\` + \`ThemeExtension\`). **Nada de \`Color(0x...)\` ou tamanho mágico dentro de widget.**`
   - Troque o último item (`Para UI nova, use a skill \`frontend-design\`...`) por:
     `- Direção visual e regras de UX vêm da skill \`ui-ux-pro-max\`, **sempre com stack Flutter**. Antes de criar uma tela nova, consulte a skill para os padrões daquela tela. Se precisar de regra específica, gere um override em \`pages/<tela>.md\`. A \`frontend-design\` é opcional, só para explorar conceitos. Depois de mexer na tela, valide no emulador (screenshot via MCP do Flutter).`

3. Na seção **Skills e plugins** (no fim do arquivo), acrescente `ui-ux-pro-max` à lista de skills e esta frase:
   `A \`ui-ux-pro-max\` é a fonte de design; quando ela sugerir algo de web (imports do Google Fonts, CSS, Tailwind), traduza para o equivalente Flutter conforme \`docs/DESIGN.md\`.`

### A4. Ajustar a skill `tela-4-estados`
Em `.claude/skills/tela-4-estados/SKILL.md`:
- **Passo 1**: troque `Leia \`docs/DESIGN.md\`` por `Leia \`design-system/ja-vi-esse-filme/pages/<tela>.md\` se existir; senão, o \`MASTER.md\`. Siga também as regras de \`docs/DESIGN.md\``.
- **Passo 6**: troque `compare com o \`DESIGN.md\`` por `compare com o \`MASTER.md\`/override da tela`. Troque também `Use a skill \`frontend-design\` quando a tela for nova...` por `Para tela nova, consulte a \`ui-ux-pro-max\` (stack Flutter) antes de codar.`

### A5. Ajustar o plano
Em `dev/PLANO.md`, na **Fase 0**, troque o item
`- [ ] \`core/theme\` com tokens do \`docs/DESIGN.md\` (tema escuro)`
por dois itens:
```
- [ ] Gerar design system com `ui-ux-pro-max` (stack Flutter) → `design-system/ja-vi-esse-filme/MASTER.md`
- [ ] `core/theme` com tokens do `MASTER.md` (tema escuro, fontes empacotadas)
```

### A6. Registrar a decisão
Rode `/decisao Adotar a skill ui-ux-pro-max como fonte da verdade de design`. Preencha com:
- **Contexto**: precisávamos de uma direção de design consistente e de regras de UX, sem duplicar fontes.
- **Opções**: `frontend-design` sozinha (focada em web), escrever o design system à mão, ou `ui-ux-pro-max` (orientação para Flutter, base de dados de estilos e UX).
- **Decisão**: `ui-ux-pro-max`, com `MASTER.md` como fonte da verdade e `docs/DESIGN.md` só com as regras de adaptação para Flutter.
- **Consequências**: skill de terceiros versionada no repo e revisada antes de atualizar; sugestões de web precisam ser traduzidas; fontes empacotadas.

### A7. Verificar e commitar
1. `git status`. Confira que nenhum arquivo de `env/` (exceto `example.json`) aparece.
2. Garanta que a skill está versionada: `git add .claude/skills/ui-ux-pro-max`.
3. Commit único:
   `chore: adota ui-ux-pro-max como fonte de design`
4. Me mostre o diff resumido (`git show --stat`) e o resultado da revisão de segurança do A1.

**Não faça push.**

---

## Parte B — Gerar o design system e os tokens (somente em sessão)

Comece com:
```
/sessao Fase 0 — design system com ui-ux-pro-max e tokens em core/theme
```

### B1. Gerar o design system
Use a skill `ui-ux-pro-max` para gerar e **persistir** o design system com este briefing:
- **Produto**: "Já Vi Esse Filme", app mobile para cinéfilos. O usuário busca filmes, vê detalhes (sinopse, elenco, trailers), marca o que já viu, favorita e organiza listas.
- **Tom**: experiência de sala de cinema; o pôster é o protagonista; elegante, sem poluição visual.
- **Plataforma**: Android primeiro, **stack Flutter**, Material 3, **tema escuro padrão**.
- **Telas principais**: Descobrir (grade de pôsteres), Busca, Detalhes do filme, Minha estante (já vistos / favoritos / listas), Perfil/Sobre.
- **Restrições**: contraste AA, alvo de toque ≥ 48dp, suporte a fonte grande, desempenho em Android intermediário.

O resultado deve ficar em `design-system/ja-vi-esse-filme/MASTER.md`. Se a skill usar outro slug, renomeie a pasta para `ja-vi-esse-filme`.

**Pare aqui e me mostre** paleta, tipografia, estilo e anti-padrões propostos. Só siga depois do meu ok. Se eu pedir ajustes, edite o `MASTER.md`.

### B2. Fontes
1. Baixe as fontes escolhidas do Google Fonts (arquivos `.ttf`, licença OFL) para `assets/fonts/`. Se não conseguir baixar, me peça os arquivos.
2. Declare-as no `pubspec.yaml`. **Não** adicione o pacote `google_fonts`.

### B3. Tokens com TDD (`lib/core/theme/`)
Em ciclos Red → Green → Refactor:
1. **Red**: testes em `test/core/theme/` que verificam:
   - o `ColorScheme` escuro usa as cores do `MASTER.md`;
   - a `ThemeExtension` própria expõe os tokens extras (ex.: espaçamentos, raios, cor de "já visto");
   - o `TextTheme` usa as famílias empacotadas;
   - os pares texto/fundo principais atingem contraste AA (teste com cálculo de luminância relativa).
2. **Green**: implemente `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, a `ThemeExtension` e `app_theme.dart` (`ThemeData` Material 3).
3. **Refactor**: limpe e aplique o tema no `MaterialApp` do `main.dart`.

### B4. Fechar
1. Rode `/revisar`.
2. Rode `/fechar-sessao`, que exige `flutter analyze` limpo e `flutter test` verde.

---

## Critérios de aceite
- [ ] Revisão de segurança da skill relatada (A1)
- [ ] `docs/DESIGN.md`, `CLAUDE.md`, `tela-4-estados`, `PLANO.md` atualizados (A2–A5)
- [ ] Decisão registrada em `dev/decisoes/` (A6)
- [ ] Commit da Parte A feito, sem push (A7)
- [ ] `MASTER.md` gerado com stack Flutter e aprovado por mim (B1)
- [ ] Fontes empacotadas, sem `google_fonts` (B2)
- [ ] Tokens em `core/theme/` com testes, inclusive de contraste AA (B3)
- [ ] Sessão fechada com analyze limpo e testes verdes (B4)
