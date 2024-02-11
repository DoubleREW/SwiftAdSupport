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

    private var isInterstitialEnabled: Bool {
        adManager.isEnabled && interstitialManager.isReady
    }

    public func body(content: Content) -> some View {
        content
            .onAppear(perform: {
                setupIfNeeded()
            })
            .onChange(of: adManager.isEnabled, {
                setupIfNeeded()
            })
            .background {
                // Add the adViewControllerRepresentable to the background so it
                // doesn't influence the placement of other views in the view hierarchy.
                AdInterstitialViewControllerRepresentable()
                    .frame(width: .zero, height: .zero)
            }
            .alert(Text("Upgrade or watch an ad to continue", bundle: .module), isPresented: $interstitialManager.isUpgradePlanAlertPresented) {
                Button(String(localized: "Discover \(adManager.premiumPlanName) upgrade", bundle: .module)) {
                    appUpgradeHandler()
                }
                Button(String(localized: "Watch ad", bundle: .module)) {
                    interstitialManager.presentAd()
                }
                Button(String(localized: "Cancel", bundle: .module), role: .cancel) {
                    interstitialManager.onDismissAction = nil
                }
            }
            .environment(interstitialManager)
            .environment(\.adsTrigger, { (position, action, completion) in
                guard isInterstitialEnabled else {
                    Task {
                        await action()
                        await completion?()
                    }
                    return
                }

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
                guard isInterstitialEnabled else {
                    return
                }

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

    private func setupIfNeeded() {
        guard !interstitialManager.isSetupCompleted && adManager.isEnabled else {
            return
        }

        interstitialManager.setup(
            provider: adManager.makeFullscreenProvider(delegate: interstitialManager),
            askBeforePresent: adManager.askBeforePresentInterstitial,
            usageCounter: adManager.interstitialUsageCounter
        )
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
            Text(verbatim: "Content")
            Button(String("Show ad before action")) {
                adsTrigger(.beforeAction, {
                    print("Azione")
                }, {
                    print("Completato")
                })
            }
            Button(String("Show ad after action")) {
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
