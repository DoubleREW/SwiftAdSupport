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
    private var provider: (any AdFullscreenProvider)? = nil
    private var usageCounter: (any UsageCounter)? = nil
    private var askBeforePresent: Bool = true
    public var isUpgradePlanAlertPresented = false
    public private(set) var isInterstitialVisible = false
    var onDismissAction: (() async -> Void)? = nil
    public var isReady: Bool {
        self.provider?.isReady == true
    }

    override init() {
    }

    var isSetupCompleted: Bool {
        provider?.isSetupCompleted == true
    }

    func setup(rootViewController: UIViewController) {
        provider?.setup(rootViewController: rootViewController)

        loadAd()
    }

    func setup(provider: (any AdFullscreenProvider)?, askBeforePresent: Bool = true, usageCounter: (any UsageCounter)? = nil) {
        guard self.provider?.isSetupCompleted != true || self.provider?.type != provider?.type else {
            return
        }

        self.provider = provider
        self.askBeforePresent = askBeforePresent
        self.usageCounter = usageCounter

        loadAd()
    }

    private func loadAd() {
        if let provider, provider.isSetupCompleted && !provider.isReady {
            provider.load()
        }
    }

    public func presentAd() {
        guard let provider, provider.isSetupCompleted else {
            return
        }

        guard isReady else {
            if !provider.isLoadingAd {
                provider.load()
            }

            return
        }

        provider.present()
    }

    @discardableResult
    public func trigger() -> Bool {
        let isLimitReached: Bool
        if let usageCounter {
            usageCounter.increment()
            isLimitReached = usageCounter.isLimitReached()
        } else {
            isLimitReached = true
        }

        guard isLimitReached else {
            return false
        }

        if askBeforePresent {
            isUpgradePlanAlertPresented = true
        } else {
            presentAd()
        }

        return true
    }
}


extension AdInterstitialManager: AdFullscreenProviderDelegate {
    public func adFullscreenProviderDidReceiveAd(_ provider: AdFullscreenProvider) { }

    public func adFullscreenProvider(_ provider: AdFullscreenProvider, didFailToReceiveAdWithError error: Error) {
        isInterstitialVisible = false
        onDismissAction = nil
    }

    public func adFullscreenProvider(_ provider: AdFullscreenProvider, didFailToPresentFullScreenContentWithError error: Error) {
        isInterstitialVisible = false
        onDismissAction = nil
    }

    public func adFullscreenProviderWillPresentFullScreenContent(_ provider: AdFullscreenProvider) {
        usageCounter?.reset()
        isInterstitialVisible = true
    }

    public func adFullscreenProviderWillDismissFullScreenContent(_ provider: AdFullscreenProvider) { }

    public func adFullscreenProviderDidDismissFullScreenContent(_ provider: AdFullscreenProvider) {
        isInterstitialVisible = false
        loadAd()

        if let onDismissAction {
            Task {
                await onDismissAction()
            }

            self.onDismissAction = nil
        }
    }
}
