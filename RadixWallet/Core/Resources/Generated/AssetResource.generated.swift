// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
enum AssetResource {
  static let iconAcceptAirdrop = ImageAsset(name: "icon-accept-airdrop")
  static let iconAcceptKnownAirdrop = ImageAsset(name: "icon-accept-known-airdrop")
  static let iconDeclineAirdrop = ImageAsset(name: "icon-decline-airdrop")
  static let iconMinusCircle = ImageAsset(name: "icon-minus-circle")
  static let iconPlusCircle = ImageAsset(name: "icon-plus-circle")
  static let addAccount = ImageAsset(name: "addAccount")
  static let addMessage = ImageAsset(name: "addMessage")
  static let chooseAccount = ImageAsset(name: "chooseAccount")
  static let transfer = ImageAsset(name: "transfer")
  static let fungibleTokens = ImageAsset(name: "fungible-tokens")
  static let nft = ImageAsset(name: "nft")
  static let poolUnits = ImageAsset(name: "pool-units")
  static let stakes = ImageAsset(name: "stakes")
  static let freezableByAnyone = ImageAsset(name: "freezable-by-anyone")
  static let freezableByThirdParty = ImageAsset(name: "freezable-by-third-party")
  static let informationChangeableByAnyone = ImageAsset(name: "information-changeable-by-anyone")
  static let informationChangeable = ImageAsset(name: "information-changeable")
  static let movementRestrictableInFutureByAnyone = ImageAsset(name: "movement-restrictable-in-future-by-anyone")
  static let movementRestrictableInFuture = ImageAsset(name: "movement-restrictable-in-future")
  static let movementRestricted = ImageAsset(name: "movement-restricted")
  static let nftDataChangeableByAnyone = ImageAsset(name: "nft-data-changeable-by-anyone")
  static let nftDataChangeable = ImageAsset(name: "nft-data-changeable")
  static let removableByAnyone = ImageAsset(name: "removable-by-anyone")
  static let removableByThirdParty = ImageAsset(name: "removable-by-third-party")
  static let simpleAsset = ImageAsset(name: "simple-asset")
  static let supplyDecreasableByAnyone = ImageAsset(name: "supply-decreasable-by-anyone")
  static let supplyDecreasable = ImageAsset(name: "supply-decreasable")
  static let supplyFlexibleByAnyone = ImageAsset(name: "supply-flexible-by-anyone")
  static let supplyFlexible = ImageAsset(name: "supply-flexible")
  static let supplyIncreasableByAnyone = ImageAsset(name: "supply-increasable-by-anyone")
  static let supplyIncreasable = ImageAsset(name: "supply-increasable")
  static let carouselBackgroundConnect = ImageAsset(name: "carousel_background_connect")
  static let carouselBackgroundRadquest = ImageAsset(name: "carousel_background_radquest")
  static let arrowBack = ImageAsset(name: "arrow-back")
  static let check = ImageAsset(name: "check")
  static let checkmarkDarkSelected = ImageAsset(name: "checkmark-dark-selected")
  static let checkmarkDarkUnselected = ImageAsset(name: "checkmark-dark-unselected")
  static let checkmarkLightSelected = ImageAsset(name: "checkmark-light-selected")
  static let checkmarkLightUnselected = ImageAsset(name: "checkmark-light-unselected")
  static let chevronDown = ImageAsset(name: "chevron-down")
  static let chevronRight = ImageAsset(name: "chevron-right")
  static let chevronUp = ImageAsset(name: "chevron-up")
  static let close = ImageAsset(name: "close")
  static let code = ImageAsset(name: "code")
  static let copyBig = ImageAsset(name: "copy-big")
  static let copy = ImageAsset(name: "copy")
  static let create = ImageAsset(name: "create")
  static let ellipsis = ImageAsset(name: "ellipsis")
  static let error = ImageAsset(name: "error")
  static let fullScreen = ImageAsset(name: "full-screen")
  static let iconHardwareLedger = ImageAsset(name: "icon-hardware-ledger")
  static let iconHistory = ImageAsset(name: "icon-history")
  static let iconLinkOut = ImageAsset(name: "icon-link-out")
  static let iconTxnBlocks = ImageAsset(name: "icon-txn-blocks")
  static let iconValidator = ImageAsset(name: "icon-validator")
  static let info = ImageAsset(name: "info")
  static let lockMetadata = ImageAsset(name: "lock-metadata")
  static let lock = ImageAsset(name: "lock")
  static let minusCircle = ImageAsset(name: "minus-circle")
  static let plusCircle = ImageAsset(name: "plus-circle")
  static let radioButtonDarkDisabledUnselected = ImageAsset(name: "radioButton-dark-disabled-unselected")
  static let radioButtonDarkDisabled = ImageAsset(name: "radioButton-dark-disabled")
  static let radioButtonDarkSelected = ImageAsset(name: "radioButton-dark-selected")
  static let radioButtonDarkUnselected = ImageAsset(name: "radioButton-dark-unselected")
  static let radioButtonLightDisabledUnselected = ImageAsset(name: "radioButton-light-disabled-unselected")
  static let radioButtonLightDisabled = ImageAsset(name: "radioButton-light-disabled")
  static let radioButtonLightSelected = ImageAsset(name: "radioButton-light-selected")
  static let radioButtonLightUnselected = ImageAsset(name: "radioButton-light-unselected")
  static let share = ImageAsset(name: "share")
  static let signingKey = ImageAsset(name: "signing-key")
  static let trash = ImageAsset(name: "trash")
  static let walletAppIcon = ImageAsset(name: "wallet-app-icon")
  static let homeAccountSecurity = ImageAsset(name: "home-account-security")
  static let homeAggregatedValueHidden = ImageAsset(name: "home-aggregatedValue-hidden")
  static let homeAggregatedValueShown = ImageAsset(name: "home-aggregatedValue-shown")
  static let homeHeaderSettings = ImageAsset(name: "home-header-settings")
  static let placeholderSecurityStructure = ImageAsset(name: "PLACEHOLDER_SecurityStructure")
  static let brokenImagePlaceholder = ImageAsset(name: "broken-image-placeholder")
  static let persona = ImageAsset(name: "persona")
  static let token = ImageAsset(name: "token")
  static let unknownComponent = ImageAsset(name: "unknown-component")
  static let xrd = ImageAsset(name: "xrd")
  static let advancedLock = ImageAsset(name: "advancedLock")
  static let appSettings = ImageAsset(name: "appSettings")
  static let authorizedDapps = ImageAsset(name: "authorized-dapps")
  static let backups = ImageAsset(name: "backups")
  static let browsers = ImageAsset(name: "browsers")
  static let delete = ImageAsset(name: "delete")
  static let depositGuarantees = ImageAsset(name: "depositGuarantees")
  static let desktopConnections = ImageAsset(name: "desktop-connections")
  static let desktopLinkConnector = ImageAsset(name: "desktop-link-connector")
  static let developerMode = ImageAsset(name: "developerMode")
  static let discord = ImageAsset(name: "discord")
  static let entityHiding = ImageAsset(name: "entityHiding")
  static let gateway = ImageAsset(name: "gateway")
  static let ledger = ImageAsset(name: "ledger")
  static let personas = ImageAsset(name: "personas")
  static let qrCodeScanner = ImageAsset(name: "qr-code-scanner")
  static let recovery = ImageAsset(name: "recovery")
  static let security = ImageAsset(name: "security")
  static let seedPhrases = ImageAsset(name: "seedPhrases")
  static let tempLinkConnector = ImageAsset(name: "temp-link-connector")
  static let troubleshooting = ImageAsset(name: "troubleshooting")
  static let splash = ImageAsset(name: "Splash")
  static let splashItem1 = ImageAsset(name: "splash-item-1")
  static let splashItem2 = ImageAsset(name: "splash-item-2")
  static let splashItem3 = ImageAsset(name: "splash-item-3")
  static let splashItem4 = ImageAsset(name: "splash-item-4")
  static let splashItem5 = ImageAsset(name: "splash-item-5")
  static let splashPhoneFrame = ImageAsset(name: "splash-phone-frame")
  static let officialTagIcon = ImageAsset(name: "official-tag-icon")
  static let tagIcon = ImageAsset(name: "tag-icon")
  static let transactionHistoryDeposit = ImageAsset(name: "transactionHistory_deposit")
  static let transactionHistoryFilterList = ImageAsset(name: "transactionHistory_filter-list")
  static let transactionHistoryFilterDeposit = ImageAsset(name: "transactionHistory_filter_deposit")
  static let transactionHistoryFilterWithdrawal = ImageAsset(name: "transactionHistory_filter_withdrawal")
  static let transactionHistorySettings = ImageAsset(name: "transactionHistory_settings")
  static let transactionHistoryWithdrawal = ImageAsset(name: "transactionHistory_withdrawal")
  static let transactionReviewMessage = ImageAsset(name: "transactionReview-message")
  static let transactionReviewPools = ImageAsset(name: "transactionReview-pools")
  static let transactionReviewDapps = ImageAsset(name: "transactionReview_dapps")
  static let transactionReviewDepositSetting = ImageAsset(name: "transactionReview_depositSetting")
  static let transactionReviewDepositing = ImageAsset(name: "transactionReview_depositing")
  static let transactionReviewWithdrawing = ImageAsset(name: "transactionReview_withdrawing")
  static let checkCircle = ImageAsset(name: "check_circle")
  static let cloud = ImageAsset(name: "cloud")
  static let configurationBackup = ImageAsset(name: "configuration_backup")
  static let errorLarge = ImageAsset(name: "error_large")
  static let successCheckmark = ImageAsset(name: "success-checkmark")
  static let transactionInProgress = ImageAsset(name: "transaction_in_progress")
  static let folder = ImageAsset(name: "folder")
  static let iconLiquidStakeUnits = ImageAsset(name: "iconLiquidStakeUnits")
  static let iconPackageOwnerBadge = ImageAsset(name: "iconPackageOwnerBadge")
  static let radixIconWhite = ImageAsset(name: "radix-icon-white")
  static let securityFactors = ImageAsset(name: "security_factors")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

struct ImageAsset {
  fileprivate(set) var name: String

  #if os(macOS)
  typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
