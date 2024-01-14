//
//  AdBannerViewController.swift
//  DataAssistant
//
//  Created by Fausto Ristagno on 13/01/24.
//

import Foundation
import GoogleMobileAds

public protocol AdBannerViewControllerDelegate: AnyObject {
    func adBannerViewControllerSizeDidChange(size: CGSize)
    func adBannerViewControllerStateDidChange(loaded: Bool)
}

public class AdBannerViewController: UIViewController {
    public let uuid = UUID()
    private let bannerViewManager: AdBannerViewManager
    public weak var delegate: AdBannerViewControllerDelegate? = nil

    public init(bannerViewManager: AdBannerViewManager) {
        self.bannerViewManager = bannerViewManager
        print(#function)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print(#function)
        bannerViewManager.remove(bannerViewController: self)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        print(#function)
        bannerViewManager.add(bannerViewController: self)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(#function)
        appendBannerView(force: true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(#function)
        if !bannerViewManager.isBannerLoaded {
            bannerViewManager.loadBannerAd(in: self.view)
        }

        delegate?.adBannerViewControllerStateDidChange(loaded: bannerViewManager.isBannerLoaded)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to:size, with:coordinator)
        print(#function)
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

        delegate?.adBannerViewControllerSizeDidChange(size: size)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        print(#function)

        let bannerView = self.bannerViewManager.admobBannerView
        let bannerLoaded = self.bannerViewManager.isBannerLoaded && (bannerView != nil)
        var bannerFrame = bannerView != nil ? bannerView!.bounds : CGRect.zero
        /*let contentFrame = self.view.bounds

        if (bannerLoaded) {
            // contentFrame.size.height -= bannerFrame.size.height
            bannerFrame.origin.y = contentFrame.size.height - bannerFrame.size.height
            if let tabBarController = self.rootViewController as? UITabBarController {
                if tabBarController.tabBar.isTranslucent || self.contentViewController.extendedLayoutIncludesOpaqueBars {
                    bannerFrame.origin.y -= tabBarController.tabBar.bounds.size.height
                }
            }
        } else {
            bannerFrame.origin.y = contentFrame.size.height
        }

        if let tableViewController = self.contentViewController as? UITableViewController {
            let contentInset: UIEdgeInsets
            if (bannerLoaded) {
                contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bannerFrame.size.height, right: 0)
            } else {
                contentInset = UIEdgeInsets.zero
            }
            tableViewController.tableView.contentInset = contentInset
            tableViewController.tableView.scrollIndicatorInsets = contentInset
        } else if let viewController = self.contentViewController {
            var newFrame = self.view.bounds
            // newFrame.origin = viewController.view.frame.origin

            if bannerLoaded {
                newFrame.size.height -= bannerFrame.height
                if let tabBarController = self.rootViewController as? UITabBarController {
                    if tabBarController.tabBar.isTranslucent || viewController.extendedLayoutIncludesOpaqueBars {
                        newFrame.size.height -= tabBarController.tabBar.bounds.size.height
                    }
                }
            }

            viewController.view.frame = newFrame
        }

        let bgColor = self.contentViewController.view.backgroundColor

        self.view.backgroundColor = bgColor
 */
        if (self.isViewLoaded && (self.view.window != nil)) {
            // print("bannerFrame \(bannerFrame) \(bannerView != nil) \(bannerView?.bounds) \(self.view.superview?.bounds)")
            // self.view.frame = bannerFrame

            if bannerView != nil {
                //self.view.addSubview(bannerView!)
                //bannerView!.frame = bannerFrame
                //bannerView!.backgroundColor = bgColor
            }

            // self.view.layoutSubviews() // required by auto layout
        }

    }

    internal func appendBannerView(force: Bool = false) {
        guard
            let banner = bannerViewManager.bannerView,
            (force || (isViewLoaded && view.window != nil))
        else {
            return
        }

        print(#function)

        view.addSubview(banner)
    }

    internal func updateLayout() {
        appendBannerView()
        print(#function)
        UIView.animate(withDuration: 0.25) {
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }

        delegate?.adBannerViewControllerStateDidChange(loaded: bannerViewManager.isBannerLoaded)
    }
}
