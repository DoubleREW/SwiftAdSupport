//
//  AdManager.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 14/01/24.
//

import Foundation
import UIKit
import GoogleMobileAds
import UserMessagingPlatform

@Observable
public class AdManager {
    // Gestione consenso con UMP:  https://github.com/googleads/googleads-mobile-ios-examples/blob/main/Swift/admanager/AdManagerBannerExample/AdManagerBannerExample/GoogleMobileAdsConsentManager.swift

    #if DEBUG
    public static let testManager: AdManager = {
        let manager = AdManager(
            admobBannerUnitID: "ca-app-pub-3940256099942544/2934735716",
            admobInterstitialUnitID: "ca-app-pub-3940256099942544/5135589807")

        manager.enable()

        return manager
    }()
    #endif

    public private(set) var admobBannerUnitID: String?
    public private(set) var admobInterstitialUnitID: String?
    public private(set) var interstitialUsageCounter: (any UsageCounter)?
    public private(set) var askBeforePresentInterstitial: Bool = true
    public private(set) var isEnabled: Bool = false
    public private(set) var premiumPlanName: String
    public var testDeviceIdentifiers: [String]?
    private var isMobileAdsStartCalled = false
    public var isPrivacyOptionsRequired: Bool {
      return UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
    }

    public init(
        admobBannerUnitID: String? = nil,
        admobInterstitialUnitID: String? = nil,
        interstitialUsageCounter: (any UsageCounter)? = nil,
        askBeforePresentInterstitial: Bool = true,
        premiumPlanName: String = "PRO"
    ) {
        self.admobBannerUnitID = admobBannerUnitID
        self.admobInterstitialUnitID = admobInterstitialUnitID
        self.interstitialUsageCounter = interstitialUsageCounter
        self.askBeforePresentInterstitial = askBeforePresentInterstitial
        self.premiumPlanName = premiumPlanName
    }

    public var canShowBannerAds: Bool {
        isEnabled && admobBannerUnitID != nil
    }

    private var foregroundWindow: UIWindow? {
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let activeScene = windowScenes
            .filter { $0.activationState == .foregroundActive }
        let firstActiveScene = activeScene.first
        let keyWindow = firstActiveScene?.keyWindow

        return keyWindow
    }

    public func enable() {
        self.askConsents { [weak self] in
            guard let self else { return }

            GADMobileAds.sharedInstance().start()
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = self.testDeviceIdentifiers

            self.isEnabled = true
        }
    }

    public func disable() {
        isEnabled = false
    }

    @discardableResult
    public func presentPrivacyOptionsForm() -> Bool {
        guard let rootVC = foregroundWindow?.rootViewController else { return false }

        UMPConsentForm.presentPrivacyOptionsForm(from: rootVC) { [weak self] formError in
            guard let formError, self != nil else { return }

            print("Present privacy options form error: \(formError.localizedDescription)")
        }

        return true
    }

    func makeBannerProvider(delegate: any AdBannerProviderDelegate) -> (any AdBannerProvider)? {
        guard let admobBannerUnitID else {
            return nil
        }

        let provider = AdmobAdBannerProvider(admobUnitId: admobBannerUnitID)
        provider.delegate = delegate

        return provider
    }

    func makeFullscreenProvider(delegate: any AdFullscreenProviderDelegate) -> (any AdFullscreenProvider)? {
        guard let admobInterstitialUnitID else {
            return nil
        }

        let provider = AdmobAdInterstitialProvider(admobUnitId: admobInterstitialUnitID)
        provider.delegate = delegate

        return provider
    }

    private func askConsents(setupAdsCallback: @escaping () -> Void) {
        let setupAdsCallbackIfNeeded = { [weak self] in
            DispatchQueue.main.async {
                guard let self, !self.isMobileAdsStartCalled else { return }

                self.isMobileAdsStartCalled = true

                setupAdsCallback()
            }
        }

        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: nil) { [weak self] requestConsentError in
            guard self != nil else { return }
            guard let rootVC = self?.foregroundWindow?.rootViewController else { return }

            if let consentError = requestConsentError {
                // Consent gathering failed.
                return print("Error: \(consentError.localizedDescription)")
            }

            UMPConsentForm.loadAndPresentIfRequired(from: rootVC) { [weak self] loadAndPresentError in
                guard self != nil else { return }

                if let consentError = loadAndPresentError {
                    // Consent gathering failed.
                    return print("Error: \(consentError.localizedDescription)")
                }

                // Consent has been gathered.
                if UMPConsentInformation.sharedInstance.canRequestAds {
                    setupAdsCallbackIfNeeded()
                }
            }
        }

        // Check if you can initialize the Google Mobile Ads SDK in parallel
        // while checking for new consent information. Consent obtained in
        // the previous session can be used to request ads.
        if UMPConsentInformation.sharedInstance.canRequestAds {
            setupAdsCallbackIfNeeded()
        }
    }
}
