//
//  AdInterstitialViewController.swift
//
//
//  Created by Fausto Ristagno on 20/01/24.
//

import UIKit
import SwiftUI

class AdInterstitialViewController : UIViewController {
    private let manager: AdInterstitialManager

    init(manager: AdInterstitialManager) {
        self.manager = manager

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable, message: "init(coder:) is not available, use init(manager:)")
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not available")
    }

    private var rootViewController: UIViewController? {
        guard isViewLoaded else { return nil }

        return view.window?.rootViewController
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        trySetupManager()
    }

    private func trySetupManager() {
        guard !manager.isSetupCompleted else { return }
        guard let rootViewController else { return }

        manager.setup(rootViewController: rootViewController)
    }
}

struct AdInterstitialViewControllerRepresentable : UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        guard let manager = context.environment[AdInterstitialManager.self] else {
            fatalError("Ad interstitial manager not available")
        }

        return AdInterstitialViewController(manager: manager)
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // No implementation needed. Nothing to update.
    }
}
