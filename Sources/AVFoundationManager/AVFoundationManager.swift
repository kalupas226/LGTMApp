//
//  AVFoundationManager.swift
//
//
//  Created by Aikawa Kenta on 2021/05/23.
//

import AVFoundation
import Combine
import ComposableArchitecture
import UIKit

public struct AVFoundationManager {
    public enum Action: Equatable {
        case didFinishPrepare(AVCaptureSession, AVCaptureDevice)
        case didFinishBeginSession(CALayer, AVCapturePhotoOutput)
        case didSucceedSaveImage(UIImage)
    }

    public var prepareCamera: () -> Effect<Action, Never>
    public var beginSession: (AVCaptureSession?, AVCaptureDevice?) -> Effect<Action, Never>
    public var startSession: (AVCaptureSession?) -> Effect<Never, Never>
    public var endSession: (AVCaptureSession?) -> Effect<Never, Never>
    public var capturePhoto: (AVCapturePhotoOutput?) -> Effect<Action, Never>

    public init(prepareCamera: @escaping () -> Effect<AVFoundationManager.Action, Never>,
                beginSession: @escaping (AVCaptureSession?, AVCaptureDevice?) -> Effect<AVFoundationManager.Action, Never>,
                startSession: @escaping (AVCaptureSession?) -> Effect<Never, Never>,
                endSession: @escaping (AVCaptureSession?) -> Effect<Never, Never>,
                capturePhoto: @escaping (AVCapturePhotoOutput?) -> Effect<Action, Never>)
    {
        self.prepareCamera = prepareCamera
        self.beginSession = beginSession
        self.startSession = startSession
        self.endSession = endSession
        self.capturePhoto = capturePhoto
    }
}

public extension AVFoundationManager {
    static let live = AVFoundationManager(
        prepareCamera: {
            .future { callback in
                let captureSession = AVCaptureSession()
                captureSession.sessionPreset = .photo

                if let availableDevice = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices.first {
                    callback(.success(.didFinishPrepare(captureSession, availableDevice)))
                }
            }
        },
        beginSession: { captureSession, captureDevice in
            .future { callback in
                guard let captureSession = captureSession,
                      let captureDevice = captureDevice
                else { return }

                do {
                    let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
                    captureSession.addInput(captureDeviceInput)
                } catch {
                    print(error.localizedDescription)
                }

                let photoOutput = AVCapturePhotoOutput()
                photoOutput.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])], completionHandler: nil)

                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                }

                captureSession.commitConfiguration()

                let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                callback(.success(.didFinishBeginSession(previewLayer, photoOutput)))
            }
        },
        startSession: { captureSession in
            .fireAndForget {
                guard let captureSession = captureSession else { return }

                if captureSession.isRunning { return }
                captureSession.startRunning()
            }
        },
        endSession: { captureSession in
            .fireAndForget {
                guard let captureSession = captureSession else { return }

                if !captureSession.isRunning { return }
                captureSession.stopRunning()
            }
        },
        capturePhoto: { photoOutput in
            .run { subscriber in
                guard let photoOutput = photoOutput else { return AnyCancellable {} }

                let settings = AVCapturePhotoSettings()
                settings.flashMode = .auto
                var delegate: AVCapturePhotoStream? = AVCapturePhotoStream(subscriber: subscriber)
                photoOutput.capturePhoto(with: settings, delegate: delegate!)

                return AnyCancellable {
                    delegate = nil
                }
            }
        }
    )
}

private class AVCapturePhotoStream: NSObject, AVCapturePhotoCaptureDelegate {
    let subscriber: Effect<AVFoundationManager.Action, Never>.Subscriber

    public init(subscriber: Effect<AVFoundationManager.Action, Never>.Subscriber) {
        self.subscriber = subscriber
    }

    func photoOutput(_: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error _: Error?) {
        if let imageData = photo.fileDataRepresentation() {
            guard let uiImage = UIImage(data: imageData) else { return }
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            subscriber.send(.didSucceedSaveImage(uiImage))
            subscriber.send(completion: .finished)
        }
    }
}
