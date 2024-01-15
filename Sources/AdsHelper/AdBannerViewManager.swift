//
//  AdBannerViewManager.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 13/01/24.
//

import Foundation
import UIKit
import GoogleMobileAds

class AdBannerViewManagerRegistry : NSObject {
    static let shared: AdBannerViewManagerRegistry = {
        AdBannerViewManagerRegistry()
    }()

    private var managers: [UUID: AdBannerViewManager] = [:]
    private var admobBannerUnitID: String? = nil

    func configure(admobBannerUnitID: String?) {
        self.admobBannerUnitID = admobBannerUnitID
    }

    func manager(for sceneId: UUID) -> AdBannerViewManager {
        guard let admobBannerUnitID else {
            fatalError("AdBannerViewManagerRegistry not configured")
        }
        
        if let manager = managers[sceneId] {
            return manager
        }

        let manager = AdBannerViewManager(sceneId: sceneId, admobBannerUnitId: admobBannerUnitID)
        manager.delegate = self

        managers[sceneId] = manager

        return manager
    }

    private func remove(manager: AdBannerViewManager) {
        managers.removeValue(forKey: manager.sceneId)
    }
}

extension AdBannerViewManagerRegistry : AdBannerViewManagerDelegate {
    fileprivate func bannerViewManager(_ manager: AdBannerViewManager, didRemove viewController: AdBannerViewController) {
        if manager.bannerViewControllers.isEmpty {
            remove(manager: manager)
        }
    }
}

fileprivate protocol AdBannerViewManagerDelegate: NSObject {
    func bannerViewManager(_ manager: AdBannerViewManager, didRemove viewController: AdBannerViewController)
}

class AdBannerViewManager: NSObject {
    let sceneId: UUID
    fileprivate weak var delegate: AdBannerViewManagerDelegate? = nil
    private(set) var isBannerLoaded: Bool = false
    private(set) var admobBannerUnitId: String
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
        admobBannerView != nil && admobBannerView!.rootViewController != nil
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

    init(sceneId: UUID, admobBannerUnitId: String) {
        self.sceneId = sceneId
        self.admobBannerUnitId = admobBannerUnitId
        super.init()
    }

    @available(*, deprecated, message: "Do not call disable directly")
    public func disable() {
        self.admobBannerView?.removeFromSuperview()
        self.admobBannerView = nil
        self.refreshBannerViewControllers()
    }

    func loadBannerAd(in view: UIView) {
        print("loadBannerAd")

        if let controller = findBannerViewController(of: view) {
            print("loadBannerAd \(controller.uuid)")
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

    func setupAdmobBannerView(for window: UIWindow) {
        self.admobBannerView = GADBannerView()
        self.admobBannerView!.adUnitID = self.admobBannerUnitId
        self.admobBannerView!.delegate = self
        self.admobBannerView!.backgroundColor = .clear
        self.admobBannerView!.rootViewController = window.rootViewController

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
        for controller in self.bannerViewControllers.values {
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
        self.isBannerLoaded = true
        self.refreshBannerViewControllers()
    }

    func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        self.isBannerLoaded = false
    }

    func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        self.postBannerViewActionWillBeginNotification()
    }

    func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        self.postBannerViewActionDidFinishNotification()
    }
}

