// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();
//
//   Future<UserCredential?> signInWithGoogle() async {
//     try {
//       // Trigger the Google sign-in flow.
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) return null;  // User cancelled sign-in.
//
//       // Obtain the authentication details.
//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//
//       // Create a new credential.
//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );
//
//       // Sign in to Firebase with the credential.
//       return await _auth.signInWithCredential(credential);
//     } catch (e) {
//       print("Error during Google sign in: $e");
//       return null;
//     }
//   }
//
//   Future<void> signOut() async {
//     await _googleSignIn.signOut();
//     await _auth.signOut();
//   }
// }
