//
//  AviaryApp.swift
//  Aviary
//
//  Created by Xinyu Fang on 4/27/26.
//

import SwiftUI

@main
struct AviaryApp: App {
    @StateObject private var demoStore: DemoModeStore
    @StateObject private var auth: AuthViewModel

    init() {
        let store = DemoModeStore()
        _demoStore = StateObject(wrappedValue: store)
        _auth = StateObject(wrappedValue: AuthViewModel(demoStore: store))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(auth)
                .environmentObject(demoStore)
                .task { await auth.bootstrap() }
        }
    }
}
