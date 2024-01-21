//
//  AdBannerViewManager.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 13/01/24.
//

import Foundation
import UIKit
import GoogleMobileAds

fileprivate protocol AdBannerViewManagerDelegate: NSObject {
    func bannerViewManager(_ manager: AdBannerViewManager, didRemove viewController: AdBannerViewController)
}

@Observable
class AdBannerViewManager: NSObject {
    fileprivate weak var delegate: AdBannerViewManagerDelegate? = nil
    private(set) var isBannerLoaded: Bool = false
    private(set) var admobUnitId: String? = nil
    var admobBannerView: GADBannerView? {
        didSet {
            if admobBannerView == nil {
                self.isBannerLoaded = false
            }
        }
    }
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
            self.admobBannerView
        }
    }
    var isSetupCompleted: Bool {
        admobUnitId != nil && admobBannerView?.rootViewController != nil
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

    @available(*, deprecated, message: "Do not call disable directly")
    public func disable() {
        self.admobBannerView?.removeFromSuperview()
        self.admobBannerView = nil
        self.refreshBannerViewControllers()
    }

    func loadBannerAd(in view: UIView) {
        if let controller = findBannerViewController(of: view) {
            activeBannerViewControllerUUID = controller.uuid
        }

        // Step 2 - Determine the view width to use for the ad width.
        let frame = view.frame.inset(by: view.safeAreaInsets)
        let viewWidth = frame.size.width

        // Step 3 - Get Adaptive GADAdSize and set the ad view.
        // Here the current interface orientation is used. If the ad is being preloaded
        // for a future orientation change or different orientation, the function for the
        // relevant orientation should be used.
        admobBannerView?.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)

        // Step 4 - Create an ad request and load the adaptive banner ad.
        admobBannerView?.load(GADRequest())
    }

    internal func setup(admobUnitId: String? = nil) {
        self.admobUnitId = admobUnitId
    }

    internal func setupAdmobBannerView(for window: UIWindow) {
        admobBannerView = GADBannerView()
        admobBannerView!.adUnitID = admobUnitId
        admobBannerView!.delegate = self
        admobBannerView!.backgroundColor = .clear
        admobBannerView!.rootViewController = window.rootViewController

        #if DEBUG
        print("Google Mobile Ads SDK version: \(GADMobileAds.sharedInstance().versionNumber)");
        #endif
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

extension AdBannerViewManager: GADBannerViewDelegate {
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        isBannerLoaded = true
        refreshBannerViewControllers()
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        isBannerLoaded = false
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        postBannerViewActionWillBeginNotification()
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        postBannerViewActionDidFinishNotification()
    }
}

