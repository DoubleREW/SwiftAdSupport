//
//  AdContext.swift
//  
//
//  Created by Fausto Ristagno on 21/01/24.
//

import SwiftUI

public typealias AppUpgradeHandler = () -> Void

private struct AppUpgradeHandlerKey: EnvironmentKey {
    static let defaultValue: AppUpgradeHandler = { }
}

public extension EnvironmentValues {
    internal var appUpgradeHandler: AppUpgradeHandler {
        get { self[AppUpgradeHandlerKey.self] }
        set { self[AppUpgradeHandlerKey.self] = newValue }
    }
}

public extension View {
    func adContext() -> some View {
        self
            .adBannerContext()
            .adInterstitialContext()
    }

    func onAdAppUpgradeRequested(perform action: @escaping AppUpgradeHandler) -> some View {
        return self
            .environment(\.appUpgradeHandler, action)
    }
}
