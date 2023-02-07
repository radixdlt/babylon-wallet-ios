// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

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
    public enum Account {
      /// Account
      public static let kind = L10n.tr("Localizable", "common.account.kind", fallback: "Account")
    }
    public enum Persona {
      /// Persona
      public static let kind = L10n.tr("Localizable", "common.persona.kind", fallback: "Persona")
    }
  }
  public enum CreateEntity {
    public enum Completion {
      /// Go to %@
      public static func goToDestination(_ p1: Any) -> String {
        return L10n.tr("Localizable", "createEntity.completion.goToDestination", String(describing: p1), fallback: "Go to %@")
      }
      /// Congratulations
      public static let title = L10n.tr("Localizable", "createEntity.completion.title", fallback: "Congratulations")
      public enum Destination {
        /// Choose %ss
        public static func chooseEntities(_ p1: UnsafePointer<CChar>) -> String {
          return L10n.tr("Localizable", "createEntity.completion.destination.chooseEntities", p1, fallback: "Choose %ss")
        }
        /// Account List
        public static let home = L10n.tr("Localizable", "createEntity.completion.destination.home", fallback: "Account List")
        /// Persona List
        public static let settingsPersonaList = L10n.tr("Localizable", "createEntity.completion.destination.settingsPersonaList", fallback: "Persona List")
      }
      public enum Explanation {
        public enum Specific {
          /// Your account lives on the Radix Network and you can access it anytime in your Radix Wallet.
          public static let account = L10n.tr("Localizable", "createEntity.completion.explanation.specific.account", fallback: "Your account lives on the Radix Network and you can access it anytime in your Radix Wallet.")
          /// Personal data that you add to your Persona will only be shared with dApp websites with your permission in the Radix Wallet.
          public static let persona = L10n.tr("Localizable", "createEntity.completion.explanation.specific.persona", fallback: "Personal data that you add to your Persona will only be shared with dApp websites with your permission in the Radix Wallet.")
        }
      }
      public enum Subtitle {
        /// You’ve created your first %s.
        public static func first(_ p1: UnsafePointer<CChar>) -> String {
          return L10n.tr("Localizable", "createEntity.completion.subtitle.first", p1, fallback: "You’ve created your first %s.")
        }
        /// Your %s has been created.
        public static func notFirst(_ p1: UnsafePointer<CChar>) -> String {
          return L10n.tr("Localizable", "createEntity.completion.subtitle.notFirst", p1, fallback: "Your %s has been created.")
        }
      }
    }
    public enum CreationOfEntity {
      /// Authenticate to create new %s with this phone.
      public static func biometricsPrompt(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "createEntity.creationOfEntity.biometricsPrompt", p1, fallback: "Authenticate to create new %s with this phone.")
      }
    }
    public enum NameNewEntity {
      /// What would you like to call your %s?
      public static func subtitle(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "createEntity.nameNewEntity.subtitle", p1, fallback: "What would you like to call your %s?")
      }
      public enum Name {
        public enum Button {
          /// Continue
          public static let title = L10n.tr("Localizable", "createEntity.nameNewEntity.name.button.title", fallback: "Continue")
        }
        public enum Field {
          /// This can be changed any time
          public static let explanation = L10n.tr("Localizable", "createEntity.nameNewEntity.name.field.explanation", fallback: "This can be changed any time")
          public enum Placeholder {
            public enum Specific {
              /// e.g. My Main Account
              public static let account = L10n.tr("Localizable", "createEntity.nameNewEntity.name.field.placeholder.specific.account", fallback: "e.g. My Main Account")
              /// e.g. My Main Persona
              public static let persona = L10n.tr("Localizable", "createEntity.nameNewEntity.name.field.placeholder.specific.persona", fallback: "e.g. My Main Persona")
            }
          }
        }
      }
      public enum Title {
        /// Create First %s
        public static func first(_ p1: UnsafePointer<CChar>) -> String {
          return L10n.tr("Localizable", "createEntity.nameNewEntity.title.first", p1, fallback: "Create First %s")
        }
        /// Create New %s
        public static func notFirst(_ p1: UnsafePointer<CChar>) -> String {
          return L10n.tr("Localizable", "createEntity.nameNewEntity.title.notFirst", p1, fallback: "Create New %s")
        }
      }
    }
  }
  public enum DApp {
    public enum ChooseAccounts {
      /// Create a New Account
      public static let createNewAccount = L10n.tr("Localizable", "dApp.chooseAccounts.createNewAccount", fallback: "Create a New Account")
      public enum Subtitle {
        public enum Message {
          public enum OneTime {
            ///  is making a one-time request for at least %d accounts.
            public static func atLeast(_ p1: Int) -> String {
              return L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.oneTime.atLeast", p1, fallback: " is making a one-time request for at least %d accounts.")
            }
            ///  is making a one-time request for at least 1 account.
            public static let atLeastOne = L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.oneTime.atLeastOne", fallback: " is making a one-time request for at least 1 account.")
            ///  is making a one-time request for any number of accounts.
            public static let atLeastZero = L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.oneTime.atLeastZero", fallback: " is making a one-time request for any number of accounts.")
            ///  is making a one-time request for at least %d accounts.
            public static func exactly(_ p1: Int) -> String {
              return L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.oneTime.exactly", p1, fallback: " is making a one-time request for at least %d accounts.")
            }
            ///  is making a one-time request for 1 account.
            public static let exactlyOne = L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.oneTime.exactlyOne", fallback: " is making a one-time request for 1 account.")
          }
          public enum Ongoing {
            /// Choose at least %d accounts you wish to use with 
            public static func atLeast(_ p1: Int) -> String {
              return L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.ongoing.atLeast", p1, fallback: "Choose at least %d accounts you wish to use with ")
            }
            /// Choose at least 1 account you wish to use with 
            public static let atLeastOne = L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.ongoing.atLeastOne", fallback: "Choose at least 1 account you wish to use with ")
            /// Choose any accounts you wish to use with 
            public static let atLeastZero = L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.ongoing.atLeastZero", fallback: "Choose any accounts you wish to use with ")
            /// Choose %d accounts you wish to use with 
            public static func exactly(_ p1: Int) -> String {
              return L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.ongoing.exactly", p1, fallback: "Choose %d accounts you wish to use with ")
            }
            /// Choose 1 account you wish to use with 
            public static let exactlyOne = L10n.tr("Localizable", "dApp.chooseAccounts.subtitle.message.ongoing.exactlyOne", fallback: "Choose 1 account you wish to use with ")
          }
        }
      }
    }
    public enum LoginRequest {
      /// Choose a Persona
      public static let chooseAPersonaTitle = L10n.tr("Localizable", "dApp.loginRequest.chooseAPersonaTitle", fallback: "Choose a Persona")
      /// Continue
      public static let continueButtonTitle = L10n.tr("Localizable", "dApp.loginRequest.continueButtonTitle", fallback: "Continue")
      public enum Row {
        /// Your last login was on %@
        public static func lastLoginWasOn(_ p1: Any) -> String {
          return L10n.tr("Localizable", "dApp.loginRequest.row.lastLoginWasOn", String(describing: p1), fallback: "Your last login was on %@")
        }
      }
      public enum Subtitle {
        ///  is requesting you login with a Persona.
        public static let knownDapp = L10n.tr("Localizable", "dApp.loginRequest.subtitle.knownDapp", fallback: " is requesting you login with a Persona.")
        ///  is requesting you login for the first time with a Persona.
        public static let newDapp = L10n.tr("Localizable", "dApp.loginRequest.subtitle.newDapp", fallback: " is requesting you login for the first time with a Persona.")
      }
      public enum Title {
        /// Login Request
        public static let knownDapp = L10n.tr("Localizable", "dApp.loginRequest.title.knownDapp", fallback: "Login Request")
        /// New Login Request
        public static let newDapp = L10n.tr("Localizable", "dApp.loginRequest.title.newDapp", fallback: "New Login Request")
      }
    }
    public enum MetadataLoading {
      /// Loading...
      public static let prompt = L10n.tr("Localizable", "dApp.metadataLoading.prompt", fallback: "Loading...")
      public enum ErrorAlert {
        /// Cancel
        public static let cancelButtonTitle = L10n.tr("Localizable", "dApp.metadataLoading.errorAlert.cancelButtonTitle", fallback: "Cancel")
        /// Danger! Bad dApp config or you're being spoofed!
        public static let message = L10n.tr("Localizable", "dApp.metadataLoading.errorAlert.message", fallback: "Danger! Bad dApp config or you're being spoofed!")
        /// Retry
        public static let retryButtonTitle = L10n.tr("Localizable", "dApp.metadataLoading.errorAlert.retryButtonTitle", fallback: "Retry")
      }
    }
    public enum Request {
      /// Request received from dApp for network %@, but you are currently connected to %@.
      public static func wrongNetworkError(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dApp.request.wrongNetworkError", String(describing: p1), String(describing: p2), fallback: "Request received from dApp for network %@, but you are currently connected to %@.")
      }
      public enum MalformedErrorAlert {
        /// Interaction received from dApp does not contain any valid requests.
        public static let message = L10n.tr("Localizable", "dApp.request.malformedErrorAlert.message", fallback: "Interaction received from dApp does not contain any valid requests.")
        /// OK
        public static let okButtonTitle = L10n.tr("Localizable", "dApp.request.malformedErrorAlert.okButtonTitle", fallback: "OK")
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
    public enum CreateAccount {
      /// Create Account
      public static let buttonTitle = L10n.tr("Localizable", "home.createAccount.buttonTitle", fallback: "Create Account")
    }
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
  public enum PersonaList {
    /// Create new persona
    public static let createNewPersonaButtonTitle = L10n.tr("Localizable", "personaList.createNewPersonaButtonTitle", fallback: "Create new persona")
    /// Here are all the Personas connected to your account
    public static let subtitle = L10n.tr("Localizable", "personaList.subtitle", fallback: "Here are all the Personas connected to your account")
    /// Personas
    public static let title = L10n.tr("Localizable", "personaList.title", fallback: "Personas")
  }
  public enum Personas {
    /// Create a New Persona
    public static let createNewPersonaButtonTitle = L10n.tr("Localizable", "personas.createNewPersonaButtonTitle", fallback: "Create a New Persona")
    /// Here are all the Personas connected to your account
    public static let subtitle = L10n.tr("Localizable", "personas.subtitle", fallback: "Here are all the Personas connected to your account")
    /// Personas
    public static let title = L10n.tr("Localizable", "personas.title", fallback: "Personas")
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
    /// Personas
    public static let personasButtonTitle = L10n.tr("Localizable", "settings.personasButtonTitle", fallback: "Personas")
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
    public enum Alert {
      public enum BiometricsCheckFailed {
        /// Cancel
        public static let cancelButtonTitle = L10n.tr("Localizable", "splash.alert.biometricsCheckFailed.cancelButtonTitle", fallback: "Cancel")
        /// Biometrics are not set up. Please update settings.
        public static let message = L10n.tr("Localizable", "splash.alert.biometricsCheckFailed.message", fallback: "Biometrics are not set up. Please update settings.")
        /// Settings
        public static let settingsButtonTitle = L10n.tr("Localizable", "splash.alert.biometricsCheckFailed.settingsButtonTitle", fallback: "Settings")
        /// Warning
        public static let title = L10n.tr("Localizable", "splash.alert.biometricsCheckFailed.title", fallback: "Warning")
      }
    }
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
