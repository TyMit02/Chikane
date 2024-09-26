//
//  SignUpView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//

import SwiftUI
import Combine

struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var isAnimating = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case username, email, password
    }
    
    var body: some View {
        ZStack {
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                Spacer()
                
                VStack(spacing: 30) {
                   Spacer()
                    
                    logoView
                    
                    VStack(spacing: 20) {
                        usernameField
                        emailField
                        passwordField
                    }
                    
                    signUpButton
                    
                    signInButton
                }
                .padding(.horizontal, 30)
            }
        }
        .alert(item: $viewModel.alertItem) { alertItem in
            Alert(title: Text(alertItem.title),
                  message: Text(alertItem.message),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    private var logoView: some View {
        Image(systemName: "flag.checkered.circle")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 100, height: 100)
            .foregroundColor(AppColors.accent)
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .animation(Animation.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            .onAppear { isAnimating = true }
    }
    
    private var usernameField: some View {
           CustomTextField(
               icon: "person",
               placeholder: "Username",
               text: $viewModel.username,
               returnKeyType: .next,
               onCommit: { focusedField = .email }
           )
           .focused($focusedField, equals: .username)
       }
       
       private var emailField: some View {
           CustomTextField(
               icon: "envelope",
               placeholder: "Email",
               text: $viewModel.email,
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
               onCommit: viewModel.signUp
           )
           .focused($focusedField, equals: .password)
       }
    
    private var signUpButton: some View {
        Button(action: viewModel.signUp) {
            Text("SIGN UP")
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
    
    private var signInButton: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Text("Already have an account? Sign In")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.accent)
        }
    }
}

class SignUpViewModel: ObservableObject {
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    @Published var alertItem: AlertItem?
    
    var isFormValid: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && email.contains("@") && password.count >= 8
    }
    
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    func signUp() {
        guard isFormValid else {
            alertItem = AlertItem(title: "Invalid Form", message: "Please enter a valid username, email, and password (at least 8 characters).")
            return
        }
        
        authManager.signUp(email: email, password: password, username: username)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.alertItem = AlertItem(title: "Sign Up Failed", message: error.localizedDescription)
                }
            } receiveValue: { _ in
                // Navigation will be handled by RootView
            }
            .store(in: &cancellables)
    }
}


// Preview
struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .preferredColorScheme(.dark)
    }
}
