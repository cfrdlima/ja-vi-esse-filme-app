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

  test('não deve ter allow incondicional', () => {
    assert.doesNotMatch(rules, /if\s+true\b/);
  });
});
