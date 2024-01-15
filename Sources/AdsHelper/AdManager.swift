//
//  AdManager.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 14/01/24.
//

import Foundation
import GoogleMobileAds

@Observable
public class AdManager {
    package static let AD_SCENE_ID_STORAGE_KEY = "adSceneId"

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

    public private(set) var isEnabled: Bool = false

    public init(
        admobBannerUnitID: String? = nil,
        admobInterstitialUnitID: String? = nil
    ) {
        self.admobBannerUnitID = admobBannerUnitID
        self.admobInterstitialUnitID = admobInterstitialUnitID

        AdBannerViewManagerRegistry.shared.configure(admobBannerUnitID: admobBannerUnitID)
    }

    public var canShowBannerAds: Bool {
        isEnabled && admobBannerUnitID != nil
    }

    public func enable() {
        GADMobileAds.sharedInstance().start()

        isEnabled = true
    }

    public func disable() {
        isEnabled = false
    }
}
