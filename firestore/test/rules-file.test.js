import { describe, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { RULES_PATH } from './environment.js';

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
