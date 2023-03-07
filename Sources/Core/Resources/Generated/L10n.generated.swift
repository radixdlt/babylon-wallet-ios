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
    /// Pool Units
    public static let poolUnits = L10n.tr("Localizable", "assetsView.poolUnits", fallback: "Pool Units")
    /// Tokens
    public static let tokens = L10n.tr("Localizable", "assetsView.tokens", fallback: "Tokens")
  }
  public enum AuthorizedDapps {
    /// Here are all the dApps that you have logged into with this Radix Wallet.
    public static let intro = L10n.tr("Localizable", "authorizedDapps.intro", fallback: "Here are all the dApps that you have logged into with this Radix Wallet.")
    /// Authorized dApps
    public static let title = L10n.tr("Localizable", "authorizedDapps.title", fallback: "Authorized dApps")
  }
  public enum Common {
    public enum Account {
      /// Account
      public static let kind = L10n.tr("Localizable", "common.account.kind", fallback: "Account")
    }
    public enum BiometricsPrompt {
      /// Authenticate to create new %s with this phone.
      public static func creationOfEntity(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "common.biometricsPrompt.creationOfEntity", p1, fallback: "Authenticate to create new %s with this phone.")
      }
      /// Authenticate to sign auth chellenge with this phone.
      public static let signAuthChallenge = L10n.tr("Localizable", "common.biometricsPrompt.signAuthChallenge", fallback: "Authenticate to sign auth chellenge with this phone.")
      /// Authenticate to sign transaction with this phone.
      public static let signTransaction = L10n.tr("Localizable", "common.biometricsPrompt.signTransaction", fallback: "Authenticate to sign transaction with this phone.")
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
    public enum NameNewEntity {
      /// What would you like to call your %s?
      public static func subtitle(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "createEntity.nameNewEntity.subtitle", p1, fallback: "What would you like to call your %s?")
      }
      public enum Account {
        public enum Title {
          /// Create First Account
          public static let first = L10n.tr("Localizable", "createEntity.nameNewEntity.account.title.first", fallback: "Create First Account")
          /// Create New Account
          public static let notFirst = L10n.tr("Localizable", "createEntity.nameNewEntity.account.title.notFirst", fallback: "Create New Account")
        }
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
      public enum Persona {
        /// Create a Persona
        public static let title = L10n.tr("Localizable", "createEntity.nameNewEntity.persona.title", fallback: "Create a Persona")
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
      public enum Title {
        /// Account Request
        public static let oneTime = L10n.tr("Localizable", "dApp.chooseAccounts.title.oneTime", fallback: "Account Request")
        /// Account Permission
        public static let ongoing = L10n.tr("Localizable", "dApp.chooseAccounts.title.ongoing", fallback: "Account Permission")
      }
    }
    public enum Completion {
      /// Request from %s complete
      public static func subtitle(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dApp.completion.subtitle", p1, fallback: "Request from %s complete")
      }
      /// Success
      public static let title = L10n.tr("Localizable", "dApp.completion.title", fallback: "Success")
    }
    public enum Login {
      /// Choose a Persona
      public static let chooseAPersonaTitle = L10n.tr("Localizable", "dApp.login.chooseAPersonaTitle", fallback: "Choose a Persona")
      /// Continue
      public static let continueButtonTitle = L10n.tr("Localizable", "dApp.login.continueButtonTitle", fallback: "Continue")
      public enum Row {
        /// Your last login was on %@
        public static func lastLoginWasOn(_ p1: Any) -> String {
          return L10n.tr("Localizable", "dApp.login.row.lastLoginWasOn", String(describing: p1), fallback: "Your last login was on %@")
        }
      }
      public enum Subtitle {
        ///  is requesting you login with a Persona.
        public static let knownDapp = L10n.tr("Localizable", "dApp.login.subtitle.knownDapp", fallback: " is requesting you login with a Persona.")
        ///  is requesting you login for the first time with a Persona.
        public static let newDapp = L10n.tr("Localizable", "dApp.login.subtitle.newDapp", fallback: " is requesting you login for the first time with a Persona.")
      }
      public enum Title {
        /// Login Request
        public static let knownDapp = L10n.tr("Localizable", "dApp.login.title.knownDapp", fallback: "Login Request")
        /// New Login Request
        public static let newDapp = L10n.tr("Localizable", "dApp.login.title.newDapp", fallback: "New Login Request")
      }
    }
    public enum Metadata {
      /// Unknown dApp
      public static let unknownName = L10n.tr("Localizable", "dApp.metadata.unknownName", fallback: "Unknown dApp")
    }
    public enum MetadataLoading {
      /// Loading...
      public static let prompt = L10n.tr("Localizable", "dApp.metadataLoading.prompt", fallback: "Loading...")
      public enum ErrorAlert {
        /// Cancel
        public static let cancelButtonTitle = L10n.tr("Localizable", "dApp.metadataLoading.errorAlert.cancelButtonTitle", fallback: "Cancel")
        /// Danger! Bad dApp config or you're being spoofed!
        /// 
        /// %@
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "dApp.metadataLoading.errorAlert.message", String(describing: p1), fallback: "Danger! Bad dApp config or you're being spoofed!\n\n%@")
        }
        /// Retry
        public static let retryButtonTitle = L10n.tr("Localizable", "dApp.metadataLoading.errorAlert.retryButtonTitle", fallback: "Retry")
      }
    }
    public enum Permission {
      /// You can update this permission in your settings at any time.
      public static let updateInSettingsExplanation = L10n.tr("Localizable", "dApp.permission.updateInSettingsExplanation", fallback: "You can update this permission in your settings at any time.")
      public enum NumberOfAccounts {
        /// %d or more accounts
        public static func atLeast(_ p1: Int) -> String {
          return L10n.tr("Localizable", "dApp.permission.numberOfAccounts.atLeast", p1, fallback: "%d or more accounts")
        }
        /// Any number of accounts
        public static let atLeastZero = L10n.tr("Localizable", "dApp.permission.numberOfAccounts.atLeastZero", fallback: "Any number of accounts")
        /// %d accounts
        public static func exactly(_ p1: Int) -> String {
          return L10n.tr("Localizable", "dApp.permission.numberOfAccounts.exactly", p1, fallback: "%d accounts")
        }
        /// 1 account
        public static let exactlyOne = L10n.tr("Localizable", "dApp.permission.numberOfAccounts.exactlyOne", fallback: "1 account")
      }
      public enum Subtitle {
        /// always
        public static let always = L10n.tr("Localizable", "dApp.permission.subtitle.always", fallback: "always")
        public enum Explanation {
          public enum Accounts {
            ///  is requesting permission to 
            public static let first = L10n.tr("Localizable", "dApp.permission.subtitle.explanation.accounts.first", fallback: " is requesting permission to ")
            ///  be able to view account information when you login with this Persona.
            public static let second = L10n.tr("Localizable", "dApp.permission.subtitle.explanation.accounts.second", fallback: " be able to view account information when you login with this Persona.")
          }
          public enum PersonalData {
            ///  is requesting permission to 
            public static let first = L10n.tr("Localizable", "dApp.permission.subtitle.explanation.personalData.first", fallback: " is requesting permission to ")
            ///  be able to view the following personal data when you login with this Persona.
            public static let second = L10n.tr("Localizable", "dApp.permission.subtitle.explanation.personalData.second", fallback: " be able to view the following personal data when you login with this Persona.")
          }
        }
      }
      public enum Title {
        /// Account Permission
        public static let accounts = L10n.tr("Localizable", "dApp.permission.title.accounts", fallback: "Account Permission")
        /// Personal Data Permission
        public static let personalData = L10n.tr("Localizable", "dApp.permission.title.personalData", fallback: "Personal Data Permission")
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
      public enum SpecifiedPersonaNotFoundError {
        /// Cancel
        public static let cancelButtonTitle = L10n.tr("Localizable", "dApp.request.specifiedPersonaNotFoundError.cancelButtonTitle", fallback: "Cancel")
        /// Persona specified by dApp does not exist.
        /// 
        /// %@
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "dApp.request.specifiedPersonaNotFoundError.message", String(describing: p1), fallback: "Persona specified by dApp does not exist.\n\n%@")
        }
      }
    }
    public enum Response {
      public enum FailureAlert {
        /// Cancel
        public static let cancelButtonTitle = L10n.tr("Localizable", "dApp.response.failureAlert.cancelButtonTitle", fallback: "Cancel")
        /// Failed to send response payload back to dApp.
        /// 
        /// %@
        public static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "dApp.response.failureAlert.message", String(describing: p1), fallback: "Failed to send response payload back to dApp.\n\n%@")
        }
        /// Retry
        public static let retryButtonTitle = L10n.tr("Localizable", "dApp.response.failureAlert.retryButtonTitle", fallback: "Retry")
      }
    }
  }
  public enum DAppDetails {
    /// dApp Definition
    public static let definition = L10n.tr("Localizable", "dAppDetails.definition", fallback: "dApp Definition")
    /// Forget this dApp
    public static let forgetDapp = L10n.tr("Localizable", "dAppDetails.forgetDapp", fallback: "Forget this dApp")
    /// Cancel
    public static let forgetDappAlertCancel = L10n.tr("Localizable", "dAppDetails.forgetDappAlertCancel", fallback: "Cancel")
    /// Forget
    public static let forgetDappAlertConfirm = L10n.tr("Localizable", "dAppDetails.forgetDappAlertConfirm", fallback: "Forget")
    /// Do you really want to forget this dApp?
    public static let forgetDappAlertMessage = L10n.tr("Localizable", "dAppDetails.forgetDappAlertMessage", fallback: "Do you really want to forget this dApp?")
    /// Forget dApp?
    public static let forgetDappAlertTitle = L10n.tr("Localizable", "dAppDetails.forgetDappAlertTitle", fallback: "Forget dApp?")
    /// Missing description
    public static let missingDescription = L10n.tr("Localizable", "dAppDetails.missingDescription", fallback: "Missing description")
    /// Associated NFTs
    public static let nfts = L10n.tr("Localizable", "dAppDetails.nfts", fallback: "Associated NFTs")
    /// No Personas have been used to connect to this dApp.
    public static let noPersonasHeading = L10n.tr("Localizable", "dAppDetails.noPersonasHeading", fallback: "No Personas have been used to connect to this dApp.")
    /// Here are the Personas that you have previously used to connect to this dApp.
    public static let personaHeading = L10n.tr("Localizable", "dAppDetails.personaHeading", fallback: "Here are the Personas that you have previously used to connect to this dApp.")
    /// Associated Tokens
    public static let tokens = L10n.tr("Localizable", "dAppDetails.tokens", fallback: "Associated Tokens")
    /// Website
    public static let website = L10n.tr("Localizable", "dAppDetails.website", fallback: "Website")
  }
  public enum FactorSource {
    public enum Device {
      /// Unknown iPhone
      public static let iPhoneModelFallback = L10n.tr("Localizable", "factorSource.device.iPhoneModelFallback", fallback: "Unknown iPhone")
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
  public enum PersonaDetails {
    /// Here are the account names and addresses that you are currently sharing with %@.
    public static func accountSharingDescription(_ p1: Any) -> String {
      return L10n.tr("Localizable", "personaDetails.accountSharingDescription", String(describing: p1), fallback: "Here are the account names and addresses that you are currently sharing with %@.")
    }
    /// Disconnect Persona from this dApp
    public static let disconnectPersona = L10n.tr("Localizable", "personaDetails.disconnectPersona", fallback: "Disconnect Persona from this dApp")
    /// Cancel
    public static let disconnectPersonaAlertCancel = L10n.tr("Localizable", "personaDetails.disconnectPersonaAlertCancel", fallback: "Cancel")
    /// Disconnect
    public static let disconnectPersonaAlertConfirm = L10n.tr("Localizable", "personaDetails.disconnectPersonaAlertConfirm", fallback: "Disconnect")
    /// Do you really want to disconnect the Persona from this dApp?
    public static let disconnectPersonaAlertMessage = L10n.tr("Localizable", "personaDetails.disconnectPersonaAlertMessage", fallback: "Do you really want to disconnect the Persona from this dApp?")
    /// Disconnect Persona?
    public static let disconnectPersonaAlertTitle = L10n.tr("Localizable", "personaDetails.disconnectPersonaAlertTitle", fallback: "Disconnect Persona?")
    /// Edit Account Sharing
    public static let editAccountSharing = L10n.tr("Localizable", "personaDetails.editAccountSharing", fallback: "Edit Account Sharing")
    /// Edit Persona
    public static let editPersona = L10n.tr("Localizable", "personaDetails.editPersona", fallback: "Edit Persona")
    /// Email
    public static let emailHeading = L10n.tr("Localizable", "personaDetails.emailHeading", fallback: "Email")
    /// First Name
    public static let firstNameHeading = L10n.tr("Localizable", "personaDetails.firstNameHeading", fallback: "First Name")
    /// You are not sharing any personal data with %@
    public static func notSharingAnything(_ p1: Any) -> String {
      return L10n.tr("Localizable", "personaDetails.notSharingAnything", String(describing: p1), fallback: "You are not sharing any personal data with %@")
    }
    /// Here is the personal data that you are sharing with %@
    public static func personalDataSharingDescription(_ p1: Any) -> String {
      return L10n.tr("Localizable", "personaDetails.personalDataSharingDescription", String(describing: p1), fallback: "Here is the personal data that you are sharing with %@")
    }
    /// Persona Name
    public static let personaNameHeading = L10n.tr("Localizable", "personaDetails.personaNameHeading", fallback: "Persona Name")
    /// Second Name
    public static let secondNameHeading = L10n.tr("Localizable", "personaDetails.secondNameHeading", fallback: "Second Name")
    /// Zip Code
    public static let zipCodeHeading = L10n.tr("Localizable", "personaDetails.zipCodeHeading", fallback: "Zip Code")
  }
  public enum PersonaList {
    /// Create new persona
    public static let createNewPersonaButtonTitle = L10n.tr("Localizable", "personaList.createNewPersonaButtonTitle", fallback: "Create new persona")
    /// Here are all of your current Personas in your Wallet
    public static let subtitle = L10n.tr("Localizable", "personaList.subtitle", fallback: "Here are all of your current Personas in your Wallet")
    /// Personas
    public static let title = L10n.tr("Localizable", "personaList.title", fallback: "Personas")
  }
  public enum Personas {
    /// Create a New Persona
    public static let createNewPersonaButtonTitle = L10n.tr("Localizable", "personas.createNewPersonaButtonTitle", fallback: "Create a New Persona")
    /// Here are all of your current Personas in your Wallet
    public static let subtitle = L10n.tr("Localizable", "personas.subtitle", fallback: "Here are all of your current Personas in your Wallet")
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
    /// App Settings
    public static let appSettingsButtonTitle = L10n.tr("Localizable", "settings.appSettingsButtonTitle", fallback: "App Settings")
    /// Authorized dApps
    public static let authorizedDappsButtonTitle = L10n.tr("Localizable", "settings.authorizedDappsButtonTitle", fallback: "Authorized dApps")
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
    /// Delete Wallet Data
    public static let incompatibleProfileVersionAlertDeleteButton = L10n.tr("Localizable", "splash.incompatibleProfileVersionAlertDeleteButton", fallback: "Delete Wallet Data")
    /// For this Preview wallet version, you must delete your wallet data to continue.
    public static let incompatibleProfileVersionAlertMessage = L10n.tr("Localizable", "splash.incompatibleProfileVersionAlertMessage", fallback: "For this Preview wallet version, you must delete your wallet data to continue.")
    /// Wallet Data is Incompatible
    public static let incompatibleProfileVersionAlertTitle = L10n.tr("Localizable", "splash.incompatibleProfileVersionAlertTitle", fallback: "Wallet Data is Incompatible")
    /// This app requires your phone to have a passcode set up
    public static let passcodeNotSetUpMessage = L10n.tr("Localizable", "splash.passcodeNotSetUpMessage", fallback: "This app requires your phone to have a passcode set up")
    /// Passcode not set up
    public static let passcodeNotSetUpTitle = L10n.tr("Localizable", "splash.passcodeNotSetUpTitle", fallback: "Passcode not set up")
    public enum Alert {
      public enum PasscodeCheckFailed {
        /// Cancel
        public static let cancelButtonTitle = L10n.tr("Localizable", "splash.alert.passcodeCheckFailed.cancelButtonTitle", fallback: "Cancel")
        /// Passcode are not set up. Please update settings.
        public static let message = L10n.tr("Localizable", "splash.alert.passcodeCheckFailed.message", fallback: "Passcode are not set up. Please update settings.")
        /// Settings
        public static let settingsButtonTitle = L10n.tr("Localizable", "splash.alert.passcodeCheckFailed.settingsButtonTitle", fallback: "Settings")
        /// Warning
        public static let title = L10n.tr("Localizable", "splash.alert.passcodeCheckFailed.title", fallback: "Warning")
      }
    }
  }
  public enum TransactionSigning {
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
