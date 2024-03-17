//
//  AdBannerContext.swift
//
//
//  Created by Fausto Ristagno on 20/01/24.
//

import SwiftUI

public struct AdBannerContext : ViewModifier {
    @Environment(AdManager.self)
    private var adManager

    @State
    private var bannerManager = AdBannerViewManager()

    public func body(content: Content) -> some View {
        content
            .onAppear {
                bannerManager.setup(provider: adManager.makeBannerProvider(
                    delegate: bannerManager
                ))
            }
            .environment(bannerManager)
    }
}

public extension View {
    func adBannerContext() -> some View {
        self
            .modifier(AdBannerContext())
    }
}

#if DEBUG
private struct BannerAdsPreviewView : View {
    var body: some View {
        VStack {
            Text(verbatim: "AAAA")
        }
    }
}

#Preview {
    NavigationView {
        BannerAdsPreviewView()
            .adBannerContext()
    }
    .environment(AdManager.testManager)
}
#endif
