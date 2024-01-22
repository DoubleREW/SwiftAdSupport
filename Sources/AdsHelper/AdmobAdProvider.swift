//
//  AdmobAdProvider.swift
//
//
//  Created by Fausto Ristagno on 22/01/24.
//

import UIKit
import GoogleMobileAds

public class AdmobAdBannerProvider : NSObject, AdBannerProvider {
    public private(set) var admobUnitId: String

    public weak var delegate: AdBannerProviderDelegate? = nil

    private var admobBannerView: GADBannerView? = nil

    public var bannerView: UIView? {
        admobBannerView
    }

    public var isSetupCompleted: Bool {
        admobBannerView?.rootViewController != nil
    }

    public init(admobUnitId: String) {
        self.admobUnitId = admobUnitId
    }

    public func setup(window: UIWindow) {
        guard admobBannerView == nil || admobBannerView!.rootViewController != window.rootViewController else {
            return
        }
        
        admobBannerView = GADBannerView()
        admobBannerView!.adUnitID = admobUnitId
        admobBannerView!.delegate = self
        admobBannerView!.backgroundColor = .clear
        admobBannerView!.rootViewController = window.rootViewController

        #if DEBUG
        print("Google Mobile Ads SDK version: \(GADMobileAds.sharedInstance().versionNumber)");
        #endif
    }
    
    public func load(for size: CGSize) {
        guard let admobBannerView else {
            return
        }

        admobBannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(size.width)

        admobBannerView.load(GADRequest())
    }
}

extension AdmobAdBannerProvider: GADBannerViewDelegate {
    public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        delegate?.adBannerProviderDidReceiveAd(self)
    }

    public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
        delegate?.adBannerProvider(self, didFailToReceiveAdWithError: error)
    }

    public func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
        delegate?.adBannerProviderWillPresentScreen(self)
    }

    public func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
        delegate?.adBannerProviderDidDismissScreen(self)
    }
}

public class AdmobAdInterstitialProvider : NSObject, AdFullscreenProvider {
    public private(set) var admobUnitId: String
    public weak var delegate: AdFullscreenProviderDelegate? = nil
    private weak var rootViewController: UIViewController? = nil
    private var interstitial: GADInterstitialAd?

    public init(admobUnitId: String) {
        self.admobUnitId = admobUnitId
    }

    public var isSetupCompleted: Bool {
        rootViewController != nil
    }

    public var isReady: Bool {
        interstitial != nil
    }

    public var isLoadingAd: Bool = false

    public func setup(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }
    
    public func load() {
        guard !isLoadingAd else { return }

        isLoadingAd.toggle()

        GADInterstitialAd.load(withAdUnitID: admobUnitId, request: GADRequest()) { [weak self] (ad, error) in
            guard let self else { return }

            if let error {
                print("Failed to load interstitial ad with error: \(error.localizedDescription)")
                self.interstitial = nil
                self.delegate?.adFullscreenProvider(self, didFailToReceiveAdWithError: error)
            } else {
                self.interstitial = ad
                self.interstitial?.fullScreenContentDelegate = self
                self.delegate?.adFullscreenProviderDidReceiveAd(self)
            }

            self.isLoadingAd = false
        }
    }
    
    public func present() {
        guard
            let rootViewController,
            let interstitial
        else {
            return
        }

        guard isReady else {
            if !isLoadingAd {
                load()
            }

            return
        }

        interstitial.present(fromRootViewController: rootViewController)
    }
    
}

extension AdmobAdInterstitialProvider : GADFullScreenContentDelegate {
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("interstitial:didFailToReceiveAdWithError: \(error.localizedDescription)")
        interstitial = nil
        delegate?.adFullscreenProvider(self, didFailToPresentFullScreenContentWithError: error)
    }

    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        delegate?.adFullscreenProviderWillPresentFullScreenContent(self)
    }

    public func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        delegate?.adFullscreenProviderWillDismissFullScreenContent(self)
    }

    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        delegate?.adFullscreenProviderDidDismissFullScreenContent(self)
        load()
    }
}
