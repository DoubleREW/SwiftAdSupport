//
//  AdProvider.swift
//
//
//  Created by Fausto Ristagno on 22/01/24.
//

import UIKit

public struct AdProviderType : RawRepresentable, ExpressibleByStringLiteral, Equatable {
    public var rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.init(rawValue: value)
    }
}

public protocol AdProvider {
    var type: AdProviderType { get }
}

public protocol AdProviderDelegate {}

public protocol AdFullscreenProvider : AdProvider {
    var isSetupCompleted: Bool { get }
    var isReady: Bool { get }
    var isLoadingAd: Bool { get }
    
    func setup(rootViewController: UIViewController)
    func load()
    func present()
}

public protocol AdFullscreenProviderDelegate : AnyObject, AdProviderDelegate {
    func adFullscreenProviderDidReceiveAd(_ provider: any AdFullscreenProvider)

    func adFullscreenProvider(_ provider: any AdFullscreenProvider, didFailToReceiveAdWithError error: Error)

    func adFullscreenProvider(_ provider: any AdFullscreenProvider, didFailToPresentFullScreenContentWithError error: Error)

    func adFullscreenProviderWillPresentFullScreenContent(_ provider: any AdFullscreenProvider)

    func adFullscreenProviderWillDismissFullScreenContent(_ provider: any AdFullscreenProvider)

    func adFullscreenProviderDidDismissFullScreenContent(_ provider: any AdFullscreenProvider)
}

public protocol AdBannerProvider : AdProvider {
    var delegate: (any AdBannerProviderDelegate)? { get set }
    var bannerView: UIView? { get }
    var isSetupCompleted: Bool { get }

    func setup(window: UIWindow)
    func load(for size: CGSize)
}

public protocol AdBannerProviderDelegate : AnyObject, AdProviderDelegate {
    func adBannerProviderDidReceiveAd(_ provider: any AdBannerProvider)

    func adBannerProvider(_ provider: any AdBannerProvider, didFailToReceiveAdWithError error: Error)

    func adBannerProviderWillPresentScreen(_ provider: any AdBannerProvider)

    func adBannerProviderDidDismissScreen(_ provider: any AdBannerProvider)
}
