import 'package:alita_pricelist/features/auth/data/services/firebase_anonymous_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

void main() {
  group('FirebaseAnonymousAuth', () {
    test('signs in anonymously when there is no current user', () async {
      final mockAuth = MockFirebaseAuth();
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.signInAnonymously()).thenAnswer((_) async => MockUserCredential());

      await FirebaseAnonymousAuth(auth: mockAuth).ensureSignedIn();

      verify(() => mockAuth.signInAnonymously()).called(1);
    });

    test('does nothing when a user is already signed in', () async {
      final mockAuth = MockFirebaseAuth();
      when(() => mockAuth.currentUser).thenReturn(MockUser());

      await FirebaseAnonymousAuth(auth: mockAuth).ensureSignedIn();

      verifyNever(() => mockAuth.signInAnonymously());
    });

    test('swallows a failure instead of throwing (login must never fail because of this)', () async {
      final mockAuth = MockFirebaseAuth();
      when(() => mockAuth.currentUser).thenReturn(null);
      when(() => mockAuth.signInAnonymously()).thenThrow(Exception('network down'));

      await expectLater(FirebaseAnonymousAuth(auth: mockAuth).ensureSignedIn(), completes);
    });
  });
}
