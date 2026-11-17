import { test } from 'node:test';
import assert from 'node:assert/strict';

test('o emulador do Firestore está de pé', () => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST);
});
