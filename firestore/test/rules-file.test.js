import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { RULES_PATH, USER_COLLECTIONS_PATH } from './environment.js';

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

  // Lê o `all` de UserCollections e troca cada constante pelo valor dela.
  function collectionsInApp() {
    const dart = readFileSync(USER_COLLECTIONS_PATH, 'utf8');
    const values = Object.fromEntries(
      [...dart.matchAll(/static const ([A-Za-z]+) = '([A-Za-z]+)';/g)]
        .map(([, constant, value]) => [constant, value]),
    );
    const all = dart.match(/static const all = \[([^\]]*)\];/);
    assert.ok(all, 'UserCollections.all não encontrado');
    return [...all[1].matchAll(/([A-Za-z]+)/g)]
      .map(([, constant]) => values[constant])
      .sort();
  }

  test('deve ter nas regras ao menos uma subcoleção', () => {
    assert.ok(collectionsInRules().length > 0);
  });

  test('deve ter no app as mesmas subcoleções das regras', () => {
    assert.deepEqual(collectionsInApp(), collectionsInRules());
  });
});
