<!-- modelo:inicio · bloco do modelo-de-projeto: mude no modelo e rode `modelo atualizar` -->
## Forma de trabalho

Converse em português. Vocabulário do domínio: `GLOSSARY.md`. Decisões e alternativas já rejeitadas: `docs/adr/` (skill `domain-modeling`).

### Memória do projeto (ai-memory)

Histórico, armadilhas e estado atual ficam no ai-memory (MCP `ai-memory`, projeto fixado em `.ai-memory.toml`). Todo agente lê e atualiza essa memória:

- **Ao começar uma tarefa**, leia a página do projeto em `concepts/`, as de `gotchas/` e as de `decisions/` ligadas a ela, antes de propor ou mudar algo.
- **Uma entrega só termina com a memória em dia.** A cada funcionalidade, correção, release, decisão ou armadilha nova, reescreva por conta própria as páginas afetadas:
  - a página do projeto em `concepts/`: versão, o que o projeto faz, onde fica cada coisa, testes e pendências;
  - `decisions/<assunto>.md`, fixada, para cada ADR novo em `docs/adr/`;
  - `gotchas/<assunto>.md`: cada armadilha que custou tempo.

### Processo

- Decisões em rodadas de perguntas numeradas (Q1, Q2…), cada uma com a sua recomendação (skill `grilling`).
- TDD com os pontos de teste combinados com o usuário antes de escrever o primeiro teste (skill `tdd`).
- Quando não se sabe se algo funciona no ambiente real, valide lá antes de construir em cima.
- Commits em Conventional Commits, em português, terminando com a linha `Co-Authored-By` do agente. Push só quando o usuário pedir.
- Release: PR com squash, branch remota mantida e tag anotada `vX.Y.Z` com a mensagem "Versão X.Y.Z: …".
- Ao fim de cada release, sugira um `/retro`. O que valer para qualquer projeto vira mudança no modelo (`~/Workspace/modelo-de-projeto`), só com o ok do usuário; o resto fica neste arquivo ou em `gotchas/`.

### Notebook

- Disco curto: confira `df` antes de baixar, use `pip --no-cache-dir` e apague cada download assim que ele cumprir a função.
- Pare os daemons de build ao fim de cada rodada (por exemplo, `./gradlew --stop`).
<!-- modelo:fim -->
