//
//  AdBannerContainer.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 10/01/24.
//

import SwiftUI
import GoogleMobileAds

private struct AdBannerContainer: ViewModifier {

    @Environment(AdManager.self)
    private var adManager
    @State
    private var isBannerLoaded: Bool = false
    @State
    private var bannerSize: CGSize = .zero
    @SceneStorage(AdManager.AD_SCENE_ID_STORAGE_KEY)
    private var adSceneId: String = UUID().uuidString

    @ViewBuilder
    func body(content: Self.Content) -> some View {
        if adManager.canShowBannerAds {
            content
                .safeAreaPadding(isBannerLoaded ? .bottom : [], 54)
                .overlay(
                    AdBannerView(sceneId: adSceneId, bannerLoaded: $isBannerLoaded, bannerSize: $bannerSize)
                        .background(Material.regular)
                        .opacity(isBannerLoaded ? 1 : 0)
                        .allowsHitTesting(isBannerLoaded)
                        .frame(maxWidth: .infinity, maxHeight: 54)
                    , alignment: .bottom)
                .onChange(of: isBannerLoaded) { oldValue, newValue in
                    print("isBannerLoaded \(isBannerLoaded)")
                }
        } else {
            content
        }
    }
}

extension View {
    func adBannerContainer() -> some View {
        return self.modifier(AdBannerContainer())
    }
}

#Preview("Stack") {
    NavigationView {
        List {
            ForEach(0..<20, id: \.self) { i in
                NavigationLink("Row: \(i)") {
                    Text("Selection: \(i)")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .navigationTitle("Row \(i)")
                        .adBannerContainer()
                }
            }
        }
        .navigationTitle("My List")
        .adBannerContainer()
    }
    .environment(AdManager.testManager)
}

#Preview("Tabs") {
    TabView {
        NavigationView {
            List {
                ForEach(0..<20, id: \.self) { i in
                    NavigationLink("Tab 1 row: \(i)") {
                        Text("Selection: \(i)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .navigationTitle("Tab 1 row \(i)")
                            .adBannerContainer()
                    }
                }
            }
            .navigationTitle("My List")
            .adBannerContainer()
        }
        .tabItem { Label("Tab 1", image: "gear") }
        NavigationView {
            List {
                ForEach(0..<20, id: \.self) { i in
                    NavigationLink("Tab 2 row: \(i)") {
                        Text("Selection: \(i)")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .navigationTitle("Tab 2 Row \(i)")
                            .adBannerContainer()
                    }
                }
            }
            .navigationTitle("My List")
            .adBannerContainer()
        }
        .tabItem { Label("Tab 2", image: "gear") }
    }
    .environment(AdManager.testManager)
}
