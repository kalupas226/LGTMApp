//
//  SampleTest.swift
//
//
//  Created by Aikawa Kenta on 2021/05/21.
//

import ComposableArchitecture
import XCTest

@testable import AppFeature

class SampleTest: XCTestCase {
    func testTextFieldChanged() {
        let store = TestStore(
            initialState: AppState(),
            reducer: appReducer,
            environment: AppEnvironment(avFoundationManager: .live)
        )
    }
}
