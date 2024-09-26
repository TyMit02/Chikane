//
//  SignInView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/15/24.
//


import SwiftUI
import Combine

struct SignInView: View {
    @StateObject private var viewModel: SignInViewModel
    @State private var isAnimating = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email, password
    }
    
    init(showSignUp: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: SignInViewModel(showSignUp: showSignUp))
    }
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 30) {
                    logoView
                    
                    VStack(spacing: 20) {
                        emailField
                        passwordField
                    }
                    
                    signInButton
                    
                    forgotPasswordButton
                    
                    signUpButton
                }
                .padding(.horizontal, 30)
            }
        }
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(title: Text(alertItem.title),
                  message: Text(alertItem.message),
                  dismissButton: .default(Text("OK")))
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
    
    private var logoView: some View {
        Image(systemName: "flag.checkered.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
            .foregroundColor(AppColors.secondary)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear { isAnimating = true }
    }
    
    private var emailField: some View {
           CustomTextField(
               icon: "envelope",
               placeholder: "Email",
               text: $viewModel.email,
               isSecure: false,
               keyboardType: .emailAddress,
               returnKeyType: .next,
               onCommit: { focusedField = .password }
           )
           .focused($focusedField, equals: .email)
       }
       
       private var passwordField: some View {
           CustomTextField(
               icon: "lock",
               placeholder: "Password",
               text: $viewModel.password,
               isSecure: true,
               returnKeyType: .go,
               onCommit: viewModel.signIn
           )
           .focused($focusedField, equals: .password)
       }
       
    
    private var signInButton: some View {
        Button(action: viewModel.signIn) {
            Text("SIGN IN")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(AppColors.accent)
                .cornerRadius(10)
        }
        .disabled(!viewModel.isFormValid)
        .opacity(viewModel.isFormValid ? 1.0 : 0.6)
    }
    
    private var forgotPasswordButton: some View {
        Button(action: viewModel.forgotPassword) {
            Text("Forgot Password?")
                .font(AppFonts.footnote)
                .foregroundColor(AppColors.secondary)
        }
    }
    
    private var signUpButton: some View {
        Button(action: viewModel.showSignUp) {
            Text("Don't have an account? Sign Up")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.secondary)
        }
    }
}

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var onCommit: (() -> Void)?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppColors.lightText)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
                    .textContentType(keyboardType == .emailAddress ? .emailAddress : .none)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(10)
        .foregroundColor(AppColors.text)
        .keyboardType(keyboardType)
        .submitLabel(returnKeyType == .next ? .next : .done)
        .onSubmit(onCommit ?? {})
    }
}


class SignInViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var alertItem: AlertItem?
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    private let authManager = AuthenticationManager.shared
    var showSignUp: () -> Void
    private var cancellables = Set<AnyCancellable>()
    
    init(showSignUp: @escaping () -> Void) {
        self.showSignUp = showSignUp
    }
    
    func signIn() {
        guard isFormValid else {
            alertItem = AlertItem(title: "Invalid Form", message: "Please enter a valid email and password.")
            return
        }
        
        authManager.signIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.alertItem = AlertItem(title: "Sign In Failed", message: error.localizedDescription)
                }
            } receiveValue: { _ in
                // Navigation will be handled by RootView
            }
            .store(in: &cancellables)
    }
    
    func forgotPassword() {
        // Implement forgot password functionality
        alertItem = AlertItem(title: "Forgot Password", message: "This feature is not yet implemented.")
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
// Preview
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(showSignUp: {})
            .preferredColorScheme(.dark)
    }
}
