//
//  AdBannerContainer.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 10/01/24.
//

import SwiftUI
import GoogleMobileAds
import UIFoundation

struct AdBannerContainer: ViewModifier {

    private var isNavigationView: Bool = false

    @Environment(AdManager.self)
    private var adManager
    @State
    private var isBannerLoaded: Bool = false
    @State
    private var bannerSize: CGSize = .zero

    init(isNavigationView: Bool = false) {
        self.isNavigationView = isNavigationView
    }

    @ViewBuilder
    func body(content: Self.Content) -> some View {
        if adManager.canShowBannerAds {
            content
                .safeAreaPadding((isBannerLoaded && !isNavigationView) ? .bottom : [], bannerSize.height)
                .addAdditionalBottomPadding((isBannerLoaded && isNavigationView) ? bannerSize.height : 0)
                .overlay(
                    AdBannerView(bannerLoaded: $isBannerLoaded, bannerSize: $bannerSize)
                        .background(Material.regular)
                        .opacity(isBannerLoaded ? 1 : 0)
                        .allowsHitTesting(isBannerLoaded)
                        .frame(maxWidth: .infinity, maxHeight: bannerSize.height)
                    , alignment: .bottom)
        } else {
            content
        }
    }
}

public extension View {
    func adBannerContainer() -> some View {
        return self.modifier(AdBannerContainer())
    }

    func adBannerNavContainer() -> some View {
        return self.modifier(AdBannerContainer(isNavigationView: true))
    }
}

#if DEBUG
#Preview("Stack") {
    NavigationStack {
        List {
            ForEach(0..<20, id: \.self) { i in
                NavigationLink(String("Row: \(i)")) {
                    Text(verbatim: "Selection: \(i)")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .navigationTitle(String("Row \(i)"))
                        .adBannerContainer()
                }
            }
        }
        .navigationTitle(String("My List"))
        .adBannerContainer()
    }
    .adBannerContext()
    .environment(AdManager.testManager)
}

#Preview("Sheet") {
    NavigationStack {
        List {
            Text(verbatim: "View")
        }
        .adBannerContainer()
        .navigationTitle(String("My List"))
        .sheet(isPresented: .constant(true), content: {
            NavigationView {
                List {
                    Text(verbatim: "Sheet")
                }
            }
            .adBannerContainer()
        })
    }
    .adBannerContext()
    .environment(AdManager.testManager)
}


#Preview("Tabs") {
    TabView {
        NavigationStack {
            List {
                ForEach(0..<20, id: \.self) { i in
                    NavigationLink(String("Tab 1 row: \(i)")) {
                        Text(verbatim: "Selection: \(i)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .navigationTitle(String("Tab 1 row \(i)"))
                            .additionalBottomPadding()
                    }
                }
            }
            .additionalBottomPadding()
            .navigationTitle(String("My List"))
        }
        .adBannerNavContainer()
        .tabItem { Label(String("Tab 1"), image: "gear") }
        
        NavigationStack {
            List {
                ForEach(0..<20, id: \.self) { i in
                    NavigationLink(String("Tab 2 row: \(i)")) {
                        Text(verbatim: "Selection: \(i)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .additionalBottomPadding()
                            .navigationTitle(String("Tab 2 Row \(i)"))
                    }
                }
            }
            .additionalBottomPadding()
            .navigationTitle(String("My List"))
        }
        .adBannerNavContainer()
        .tabItem { Label(String("Tab 2"), image: "gear") }
    }
    .adBannerContext()
    .environment(AdManager.testManager)
}
#endif
