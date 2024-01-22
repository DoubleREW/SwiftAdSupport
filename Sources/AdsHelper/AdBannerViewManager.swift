//
//  AdBannerViewManager.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 13/01/24.
//

import UIKit

fileprivate protocol AdBannerViewManagerDelegate: NSObject {
    func bannerViewManager(_ manager: AdBannerViewManager, didRemove viewController: AdBannerViewController)
}

@Observable
class AdBannerViewManager: NSObject {
    private var provider: (any AdBannerProvider)? = nil

    fileprivate weak var delegate: AdBannerViewManagerDelegate? = nil
    private(set) var isBannerLoaded: Bool = false
    fileprivate var bannerViewControllers = [UUID: WeakAdBannerViewController]()
    private var activeBannerViewControllerUUID: UUID? = nil
    private var activeBannerViewController: AdBannerViewController? {
        guard let uuid = activeBannerViewControllerUUID else {
            return nil
        }

        return bannerViewControllers[uuid]?.ref
    }
    var bannerView: UIView? {
        get {
            provider?.bannerView
        }
    }
    var isSetupCompleted: Bool {
        provider?.isSetupCompleted == true
    }

    struct Notification {
        static let bannerViewActionWillBegin = NSNotification.Name(rawValue: "bannerViewActionWillBegin")
        static let bannerViewActionDidFinish = NSNotification.Name(rawValue: "bannerViewActionDidFinish")
    }

    fileprivate struct WeakAdBannerViewController: Equatable, Hashable {
        weak var ref: AdBannerViewController?

        init (ref: AdBannerViewController) {
            self.ref = ref
        }

        static func == (lhs: WeakAdBannerViewController, rhs: WeakAdBannerViewController) -> Bool {
            return lhs.ref === rhs.ref
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ref)
        }
    }

    func loadBannerAd(in view: UIView) {
        if let controller = findBannerViewController(of: view) {
            activeBannerViewControllerUUID = controller.uuid
        }

        let frame = view.frame.inset(by: view.safeAreaInsets)

        provider?.load(for: frame.size)
    }

    internal func setup(provider: (any AdBannerProvider)? = nil) {
        self.provider = provider
    }

    internal func setup(window: UIWindow) {
        provider?.setup(window: window)
    }

    internal func add(bannerViewController controller: AdBannerViewController) {
        self.bannerViewControllers[controller.uuid] = WeakAdBannerViewController(ref: controller)
    }

    internal func remove(bannerViewController controller: AdBannerViewController) {
        self.bannerViewControllers.removeValue(forKey: controller.uuid)
        self.delegate?.bannerViewManager(self, didRemove: controller)
    }

    private func refreshBannerViewControllers() {
        for controller in bannerViewControllers.values {
            controller.ref?.updateLayout()
        }
    }

    private func findBannerViewController(of view: UIView) -> AdBannerViewController? {
        var responder = view.next;
        while (responder != nil) {
            if let viewController = responder as? AdBannerViewController {
                return viewController
            }
                
            responder = responder?.next
        }

        return nil
    }

    private func postBannerViewActionWillBeginNotification() {
        NotificationCenter.default.post(name: Notification.bannerViewActionWillBegin, object: self)
    }

    private func postBannerViewActionDidFinishNotification() {
        NotificationCenter.default.post(name: Notification.bannerViewActionDidFinish, object: self)
    }
}

extension AdBannerViewManager: AdBannerProviderDelegate {
    func adBannerProviderDidReceiveAd(_ provider: AdBannerProvider) {
        isBannerLoaded = true
        refreshBannerViewControllers()
    }

    func adBannerProvider(_ provider: AdBannerProvider, didFailToReceiveAdWithError error: Error) {
        isBannerLoaded = false
    }

    func adBannerProviderWillPresentScreen(_ provider: AdBannerProvider) {
        postBannerViewActionWillBeginNotification()
    }

    func adBannerProviderDidDismissScreen(_ provider: AdBannerProvider) {
        postBannerViewActionDidFinishNotification()
    }
}
