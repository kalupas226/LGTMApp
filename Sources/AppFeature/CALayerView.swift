//
//  CALayerView.swift
//
//
//  Created by Aikawa Kenta on 2021/05/23.
//

import SwiftUI

struct CALayerView: UIViewRepresentable {
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    var caLayer: CALayer

    func makeUIView(context _: Context) -> some UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight - 200))
        view.layer.addSublayer(caLayer)
        caLayer.frame = view.layer.frame

        return view
    }

    func updateUIView(_ uiView: UIViewType, context _: Context) {
        caLayer.frame = uiView.layer.frame
    }
}
