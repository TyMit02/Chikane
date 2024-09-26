//
//  ChikaneApp.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/16/24.
//

//
//  ChikaneApp.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/14/24.
//

import SwiftUI
import Firebase

@main
struct ChikaneApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager.shared

    var body: some Scene {
        WindowGroup {
            if authManager.user != nil {
                ContentView()
                    .onAppear {
                        UIApplication.shared.isIdleTimerDisabled = true // Keep screen on
                                }
                        .onDisappear {
                            UIApplication.shared.isIdleTimerDisabled = false // Allow screen to turn off when app is not active
                                        }
            } else {
                AuthenticationView()
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
