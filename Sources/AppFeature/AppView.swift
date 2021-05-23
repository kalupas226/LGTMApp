//
//  AppView.swift
//  LGTMApp
//
//  Created by Aikawa Kenta on 2021/05/21.
//

import AVFoundation
import AVFoundationManager
import ComposableArchitecture
import SwiftUI

public struct AppState: Equatable {
    public init() {}

    var image: UIImage?
    var previewLayer: CALayer?
    var captureSession: AVCaptureSession?
    var captureDevice: AVCaptureDevice?
    var photoOutput: AVCapturePhotoOutput?
    var longPressTimer: Timer?
}

public enum AppAction: Equatable {
    case onAppear
    case onDissapear
    case longPressing
    case longPressed
    case didTapCapturePhotoButton
    case avFoundationManager(AVFoundationManager.Action)
}

public struct AppEnvironment {
    let avFoundationManager: AVFoundationManager

    public init(avFoundationManager: AVFoundationManager) {
        self.avFoundationManager = avFoundationManager
    }
}

public let appReducer = Reducer<AppState, AppAction, AppEnvironment> { state, action, environment in
    switch action {
    case .onAppear:
        return environment.avFoundationManager.prepareCamera()
            .eraseToEffect()
            .map(AppAction.avFoundationManager)

    case .onDissapear:
        return environment.avFoundationManager.endSession(state.captureSession)
            .fireAndForget()

    case .longPressing:
        state.longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            print("pressing")
        }
        return .none

    case .longPressed:
        state.longPressTimer?.invalidate()
        state.longPressTimer = nil
        return environment.avFoundationManager.capturePhoto(state.photoOutput)
            .eraseToEffect()
            .map(AppAction.avFoundationManager)

    case .didTapCapturePhotoButton:
        return environment.avFoundationManager.capturePhoto(state.photoOutput)
            .eraseToEffect()
            .map(AppAction.avFoundationManager)

    case let .avFoundationManager(action):
        switch action {
        case let .didFinishPrepare(captureSession, captureDevice):
            state.captureSession = captureSession
            state.captureDevice = captureDevice
            return environment.avFoundationManager.beginSession(captureSession, captureDevice)
                .eraseToEffect()
                .map(AppAction.avFoundationManager)

        case let .didFinishBeginSession(previewLayer, photoOutput):
            state.previewLayer = previewLayer
            state.photoOutput = photoOutput
            return environment.avFoundationManager.startSession(state.captureSession)
                .fireAndForget()

        case let .didSucceedSaveImage(image):
            print("Success save image!")
            return .none
        }
    }
}

public struct AppView: View {
    let store: Store<AppState, AppAction>

    public init(store: Store<AppState, AppAction>) {
        self.store = store
    }

    public var body: some View {
        WithViewStore(store) { viewStore in
            Group {
                if let previewLayer = viewStore.previewLayer {
                    GeometryReader { proxy in
                        VStack {
                            CALayerView(
                                screenWidth: proxy.size.width,
                                screenHeight: proxy.size.height,
                                caLayer: previewLayer
                            )
                            Circle()
                                .frame(width: 80, height: 80)
                                .onTapGesture {
                                    viewStore.send(.didTapCapturePhotoButton)
                                }
                                .gesture(
                                    LongPressGesture()
                                        .onEnded { _ in
                                            viewStore.send(.longPressing)
                                        }
                                        .sequenced(
                                            before: DragGesture(minimumDistance: 0)
                                                .onEnded { _ in
                                                    viewStore.send(.longPressed)
                                                }
                                        )
                                )
                                .padding(.bottom, 80)
                        }
                    }
                }
            }
            .onAppear(perform: {
                viewStore.send(.onAppear)
            })
            .onDisappear(perform: {
                viewStore.send(.onDissapear)
            })
        }
    }
}

struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        AppView(
            store: Store(
                initialState: AppState(),
                reducer: appReducer,
                environment: AppEnvironment(avFoundationManager: .live)
            )
        )
    }
}
