//
//  AdInterstitialContext.swift
//
//
//  Created by Fausto Ristagno on 20/01/24.
//

import SwiftUI

public typealias AdsTriggerHandler = (
    AdsDisplayOrder,
    @escaping () -> Void,
    (() async -> Void)?
) -> Void

private struct AdsTriggerKey: EnvironmentKey {
    static let defaultValue: AdsTriggerHandler = {
        $1()

        if let completion = $2 {
            Task {
                await completion()
            }
        }
    }
}

public extension EnvironmentValues {
    fileprivate(set) var adsTrigger: AdsTriggerHandler {
        get { self[AdsTriggerKey.self] }
        set { self[AdsTriggerKey.self] = newValue }
    }
}

public struct AdInterstitialContext : ViewModifier {
    @Environment(AdManager.self)
    private var adManager

    @State
    private var interstitialManager = AdInterstitialManager()

    public func body(content: Content) -> some View {
        content
            .onAppear {
                interstitialManager.setup(
                    admobUnitId: adManager.admobInterstitialUnitID,
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
                    adManager.planUpgradeCallback()
                }
                Button("Cancel", role: .cancel) {
                    // Handle the deletion.
                }

            }
            .environment(interstitialManager)
            .environment(\.adsTrigger, { (position, action, completion) in
                AdsTrigger(manager: interstitialManager, position: position, action: action, completion: completion)
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
            Text("AAAA")
            Button("BBBB") {
                adsTrigger(.after, {
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
    }
    .environment(AdManager.testManager)
}
