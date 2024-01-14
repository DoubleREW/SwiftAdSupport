//
//  AdBannerViewManager.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 13/01/24.
//

import Foundation
import UIKit
import GoogleMobileAds

public class AdBannerViewManagerRegistry : NSObject {
    public static let shared: AdBannerViewManagerRegistry = {
        AdBannerViewManagerRegistry()
    }()

    private var managers: [UUID: AdBannerViewManager] = [:]

    public func manager(for sceneId: UUID) -> AdBannerViewManager {
        if let manager = managers[sceneId] {
            return manager
        }

        let manager = AdBannerViewManager(sceneId: sceneId)
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

public class AdBannerViewManager: NSObject {
    public let sceneId: UUID
    fileprivate weak var delegate: AdBannerViewManagerDelegate? = nil
    public var isBannerLoaded: Bool = false
    public var admobBannerUnitId: String! = "ca-app-pub-3940256099942544/2435281174"
    internal var admobBannerView: GADBannerView? {
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
    public var bannerView: UIView? {
        get {
            self.admobBannerView
        }
    }

    public struct Notification {
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

    public init(sceneId: UUID) {
        self.sceneId = sceneId
        super.init()
    }

    public func enable() {
        self.setupAdmobBannerView()
    }

    public func disable() {
        self.admobBannerView?.removeFromSuperview()
        self.admobBannerView = nil
        self.refreshBannerViewControllers()
    }

    internal func loadBannerAd(in view: UIView) {
        print("loadBannerAd")

        if let controller = findBannerViewController(of: view) {
            print("loadBannerAd \(controller.uuid)")
            activeBannerViewControllerUUID = controller.uuid
        }

        if self.admobBannerView == nil {
            self.setupAdmobBannerView()
            self.admobBannerView!.rootViewController = view.window?.rootViewController
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

    private func setupAdmobBannerView() {
        self.admobBannerView = GADBannerView()
        self.admobBannerView!.adUnitID = self.admobBannerUnitId
        self.admobBannerView!.delegate = self
        self.admobBannerView!.backgroundColor = .black

        #if DEBUG
        print("Google Mobile Ads SDK version: \(GADMobileAds.sharedInstance().versionNumber)");
        #endif
    }

    internal func add(bannerViewController controller: AdBannerViewController) {
        print("add \(controller.view.window)")
        self.bannerViewControllers[controller.uuid] = WeakAdBannerViewController(ref: controller)
    }

    internal func remove(bannerViewController controller: AdBannerViewController) {
        print("remove")
        self.bannerViewControllers.removeValue(forKey: controller.uuid)
        self.delegate?.bannerViewManager(self, didRemove: controller)
    }

    private func refreshBannerViewControllers() {
        print(#function)
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
    public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        print(#function)
        print("bannerViewDidReceiveAd:")
        self.isBannerLoaded = true
        self.refreshBannerViewControllers()
    }

    public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        print("bannerView:didFailToReceiveAdWithError: \(error.localizedDescription)")
        self.isBannerLoaded = false
    }

    public func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        self.postBannerViewActionWillBeginNotification()
    }

    public func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        self.postBannerViewActionDidFinishNotification()
    }
}

