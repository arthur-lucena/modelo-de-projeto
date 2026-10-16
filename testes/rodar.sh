#!/usr/bin/env bash
# Testes do script `modelo` (pontos T1–T6). Rodam em pastas temporárias e
# precisam de internet: as skills do mattpocock vêm do GitHub.
# MODELO_SO_NA_PASTA=1 impede que o script registre o MCP ou crie páginas no
# ai-memory; isso fica para o teste manual (T7).
set -uo pipefail

RAIZ=$(cd "$(dirname "$0")/.." && pwd)
MODELO="$RAIZ/modelo"
export MODELO_SO_NA_PASTA=1
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

falhas=0
confere() { # confere <descrição> <comando...>
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then printf '  ok     %s\n' "$desc"
  else printf '  FALHA  %s\n' "$desc"; falhas=$((falhas + 1)); fi
}
nega() { ! "$@"; }

# Impressão digital de uma pasta: caminho e conteúdo de cada arquivo e link, fora do .git.
assinatura() {
  (cd "$1" && find . -path ./.git -prune -o \( -type f -o -type l \) -print | LC_ALL=C sort |
    while IFS= read -r f; do
      if [ -L "$f" ]; then echo "$f -> $(readlink "$f")"; else sha256sum "$f"; fi
    done) | sha256sum
}
# Igual à assinatura, sem o AGENTS.md, o skills-lock.json e as skills.
assinatura_sem_bloco_nem_skills() {
  (cd "$1" && find . \( -path ./.git -o -path ./.agents \) -prune -o \( -type f -o -type l \) -print |
    grep -vxF -e ./AGENTS.md -e ./skills-lock.json | LC_ALL=C sort |
    while IFS= read -r f; do
      if [ -L "$f" ]; then echo "$f -> $(readlink "$f")"; else sha256sum "$f"; fi
    done) | sha256sum
}
fora_do_bloco() { sed '/^<!-- modelo:inicio/,/^<!-- modelo:fim -->$/d' "$1"; }
export -f fora_do_bloco

URL_ESPERADA="http://$(sed -n 's/^bind *= *"\(.*\)"/\1/p' "$HOME/.config/ai-memory/config.toml" | head -1)"
SKILLS_DO_MODELO=(codebase-design domain-modeling grill-me grill-with-docs grilling
  improve-codebase-architecture retro tdd writing-for-agents)
SKILLS_DO_AI_MEMORY=(ai-memory-durable-pages ai-memory-handoff ai-memory-learning-maintenance
  ai-memory-messaging ai-memory-retrieval ai-memory-routing-install)
tem_skill() { [ -f "$1/.agents/skills/$2/SKILL.md" ]; }
todas_as_skills() {
  local s
  for s in "${SKILLS_DO_MODELO[@]}" "${SKILLS_DO_AI_MEMORY[@]}"; do tem_skill "$1" "$s" || return 1; done
}
hooks_com_url() { # quantos comandos de hook apontam para a URL esperada
  jq --arg u "--server-url $URL_ESPERADA" '[.hooks[][].hooks[].command | select(contains($u))] | length' \
    "$1/.claude/settings.local.json"
}
sem_marcas_de_preencher() { ! grep -n '{{' "$@"; }

CONFIG_GLOBAL_ANTES=$(sha256sum "$HOME/.claude/settings.json")

# ---------------------------------------------------------------- T1 novo
echo "T1 novo"
NOVO="$TMP/novo"
printf '## Comandos que provam que algo funciona\n\n`make test`\n' > "$TMP/secoes.md"
"$MODELO" novo "$NOVO" --projeto teste-modelo --nome "Projeto de Teste" \
  --descricao "Um projeto para testar o modelo." --secoes "$TMP/secoes.md" > "$TMP/novo.log" 2>&1
confere "termina sem erro" test $? -eq 0
confere "AGENTS.md com título e descrição" grep -qxF "# Projeto de Teste" "$NOVO/AGENTS.md"
confere "AGENTS.md com a descrição" grep -qxF "Um projeto para testar o modelo." "$NOVO/AGENTS.md"
confere "AGENTS.md com o bloco entre marcadores" \
  bash -c "grep -q '^<!-- modelo:inicio' '$NOVO/AGENTS.md' && grep -qxF '<!-- modelo:fim -->' '$NOVO/AGENTS.md'"
confere "AGENTS.md com as seções do projeto depois do bloco" \
  bash -c "fim=\$(grep -nxF '<!-- modelo:fim -->' '$NOVO/AGENTS.md' | cut -d: -f1); \
           sec=\$(grep -nxF '\`make test\`' '$NOVO/AGENTS.md' | cut -d: -f1); [ \"\$sec\" -gt \"\$fim\" ]"
confere "CLAUDE.md só importa o AGENTS.md" test "$(cat "$NOVO/CLAUDE.md")" = "@AGENTS.md"
confere "GLOSSARY.md com o título" grep -qxF "# Projeto de Teste" "$NOVO/GLOSSARY.md"
confere "pasta docs/adr/" test -d "$NOVO/docs/adr"
confere ".ai-memory.toml com o projeto" grep -qxF 'project = "teste-modelo"' "$NOVO/.ai-memory.toml"
confere ".gitignore com o settings.local.json" grep -qxF '/.claude/settings.local.json' "$NOVO/.gitignore"
confere "nenhum {{…}} sobrando" sem_marcas_de_preencher "$NOVO/AGENTS.md" "$NOVO/CLAUDE.md" \
  "$NOVO/GLOSSARY.md" "$NOVO/.ai-memory.toml" "$NOVO/.gitignore"
confere "repositório Git criado" test -d "$NOVO/.git"

# ---------------------------------------------------------------- T2 skills
echo "T2 skills"
confere "as 15 skills em .agents/skills" todas_as_skills "$NOVO"
confere ".claude/skills aponta para .agents/skills" test "$(readlink "$NOVO/.claude/skills")" = "../.agents/skills"
confere "skills visíveis por .claude/skills" test -f "$NOVO/.claude/skills/grilling/SKILL.md"
confere "skills-lock.json lista as 9 do mattpocock" \
  test "$(jq -r '.skills | keys | join(" ")' "$NOVO/skills-lock.json")" = "${SKILLS_DO_MODELO[*]}"

# ---------------------------------------------------------------- T3 hooks
echo "T3 hooks"
confere "9 hooks no settings.local.json com $URL_ESPERADA" test "$(hooks_com_url "$NOVO")" -eq 9

# ---------------------------------------------------------------- T4 adotar
echo "T4 adotar"
EXISTE="$TMP/existente"
mkdir -p "$EXISTE/.claude/skills/minha-skill"
git -C "$EXISTE" init -q -b main
printf '# Meu App\n\nIntrodução do app.\n\n## Regras próprias\n\nNão mexa no X.\n' > "$EXISTE/AGENTS.md"
printf '@AGENTS.md\n' > "$EXISTE/CLAUDE.md"
printf 'build/\n*.log\n' > "$EXISTE/.gitignore"
printf -- '---\nname: minha-skill\ndescription: Skill própria do projeto.\n---\n\nFaça X.\n' \
  > "$EXISTE/.claude/skills/minha-skill/SKILL.md"
cp "$EXISTE/AGENTS.md" "$TMP/agents-original.md"

antes=$(assinatura "$EXISTE")
"$MODELO" adotar "$EXISTE" --projeto meu-app > "$TMP/plano.log" 2>&1
confere "sem --aplicar termina sem erro" test $? -eq 0
confere "sem --aplicar nada muda no disco" test "$(assinatura "$EXISTE")" = "$antes"
confere "sem --aplicar mostra o bloco que entraria" grep -q 'modelo:inicio' "$TMP/plano.log"

"$MODELO" adotar "$EXISTE" --projeto meu-app --aplicar > "$TMP/adotar.log" 2>&1
confere "com --aplicar termina sem erro" test $? -eq 0
confere "bloco inserido" grep -qxF '<!-- modelo:fim -->' "$EXISTE/AGENTS.md"
confere "texto do projeto fora dos marcadores intacto" \
  bash -c "diff <(cat -s '$TMP/agents-original.md') <(fora_do_bloco '$EXISTE/AGENTS.md' | cat -s)"
confere "linhas antigas do .gitignore mantidas" \
  bash -c "grep -qxF 'build/' '$EXISTE/.gitignore' && grep -qxF '*.log' '$EXISTE/.gitignore'"
confere ".gitignore com o settings.local.json" grep -qxF '/.claude/settings.local.json' "$EXISTE/.gitignore"
confere "skill própria movida para .agents/skills" tem_skill "$EXISTE" minha-skill
confere "skill própria visível por .claude/skills" test -f "$EXISTE/.claude/skills/minha-skill/SKILL.md"
confere "as 15 skills do modelo instaladas" todas_as_skills "$EXISTE"
confere ".ai-memory.toml com o projeto" grep -qxF 'project = "meu-app"' "$EXISTE/.ai-memory.toml"
confere "9 hooks com $URL_ESPERADA" test "$(hooks_com_url "$EXISTE")" -eq 9

# ---------------------------------------------------------------- T5 atualizar
echo "T5 atualizar"
MODELO2="$TMP/modelo2"
cp -a "$RAIZ" "$MODELO2"
sed -i 's/^<!-- modelo:fim -->$/- Regra nova de teste.\n<!-- modelo:fim -->/' "$MODELO2/base/bloco.md"
ATUAL="$TMP/atualizar"
cp -a "$EXISTE" "$ATUAL"
fora_antes=$(fora_do_bloco "$ATUAL/AGENTS.md")
resto_antes=$(assinatura_sem_bloco_nem_skills "$ATUAL")

antes=$(assinatura "$ATUAL")
"$MODELO2/modelo" atualizar "$ATUAL" > "$TMP/plano-atualizar.log" 2>&1
confere "sem --aplicar termina sem erro" test $? -eq 0
confere "sem --aplicar nada muda no disco" test "$(assinatura "$ATUAL")" = "$antes"
confere "sem --aplicar mostra a regra nova" grep -q 'Regra nova de teste' "$TMP/plano-atualizar.log"

"$MODELO2/modelo" atualizar "$ATUAL" --aplicar > "$TMP/atualizar.log" 2>&1
confere "com --aplicar termina sem erro" test $? -eq 0
confere "regra nova no bloco" grep -qxF -- '- Regra nova de teste.' "$ATUAL/AGENTS.md"
confere "texto fora dos marcadores idêntico" test "$(fora_do_bloco "$ATUAL/AGENTS.md")" = "$fora_antes"
confere "nada mais mudou além do bloco e das skills" test "$(assinatura_sem_bloco_nem_skills "$ATUAL")" = "$resto_antes"

# ---------------------------------------------------------------- T6 rodar duas vezes
echo "T6 rodar duas vezes"
antes=$(assinatura "$NOVO")
"$MODELO" novo "$NOVO" --projeto teste-modelo > "$TMP/novo2.log" 2>&1
confere "novo numa pasta que não está vazia recusa" test $? -ne 0
confere "novo recusado não muda nada" test "$(assinatura "$NOVO")" = "$antes"

antes=$(assinatura "$EXISTE")
"$MODELO" adotar "$EXISTE" --projeto meu-app --aplicar > "$TMP/adotar2.log" 2>&1
confere "adotar de novo termina sem erro" test $? -eq 0
confere "adotar de novo não muda nada" test "$(assinatura "$EXISTE")" = "$antes"
confere "um bloco só" test "$(grep -c '^<!-- modelo:inicio' "$EXISTE/AGENTS.md")" -eq 1
confere "uma linha só no .gitignore" test "$(grep -cxF '/.claude/settings.local.json' "$EXISTE/.gitignore")" -eq 1
confere "hooks sem duplicar" test "$(jq '[.hooks[][].hooks[]] | length' "$EXISTE/.claude/settings.local.json")" -eq 9

antes=$(assinatura "$ATUAL")
"$MODELO2/modelo" atualizar "$ATUAL" --aplicar > "$TMP/atualizar2.log" 2>&1
confere "atualizar de novo termina sem erro" test $? -eq 0
confere "atualizar de novo não muda nada" test "$(assinatura "$ATUAL")" = "$antes"

echo "Geral"
confere "~/.claude/settings.json intocado" test "$(sha256sum "$HOME/.claude/settings.json")" = "$CONFIG_GLOBAL_ANTES"

if [ "$falhas" -gt 0 ]; then
  echo "$falhas falha(s). Logs em $TMP (apagados ao sair; rode com MODELO_MANTER=1 para guardar)."
  [ "${MODELO_MANTER:-}" = 1 ] && trap - EXIT
  exit 1
fi
echo "Tudo certo."
