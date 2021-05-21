//
//  AppView.swift
//  LGTMApp
//
//  Created by Aikawa Kenta on 2021/05/21.
//

import ComposableArchitecture
import SwiftUI

public struct AppState: Equatable {
    public init() {}

    var testText = ""
}

public enum AppAction: Equatable {
    case textFieldChanged(String)
}

public struct AppEnvironment: Equatable {
    public init() {}
}

public let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case .textFieldChanged(let text):
        state.testText = text
        return .none
    }
}

public struct AppView: View {
    let store: Store<AppState, AppAction>

    public init(store: Store<AppState, AppAction>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            TextField(
                "Enter Text",
                text: viewStore.binding(get: \.testText, send: AppAction.textFieldChanged)
            )
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: Store(
                initialState: AppState(),
                reducer: appReducer,
                environment: AppEnvironment()
            )
        )
    }
}
