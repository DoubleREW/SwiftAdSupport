//
//  AdBannerView.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 13/01/24.
//

import SwiftUI

public struct AdBannerView: UIViewControllerRepresentable {
    public typealias UIViewControllerType = AdBannerViewController

    private var sceneId: String

    @Binding
    private var bannerLoaded: Bool

    @Binding
    private var bannerSize: CGSize

    internal init(sceneId: String, bannerLoaded: Binding<Bool>, bannerSize: Binding<CGSize>) {
        self.sceneId = sceneId
        self._bannerLoaded = bannerLoaded
        self._bannerSize = bannerSize
    }

    public func makeUIViewController(context: Context) -> AdBannerViewController {
        guard let sceneUuid = UUID(uuidString: sceneId) else {
            fatalError("Invalid scene id")
        }

        print("makeUIViewController \(sceneUuid)")

        let bannerManager = AdBannerViewManagerRegistry.shared.manager(for: sceneUuid)
        let controller = AdBannerViewController(bannerViewManager: bannerManager)
        controller.delegate = context.coordinator

        return controller
    }
    
    public func updateUIViewController(_ uiViewController: AdBannerViewController, context: Context) {

    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, AdBannerViewControllerDelegate {
        let parent: AdBannerView

        init(_ parent: AdBannerView) {
            self.parent = parent
        }

        public func adBannerViewControllerSizeDidChange(size: CGSize) {
            parent.bannerSize = size
        }

        public func adBannerViewControllerStateDidChange(loaded: Bool) {
            parent.bannerLoaded = loaded
            print("bannerLoaded \(loaded)")
        }
    }
}
