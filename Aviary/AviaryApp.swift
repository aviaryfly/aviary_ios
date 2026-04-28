//
//  AviaryApp.swift
//  Aviary
//
//  Created by Xinyu Fang on 4/27/26.
//

import SwiftUI

@main
struct AviaryApp: App {
    @StateObject private var auth = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .task { await auth.bootstrap() }
        }
    }
}
