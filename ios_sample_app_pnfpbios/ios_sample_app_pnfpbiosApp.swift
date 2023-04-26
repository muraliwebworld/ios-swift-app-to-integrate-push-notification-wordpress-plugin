//
//  ios_sample_app_pnfpbiosApp.swift
//  ios_sample_app_pnfpbios
//
//  Created by Muralidharan Ramasamy on 26/04/23.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

@main
struct Aqua_NetApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
