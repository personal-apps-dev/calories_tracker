import SwiftUI
import AuthenticationServices

/// Native Sign in with Apple button. On success populates appState.userName
/// (only the first time — Apple only sends the name on first authorization)
/// and stores the stable user id + email for later "sign out" support.
struct AppleSignInButton: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    var onComplete: (Bool) -> Void = { _ in }

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            handle(result: result)
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func handle(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential else {
                onComplete(false)
                return
            }
            appState.appleUserId = cred.user
            if let email = cred.email, !email.isEmpty {
                appState.appleEmail = email
            }
            // Apple only returns fullName the very first time. Use it
            // to populate display name; later sign-ins will see nil
            // and we just keep the existing userName.
            if let parts = cred.fullName {
                let assembled = [parts.givenName, parts.familyName]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                if !assembled.isEmpty {
                    appState.userName = assembled
                }
            }
            // Don't ever bother the user with the welcome name prompt
            // again once they've used Apple sign-in.
            appState.hasSeenNamePrompt = true
            onComplete(true)
        case .failure:
            onComplete(false)
        }
    }
}
