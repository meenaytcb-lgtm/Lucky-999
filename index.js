const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

exports.createWalletRequest = onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Please sign in.');
  const { type, amount } = request.data || {};
  if (!['deposit', 'withdraw'].includes(type)) {
    throw new HttpsError('invalid-argument', 'type must be deposit or withdraw.');
  }
  if (!Number.isInteger(amount) || amount < 1 || amount > 100000) {
    throw new HttpsError('invalid-argument', 'amount must be an integer from 1 to 100000.');
  }

  // Basic server-side rate guard; production systems need stronger abuse prevention.
  const uid = request.auth.uid;
  const recent = await db.collection('walletRequests')
    .where('uid', '==', uid)
    .where('createdAt', '>', new Date(Date.now() - 60 * 60 * 1000))
    .limit(10).get();
  if (recent.size >= 5) throw new HttpsError('resource-exhausted', 'Too many requests. Try later.');

  const ref = db.collection('walletRequests').doc();
  await ref.set({
    uid, type, amount, status: 'pending',
    createdAt: FieldValue.serverTimestamp(),
    reviewedAt: null,
    note: 'Demo request only; no funds were moved.'
  });
  return { requestId: ref.id, status: 'pending' };
});

exports.reviewWalletRequest = onCall(async (request) => {
  if (!request.auth || request.auth.token.admin !== true) {
    throw new HttpsError('permission-denied', 'Admin access required.');
  }
  const { requestId, decision, note = '' } = request.data || {};
  if (typeof requestId !== 'string' || !['approved', 'rejected'].includes(decision)) {
    throw new HttpsError('invalid-argument', 'Invalid requestId or decision.');
  }
  const ref = db.collection('walletRequests').doc(requestId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'Request not found.');
    if (snap.data().status !== 'pending') throw new HttpsError('failed-precondition', 'Request already reviewed.');
    tx.update(ref, {
      status: decision,
      note: String(note).slice(0, 500),
      reviewedAt: FieldValue.serverTimestamp(),
      reviewedBy: request.auth.uid
    });
  });
  // Intentionally does not credit/debit a balance or execute a payment.
  return { ok: true, message: 'Request reviewed; no money was moved.' };
});
