//
//  AdInterstitialManager.swift
//
//
//  Created by Fausto Ristagno on 16/01/24.
//

import SwiftUI
import GoogleMobileAds

@Observable
public class AdInterstitialManager : NSObject {
    private var admobUnitId: String? = nil
    private var usageCounter: (any UsageCounter)? = nil
    private var askBeforePresent: Bool = true
    private weak var rootViewController: UIViewController? = nil
    private var interstitial: GADInterstitialAd?
    public var isUpgradePlanAlertPresented = false
    public private(set) var isInterstitialVisible = false
    private var isLoadingAd = false
    public var isReady: Bool {
        return self.interstitial != nil
    }

    override init() {
    }

    var isSetupCompleted: Bool {
        admobUnitId != nil && rootViewController != nil
    }

    func setup(rootViewController: UIViewController) {
        self.rootViewController = rootViewController

        if isSetupCompleted && interstitial == nil {
            loadAd()
        }
    }

    func setup(admobUnitId: String?, askBeforePresent: Bool = true, usageCounter: (any UsageCounter)? = nil) {
        self.admobUnitId = admobUnitId
        self.askBeforePresent = askBeforePresent
        self.usageCounter = usageCounter

        if isSetupCompleted && interstitial == nil {
            loadAd()
        }
    }

    private func loadAd() {
        guard let adUnitId =  self.admobUnitId else { return }
        guard !isLoadingAd else { return }

        isLoadingAd.toggle()

        let adRequest = GADRequest()
        GADInterstitialAd.load(withAdUnitID: adUnitId, request: adRequest) { (ad, error) in
            if let error {
                self.interstitial = nil
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                return
            }

            self.interstitial = ad
            self.interstitial?.fullScreenContentDelegate = self
            self.isLoadingAd = false
        }
    }

    public func presentAd() {
        guard
            let rootViewController,
            let interstitial
        else {
            return
        }

        guard isReady else {
            if !isLoadingAd {
                loadAd()
            }

            return
        }

        interstitial.present(fromRootViewController: rootViewController)
    }

    public func trigger() {
        let isLimitReached: Bool
        if let usageCounter {
            usageCounter.increment()
            isLimitReached = usageCounter.isLimitReached()
        } else {
            isLimitReached = true
        }

        guard isLimitReached else { return }

        if askBeforePresent {
            isUpgradePlanAlertPresented = true
        } else {
            presentAd()
        }
    }
}


extension AdInterstitialManager: GADFullScreenContentDelegate {
    /// Tells the delegate an ad request failed.
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
        interstitial = nil
    }

    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        usageCounter?.reset()
    }

    /// Tells the delegate that an interstitial will be presented.
    public func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isInterstitialVisible = true
    }

    /// Tells the delegate the interstitial had been animated off the screen.
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isInterstitialVisible = false
        loadAd()
    }
}
