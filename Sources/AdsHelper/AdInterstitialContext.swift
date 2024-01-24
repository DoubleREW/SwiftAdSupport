//
//  AdInterstitialContext.swift
//
//
//  Created by Fausto Ristagno on 20/01/24.
//

import SwiftUI

public typealias AdsTriggerHandler = (
    AdsDisplayOrder,
    @escaping () async -> Void,
    (() async -> Void)?
) -> Void

private struct AdsTriggerKey: EnvironmentKey {
    static let defaultValue: AdsTriggerHandler = { (_, action, completion) in
        Task {
            await action()

            if let completion {
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
                    adManager.planUpgradeCallback()
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
    }
    .environment(AdManager.testManager)
}
