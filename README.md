# Modelo de projeto

A forma de trabalho do Leitor PDF, pronta para qualquer projeto e qualquer tecnologia:

- `AGENTS.md` como fonte única das regras (o `CLAUDE.md` só faz `@AGENTS.md`), com um **bloco fixo** entre `<!-- modelo:inicio -->` e `<!-- modelo:fim -->`: português, perguntas Q1/Q2 com recomendação, TDD com pontos de teste combinados, validação no ambiente real, Conventional Commits, releases com squash e tag anotada, `/retro` ao fim de cada release, memória do ai-memory em dia e cuidados com o notebook;
- `GLOSSARY.md` e `docs/adr/` (skill `domain-modeling`);
- as 9 skills do [mattpocock/skills](https://github.com/mattpocock/skills), baixadas do GitHub pelo `skills-lock.json`, e as 6 do ai-memory, numa cópia só em `.agents/skills`, com `.claude/skills` como link (Claude Code, Codex e OpenCode leem a mesma pasta);
- ai-memory só nos projetos que usam o modelo: `.ai-memory.toml`, hooks do Claude Code em `.claude/settings.local.json`, MCP em escopo local e as páginas `concepts/<projeto>` e `_rules/forma-de-trabalho`.

## Usar

A skill `novo-projeto` conduz tudo: faz a rodada de perguntas, chama o script e escreve as seções do projeto. Instalação, uma vez por máquina:

```bash
npx -y skills@1.7.2 add ~/Workspace/modelo-de-projeto --skill novo-projeto -g -y -a claude-code codex opencode
```

Depois, em qualquer agente: "/novo-projeto", ou "comece um projeto novo com o modelo", "adote o modelo neste projeto", "atualize este projeto com o modelo".

O script também roda sozinho:

```bash
./modelo novo <pasta> --projeto <nome> [--nome <título>] [--descricao <frase>] [--secoes <arquivo.md>]
./modelo adotar <pasta> [--projeto <nome>] [--aplicar]   # sem --aplicar só mostra o plano
./modelo atualizar <pasta> [--aplicar]                    # troca o bloco e atualiza as skills
```

Precisa de `bash`, `git`, `jq`, `npx` e do `ai-memory` com o serviço rodando; o endereço vem do `bind` de `~/.config/ai-memory/config.toml` (ou de `AI_MEMORY_SERVER_URL`).

## Mudar o modelo

- Regras gerais: `base/bloco.md`. Chegam aos projetos com `modelo atualizar`.
- Skills: `base/skills-lock.json` (entradas do `npx skills`). Projetos recebem as novas no `atualizar`.
- Seções que cada projeto preenche: `base/secoes.md` e as perguntas em `skills/novo-projeto/SKILL.md`.
- Páginas iniciais do ai-memory: `memoria/`.

## Testes

```bash
./testes/rodar.sh
```

Pontos T1–T6 (novo, skills, hooks, adotar, atualizar, rodar duas vezes), em pastas temporárias e com internet, sem tocar no ai-memory nem no `~/.claude`. O teste com o agente aberto (T7) é manual.
