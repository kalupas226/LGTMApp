//
//  LGTMApp.swift
//  LGTMApp
//
//  Created by Aikawa Kenta on 2021/05/21.
//

import AppFeature
import ComposableArchitecture
import SwiftUI

@main
struct LGTMApp: App {
    let store = Store(
        initialState: AppState(),
        reducer: appReducer,
        environment: AppEnvironment()
    )

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
