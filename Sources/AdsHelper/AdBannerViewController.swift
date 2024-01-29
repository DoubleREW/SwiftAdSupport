//
//  AdBannerViewController.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 13/01/24.
//

import Foundation
import GoogleMobileAds

protocol AdBannerViewControllerDelegate: AnyObject {
    func adBannerViewControllerSizeDidChange(size: CGSize)
    func adBannerViewControllerStateDidChange(loaded: Bool)
}

class AdBannerViewController: UIViewController {
    let uuid = UUID()
    private let bannerViewManager: AdBannerViewManager
    weak var delegate: AdBannerViewControllerDelegate? = nil

    init(bannerViewManager: AdBannerViewManager) {
        self.bannerViewManager = bannerViewManager

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        bannerViewManager.remove(bannerViewController: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bannerViewManager.add(bannerViewController: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        becomeBannerOwner()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        becomeBannerOwner()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        bannerViewManager.bannerViewController(didDisappear: self)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size, with:coordinator)

        guard
            let banner = self.bannerViewManager.bannerView,
            banner.superview == self.view
        else {
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self else { return }

            self.bannerViewManager.loadBannerAd(in: self.view)
        })

        delegate?.adBannerViewControllerSizeDidChange(size: banner.bounds.size)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let bannerView = bannerViewManager.bannerView else {
            return
        }
        
        let bannerHeight = bannerView.bounds.height
        let viewFrame = view.frame

        view.frame = CGRect(origin: viewFrame.origin, size: CGSize(width: viewFrame.size.width, height: bannerHeight))
    }

    func becomeBannerOwner() {
        if !bannerViewManager.isSetupCompleted {
            guard isViewLoaded else { return }
            guard let window = view.window else { return }

            bannerViewManager.setup(window: window)
        }

        if !bannerViewManager.isBannerLoaded {
            bannerViewManager.loadBannerAd(in: view)
        } else if let bannerView = bannerViewManager.bannerView, bannerView.superview != view {
            view.addSubview(bannerView)
        }

        delegate?.adBannerViewControllerStateDidChange(loaded: bannerViewManager.isBannerLoaded)

        if let bannerView = bannerViewManager.bannerView {
            delegate?.adBannerViewControllerSizeDidChange(size: bannerView.bounds.size)
        }
    }

    func updateLayout() {
        becomeBannerOwner()

        UIView.animate(withDuration: 0.25) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
}
