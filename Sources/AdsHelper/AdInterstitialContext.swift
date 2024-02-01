//
//  AdInterstitialContext.swift
//
//
//  Created by Fausto Ristagno on 20/01/24.
//

import SwiftUI

public struct AdInterstitialContext : ViewModifier {
    @Environment(AdManager.self)
    private var adManager

    @Environment(\.appUpgradeHandler)
    private var appUpgradeHandler

    @State
    private var interstitialManager = AdInterstitialManager()

    public func body(content: Content) -> some View {
        content
            .onAppear {
                interstitialManager.setup(
                    provider: adManager.makeFullscreenProvider(delegate: interstitialManager),
                    askBeforePresent: adManager.askBeforePresentInterstitial,
                    usageCounter: adManager.interstitialUsageCounter
                )
            }
            .background {
                // Add the adViewControllerRepresentable to the background so it
                // doesn't influence the placement of other views in the view hierarchy.
                AdInterstitialViewControllerRepresentable()
                    .frame(width: .zero, height: .zero)
            }
            .alert("Upgrade plan", isPresented: $interstitialManager.isUpgradePlanAlertPresented) {
                Button("Watch ad") {
                    interstitialManager.presentAd()
                }
                Button("Discover PRO upgrade") {
                    appUpgradeHandler()
                }
                Button("Cancel", role: .cancel) {
                    interstitialManager.onDismissAction = nil
                }

            }
            .environment(interstitialManager)
            .environment(\.adsTrigger, { (position, action, completion) in
                Task {
                    await AdsTrigger(
                        manager: interstitialManager,
                        position: position,
                        action: action,
                        completion: completion
                    )()
                }
            })
            .environment(\.adsAsyncTrigger, {
                Task {
                    try await Task.sleep(nanoseconds: 2_000_000_000)

                    await AdsTrigger(
                        manager: interstitialManager,
                        position: .defaultOrder,
                        action: {},
                        completion: nil
                    )()
                }
            })
    }
}

public extension View {
    func adInterstitialContext() -> some View {
        self
            .modifier(AdInterstitialContext())
    }
}

#if DEBUG
private struct InterstitialAdsPreviewView : View {
    @Environment(\.adsTrigger)
    private var adsTrigger

    var body: some View {
        VStack {
            Text("Content")
            Button("Show ad before action") {
                adsTrigger(.beforeAction, {
                    print("Azione")
                }, {
                    print("Completato")
                })
            }
            Button("Show ad after action") {
                adsTrigger(.afterAction, {
                    print("Azione")
                }, {
                    print("Completato")
                })
            }
        }
    }
}
#endif

#Preview {
    NavigationView {
        InterstitialAdsPreviewView()
            .adInterstitialContext()
            .onAdAppUpgradeRequested {
                print("App upgrade requested")
            }
    }
    .environment(AdManager.testManager)
}
