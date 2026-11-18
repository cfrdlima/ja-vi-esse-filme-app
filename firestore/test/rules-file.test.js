import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { RULES_PATH, collectionsInApp } from './environment.js';

// Um curinga recursivo com allow abriria subcoleções que ninguém revisou.
describe('arquivo firestore.rules', () => {
  const rules = readFileSync(RULES_PATH, 'utf8');

  test('não deve ter match com curinga recursivo', () => {
    assert.doesNotMatch(rules, /match\s+\/[^\n]*=\*\*\}/);
  });

  test('não deve ter allow com if true', () => {
    assert.doesNotMatch(rules, /if\s*\(?\s*true\b/);
  });

  // Sem if, o allow libera o acesso sem condição nenhuma.
  test('não deve ter allow sem condição', () => {
    assert.doesNotMatch(rules, /allow\s+[a-z,\s]+;/);
  });
});

// A exclusão da conta apaga só as subcoleções da lista fixa do app, porque
// o SDK do cliente não lista subcoleções (decisões 010 e 015). Uma coleção
// nas regras que falte na lista sobraria em users/{uid} depois da exclusão.
describe('lista fixa das subcoleções de users/{uid}', () => {
  // Dentro dos testes, e não no describe: um erro de leitura no describe
  // aparece como "not ok", mas o node --test sai com 0.
  function collectionsInRules() {
    const rules = readFileSync(RULES_PATH, 'utf8');
    const names = [...rules.matchAll(/match\s+\/users\/\{uid\}\/([A-Za-z]+)\//g)]
      .map(([, name]) => name);
    return [...new Set(names)].sort();
  }

  // Um curinga com outro nome ({userId}) ou um match aninhado (os items de
  // uma lista, na Fase 3) escaparia da comparação abaixo, e a exclusão não
  // saberia apagar a subcoleção (`/revisar` da sessão 024).
  test('deve ter só match no formato /users/{uid}/<nome>/{id}', () => {
    const rules = readFileSync(RULES_PATH, 'utf8');
    const matches = [...rules.matchAll(/match\s+(\S+)\s*\{/g)]
      .map(([, path]) => path)
      .filter((path) => path !== '/databases/{database}/documents');

    const outside = matches.filter(
      (path) => !/^\/users\/\{uid\}\/[A-Za-z]+\/\{[A-Za-z]+\}$/.test(path),
    );

    assert.deepEqual(outside, []);
  });

  test('deve ter nas regras ao menos uma subcoleção', () => {
    assert.ok(collectionsInRules().length > 0);
  });

  test('deve ter no app as mesmas subcoleções das regras', () => {
    assert.deepEqual(collectionsInApp(), collectionsInRules());
  });
});
