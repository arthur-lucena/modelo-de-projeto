---
name: novo-projeto
description: Modelo de projeto (AGENTS.md com o bloco da forma de trabalho, skills, ai-memory). Use para começar um projeto novo, adotar o modelo num projeto existente ou atualizar um projeto a partir do modelo.
---

# Modelo de projeto

O modelo fica em `~/Workspace/modelo-de-projeto`; se não estiver lá, clone `arthur-lucena/modelo-de-projeto` nessa pasta. O script `modelo` faz o trabalho fixo: copia os arquivos e instala as skills, os hooks e o MCP. Esta skill cuida da conversa e das seções próprias do projeto.

## 1. Escolha o modo

- **novo**: a pasta do projeto não existe ou está vazia. Se o usuário não disser onde, proponha `~/Workspace/<projeto>`.
- **adotar**: o projeto existe, mas o `AGENTS.md` não tem `<!-- modelo:inicio`.
- **atualizar**: o `AGENTS.md` já tem o bloco. Vá direto ao passo 4.

## 2. Rodada de perguntas (novo e adotar)

Faça uma rodada no formato da skill `grilling`: perguntas numeradas, cada uma com a sua recomendação. No adotar, leia o projeto antes (README, arquivos de build, testes, `AGENTS.md`, `CLAUDE.md`, `.gitignore`) e tire dele as recomendações; pergunte só o que o código não responde.

1. **Nome e descrição**: o nome do projeto no ai-memory (minúsculas, números e hífen) e a descrição em uma frase. Se já houver um `.ai-memory.toml`, o nome é o dele.
2. **Comandos**: a stack e os comandos que provam que algo funciona (compilar, testar).
3. **Ambiente de teste**: onde o projeto roda de verdade (aparelho, servidor, banco) e os cuidados antes de mexer nele.
4. **Limites**: o que fica fora do Git e o que não pode ser usado.
5. **Versões**: como a versão é numerada e onde ela aparece (tag; arquivo de versão, se houver).

O passo termina quando as cinco têm resposta, mesmo que seja "não se aplica".

## 3. Escreva as seções do projeto

Num arquivo temporário, escreva as seções próprias com as respostas, nos títulos de `base/secoes.md` do modelo: "Comandos que provam que algo funciona", "Ambiente de teste", "Limites" e "Versões". Siga a skill `writing-for-agents`: escreva o que o agente não descobre olhando o projeto e deixe de fora a seção que não se aplica.

## 4. Rode o script

- **novo**: `~/Workspace/modelo-de-projeto/modelo novo <pasta> --projeto <nome> --nome "<título>" --descricao "<frase>" --secoes <arquivo>`.
- **adotar**: rode `modelo adotar <pasta> --projeto <nome>` sem `--aplicar`, mostre o plano ao usuário e, com o ok dele, rode de novo com `--aplicar`. Depois, edite o `AGENTS.md`: ponha as seções do passo 3 fora dos marcadores e tire de lá as regras que o bloco já diz. Mostre o diff ao usuário antes do commit.
- **atualizar**: rode `modelo atualizar <pasta>` sem `--aplicar`, mostre o plano e, com o ok do usuário, rode com `--aplicar`.

O texto entre `<!-- modelo:inicio` e `<!-- modelo:fim -->` pertence ao modelo: mudanças nele vão para `base/bloco.md` do modelo, com o ok do usuário, e chegam aos projetos pelo `atualizar`.

## 5. Feche

- **novo e adotar**: preencha "Stack" e "Testes" na página do projeto em `concepts/` do ai-memory com as respostas da rodada (skill `ai-memory-durable-pages`; sem o MCP nesta sessão, use `AI_MEMORY_SERVER_URL=http://<bind> ai-memory write-page`, com o `bind` de `~/.config/ai-memory/config.toml`).
- Faça o commit em Conventional Commits: `chore: iniciar o projeto a partir do modelo`, `chore: adotar o modelo de projeto` ou `chore: atualizar o bloco do modelo`. Push só quando o usuário pedir.
- No novo e no adotar, avise que os hooks e o MCP só carregam numa sessão aberta na pasta do projeto.
