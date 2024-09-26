//
//  AuthenticationView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//


import SwiftUI

struct AuthenticationView: View {
    @State private var isShowingSignUp = false

    var body: some View {
        NavigationView {
            SignInView(showSignUp: {
                self.isShowingSignUp = true
            })
        }
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
        }
    }
}
