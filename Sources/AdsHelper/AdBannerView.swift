//
//  AdBannerView.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 13/01/24.
//

import SwiftUI

struct AdBannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = AdBannerViewController

    @Binding
    private var bannerLoaded: Bool

    @Binding
    private var bannerSize: CGSize

    init(bannerLoaded: Binding<Bool>, bannerSize: Binding<CGSize>) {
        self._bannerLoaded = bannerLoaded
        self._bannerSize = bannerSize
    }

    func makeUIViewController(context: Context) -> AdBannerViewController {
        guard let bannerManager = context.environment[AdBannerViewManager.self] else {
            fatalError("Ad interstitial manager not available")
        }

        let controller = AdBannerViewController(bannerViewManager: bannerManager)
        controller.delegate = context.coordinator

        return controller
    }
    
    func updateUIViewController(_ uiViewController: AdBannerViewController, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AdBannerViewControllerDelegate {
        let parent: AdBannerView

        init(_ parent: AdBannerView) {
            self.parent = parent
        }

        func adBannerViewControllerSizeDidChange(size: CGSize) {
            self.parent.bannerSize = size
        }

        func adBannerViewControllerStateDidChange(loaded: Bool) {
            parent.bannerLoaded = loaded
        }
    }
}
