import { readFileSync } from 'node:fs';

const USER_COLLECTIONS_PATH = new URL(
  '../../lib/core/firestore/user_collections.dart',
  import.meta.url,
);

// Lê o `all` de UserCollections e troca cada constante pelo valor dela: a
// lista fixa que a exclusão da conta apaga (decisão 015). Os testes das
// regras e da limpeza mensal (decisão 017) comparam com ela.
export function collectionsInApp() {
  const dart = readFileSync(USER_COLLECTIONS_PATH, 'utf8');
  const values = Object.fromEntries(
    [...dart.matchAll(/static const ([A-Za-z]+) = '([A-Za-z]+)';/g)]
      .map(([, constant, value]) => [constant, value]),
  );
  const all = dart.match(/static const all = \[([^\]]*)\];/);
  if (!all) throw new Error('UserCollections.all não encontrado');
  return [...all[1].matchAll(/([A-Za-z]+)/g)]
    .map(([, constant]) => values[constant])
    .sort();
}
