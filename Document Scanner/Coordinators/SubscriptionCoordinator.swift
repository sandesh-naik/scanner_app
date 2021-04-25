//
//  SubscriptionCoordinator.swift
//  Document Scanner
//
//  Created by Sandesh on 08/04/21.
//

import UIKit
import NVActivityIndicatorView

class SubscribeCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var parentCoordinator: Coordinator?
    var subscriptionVC: SubscriptionViewControllerProtocol
    var specialOfferVC: SpecialOfferViewControllerProtocol?
    var navigationController: UINavigationController
    var timer: Timer?
    
    var currentEvent: SubscriptionHelper.EventForSubscription = .call
    
    var availableProducts: [IAPProduct]?
    private var _productsFetched = false
    private var window: UIWindow?
    private var _offeringIdentifier: String?
    private var _presented: Bool
    private let _showSpecialOffer: Bool
    
    private var _lastTimeUserShownSubscriptionScreen: Date?
    private var lastTimeUserShownSubscriptionScreen: Date? {
        get {
            return _lastTimeUserShownSubscriptionScreen
        }
        
        set {
            _lastTimeUserShownSubscriptionScreen = newValue
            //UserDefaults.standard.save(newValue, forKey: Constants.CallRecorderDefaults.timeWhenFirstSubscriptionScreenShownKey)
        }
    }
    
    init(navigationController: UINavigationController, offeringIdentifier: String? = nil, presented: Bool = true, giftOffer: Bool = false, hideCloseButton: Bool = false, showSpecialOffer: Bool = false) {
        _offeringIdentifier = offeringIdentifier
        _presented = presented
        _showSpecialOffer = showSpecialOffer
        
        // after onboarding we need to show discounted rate and it will always be presented
        subscriptionVC = AnnualNoTrialViewController()
        //_lastTimeUserShownSubscriptionScreen = UserDefaults.standard.fetch(forKey: Constants.CallRecorderDefaults.timeWhenFirstSubscriptionScreenShownKey)
        
        subscriptionVC.giftOffer = giftOffer
        subscriptionVC.hideCloseButton = hideCloseButton
        self.navigationController = navigationController
    }
    
    func start() {
        self._fetchAvailableProducts()
        subscriptionVC.delegate = self
        subscriptionVC.uiProviderDelegate = self
        subscriptionVC.specialOfferUIProviderDelegate = self
        navigationController.pushViewController(subscriptionVC, animated: true)
    }
    
    private func _fetchAvailableProducts() {
        SubscriptionHelper.shared.fetchAvailableProducts(for: _offeringIdentifier) { (allProducts, error) in
            print("**********Fetched allProducts")
            self._productsFetched = true
            if error == nil {
                self.availableProducts = allProducts
                NotificationCenter.default.post(name: .iapProductsFetchedNotification,
                                                object: nil)
            } else {
                //TODO: - Present product not available alert
            }
        }
    }
    
    private func _dismiss() {
        navigationController.dismiss(animated: true)
    }
    
    var rootViewController: UIViewController {
        return subscriptionVC
    }
    
    private func showTermsOfLaw() {
        let callRecordLawsVC = WebViewVC()
        callRecordLawsVC.configureUI(title: "Terms of law".localized)
        callRecordLawsVC.webPageLink = Constants.WebLinks.termsOfLaw
        navigationController.pushViewController(callRecordLawsVC, animated: true)
        navigationController.setNavigationBarHidden(false, animated: true)
    }
    
    private func showPrivacyPolicy() {
        let callRecordLawsVC = WebViewVC()
        callRecordLawsVC.configureUI(title: "Privacy policy".localized)
        callRecordLawsVC.webPageLink = Constants.WebLinks.privacyPolicy
        navigationController.pushViewController(callRecordLawsVC, animated: true)
        navigationController.setNavigationBarHidden(false, animated: true)
    }
    
    private func _updateSpecialOfferTimeLabel(_ timeRemainingForOffer: Double) {
        let hour = Int(timeRemainingForOffer) / 3600
        let minutes = Int(timeRemainingForOffer) / 60 % 60
        let seconds = Int(timeRemainingForOffer) % 60
        self.specialOfferVC?.updateTimer(String(format: "%02d", hour) + ":" + String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds))
    }
    
  
    
    private func _purchaseProduct(_ product: IAPProduct) {
        SubscriptionHelper.shared.purchasePackage(product) { [weak self] (success, error) in
            guard error == nil else {
                switch error! {
                case .purchasedFailed:
                    self?._presentPurchaseFailedAlert(product: product)
                case .userCancelledPurchase:
                    //Do nothing
                    break
                case .noProductsAvailable:
                    break
                }
                return
            }
            
            if success {
                if let self = self {
                    self._dismiss()
                }
            } else {
                self?._presentPurchaseFailedAlert(product: product)
            }
        }
    }
    
    private func _restorePurchases() {
        SubscriptionHelper.shared.restorePurchases {[weak self] (success, error) in
            guard error == nil else {
                self?._presentRestorationFailedAlert()
                return
            }
            if success {
                self?._dismiss()
            }
        }
    }
    
    private func _presentPurchaseFailedAlert(product: IAPProduct) {
        //TODO: - Present purchase failed alert
    }
    
    private func _presentRestorationFailedAlert() {
        //TODO: - Present restoration failed alert
    }
    
    static func attributedFeatureText(_ feature: String) -> String {
        return "✓  " + feature
    }
    
}

// MARK: - UpgradeUIProviderDelegate
extension SubscribeCoordinator: UpgradeUIProviderDelegate {
    
    
    func productsFetched() -> Bool {
        return _productsFetched
    }
    
    func headerMessage(for index: Int) -> String {
        return "Try Document Scanner free for 7 days".localized
    }
    
    func subscriptionTitle(for index: Int) -> String {
        guard let availableProducts = availableProducts,
              availableProducts.count > index else {
            return ""
        }
        
        return availableProducts[index].displayName
    }
    
    func introductoryPrice(for index: Int, withDurationSuffix: Bool) -> String {
        guard let availableProducts = availableProducts,
              availableProducts.count > index else {
            return ""
        }
        
        if withDurationSuffix {
            return availableProducts[index].introductoryPriceWithDurationSuffix
        } else {
            return availableProducts[index].introductoryPrice
        }
    }
    
    func subscriptionPrice(for index: Int, withDurationSuffix: Bool) -> String {
        guard let availableProducts = availableProducts,
              availableProducts.count > index else {
            return ""
        }
        
        if withDurationSuffix {
            return availableProducts[index].priceWithDurationSuffix
        } else {
            return availableProducts[index].price
        }
    }
    
    func continueButtonTitle(for index: Int) -> String {
        guard let availableProducts = availableProducts,
              availableProducts.count > index else {
            return ""
        }
        
        return "Try Free and Continue".localized
    }
    
    func offersFreeTrial(for index: Int) -> Bool {
        guard let availableProducts = availableProducts,
              availableProducts.count > index else {
            return false
        }
        
        return availableProducts[index].offersFreeTrial
    }
}

// MARK: - UpgradeViewControllerDelegate
extension SubscribeCoordinator: SubscriptionViewControllerDelegate {
    func viewWillAppear(_ controller: SubscriptionViewControllerProtocol) {
        controller.navigationController?.setNavigationBarHidden(true, animated: true)
        if !_productsFetched {
          //TODO: - Add activity Indicator
        }
    }
    
    func viewDidAppear(_ controller: SubscriptionViewControllerProtocol) {
        if !_productsFetched {
            //TODO: - Add activity Indicator
        }
    }
    
    func exit(_ controller: SubscriptionViewControllerProtocol) {
        
        func showSpecialOffer() {
            specialOfferVC = SpecialOfferViewController()
            specialOfferVC!.delegate = self
            specialOfferVC?.uiProviderDelegate = self
            navigationController.pushViewController(specialOfferVC!, animated: true)
        }
        
        // - Do Not delete below commented code
            if lastTimeUserShownSubscriptionScreen == nil {
                lastTimeUserShownSubscriptionScreen = Date()
                showSpecialOffer()
            } else {
                let lastTime = lastTimeUserShownSubscriptionScreen!
                if  (300 - Date().timeIntervalSince(lastTime)) > 0 {
                    showSpecialOffer()
                } else {
                    self._dismiss()
                }
            }
    }
    
    func selectPlan(at index: Int, controller: SubscriptionViewControllerProtocol) {
        guard let availableProducts = availableProducts, availableProducts.count > index else {
            return
        }
        _purchaseProduct(availableProducts[index])
    }
    
    func restorePurchases(_ controller: SubscriptionViewControllerProtocol) {
        _restorePurchases()
    }
    
    func showPrivacyPolicy(_ controller: SubscriptionViewControllerProtocol) {
        showPrivacyPolicy()
    }
    
    func showTermsOfLaw(_ controller: SubscriptionViewControllerProtocol) {
        showTermsOfLaw()
    }
}

// MARK: - SpecialOfferViewControllerDelegate
extension SubscribeCoordinator: SpecialOfferViewControllerDelegate {
    
    func viewDidLoad(_ controller: SpecialOfferViewController) {
        guard let lastTime = lastTimeUserShownSubscriptionScreen  else {
            navigationController.dismiss(animated: true)
            return
        }
        
        var timeRemainingForOffer = 300 - Date().timeIntervalSince(lastTime)
        _updateSpecialOfferTimeLabel(timeRemainingForOffer)
        
        if timeRemainingForOffer > 0 {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                timeRemainingForOffer -= 1
                if timeRemainingForOffer > 0 {
                    self._updateSpecialOfferTimeLabel(timeRemainingForOffer)
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                    self.navigationController.dismiss(animated: true)
                }
            })
        } else {
            navigationController.dismiss(animated: true)
        }
    }
    
    func viewWillAppear(_ controller: SpecialOfferViewController) {
        navigationController.setNavigationBarHidden(true, animated: true)
    }
    
    func didTapCancelButton(_ controller: SpecialOfferViewController) {
        _dismiss()
    }
    
    func purchaseOffer(_ controller: SpecialOfferViewController) {
        // assuming this is the last which you shouldn't
        // refactor later
        guard let annualReducedProduct = availableProducts?.last else {
            return
        }
        _purchaseProduct(annualReducedProduct)
    }
    
    func restorePurchases(_ controller: SpecialOfferViewController) {
        _restorePurchases()
    }
    
    func didTapBackButton(_ controller: SpecialOfferViewController) {
        timer?.invalidate()
        navigationController.popViewController(animated: true)
    }
    
    func showPrivacyPolicy(_ controller: SpecialOfferViewController) {
        showPrivacyPolicy()
    }
    
    func showTermsOfLaw(_ controller: SpecialOfferViewController) {
        showTermsOfLaw()
    }
}

extension SubscribeCoordinator: SpecialOfferUIProviderDelegate {
    // Sagar assuming first product is always the one with special offer; refactor later
    func originalPrice() -> String {
        guard let annualReducedProduct = availableProducts?.first else {
            return ""
        }
        
        return annualReducedProduct.price
    }
    
    func discountedPrice() -> String {
        guard let annualReducedProduct = availableProducts?.first else {
            return ""
        }
        
        return annualReducedProduct.introductoryPrice
    }
    
    func percentDiscount() -> String {
        guard let annualReducedProduct = availableProducts?.first,
              let introductoryPrice = annualReducedProduct.product.introductoryPrice?.price else {
            return ""
        }
        
        let originalPrice = annualReducedProduct.product.price
        let discount = originalPrice.subtracting(introductoryPrice).dividing(by: originalPrice).multiplying(by: 100)
        return "\(lround(discount.doubleValue))"
    }
    
    func monthlyComputedDiscountPrice(withIntroDiscount: Bool, withDurationSuffix: Bool) -> String {
        guard let availableProduct = availableProducts?.first else {
            return ""
        }
        
        if withIntroDiscount {
            if let introductoryPrice = availableProduct.product.introductoryPrice?.price {
                if let price = introductoryPrice.dividing(by: 12).toCurrency(locale: availableProduct.product.introductoryPrice?.priceLocale) {
                    return withDurationSuffix ? price + "/" + "month".localized : price
                }
            }
        } else {
            let regularPrice = availableProduct.product.price
            if let price = regularPrice.dividing(by: 12).toCurrency(locale: availableProduct.product.priceLocale) {
                return withDurationSuffix ? price + "/" + "month".localized : price
            }
        }
        
        return ""
    }
}