//
//  AdBannerView.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 13/01/24.
//

import SwiftUI

struct AdBannerView: UIViewControllerRepresentable {
    typealias UIViewControllerType = AdBannerViewController

    private var sceneId: String

    @Binding
    private var bannerLoaded: Bool

    @Binding
    private var bannerSize: CGSize

    init(sceneId: String, bannerLoaded: Binding<Bool>, bannerSize: Binding<CGSize>) {
        self.sceneId = sceneId
        self._bannerLoaded = bannerLoaded
        self._bannerSize = bannerSize
    }

    func makeUIViewController(context: Context) -> AdBannerViewController {
        guard let sceneUuid = UUID(uuidString: sceneId) else {
            fatalError("Invalid scene id")
        }

        let bannerManager = AdBannerViewManagerRegistry.shared.manager(for: sceneUuid)
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
