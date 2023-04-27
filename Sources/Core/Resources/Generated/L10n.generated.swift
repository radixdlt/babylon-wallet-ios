// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum P2PLinks {
    /// Connector ID: %@
    public static func connectionID(_ p1: Any) -> String {
      return L10n.tr("Localizable", "P2PLinks.connectionID", String(describing: p1), fallback: "Connector ID: %@")
    }
    /// Link New Connector
    public static let newConnectionButtonTitle = L10n.tr("Localizable", "P2PLinks.newConnectionButtonTitle", fallback: "Link New Connector")
    /// Link New Connector
    public static let newConnectionTitle = L10n.tr("Localizable", "P2PLinks.newConnectionTitle", fallback: "Link New Connector")
    /// Your Radix Wallet is linked to the following desktop browser using the Connector browser extension.
    public static let p2PConnectionsSubtitle = L10n.tr("Localizable", "P2PLinks.P2PConnectionsSubtitle", fallback: "Your Radix Wallet is linked to the following desktop browser using the Connector browser extension.")
    /// Linked Connector
    public static let p2PConnectionsTitle = L10n.tr("Localizable", "P2PLinks.P2PConnectionsTitle", fallback: "Linked Connector")
    /// Send Test Msg
    public static let sendTestMessageButtonTitle = L10n.tr("Localizable", "P2PLinks.sendTestMessageButtonTitle", fallback: "Send Test Msg")
  }
  public enum AccountDetails {
    /// ID
    public static let id = L10n.tr("Localizable", "accountDetails.ID", fallback: "ID")
    /// Transfer
    public static let transferButtonTitle = L10n.tr("Localizable", "accountDetails.transferButtonTitle", fallback: "Transfer")
  }
  public enum AccountList {
    public enum Row {
      /// Copy
      public static let copyTitle = L10n.tr("Localizable", "accountList.row.copyTitle", fallback: "Copy")
      /// Legacy
      public static let legacyAccount = L10n.tr("Localizable", "accountList.row.legacyAccount", fallback: "Legacy")
      /// Apply Security Settings
      public static let securityPrompt = L10n.tr("Localizable", "accountList.row.securityPrompt", fallback: "Apply Security Settings")
    }
  }
  public enum AccountPreferences {
    /// Get RCnet XRD Test Tokens
    public static let faucetButtonTitle = L10n.tr("Localizable", "accountPreferences.faucetButtonTitle", fallback: "Get RCnet XRD Test Tokens")
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
      /// Validate seed phrase exists.
      public static let importOlympiaAccounts = L10n.tr("Localizable", "common.biometricsPrompt.importOlympiaAccounts", fallback: "Validate seed phrase exists.")
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
        /// Gateways
        public static let gateways = L10n.tr("Localizable", "createEntity.completion.destination.gateways", fallback: "Gateways")
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
    public enum Introduction {
      public enum Button {
        /// Continue
        public static let `continue` = L10n.tr("Localizable", "createEntity.introduction.button.continue", fallback: "Continue")
      }
      public enum Persona {
        /// A Persona is an identity that you own and control. You can have as many as you like.
        public static let subtitle0 = L10n.tr("Localizable", "createEntity.introduction.persona.subtitle0", fallback: "A Persona is an identity that you own and control. You can have as many as you like.")
        /// You will chosose Peronas to login to dApps, and dApps may request access to personal information associated with that Persona.
        public static let subtitle1 = L10n.tr("Localizable", "createEntity.introduction.persona.subtitle1", fallback: "You will chosose Peronas to login to dApps, and dApps may request access to personal information associated with that Persona.")
        /// Create a Persona
        public static let title = L10n.tr("Localizable", "createEntity.introduction.persona.title", fallback: "Create a Persona")
        public enum Button {
          /// Learn about Personas
          public static let tutorial = L10n.tr("Localizable", "createEntity.introduction.persona.button.tutorial", fallback: "Learn about Personas")
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
    public enum AccountPermission {
      /// Account Permission
      public static let title = L10n.tr("Localizable", "dApp.accountPermission.title", fallback: "Account Permission")
      /// You can update this permission in your settings at any time.
      public static let updateInSettingsExplanation = L10n.tr("Localizable", "dApp.accountPermission.updateInSettingsExplanation", fallback: "You can update this permission in your settings at any time.")
      public enum Button {
        /// Continue
        public static let `continue` = L10n.tr("Localizable", "dApp.accountPermission.button.continue", fallback: "Continue")
      }
      public enum NumberOfAccounts {
        /// %d or more accounts
        public static func atLeast(_ p1: Int) -> String {
          return L10n.tr("Localizable", "dApp.accountPermission.numberOfAccounts.atLeast", p1, fallback: "%d or more accounts")
        }
        /// Any number of accounts
        public static let atLeastZero = L10n.tr("Localizable", "dApp.accountPermission.numberOfAccounts.atLeastZero", fallback: "Any number of accounts")
        /// %d accounts
        public static func exactly(_ p1: Int) -> String {
          return L10n.tr("Localizable", "dApp.accountPermission.numberOfAccounts.exactly", p1, fallback: "%d accounts")
        }
        /// 1 account
        public static let exactlyOne = L10n.tr("Localizable", "dApp.accountPermission.numberOfAccounts.exactlyOne", fallback: "1 account")
      }
      public enum Subtitle {
        /// always
        public static let always = L10n.tr("Localizable", "dApp.accountPermission.subtitle.always", fallback: "always")
        public enum Explanation {
          ///  is requesting permission to 
          public static let first = L10n.tr("Localizable", "dApp.accountPermission.subtitle.explanation.first", fallback: " is requesting permission to ")
          ///  be able to view account information when you login with this Persona.
          public static let second = L10n.tr("Localizable", "dApp.accountPermission.subtitle.explanation.second", fallback: " be able to view account information when you login with this Persona.")
        }
      }
    }
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
        public static let message = L10n.tr("Localizable", "dApp.metadataLoading.errorAlert.message", fallback: "Danger! Bad dApp config or you're being spoofed!")
        /// Retry
        public static let retryButtonTitle = L10n.tr("Localizable", "dApp.metadataLoading.errorAlert.retryButtonTitle", fallback: "Retry")
      }
    }
    public enum OneTimePersonaData {
      /// Choose the data to provide
      public static let chooseDataToProvide = L10n.tr("Localizable", "dApp.oneTimePersonaData.chooseDataToProvide", fallback: "Choose the data to provide")
      /// One-Time Data Request
      public static let title = L10n.tr("Localizable", "dApp.oneTimePersonaData.title", fallback: "One-Time Data Request")
      public enum Button {
        /// Continue
        public static let `continue` = L10n.tr("Localizable", "dApp.oneTimePersonaData.button.continue", fallback: "Continue")
      }
      public enum Subtitle {
        /// just one time.
        public static let justOneTime = L10n.tr("Localizable", "dApp.oneTimePersonaData.subtitle.justOneTime", fallback: "just one time.")
        public enum Explanation {
          ///  is requesting that you provide some pieces of personal data 
          public static let first = L10n.tr("Localizable", "dApp.oneTimePersonaData.subtitle.explanation.first", fallback: " is requesting that you provide some pieces of personal data ")
        }
      }
    }
    public enum PersonaDataBox {
      /// Required information:
      public static let requiredInformation = L10n.tr("Localizable", "dApp.personaDataBox.requiredInformation", fallback: "Required information:")
      public enum Button {
        /// Edit
        public static let edit = L10n.tr("Localizable", "dApp.personaDataBox.button.edit", fallback: "Edit")
      }
    }
    public enum PersonaDataPermission {
      /// Personal Data Permission
      public static let title = L10n.tr("Localizable", "dApp.personaDataPermission.title", fallback: "Personal Data Permission")
      /// You can update this permission in your settings at any time.
      public static let updateInSettingsExplanation = L10n.tr("Localizable", "dApp.personaDataPermission.updateInSettingsExplanation", fallback: "You can update this permission in your settings at any time.")
      public enum Button {
        /// Continue
        public static let `continue` = L10n.tr("Localizable", "dApp.personaDataPermission.button.continue", fallback: "Continue")
      }
      public enum Subtitle {
        /// always
        public static let always = L10n.tr("Localizable", "dApp.personaDataPermission.subtitle.always", fallback: "always")
        public enum Explanation {
          ///  is requesting permission to 
          public static let first = L10n.tr("Localizable", "dApp.personaDataPermission.subtitle.explanation.first", fallback: " is requesting permission to ")
          ///  be able to view the following personal data when you login with this Persona.
          public static let second = L10n.tr("Localizable", "dApp.personaDataPermission.subtitle.explanation.second", fallback: " be able to view the following personal data when you login with this Persona.")
        }
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
        public static let message = L10n.tr("Localizable", "dApp.request.specifiedPersonaNotFoundError.message", fallback: "Persona specified by dApp does not exist.")
      }
    }
    public enum Response {
      public enum FailureAlert {
        /// Cancel
        public static let cancelButtonTitle = L10n.tr("Localizable", "dApp.response.failureAlert.cancelButtonTitle", fallback: "Cancel")
        /// Failed to send response payload back to dApp.
        public static let message = L10n.tr("Localizable", "dApp.response.failureAlert.message", fallback: "Failed to send response payload back to dApp.")
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
  public enum EditPersona {
    public enum AddAField {
      /// Select from the following fields to add them to this persona.
      public static let explanation = L10n.tr("Localizable", "editPersona.addAField.explanation", fallback: "Select from the following fields to add them to this persona.")
      /// Add a Field
      public static let title = L10n.tr("Localizable", "editPersona.addAField.title", fallback: "Add a Field")
      public enum Button {
        /// Add
        public static let add = L10n.tr("Localizable", "editPersona.addAField.button.add", fallback: "Add")
      }
    }
    public enum Button {
      /// Add a Field
      public static let addAField = L10n.tr("Localizable", "editPersona.button.addAField", fallback: "Add a Field")
      /// Save
      public static let save = L10n.tr("Localizable", "editPersona.button.save", fallback: "Save")
    }
    public enum CloseConfirmationDialog {
      /// Are you sure you want to discard changes to this persona?
      public static let message = L10n.tr("Localizable", "editPersona.closeConfirmationDialog.message", fallback: "Are you sure you want to discard changes to this persona?")
      public enum Button {
        /// Discard Changes
        public static let discardChanges = L10n.tr("Localizable", "editPersona.closeConfirmationDialog.button.discardChanges", fallback: "Discard Changes")
        /// Keep Editing
        public static let keepEditing = L10n.tr("Localizable", "editPersona.closeConfirmationDialog.button.keepEditing", fallback: "Keep Editing")
      }
    }
    public enum InputField {
      public enum Error {
        public enum EmailAddress {
          /// Invalid email address
          public static let invalid = L10n.tr("Localizable", "editPersona.inputField.error.emailAddress.invalid", fallback: "Invalid email address")
        }
        public enum General {
          /// Required field for this dApp
          public static let requiredByDapp = L10n.tr("Localizable", "editPersona.inputField.error.general.requiredByDapp", fallback: "Required field for this dApp")
        }
        public enum PersonaLabel {
          /// Label cannot be blank
          public static let blank = L10n.tr("Localizable", "editPersona.inputField.error.personaLabel.blank", fallback: "Label cannot be blank")
        }
      }
      public enum Heading {
        public enum General {
          /// Required by dApp
          public static let requiredByDapp = L10n.tr("Localizable", "editPersona.inputField.heading.general.requiredByDapp", fallback: "Required by dApp")
        }
      }
    }
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
  public enum GatewaySettings {
    /// Add New Gateway
    public static let addNewGatewayButtonTitle = L10n.tr("Localizable", "gatewaySettings.addNewGatewayButtonTitle", fallback: "Add New Gateway")
    /// RCnet Gateway
    public static let rcNetGateway = L10n.tr("Localizable", "gatewaySettings.rcNetGateway", fallback: "RCnet Gateway")
    /// Choose the gateway your wallet will use to connect. Only change this if you know what you’re doing.
    public static let subtitle = L10n.tr("Localizable", "gatewaySettings.subtitle", fallback: "Choose the gateway your wallet will use to connect. Only change this if you know what you’re doing.")
    /// Gateways
    public static let title = L10n.tr("Localizable", "gatewaySettings.title", fallback: "Gateways")
    public enum AddNewGateway {
      /// Add Gateway
      public static let addGatewayButtonTitle = L10n.tr("Localizable", "gatewaySettings.addNewGateway.addGatewayButtonTitle", fallback: "Add Gateway")
      /// Enter a Gateway URL
      public static let subtitle = L10n.tr("Localizable", "gatewaySettings.addNewGateway.subtitle", fallback: "Enter a Gateway URL")
      /// Enter full URL
      public static let textFieldPlaceholder = L10n.tr("Localizable", "gatewaySettings.addNewGateway.textFieldPlaceholder", fallback: "Enter full URL")
      /// Add New Gateway
      public static let title = L10n.tr("Localizable", "gatewaySettings.addNewGateway.title", fallback: "Add New Gateway")
      public enum Error {
        /// This url is already added
        public static let duplicateURL = L10n.tr("Localizable", "gatewaySettings.addNewGateway.error.duplicateURL", fallback: "This url is already added")
        /// No Gateway found at specified URL
        public static let noGatewayFound = L10n.tr("Localizable", "gatewaySettings.addNewGateway.error.noGatewayFound", fallback: "No Gateway found at specified URL")
      }
    }
    public enum RemoveGatewayAlert {
      /// Cancel
      public static let cancelButtonTitle = L10n.tr("Localizable", "gatewaySettings.removeGatewayAlert.cancelButtonTitle", fallback: "Cancel")
      /// You will no longer be able to connect to this Gateway
      public static let message = L10n.tr("Localizable", "gatewaySettings.removeGatewayAlert.message", fallback: "You will no longer be able to connect to this Gateway")
      /// Remove
      public static let removeButtonTitle = L10n.tr("Localizable", "gatewaySettings.removeGatewayAlert.removeButtonTitle", fallback: "Remove")
      /// Remove Gateway
      public static let title = L10n.tr("Localizable", "gatewaySettings.removeGatewayAlert.title", fallback: "Remove Gateway")
    }
    public enum WhatIsAGateway {
      /// What is a Gateway
      public static let buttonText = L10n.tr("Localizable", "gatewaySettings.whatIsAGateway.buttonText", fallback: "What is a Gateway")
      /// This is a placeholder for gateway explanation text
      public static let explanation = L10n.tr("Localizable", "gatewaySettings.whatIsAGateway.explanation", fallback: "This is a placeholder for gateway explanation text")
      /// What is a Gateway
      public static let title = L10n.tr("Localizable", "gatewaySettings.whatIsAGateway.title", fallback: "What is a Gateway")
    }
  }
  public enum GeneralSettings {
    /// App Settings
    public static let title = L10n.tr("Localizable", "generalSettings.title", fallback: "App Settings")
    public enum DeveloperMode {
      /// Warning: Disables website validity checks
      public static let subtitle = L10n.tr("Localizable", "generalSettings.developerMode.subtitle", fallback: "Warning: Disables website validity checks")
      /// Developer Mode
      public static let title = L10n.tr("Localizable", "generalSettings.developerMode.title", fallback: "Developer Mode")
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
  public enum ImportLegacyWallet {
    public enum Completion {
      /// Imported #%@ accounts.
      public static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "importLegacyWallet.completion.title", String(describing: p1), fallback: "Imported #%@ accounts.")
      }
      public enum Button {
        /// Okay
        public static let finish = L10n.tr("Localizable", "importLegacyWallet.completion.button.finish", fallback: "Okay")
      }
    }
    public enum Flow {
      /// Import Legacy Wallet
      public static let navigationTitle = L10n.tr("Localizable", "importLegacyWallet.flow.navigationTitle", fallback: "Import Legacy Wallet")
    }
    public enum ScanQRCodes {
      /// Open your Olympia Wallet and export the accounts you would like to migrate to this wallet.
      public static let scanInstructions = L10n.tr("Localizable", "importLegacyWallet.scanQRCodes.scanInstructions", fallback: "Open your Olympia Wallet and export the accounts you would like to migrate to this wallet.")
    }
    public enum SelectAccountsToImport {
      public enum AccountRow {
        public enum Label {
          /// Type
          public static let accountType = L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.accountRow.label.accountType", fallback: "Type")
          /// Path
          public static let derivationPath = L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.accountRow.label.derivationPath", fallback: "Path")
          /// Name
          public static let name = L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.accountRow.label.name", fallback: "Name")
          /// Olympia Address
          public static let olympiaAddress = L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.accountRow.label.olympiaAddress", fallback: "Olympia Address")
        }
        public enum Value {
          /// Unnamned
          public static let nameFallback = L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.accountRow.value.nameFallback", fallback: "Unnamned")
        }
      }
      public enum Button {
        /// Deselect all
        public static let deselectAll = L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.button.deselectAll", fallback: "Deselect all")
        /// Import %@ accounts
        public static func importManyAccounts(_ p1: Any) -> String {
          return L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.button.importManyAccounts", String(describing: p1), fallback: "Import %@ accounts")
        }
        /// Import one account
        public static let importOneAcccount = L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.button.importOneAcccount", fallback: "Import one account")
        /// Import accounts
        public static let importZeroAccounts = L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.button.importZeroAccounts", fallback: "Import accounts")
        /// Select all non imported
        public static let selectAllNonImported = L10n.tr("Localizable", "importLegacyWallet.selectAccountsToImport.button.selectAllNonImported", fallback: "Select all non imported")
      }
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
    /// Remove Authorization
    public static let deauthorizePersona = L10n.tr("Localizable", "personaDetails.deauthorizePersona", fallback: "Remove Authorization")
    /// Cancel
    public static let deauthorizePersonaAlertCancel = L10n.tr("Localizable", "personaDetails.deauthorizePersonaAlertCancel", fallback: "Cancel")
    /// Confirm
    public static let deauthorizePersonaAlertConfirm = L10n.tr("Localizable", "personaDetails.deauthorizePersonaAlertConfirm", fallback: "Confirm")
    /// This dApp will no longer have authorization to see data associated with this persona, unless you choose to login with it again in the future.
    public static let deauthorizePersonaAlertMessage = L10n.tr("Localizable", "personaDetails.deauthorizePersonaAlertMessage", fallback: "This dApp will no longer have authorization to see data associated with this persona, unless you choose to login with it again in the future.")
    /// Remove Authorization
    public static let deauthorizePersonaAlertTitle = L10n.tr("Localizable", "personaDetails.deauthorizePersonaAlertTitle", fallback: "Remove Authorization")
    /// Edit Account Sharing
    public static let editAccountSharing = L10n.tr("Localizable", "personaDetails.editAccountSharing", fallback: "Edit Account Sharing")
    /// Edit Persona
    public static let editPersona = L10n.tr("Localizable", "personaDetails.editPersona", fallback: "Edit Persona")
    /// Email Address
    public static let emailAddressHeading = L10n.tr("Localizable", "personaDetails.emailAddressHeading", fallback: "Email Address")
    /// First Name
    public static let firstNameHeading = L10n.tr("Localizable", "personaDetails.firstNameHeading", fallback: "First Name")
    /// Last Name
    public static let lastNameHeading = L10n.tr("Localizable", "personaDetails.lastNameHeading", fallback: "Last Name")
    /// You are not sharing any personal data with %@
    public static func notSharingAnything(_ p1: Any) -> String {
      return L10n.tr("Localizable", "personaDetails.notSharingAnything", String(describing: p1), fallback: "You are not sharing any personal data with %@")
    }
    /// Here is the personal data that you are sharing with %@
    public static func personaDataSharingDescription(_ p1: Any) -> String {
      return L10n.tr("Localizable", "personaDetails.personaDataSharingDescription", String(describing: p1), fallback: "Here is the personal data that you are sharing with %@")
    }
    /// Persona Name
    public static let personaNameHeading = L10n.tr("Localizable", "personaDetails.personaNameHeading", fallback: "Persona Name")
    /// Phone Number
    public static let phoneNumberHeading = L10n.tr("Localizable", "personaDetails.phoneNumberHeading", fallback: "Phone Number")
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
    /// Authorized dApps
    public static let authorizedDappsButtonTitle = L10n.tr("Localizable", "settings.authorizedDappsButtonTitle", fallback: "Authorized dApps")
    /// Close
    public static let closeButtonTitle = L10n.tr("Localizable", "settings.closeButtonTitle", fallback: "Close")
    /// Delete Wallet Data
    public static let deleteAllButtonTitle = L10n.tr("Localizable", "settings.deleteAllButtonTitle", fallback: "Delete Wallet Data")
    /// Linked Connector
    public static let desktopConnectionsButtonTitle = L10n.tr("Localizable", "settings.desktopConnectionsButtonTitle", fallback: "Linked Connector")
    /// Gateways
    public static let gatewaysButtonTitle = L10n.tr("Localizable", "settings.gatewaysButtonTitle", fallback: "Gateways")
    /// App Settings
    public static let generalSettingsButtonTitle = L10n.tr("Localizable", "settings.generalSettingsButtonTitle", fallback: "App Settings")
    /// Import from a Legacy Wallet
    public static let importLegacyWallet = L10n.tr("Localizable", "settings.importLegacyWallet", fallback: "Import from a Legacy Wallet")
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
        /// Passcode are not set up. Please update settings.
        public static let message = L10n.tr("Localizable", "splash.alert.passcodeCheckFailed.message", fallback: "Passcode are not set up. Please update settings.")
        /// Retry
        public static let retryButtonTitle = L10n.tr("Localizable", "splash.alert.passcodeCheckFailed.retryButtonTitle", fallback: "Retry")
        /// Settings
        public static let settingsButtonTitle = L10n.tr("Localizable", "splash.alert.passcodeCheckFailed.settingsButtonTitle", fallback: "Settings")
        /// Warning
        public static let title = L10n.tr("Localizable", "splash.alert.passcodeCheckFailed.title", fallback: "Warning")
      }
    }
  }
  public enum TransactionReview {
    /// Approve
    public static let approveButtonTitle = L10n.tr("Localizable", "transactionReview.approveButtonTitle", fallback: "Approve")
    /// Customize Guarantees
    public static let customizeGuaranteesButtonTitle = L10n.tr("Localizable", "transactionReview.customizeGuaranteesButtonTitle", fallback: "Customize Guarantees")
    /// Depositing
    public static let depositsHeading = L10n.tr("Localizable", "transactionReview.depositsHeading", fallback: "Depositing")
    /// Estimated
    public static let estimated = L10n.tr("Localizable", "transactionReview.estimated", fallback: "Estimated")
    /// Account
    public static let externalAccountName = L10n.tr("Localizable", "transactionReview.externalAccountName", fallback: "Account")
    /// Guaranteed
    public static let guaranteed = L10n.tr("Localizable", "transactionReview.guaranteed", fallback: "Guaranteed")
    /// Message
    public static let messageHeading = L10n.tr("Localizable", "transactionReview.messageHeading", fallback: "Message")
    /// Presenting
    public static let presentingHeading = L10n.tr("Localizable", "transactionReview.presentingHeading", fallback: "Presenting")
    /// Raw Transaction
    public static let rawTransactionTitle = L10n.tr("Localizable", "transactionReview.rawTransactionTitle", fallback: "Raw Transaction")
    /// Sending to
    public static let sendingToHeading = L10n.tr("Localizable", "transactionReview.sendingToHeading", fallback: "Sending to")
    /// Review Transaction
    public static let title = L10n.tr("Localizable", "transactionReview.title", fallback: "Review Transaction")
    /// Unknown
    public static let unknown = L10n.tr("Localizable", "transactionReview.unknown", fallback: "Unknown")
    /// Using dApps
    public static let usingDappsHeading = L10n.tr("Localizable", "transactionReview.usingDappsHeading", fallback: "Using dApps")
    /// Withdrawing
    public static let withdrawalsHeading = L10n.tr("Localizable", "transactionReview.withdrawalsHeading", fallback: "Withdrawing")
    public enum Guarantees {
      /// Apply
      public static let applyButtonText = L10n.tr("Localizable", "transactionReview.guarantees.applyButtonText", fallback: "Apply")
      ///  Protect yourself by setting guaranteed minimums for estimated deposits
      public static let explanationText = L10n.tr("Localizable", "transactionReview.guarantees.explanationText", fallback: " Protect yourself by setting guaranteed minimums for estimated deposits")
      ///  How do Guarantees work 
      public static let explanationTitle = L10n.tr("Localizable", "transactionReview.guarantees.explanationTitle", fallback: " How do Guarantees work ")
      /// Protect yourself by setting guaranteed minimums for estimated deposits
      public static let headerText = L10n.tr("Localizable", "transactionReview.guarantees.headerText", fallback: "Protect yourself by setting guaranteed minimums for estimated deposits")
      /// How do Guarantees work
      public static let infoButtonText = L10n.tr("Localizable", "transactionReview.guarantees.infoButtonText", fallback: "How do Guarantees work")
      /// Set guaranteed minimum %%
      public static let setText = L10n.tr("Localizable", "transactionReview.guarantees.setText", fallback: "Set guaranteed minimum %%")
      /// Customize Guarantees
      public static let title = L10n.tr("Localizable", "transactionReview.guarantees.title", fallback: "Customize Guarantees")
    }
    public enum NetworkFee {
      /// The network is currently congested. Add a tip to speed up your transfer.
      public static let congestedText = L10n.tr("Localizable", "transactionReview.networkFee.congestedText", fallback: "The network is currently congested. Add a tip to speed up your transfer.")
      /// Customize
      public static let customizeButtonTitle = L10n.tr("Localizable", "transactionReview.networkFee.customizeButtonTitle", fallback: "Customize")
      /// Network Fee
      public static let heading = L10n.tr("Localizable", "transactionReview.networkFee.heading", fallback: "Network Fee")
    }
    public enum UsingDapps {
      /// %d Unknown Components
      public static func unknownComponents(_ p1: Int) -> String {
        return L10n.tr("Localizable", "transactionReview.usingDapps.unknownComponents", p1, fallback: "%d Unknown Components")
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
