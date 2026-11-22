/// O id automático do Firestore (`doc()`), igual à `isListId` do
/// `firestore.rules` (decisão 019).
final listIdPattern = RegExp(r'^[A-Za-z0-9]{20}$');
