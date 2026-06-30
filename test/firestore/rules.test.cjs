const fs = require('node:fs');
const path = require('node:path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
} = require('firebase/firestore');

describe('Firestore security rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'demo-yks-coach',
      firestore: {
        rules: fs.readFileSync(
          path.resolve(__dirname, '../../firestore.rules'),
          'utf8',
        ),
      },
    });
  });

  beforeEach(async () => testEnv.clearFirestore());
  after(async () => testEnv.cleanup());

  function context(uid = 'alice', verified = true, provider = 'password') {
    return testEnv.authenticatedContext(uid, {
      email_verified: verified,
      firebase: { sign_in_provider: provider },
    });
  }

  function validDevice(installationId = '0123456789abcdef0123456789abcdef') {
    return {
      installationId,
      fcmToken: 'fcm-token-that-is-long-enough-for-validation',
      platform: 'android',
      timeZone: 'Europe/Istanbul',
      dailyReminder: true,
      taskReminder: true,
      motivationReminder: false,
      examReminder: false,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
  }

  it('verified owner can register and read an Android installation', async () => {
    const id = '0123456789abcdef0123456789abcdef';
    const db = context().firestore();
    const ref = doc(db, `users/alice/devices/${id}`);

    await assertSucceeds(setDoc(ref, validDevice(id)));
    await assertSucceeds(getDoc(ref));
  });

  it('unverified and anonymous clients cannot register devices', async () => {
    const id = '0123456789abcdef0123456789abcdef';
    const unverified = doc(
      context('alice', false).firestore(),
      `users/alice/devices/${id}`,
    );
    const anonymous = doc(
      testEnv.unauthenticatedContext().firestore(),
      `users/alice/devices/${id}`,
    );

    await assertFails(setDoc(unverified, validDevice(id)));
    await assertFails(setDoc(anonymous, validDevice(id)));
  });

  it('a verified user cannot access another user device', async () => {
    const id = '0123456789abcdef0123456789abcdef';
    const ref = doc(
      context('mallory').firestore(),
      `users/alice/devices/${id}`,
    );

    await assertFails(setDoc(ref, validDevice(id)));
    await assertFails(getDoc(ref));
  });

  it('rejects malformed device payloads and mismatched installation ids', async () => {
    const pathId = '0123456789abcdef0123456789abcdef';
    const ref = doc(
      context().firestore(),
      `users/alice/devices/${pathId}`,
    );
    const malformed = {
      ...validDevice('different-installation-id'),
      fcmToken: 'short',
    };

    await assertFails(setDoc(ref, malformed));
  });
});
