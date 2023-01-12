// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Prelude

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum AccountDetails {
    /// Transfer
    public static let transferButtonTitle = L10n.tr("Localizable", "accountDetails.transferButtonTitle", fallback: "Transfer")
  }
  public enum AccountList {
    public enum Row {
      /// Copy
      public static let copyTitle = L10n.tr("Localizable", "accountList.row.copyTitle", fallback: "Copy")
    }
  }
  public enum AccountPreferences {
    /// Get Betanet XRD Test Tokens
    public static let faucetButtonTitle = L10n.tr("Localizable", "accountPreferences.faucetButtonTitle", fallback: "Get Betanet XRD Test Tokens")
    /// This may take several seconds, please wait for completion
    public static let loadingPrompt = L10n.tr("Localizable", "accountPreferences.loadingPrompt", fallback: "This may take several seconds, please wait for completion")
    /// Account Preferences
    public static let title = L10n.tr("Localizable", "accountPreferences.title", fallback: "Account Preferences")
  }
  public enum AggregatedValue {
    /// Total value
    public static let title = L10n.tr("Localizable", "aggregatedValue.title", fallback: "Total value")
  }
  public enum App {
    /// Development use only. Not usable on Radix mainnet.
    public static let developmentOnlyInfo = L10n.tr("Localizable", "app.developmentOnlyInfo", fallback: "Development use only. Not usable on Radix mainnet.")
    /// An Error Occurred
    public static let errorOccurredTitle = L10n.tr("Localizable", "app.errorOccurredTitle", fallback: "An Error Occurred")
  }
  public enum AssetsView {
    /// Badges
    public static let badges = L10n.tr("Localizable", "assetsView.badges", fallback: "Badges")
    /// NFTs
    public static let nfts = L10n.tr("Localizable", "assetsView.nfts", fallback: "NFTs")
    /// Pool Shares
    public static let poolShare = L10n.tr("Localizable", "assetsView.poolShare", fallback: "Pool Shares")
    /// Tokens
    public static let tokens = L10n.tr("Localizable", "assetsView.tokens", fallback: "Tokens")
  }
  public enum Common {
    /// Inconsistency trying to use deleted Linked Connector.
    public static let p2PClientNotFoundInProfile = L10n.tr("Localizable", "common.P2PClientNotFoundInProfile", fallback: "Inconsistency trying to use deleted Linked Connector.")
    /// Linked Connector Offline
    public static let p2PConnectionOffline = L10n.tr("Localizable", "common.P2PConnectionOffline", fallback: "Linked Connector Offline")
  }
  public enum CreateAccount {
    /// Authenticate to create new account with this phone.
    public static let biometricsPrompt = L10n.tr("Localizable", "createAccount.biometricsPrompt", fallback: "Authenticate to create new account with this phone.")
    /// Create Account
    public static let createAccountButtonTitle = L10n.tr("Localizable", "createAccount.createAccountButtonTitle", fallback: "Create Account")
    /// Create First Account
    public static let createFirstAccount = L10n.tr("Localizable", "createAccount.createFirstAccount", fallback: "Create First Account")
    /// Create New Account
    public static let createNewAccount = L10n.tr("Localizable", "createAccount.createNewAccount", fallback: "Create New Account")
    /// This can be changed any time
    public static let explanation = L10n.tr("Localizable", "createAccount.explanation", fallback: "This can be changed any time")
    /// e.g. My Main Account
    public static let placeholder = L10n.tr("Localizable", "createAccount.placeholder", fallback: "e.g. My Main Account")
    /// What would you like to call your account?
    public static let subtitle = L10n.tr("Localizable", "createAccount.subtitle", fallback: "What would you like to call your account?")
    public enum Completion {
      /// Your account lives on the Radix Network and you can access it anytime in your Radix Wallet.
      public static let explanation = L10n.tr("Localizable", "createAccount.completion.explanation", fallback: "Your account lives on the Radix Network and you can access it anytime in your Radix Wallet.")
      /// Go to %@
      public static func goToDestination(_ p1: Any) -> String {
        return L10n.tr("Localizable", "createAccount.completion.goToDestination", String(describing: p1), fallback: "Go to %@")
      }
      /// Your account has been created.
      public static let subtitle = L10n.tr("Localizable", "createAccount.completion.subtitle", fallback: "Your account has been created.")
      /// You’ve created your first account.
      public static let subtitleFirstAccount = L10n.tr("Localizable", "createAccount.completion.subtitleFirstAccount", fallback: "You’ve created your first account.")
      /// Congratulations
      public static let title = L10n.tr("Localizable", "createAccount.completion.title", fallback: "Congratulations")
      public enum Destination {
        /// Choose Accounts
        public static let chooseAccounts = L10n.tr("Localizable", "createAccount.completion.destination.chooseAccounts", fallback: "Choose Accounts")
        /// Account List
        public static let home = L10n.tr("Localizable", "createAccount.completion.destination.home", fallback: "Account List")
      }
    }
  }
  public enum DApp {
    /// Unknown dApp
    public static let unknownName = L10n.tr("Localizable", "dApp.unknownName", fallback: "Unknown dApp")
    public enum ChooseAccounts {
      /// + Create a New Account
      public static let createNewAccount = L10n.tr("Localizable", "dApp.chooseAccounts.createNewAccount", fallback: "+ Create a New Account")
      /// Choose %@
      public static func explanation(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dApp.chooseAccounts.explanation", String(describing: p1), fallback: "Choose %@")
      }
      /// At Least One Account
      public static let explanationAtLeastOneAccount = L10n.tr("Localizable", "dApp.chooseAccounts.explanationAtLeastOneAccount", fallback: "At Least One Account")
      /// One Account
      public static let explanationExactlyOneAccount = L10n.tr("Localizable", "dApp.chooseAccounts.explanationExactlyOneAccount", fallback: "One Account")
      /// #%d Accounts
      public static func explanationExactNumberOfAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "dApp.chooseAccounts.explanationExactNumberOfAccounts", p1, fallback: "#%d Accounts")
      }
      /// Choose the account(s) you want %@ to know about.
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dApp.chooseAccounts.subtitle", String(describing: p1), fallback: "Choose the account(s) you want %@ to know about.")
      }
      /// Choose Accounts
      public static let title = L10n.tr("Localizable", "dApp.chooseAccounts.title", fallback: "Choose Accounts")
      /// Unnamed Account
      public static let unnamedAccount = L10n.tr("Localizable", "dApp.chooseAccounts.unnamedAccount", fallback: "Unnamed Account")
    }
    public enum ConnectionRequest {
      /// Continue
      public static let continueButtonTitle = L10n.tr("Localizable", "dApp.connectionRequest.continueButtonTitle", fallback: "Continue")
      /// For this dApp to function, it needs the following:
      public static let subtitle = L10n.tr("Localizable", "dApp.connectionRequest.subtitle", fallback: "For this dApp to function, it needs the following:")
      /// dApp Connection Request
      public static let title = L10n.tr("Localizable", "dApp.connectionRequest.title", fallback: "dApp Connection Request")
      /// %@ wants to connect to your wallet
      public static func wantsToConnect(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dApp.connectionRequest.wantsToConnect", String(describing: p1), fallback: "%@ wants to connect to your wallet")
      }
    }
    public enum Request {
      /// Request received from dApp for network %@, but you are currently connected to %@.
      public static func wrongNetworkError(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dApp.request.wrongNetworkError", String(describing: p1), String(describing: p2), fallback: "Request received from dApp for network %@, but you are currently connected to %@.")
      }
    }
  }
  public enum FungibleTokenList {
    public enum Detail {
      /// Current Supply
      public static let currentSupply = L10n.tr("Localizable", "fungibleTokenList.detail.currentSupply", fallback: "Current Supply")
      /// Resource Address
      public static let resourceAddress = L10n.tr("Localizable", "fungibleTokenList.detail.resourceAddress", fallback: "Resource Address")
    }
  }
  public enum Home {
    public enum Header {
      /// Welcome, here are all your accounts on the Radix Network
      public static let subtitle = L10n.tr("Localizable", "home.header.subtitle", fallback: "Welcome, here are all your accounts on the Radix Network")
      /// Radix Wallet
      public static let title = L10n.tr("Localizable", "home.header.title", fallback: "Radix Wallet")
    }
    public enum VisitHub {
      /// Visit the Radix Dashboard
      public static let buttonTitle = L10n.tr("Localizable", "home.visitHub.buttonTitle", fallback: "Visit the Radix Dashboard")
      /// Ready to get started using the Radix Network and your Wallet?
      public static let title = L10n.tr("Localizable", "home.visitHub.title", fallback: "Ready to get started using the Radix Network and your Wallet?")
    }
  }
  public enum ImportProfile {
    /// Import mnemonic
    public static let importMnemonic = L10n.tr("Localizable", "importProfile.importMnemonic", fallback: "Import mnemonic")
    /// Import Radix Wallet backup
    public static let importProfile = L10n.tr("Localizable", "importProfile.importProfile", fallback: "Import Radix Wallet backup")
    /// Mnemonic phrase
    public static let mnemonicPhrase = L10n.tr("Localizable", "importProfile.mnemonicPhrase", fallback: "Mnemonic phrase")
    /// Radix Wallet backup from file
    public static let profileFromSnapshot = L10n.tr("Localizable", "importProfile.profileFromSnapshot", fallback: "Radix Wallet backup from file")
    /// Save imported mnemonic
    public static let saveImportedMnemonic = L10n.tr("Localizable", "importProfile.saveImportedMnemonic", fallback: "Save imported mnemonic")
  }
  public enum ManageGateway {
    /// Current Network Gateway
    public static let currentGatewayTitle = L10n.tr("Localizable", "manageGateway.currentGatewayTitle", fallback: "Current Network Gateway")
    /// Gateway URL
    public static let gatewayAPIEndpoint = L10n.tr("Localizable", "manageGateway.gatewayAPIEndpoint", fallback: "Gateway URL")
    /// Network ID
    public static let networkID = L10n.tr("Localizable", "manageGateway.networkID", fallback: "Network ID")
    /// Network Name
    public static let networkName = L10n.tr("Localizable", "manageGateway.networkName", fallback: "Network Name")
    /// Update Gateway
    public static let switchToButtonTitle = L10n.tr("Localizable", "manageGateway.switchToButtonTitle", fallback: "Update Gateway")
    /// New Gateway URL
    public static let textFieldHint = L10n.tr("Localizable", "manageGateway.textFieldHint", fallback: "New Gateway URL")
    /// Enter full URL
    public static let textFieldPlaceholder = L10n.tr("Localizable", "manageGateway.textFieldPlaceholder", fallback: "Enter full URL")
    /// Network Gateway
    public static let title = L10n.tr("Localizable", "manageGateway.title", fallback: "Network Gateway")
    /// https://example.com:8080
    public static let urlString = L10n.tr("Localizable", "manageGateway.urlString", fallback: "https://example.com:8080")
  }
  public enum ManageP2PClients {
    /// Connector ID: %@
    public static func connectionID(_ p1: Any) -> String {
      return L10n.tr("Localizable", "manageP2PClients.connectionID", String(describing: p1), fallback: "Connector ID: %@")
    }
    /// Link New Connector
    public static let newConnectionButtonTitle = L10n.tr("Localizable", "manageP2PClients.newConnectionButtonTitle", fallback: "Link New Connector")
    /// Link New Connector
    public static let newConnectionTitle = L10n.tr("Localizable", "manageP2PClients.newConnectionTitle", fallback: "Link New Connector")
    /// Your Radix Wallet is linked to the following desktop browser using the Connector browser extension.
    public static let p2PConnectionsSubtitle = L10n.tr("Localizable", "manageP2PClients.P2PConnectionsSubtitle", fallback: "Your Radix Wallet is linked to the following desktop browser using the Connector browser extension.")
    /// Linked Connector
    public static let p2PConnectionsTitle = L10n.tr("Localizable", "manageP2PClients.P2PConnectionsTitle", fallback: "Linked Connector")
    /// Send Test Msg
    public static let sendTestMessageButtonTitle = L10n.tr("Localizable", "manageP2PClients.sendTestMessageButtonTitle", fallback: "Send Test Msg")
  }
  public enum NewConnection {
    /// Linking...
    public static let connecting = L10n.tr("Localizable", "newConnection.connecting", fallback: "Linking...")
    /// Unnamed
    public static let defaultNameOfConnection = L10n.tr("Localizable", "newConnection.defaultNameOfConnection", fallback: "Unnamed")
    /// Save Link
    public static let saveNamedConnectionButton = L10n.tr("Localizable", "newConnection.saveNamedConnectionButton", fallback: "Save Link")
    /// Scan your QR code to link your wallet with a browser extension
    public static let subtitle = L10n.tr("Localizable", "newConnection.subtitle", fallback: "Scan your QR code to link your wallet with a browser extension")
    /// Name this Connector, e.g. "Chrome on Macbook Pro"
    public static let textFieldHint = L10n.tr("Localizable", "newConnection.textFieldHint", fallback: "Name this Connector, e.g. \"Chrome on Macbook Pro\"")
    /// Name of Connector
    public static let textFieldPlaceholder = L10n.tr("Localizable", "newConnection.textFieldPlaceholder", fallback: "Name of Connector")
    /// Link to Connector
    public static let title = L10n.tr("Localizable", "newConnection.title", fallback: "Link to Connector")
    public enum CameraPermission {
      public enum DeniedAlert {
        /// Cancel
        public static let cancelButtonTitle = L10n.tr("Localizable", "newConnection.cameraPermission.deniedAlert.cancelButtonTitle", fallback: "Cancel")
        /// Camera access is required to link to connector.
        public static let message = L10n.tr("Localizable", "newConnection.cameraPermission.deniedAlert.message", fallback: "Camera access is required to link to connector.")
        /// Settings
        public static let settingsButtonTitle = L10n.tr("Localizable", "newConnection.cameraPermission.deniedAlert.settingsButtonTitle", fallback: "Settings")
        /// Access Required
        public static let title = L10n.tr("Localizable", "newConnection.cameraPermission.deniedAlert.title", fallback: "Access Required")
      }
    }
    public enum LocalNetworkPermission {
      public enum DeniedAlert {
        /// Cancel
        public static let cancelButtonTitle = L10n.tr("Localizable", "newConnection.localNetworkPermission.deniedAlert.cancelButtonTitle", fallback: "Cancel")
        /// Local Network access is required to link to connector.
        public static let message = L10n.tr("Localizable", "newConnection.localNetworkPermission.deniedAlert.message", fallback: "Local Network access is required to link to connector.")
        /// Settings
        public static let settingsButtonTitle = L10n.tr("Localizable", "newConnection.localNetworkPermission.deniedAlert.settingsButtonTitle", fallback: "Settings")
        /// Access Required
        public static let title = L10n.tr("Localizable", "newConnection.localNetworkPermission.deniedAlert.title", fallback: "Access Required")
      }
    }
  }
  public enum NftList {
    /// %d NFTs
    public static func nftPlural(_ p1: Int) -> String {
      return L10n.tr("Localizable", "nftList.nftPlural", p1, fallback: "%d NFTs")
    }
    /// %d of %d
    public static func ownedOfTotal(_ p1: Int, _ p2: Int) -> String {
      return L10n.tr("Localizable", "nftList.ownedOfTotal", p1, p2, fallback: "%d of %d")
    }
    public enum Detail {
      /// NFT ID
      public static let nftID = L10n.tr("Localizable", "nftList.detail.nftID", fallback: "NFT ID")
      /// Resource Address
      public static let resourceAddress = L10n.tr("Localizable", "nftList.detail.resourceAddress", fallback: "Resource Address")
      /// Name
      public static let resourceName = L10n.tr("Localizable", "nftList.detail.resourceName", fallback: "Name")
    }
    public enum Header {
      /// Unknown
      public static let supplyUnknown = L10n.tr("Localizable", "nftList.header.supplyUnknown", fallback: "Unknown")
    }
  }
  public enum Onboarding {
    /// New Account
    public static let newAccountButtonTitle = L10n.tr("Localizable", "onboarding.newAccountButtonTitle", fallback: "New Account")
  }
  public enum ProfileLoad {
    /// Failed to create Wallet from backup: %@
    public static func decodingError(_ p1: Any) -> String {
      return L10n.tr("Localizable", "profileLoad.decodingError", String(describing: p1), fallback: "Failed to create Wallet from backup: %@")
    }
    /// Failed to create Wallet from backup, error: %@, version: %@
    public static func failedToCreateProfileFromSnapshotError(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "profileLoad.failedToCreateProfileFromSnapshotError", String(describing: p1), String(describing: p2), fallback: "Failed to create Wallet from backup, error: %@, version: %@")
    }
  }
  public enum Settings {
    /// Close
    public static let closeButtonTitle = L10n.tr("Localizable", "settings.closeButtonTitle", fallback: "Close")
    /// Delete Wallet Data
    public static let deleteAllButtonTitle = L10n.tr("Localizable", "settings.deleteAllButtonTitle", fallback: "Delete Wallet Data")
    /// Linked Connector
    public static let desktopConnectionsButtonTitle = L10n.tr("Localizable", "settings.desktopConnectionsButtonTitle", fallback: "Linked Connector")
    /// Network Gateway
    public static let gatewayButtonTitle = L10n.tr("Localizable", "settings.gatewayButtonTitle", fallback: "Network Gateway")
    /// Inspect Profile
    public static let inspectProfileButtonTitle = L10n.tr("Localizable", "settings.inspectProfileButtonTitle", fallback: "Inspect Profile")
    /// No Wallet Data Found
    public static let noProfileText = L10n.tr("Localizable", "settings.noProfileText", fallback: "No Wallet Data Found")
    /// Wallet Settings
    public static let title = L10n.tr("Localizable", "settings.title", fallback: "Wallet Settings")
    /// Version: %@ build #%@
    public static func versionInfo(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "settings.versionInfo", String(describing: p1), String(describing: p2), fallback: "Version: %@ build #%@")
    }
    public enum ConnectExtension {
      /// Link to Connector
      public static let buttonTitle = L10n.tr("Localizable", "settings.connectExtension.buttonTitle", fallback: "Link to Connector")
      /// Scan the QR code in the Radix Wallet Connector extension
      public static let subtitle = L10n.tr("Localizable", "settings.connectExtension.subtitle", fallback: "Scan the QR code in the Radix Wallet Connector extension")
      /// Link your Wallet to a Desktop Browser
      public static let title = L10n.tr("Localizable", "settings.connectExtension.title", fallback: "Link your Wallet to a Desktop Browser")
    }
  }
  public enum Splash {
    /// This app requires your phone to have biometrics set up
    public static let biometricsNotSetUpMessage = L10n.tr("Localizable", "splash.biometricsNotSetUpMessage", fallback: "This app requires your phone to have biometrics set up")
    /// Biometrics not set up
    public static let biometricsNotSetUpTitle = L10n.tr("Localizable", "splash.biometricsNotSetUpTitle", fallback: "Biometrics not set up")
    /// Delete Wallet Data
    public static let incompatibleProfileVersionAlertDeleteButton = L10n.tr("Localizable", "splash.incompatibleProfileVersionAlertDeleteButton", fallback: "Delete Wallet Data")
    /// For this Preview wallet version, you must delete your wallet data to continue.
    public static let incompatibleProfileVersionAlertMessage = L10n.tr("Localizable", "splash.incompatibleProfileVersionAlertMessage", fallback: "For this Preview wallet version, you must delete your wallet data to continue.")
    /// Wallet Data is Incompatible
    public static let incompatibleProfileVersionAlertTitle = L10n.tr("Localizable", "splash.incompatibleProfileVersionAlertTitle", fallback: "Wallet Data is Incompatible")
  }
  public enum TransactionSigning {
    /// Authenticate to sign transaction with this phone.
    public static let biometricsPrompt = L10n.tr("Localizable", "transactionSigning.biometricsPrompt", fallback: "Authenticate to sign transaction with this phone.")
    /// Preparing transaction...
    public static let preparingTransactionLoadingText = L10n.tr("Localizable", "transactionSigning.preparingTransactionLoadingText", fallback: "Preparing transaction...")
    /// Submitting transaction...
    public static let signingAndSubmittingTransactionLoadingText = L10n.tr("Localizable", "transactionSigning.signingAndSubmittingTransactionLoadingText", fallback: "Submitting transaction...")
    /// Approve Transaction
    public static let signTransactionButtonTitle = L10n.tr("Localizable", "transactionSigning.signTransactionButtonTitle", fallback: "Approve Transaction")
    /// Approve Transaction
    public static let title = L10n.tr("Localizable", "transactionSigning.title", fallback: "Approve Transaction")
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

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
