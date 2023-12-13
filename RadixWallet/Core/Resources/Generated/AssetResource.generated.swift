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
public typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum AssetResource {
  public static let addAccount = ImageAsset(name: "addAccount")
  public static let addMessage = ImageAsset(name: "addMessage")
  public static let transfer = ImageAsset(name: "transfer")
  public static let fungibleTokens = ImageAsset(name: "fungible-tokens")
  public static let nonfungbileTokens = ImageAsset(name: "nonfungbile-tokens")
  public static let poolUnits = ImageAsset(name: "pool-units")
  public static let freezableByAnyone = ImageAsset(name: "freezable-by-anyone")
  public static let freezableByThirdParty = ImageAsset(name: "freezable-by-third-party")
  public static let informationChangeableByAnyone = ImageAsset(name: "information-changeable-by-anyone")
  public static let informationChangeable = ImageAsset(name: "information-changeable")
  public static let movementRestrictableInFutureByAnyone = ImageAsset(name: "movement-restrictable-in-future-by-anyone")
  public static let movementRestrictableInFuture = ImageAsset(name: "movement-restrictable-in-future")
  public static let movementRestricted = ImageAsset(name: "movement-restricted")
  public static let nftDataChangeableByAnyone = ImageAsset(name: "nft-data-changeable-by-anyone")
  public static let nftDataChangeable = ImageAsset(name: "nft-data-changeable")
  public static let removableByAnyone = ImageAsset(name: "removable-by-anyone")
  public static let removableByThirdParty = ImageAsset(name: "removable-by-third-party")
  public static let simpleAsset = ImageAsset(name: "simple-asset")
  public static let supplyDecreasableByAnyone = ImageAsset(name: "supply-decreasable-by-anyone")
  public static let supplyDecreasable = ImageAsset(name: "supply-decreasable")
  public static let supplyFlexibleByAnyone = ImageAsset(name: "supply-flexible-by-anyone")
  public static let supplyFlexible = ImageAsset(name: "supply-flexible")
  public static let supplyIncreasableByAnyone = ImageAsset(name: "supply-increasable-by-anyone")
  public static let supplyIncreasable = ImageAsset(name: "supply-increasable")
  public static let arrowBack = ImageAsset(name: "arrow-back")
  public static let check = ImageAsset(name: "check")
  public static let checkmarkBig = ImageAsset(name: "checkmark-big")
  public static let checkmarkDarkSelected = ImageAsset(name: "checkmark-dark-selected")
  public static let checkmarkDarkUnselected = ImageAsset(name: "checkmark-dark-unselected")
  public static let checkmarkLightSelected = ImageAsset(name: "checkmark-light-selected")
  public static let checkmarkLightUnselected = ImageAsset(name: "checkmark-light-unselected")
  public static let chevronDown = ImageAsset(name: "chevron-down")
  public static let chevronRight = ImageAsset(name: "chevron-right")
  public static let chevronUp = ImageAsset(name: "chevron-up")
  public static let close = ImageAsset(name: "close")
  public static let code = ImageAsset(name: "code")
  public static let copyBig = ImageAsset(name: "copy-big")
  public static let copy = ImageAsset(name: "copy")
  public static let create = ImageAsset(name: "create")
  public static let ellipsis = ImageAsset(name: "ellipsis")
  public static let error = ImageAsset(name: "error")
  public static let iconAcceptAirdrop = ImageAsset(name: "icon-accept-airdrop")
  public static let iconAcceptKnownAirdrop = ImageAsset(name: "icon-accept-known-airdrop")
  public static let iconDeclineAirdrop = ImageAsset(name: "icon-decline-airdrop")
  public static let iconHardwareLedger = ImageAsset(name: "icon-hardware-ledger")
  public static let iconHistory = ImageAsset(name: "icon-history")
  public static let iconLinkOut = ImageAsset(name: "icon-link-out")
  public static let info = ImageAsset(name: "info")
  public static let lock = ImageAsset(name: "lock")
  public static let minusCircle = ImageAsset(name: "minus-circle")
  public static let plusCircle = ImageAsset(name: "plus-circle")
  public static let radioButtonDarkDisabled = ImageAsset(name: "radioButton-dark-disabled")
  public static let radioButtonDarkSelected = ImageAsset(name: "radioButton-dark-selected")
  public static let radioButtonDarkUnselected = ImageAsset(name: "radioButton-dark-unselected")
  public static let radioButtonLightDisabled = ImageAsset(name: "radioButton-light-disabled")
  public static let radioButtonLightSelected = ImageAsset(name: "radioButton-light-selected")
  public static let radioButtonLightUnselected = ImageAsset(name: "radioButton-light-unselected")
  public static let signingKey = ImageAsset(name: "signing-key")
  public static let trash = ImageAsset(name: "trash")
  public static let homeAccountSecurity = ImageAsset(name: "home-account-security")
  public static let homeAggregatedValueHidden = ImageAsset(name: "home-aggregatedValue-hidden")
  public static let homeAggregatedValueShown = ImageAsset(name: "home-aggregatedValue-shown")
  public static let homeHeaderSettings = ImageAsset(name: "home-header-settings")
  public static let radixBanner = ImageAsset(name: "radix-banner")
  public static let iconMarketCap = ImageAsset(name: "Icon-Market-Cap")
  public static let placeholderSecurityStructure = ImageAsset(name: "PLACEHOLDER_SecurityStructure")
  public static let brokenImagePlaceholder = ImageAsset(name: "broken-image-placeholder")
  public static let nft = ImageAsset(name: "nft")
  public static let persona = ImageAsset(name: "persona")
  public static let poolUnit = ImageAsset(name: "poolUnit")
  public static let token = ImageAsset(name: "token")
  public static let unknownComponent = ImageAsset(name: "unknown-component")
  public static let xrd = ImageAsset(name: "xrd")
  public static let accountSecurity = ImageAsset(name: "accountSecurity")
  public static let appSettings = ImageAsset(name: "appSettings")
  public static let authorizedDapps = ImageAsset(name: "authorized-dapps")
  public static let backups = ImageAsset(name: "backups")
  public static let browsers = ImageAsset(name: "browsers")
  public static let connectorBrowsersIcon = ImageAsset(name: "connector-browsers-icon")
  public static let delete = ImageAsset(name: "delete")
  public static let depositGuarantees = ImageAsset(name: "depositGuarantees")
  public static let desktopConnections = ImageAsset(name: "desktop-connections")
  public static let developerMode = ImageAsset(name: "developerMode")
  public static let entityHiding = ImageAsset(name: "entityHiding")
  public static let gateway = ImageAsset(name: "gateway")
  public static let ledger = ImageAsset(name: "ledger")
  public static let personas = ImageAsset(name: "personas")
  public static let qrCodeScanner = ImageAsset(name: "qr-code-scanner")
  public static let tempLinkConnector = ImageAsset(name: "temp-link-connector")
  public static let splash = ImageAsset(name: "Splash")
  public static let splashItem1 = ImageAsset(name: "splash-item-1")
  public static let splashItem2 = ImageAsset(name: "splash-item-2")
  public static let splashItem3 = ImageAsset(name: "splash-item-3")
  public static let splashItem4 = ImageAsset(name: "splash-item-4")
  public static let splashItem5 = ImageAsset(name: "splash-item-5")
  public static let splashPhoneFrame = ImageAsset(name: "splash-phone-frame")
  public static let officialTagIcon = ImageAsset(name: "official-tag-icon")
  public static let tagIcon = ImageAsset(name: "tag-icon")
  public static let successCheckmark = ImageAsset(name: "success-checkmark")
  public static let transactionInProgress = ImageAsset(name: "transaction_in_progress")
  public static let warningError = ImageAsset(name: "warning_error")
  public static let radixIconWhite = ImageAsset(name: "radix-icon-white")
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public struct ImageAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  public var image: Image {
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
  public func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

public extension ImageAsset.Image {
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
public extension SwiftUI.Image {
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
