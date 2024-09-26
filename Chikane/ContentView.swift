//
//  ContentView.swift
//  Chikane
//
//  Created by Ty Mitchell on 9/14/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            SessionHistoryView()
                .tabItem {
                    Label("Sessions", systemImage: "flag.checkered")
                }
            ManageCarsView()
                .tabItem {
                    Label("Cars", systemImage: "car.fill")
                }
           UserProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
