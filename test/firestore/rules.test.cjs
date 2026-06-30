const fs = require('node:fs');
const path = require('node:path');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  deleteDoc,
  getDoc,
  serverTimestamp,
  setDoc,
  Timestamp,
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

  function validProfile() {
    return {
      userName: 'Ada Yılmaz',
      grade: '12. Sınıf',
      studyField: 'Sayısal',
      targetUniversity: 'Hedef Üniversite',
      targetDepartment: 'Bilgisayar Mühendisliği',
      targetRank: 5000,
      dailyQuestionGoal: 80,
      dailyStudyMinutes: 180,
      prioritySubjects: ['Matematik', 'Fizik'],
      dailyReminder: false,
      taskReminder: true,
      motivationReminder: true,
      examReminder: false,
      reminderMinutes: 1140,
      focusMinutes: 25,
      themeMode: 'light',
      onboardingCompleted: true,
      locale: 'tr_TR',
      timeZone: 'Europe/Istanbul',
      schemaVersion: 1,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
  }

  function validTask() {
    return {
      subject: 'Matematik',
      title: 'Türev tekrarı',
      scheduledAt: Date.UTC(2026, 5, 30),
      startMinutes: 540,
      endMinutes: 600,
      color: 0xff2563eb,
      detail: null,
      status: 'planned',
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    };
  }

  function validExam() {
    return {
      name: 'TYT Denemesi',
      type: 'TYT',
      takenAt: Date.UTC(2026, 5, 29),
      subjects: [
        {subject: 'Matematik', correct: 1, wrong: 8, blank: 31},
      ],
      totalNet: -1,
      createdAt: serverTimestamp(),
    };
  }

  function validFocusSession() {
    const startedAt = Date.UTC(2026, 5, 30, 8);
    return {
      subject: 'Matematik',
      startedAt,
      endedAt: startedAt + 25 * 60 * 1000,
      durationMinutes: 25,
      createdAt: serverTimestamp(),
    };
  }

  it('verified owner can create valid profile and study data', async () => {
    const db = context().firestore();

    await assertSucceeds(setDoc(doc(db, 'users/alice'), validProfile()));
    await assertSucceeds(
      setDoc(doc(db, 'users/alice/tasks/task-1'), validTask()),
    );
    await assertSucceeds(
      setDoc(doc(db, 'users/alice/exams/exam-1'), validExam()),
    );
    await assertSucceeds(
      setDoc(
        doc(db, 'users/alice/focusSessions/focus-1'),
        validFocusSession(),
      ),
    );
  });

  it('rejects unsupported providers and access to another user profile', async () => {
    await assertFails(
      setDoc(
        doc(context('alice', true, 'github.com').firestore(), 'users/alice'),
        validProfile(),
      ),
    );
    await assertFails(
      setDoc(
        doc(context('mallory').firestore(), 'users/alice'),
        validProfile(),
      ),
    );
  });

  it('rejects malformed profile enums and priority subjects', async () => {
    const ref = doc(context().firestore(), 'users/alice');

    await assertFails(
      setDoc(ref, {
        ...validProfile(),
        grade: 'Yönetici',
        prioritySubjects: ['Matematik', 'Bilinmeyen'],
      }),
    );
  });

  it('rejects inverted tasks and changing server creation time', async () => {
    const ref = doc(context().firestore(), 'users/alice/tasks/task-1');
    await assertFails(
      setDoc(ref, {...validTask(), startMinutes: 600, endMinutes: 540}),
    );

    await assertSucceeds(
      setDoc(ref, {
        ...validTask(),
        createdAt: Timestamp.fromMillis(1000),
      }),
    );
    await assertFails(
      setDoc(ref, {
        ...validTask(),
        createdAt: Timestamp.fromMillis(2000),
      }),
    );
  });

  it('accepts negative net but rejects oversized exam payloads', async () => {
    const db = context().firestore();
    await assertSucceeds(
      setDoc(doc(db, 'users/alice/exams/negative-net'), validExam()),
    );
    await assertFails(
      setDoc(doc(db, 'users/alice/exams/oversized'), {
        ...validExam(),
        subjects: Array.from({length: 11}, (_, index) => ({
          subject: `Ders ${index}`,
          correct: 1,
          wrong: 0,
          blank: 0,
        })),
      }),
    );
  });

  it('rejects inconsistent or zero-length focus sessions', async () => {
    const ref = doc(
      context().firestore(),
      'users/alice/focusSessions/focus-1',
    );
    const valid = validFocusSession();

    await assertFails(setDoc(ref, {...valid, durationMinutes: 5}));
    await assertFails(
      setDoc(ref, {...valid, endedAt: valid.startedAt, durationMinutes: 0}),
    );
  });

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

  it('clients cannot forge coach messages but the verified owner can read them', async () => {
    const path = 'users/alice/coachMessages/server-message';
    await testEnv.withSecurityRulesDisabled(async (adminContext) => {
      await setDoc(doc(adminContext.firestore(), path), {
        text: 'Sunucu tarafından üretilen yanıt',
        fromUser: false,
        conversationId: 'main',
        createdAt: serverTimestamp(),
      });
    });

    const ownerRef = doc(context().firestore(), path);
    await assertSucceeds(getDoc(ownerRef));
    await assertFails(
      setDoc(doc(context().firestore(), 'users/alice/coachMessages/forged'), {
        text: 'Sahte asistan yanıtı',
        fromUser: false,
        conversationId: 'main',
        createdAt: serverTimestamp(),
      }),
    );
  });

  it('daily coach quota is inaccessible to every client', async () => {
    const usageRef = doc(
      context().firestore(),
      'users/alice/usage/2026-06-30',
    );

    await assertFails(getDoc(usageRef));
    await assertFails(
      setDoc(usageRef, {
        date: '2026-06-30',
        coachMessages: 0,
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('notification delivery leases are inaccessible to every client', async () => {
    const deliveryRef = doc(
      context().firestore(),
      'users/alice/notificationDeliveries/motivation_2026-06-30_device',
    );

    await assertFails(getDoc(deliveryRef));
    await assertFails(
      setDoc(deliveryRef, {
        kind: 'daily_motivation',
        status: 'sent',
        localDate: '2026-06-30',
        installationId: '0123456789abcdef0123456789abcdef',
        updatedAt: serverTimestamp(),
      }),
    );
  });

  it('clients cannot bypass recursive account deletion by deleting the profile', async () => {
    const path = 'users/alice';
    await testEnv.withSecurityRulesDisabled(async (adminContext) => {
      await setDoc(doc(adminContext.firestore(), path), {
        serverSeeded: true,
      });
    });

    await assertFails(deleteDoc(doc(context().firestore(), path)));
  });
});
