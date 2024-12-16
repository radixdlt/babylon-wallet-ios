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
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum AssetResource {
  internal static let iconAcceptAirdrop = ImageAsset(name: "icon-accept-airdrop")
  internal static let iconAcceptKnownAirdrop = ImageAsset(name: "icon-accept-known-airdrop")
  internal static let iconDeclineAirdrop = ImageAsset(name: "icon-decline-airdrop")
  internal static let iconMinusCircle = ImageAsset(name: "icon-minus-circle")
  internal static let iconPlusCircle = ImageAsset(name: "icon-plus-circle")
  internal static let addAccount = ImageAsset(name: "addAccount")
  internal static let addMessage = ImageAsset(name: "addMessage")
  internal static let chooseAccount = ImageAsset(name: "chooseAccount")
  internal static let transfer = ImageAsset(name: "transfer")
  internal static let fungibleTokens = ImageAsset(name: "fungible-tokens")
  internal static let nft = ImageAsset(name: "nft")
  internal static let poolUnits = ImageAsset(name: "pool-units")
  internal static let stakes = ImageAsset(name: "stakes")
  internal static let freezableByAnyone = ImageAsset(name: "freezable-by-anyone")
  internal static let freezableByThirdParty = ImageAsset(name: "freezable-by-third-party")
  internal static let informationChangeableByAnyone = ImageAsset(name: "information-changeable-by-anyone")
  internal static let informationChangeable = ImageAsset(name: "information-changeable")
  internal static let movementRestrictableInFutureByAnyone = ImageAsset(name: "movement-restrictable-in-future-by-anyone")
  internal static let movementRestrictableInFuture = ImageAsset(name: "movement-restrictable-in-future")
  internal static let movementRestricted = ImageAsset(name: "movement-restricted")
  internal static let nftDataChangeableByAnyone = ImageAsset(name: "nft-data-changeable-by-anyone")
  internal static let nftDataChangeable = ImageAsset(name: "nft-data-changeable")
  internal static let removableByAnyone = ImageAsset(name: "removable-by-anyone")
  internal static let removableByThirdParty = ImageAsset(name: "removable-by-third-party")
  internal static let simpleAsset = ImageAsset(name: "simple-asset")
  internal static let supplyDecreasableByAnyone = ImageAsset(name: "supply-decreasable-by-anyone")
  internal static let supplyDecreasable = ImageAsset(name: "supply-decreasable")
  internal static let supplyFlexibleByAnyone = ImageAsset(name: "supply-flexible-by-anyone")
  internal static let supplyFlexible = ImageAsset(name: "supply-flexible")
  internal static let supplyIncreasableByAnyone = ImageAsset(name: "supply-increasable-by-anyone")
  internal static let supplyIncreasable = ImageAsset(name: "supply-increasable")
  internal static let carouselBackgroundConnect = ImageAsset(name: "carousel_background_connect")
  internal static let carouselBackgroundEcosystem = ImageAsset(name: "carousel_background_ecosystem")
  internal static let carouselBackgroundRadquest = ImageAsset(name: "carousel_background_radquest")
  internal static let arrowBack = ImageAsset(name: "arrow-back")
  internal static let check = ImageAsset(name: "check")
  internal static let checkCircleOutline = ImageAsset(name: "checkCircleOutline")
  internal static let checkmarkDarkSelected = ImageAsset(name: "checkmark-dark-selected")
  internal static let checkmarkDarkUnselected = ImageAsset(name: "checkmark-dark-unselected")
  internal static let checkmarkLightSelected = ImageAsset(name: "checkmark-light-selected")
  internal static let checkmarkLightUnselected = ImageAsset(name: "checkmark-light-unselected")
  internal static let chevronDown = ImageAsset(name: "chevron-down")
  internal static let chevronRight = ImageAsset(name: "chevron-right")
  internal static let chevronUp = ImageAsset(name: "chevron-up")
  internal static let close = ImageAsset(name: "close")
  internal static let code = ImageAsset(name: "code")
  internal static let copyBig = ImageAsset(name: "copy-big")
  internal static let copy = ImageAsset(name: "copy")
  internal static let create = ImageAsset(name: "create")
  internal static let deleteAccount = ImageAsset(name: "delete_account")
  internal static let ellipsis = ImageAsset(name: "ellipsis")
  internal static let error = ImageAsset(name: "error")
  internal static let fullScreen = ImageAsset(name: "full-screen")
  internal static let iconHardwareLedger = ImageAsset(name: "icon-hardware-ledger")
  internal static let iconHistory = ImageAsset(name: "icon-history")
  internal static let iconLinkOut = ImageAsset(name: "icon-link-out")
  internal static let iconTxnBlocks = ImageAsset(name: "icon-txn-blocks")
  internal static let iconValidator = ImageAsset(name: "icon-validator")
  internal static let info = ImageAsset(name: "info")
  internal static let lockMetadata = ImageAsset(name: "lock-metadata")
  internal static let lock = ImageAsset(name: "lock")
  internal static let minusCircle = ImageAsset(name: "minus-circle")
  internal static let plusCircle = ImageAsset(name: "plus-circle")
  internal static let radioButtonDarkDisabledUnselected = ImageAsset(name: "radioButton-dark-disabled-unselected")
  internal static let radioButtonDarkDisabled = ImageAsset(name: "radioButton-dark-disabled")
  internal static let radioButtonDarkSelected = ImageAsset(name: "radioButton-dark-selected")
  internal static let radioButtonDarkUnselected = ImageAsset(name: "radioButton-dark-unselected")
  internal static let radioButtonLightDisabledUnselected = ImageAsset(name: "radioButton-light-disabled-unselected")
  internal static let radioButtonLightDisabled = ImageAsset(name: "radioButton-light-disabled")
  internal static let radioButtonLightSelected = ImageAsset(name: "radioButton-light-selected")
  internal static let radioButtonLightUnselected = ImageAsset(name: "radioButton-light-unselected")
  internal static let share = ImageAsset(name: "share")
  internal static let signingKey = ImageAsset(name: "signing-key")
  internal static let trash = ImageAsset(name: "trash")
  internal static let walletAppIcon = ImageAsset(name: "wallet-app-icon")
  internal static let arculusFactor = ImageAsset(name: "arculusFactor")
  internal static let deviceFactor = ImageAsset(name: "deviceFactor")
  internal static let ledgerFactor = ImageAsset(name: "ledgerFactor")
  internal static let passphraseFactor = ImageAsset(name: "passphraseFactor")
  internal static let passwordFactor = ImageAsset(name: "passwordFactor")
  internal static let homeAccountSecurity = ImageAsset(name: "home-account-security")
  internal static let homeAggregatedValueHidden = ImageAsset(name: "home-aggregatedValue-hidden")
  internal static let homeAggregatedValueShown = ImageAsset(name: "home-aggregatedValue-shown")
  internal static let homeHeaderSettings = ImageAsset(name: "home-header-settings")
  internal static let placeholderSecurityStructure = ImageAsset(name: "PLACEHOLDER_SecurityStructure")
  internal static let brokenImagePlaceholder = ImageAsset(name: "broken-image-placeholder")
  internal static let persona = ImageAsset(name: "persona")
  internal static let token = ImageAsset(name: "token")
  internal static let unknownComponent = ImageAsset(name: "unknown-component")
  internal static let unknownDeposits = ImageAsset(name: "unknown_deposits")
  internal static let xrd = ImageAsset(name: "xrd")
  internal static let configurationBackup = ImageAsset(name: "configuration_backup")
  internal static let securityFactors = ImageAsset(name: "security_factors")
  internal static let securityShields = ImageAsset(name: "security_shields")
  internal static let advancedLock = ImageAsset(name: "advancedLock")
  internal static let appSettings = ImageAsset(name: "appSettings")
  internal static let authorizedDapps = ImageAsset(name: "authorized-dapps")
  internal static let backups = ImageAsset(name: "backups")
  internal static let browsers = ImageAsset(name: "browsers")
  internal static let delete = ImageAsset(name: "delete")
  internal static let depositGuarantees = ImageAsset(name: "depositGuarantees")
  internal static let desktopConnections = ImageAsset(name: "desktop-connections")
  internal static let desktopLinkConnector = ImageAsset(name: "desktop-link-connector")
  internal static let developerMode = ImageAsset(name: "developerMode")
  internal static let discord = ImageAsset(name: "discord")
  internal static let entityHiding = ImageAsset(name: "entityHiding")
  internal static let gateway = ImageAsset(name: "gateway")
  internal static let ledger = ImageAsset(name: "ledger")
  internal static let personas = ImageAsset(name: "personas")
  internal static let qrCodeScanner = ImageAsset(name: "qr-code-scanner")
  internal static let recovery = ImageAsset(name: "recovery")
  internal static let security = ImageAsset(name: "security")
  internal static let seedPhrases = ImageAsset(name: "seedPhrases")
  internal static let tempLinkConnector = ImageAsset(name: "temp-link-connector")
  internal static let troubleshooting = ImageAsset(name: "troubleshooting")
  internal static let shieldSetupOnboardingApply = ImageAsset(name: "shieldSetupOnboardingApply")
  internal static let shieldSetupOnboardingBuild = ImageAsset(name: "shieldSetupOnboardingBuild")
  internal static let shieldSetupOnboardingIntro = ImageAsset(name: "shieldSetupOnboardingIntro")
  internal static let prepareFactorSourcesAdd = ImageAsset(name: "prepareFactorSourcesAdd")
  internal static let prepareFactorSourcesCompletion = ImageAsset(name: "prepareFactorSourcesCompletion")
  internal static let prepareFactorSourcesIntro = ImageAsset(name: "prepareFactorSourcesIntro")
  internal static let splash = ImageAsset(name: "Splash")
  internal static let splashItem1 = ImageAsset(name: "splash-item-1")
  internal static let splashItem2 = ImageAsset(name: "splash-item-2")
  internal static let splashItem3 = ImageAsset(name: "splash-item-3")
  internal static let splashItem4 = ImageAsset(name: "splash-item-4")
  internal static let splashItem5 = ImageAsset(name: "splash-item-5")
  internal static let splashPhoneFrame = ImageAsset(name: "splash-phone-frame")
  internal static let officialTagIcon = ImageAsset(name: "official-tag-icon")
  internal static let tagIcon = ImageAsset(name: "tag-icon")
  internal static let transactionHistoryDeposit = ImageAsset(name: "transactionHistory_deposit")
  internal static let transactionHistoryFilterList = ImageAsset(name: "transactionHistory_filter-list")
  internal static let transactionHistoryFilterDeposit = ImageAsset(name: "transactionHistory_filter_deposit")
  internal static let transactionHistoryFilterWithdrawal = ImageAsset(name: "transactionHistory_filter_withdrawal")
  internal static let transactionHistorySettings = ImageAsset(name: "transactionHistory_settings")
  internal static let transactionHistoryWithdrawal = ImageAsset(name: "transactionHistory_withdrawal")
  internal static let transactionReviewMessage = ImageAsset(name: "transactionReview-message")
  internal static let transactionReviewPools = ImageAsset(name: "transactionReview-pools")
  internal static let transactionReviewDapps = ImageAsset(name: "transactionReview_dapps")
  internal static let transactionReviewDeletingAccount = ImageAsset(name: "transactionReview_deletingAccount")
  internal static let transactionReviewDepositSetting = ImageAsset(name: "transactionReview_depositSetting")
  internal static let transactionReviewDepositing = ImageAsset(name: "transactionReview_depositing")
  internal static let transactionReviewWithdrawing = ImageAsset(name: "transactionReview_withdrawing")
  internal static let checkCircle = ImageAsset(name: "check_circle")
  internal static let cloud = ImageAsset(name: "cloud")
  internal static let errorLarge = ImageAsset(name: "error_large")
  internal static let successCheckmark = ImageAsset(name: "success-checkmark")
  internal static let transactionInProgress = ImageAsset(name: "transaction_in_progress")
  internal static let folder = ImageAsset(name: "folder")
  internal static let iconLiquidStakeUnits = ImageAsset(name: "iconLiquidStakeUnits")
  internal static let iconPackageOwnerBadge = ImageAsset(name: "iconPackageOwnerBadge")
  internal static let radixIconWhite = ImageAsset(name: "radix-icon-white")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  internal var image: Image {
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
  internal func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  internal var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

internal extension ImageAsset.Image {
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
internal extension SwiftUI.Image {
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
