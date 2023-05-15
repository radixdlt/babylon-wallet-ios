// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
  public enum Account {
    /// Badges
    public static let badges = L10n.tr("Localizable", "account_badges", fallback: "Badges")
    /// NFTs
    public static let nfts = L10n.tr("Localizable", "account_nfts", fallback: "NFTs")
    /// Pool Units
    public static let poolUnits = L10n.tr("Localizable", "account_poolUnits", fallback: "Pool Units")
    /// Tokens
    public static let tokens = L10n.tr("Localizable", "account_tokens", fallback: "Tokens")
    /// Transfer
    public static let transfer = L10n.tr("Localizable", "account_transfer", fallback: "Transfer")
  }
  public enum AccountSettings {
    /// Account Color
    public static let accountColor = L10n.tr("Localizable", "accountSettings_accountColor", fallback: "Account Color")
    /// Select from a list of unique colors
    public static let accountColorSubtitle = L10n.tr("Localizable", "accountSettings_accountColorSubtitle", fallback: "Select from a list of unique colors")
    /// Account Label
    public static let accountLabel = L10n.tr("Localizable", "accountSettings_accountLabel", fallback: "Account Label")
    /// Account Security
    public static let accountSecurity = L10n.tr("Localizable", "accountSettings_accountSecurity", fallback: "Account Security")
    /// Set how you want this account to work
    public static let accountSecuritySubtitle = L10n.tr("Localizable", "accountSettings_accountSecuritySubtitle", fallback: "Set how you want this account to work")
    /// Get RCnet XRD Test Tokens
    public static let getXrdTestTokens = L10n.tr("Localizable", "accountSettings_getXrdTestTokens", fallback: "Get RCnet XRD Test Tokens")
    /// Hide Account
    public static let hideAccount = L10n.tr("Localizable", "accountSettings_hideAccount", fallback: "Hide Account")
    /// This may take several seconds, please wait for completion
    public static let loadingPrompt = L10n.tr("Localizable", "accountSettings_loadingPrompt", fallback: "This may take several seconds, please wait for completion")
    /// Personalize this account
    public static let personalizeHeading = L10n.tr("Localizable", "accountSettings_personalizeHeading", fallback: "Personalize this account")
    /// Set how you want this account to work
    public static let setBehaviorHeading = L10n.tr("Localizable", "accountSettings_setBehaviorHeading", fallback: "Set how you want this account to work")
    /// Show Assets with Tags
    public static let showAssets = L10n.tr("Localizable", "accountSettings_showAssets", fallback: "Show Assets with Tags")
    /// Select which tags to show for assets in this account
    public static let showAssetsSubtitle = L10n.tr("Localizable", "accountSettings_showAssetsSubtitle", fallback: "Select which tags to show for assets in this account")
    /// Third-party Deposits
    public static let thirdPartyDeposits = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits", fallback: "Third-party Deposits")
    /// Account Settings
    public static let title = L10n.tr("Localizable", "accountSettings_title", fallback: "Account Settings")
    public enum AccountColor {
      /// Selected
      public static let selected = L10n.tr("Localizable", "accountSettings_accountColor_selected", fallback: "Selected")
      /// Select the background color for this Account
      public static let text = L10n.tr("Localizable", "accountSettings_accountColor_text", fallback: "Select the background color for this Account")
    }
    public enum Behaviors {
      /// Naming and information about this asset can be changed.
      public static let informationChangeable = L10n.tr("Localizable", "accountSettings_behaviors_informationChangeable", fallback: "Naming and information about this asset can be changed.")
      /// Anyone can change naming and information about this asset.
      public static let informationChangeableByAnyone = L10n.tr("Localizable", "accountSettings_behaviors_informationChangeableByAnyone", fallback: "Anyone can change naming and information about this asset.")
      /// Movement of this asset can be restricted in the future.
      public static let movementRestrictableInFuture = L10n.tr("Localizable", "accountSettings_behaviors_movementRestrictableInFuture", fallback: "Movement of this asset can be restricted in the future.")
      /// Anyone can restrict movement of this token in the future.
      public static let movementRestrictableInFutureByAnyone = L10n.tr("Localizable", "accountSettings_behaviors_movementRestrictableInFutureByAnyone", fallback: "Anyone can restrict movement of this token in the future.")
      /// Movement of this asset is restricted.
      public static let movementRestricted = L10n.tr("Localizable", "accountSettings_behaviors_movementRestricted", fallback: "Movement of this asset is restricted.")
      /// Data that is set on these NFTs can be changed.
      public static let nftDataChangeable = L10n.tr("Localizable", "accountSettings_behaviors_nftDataChangeable", fallback: "Data that is set on these NFTs can be changed.")
      /// Anyone can change data that is set on these NFTs.
      public static let nftDataChangeableByAnyone = L10n.tr("Localizable", "accountSettings_behaviors_nftDataChangeableByAnyone", fallback: "Anyone can change data that is set on these NFTs.")
      /// Anyone can remove this asset from accounts and dApps.
      public static let removableByAnyone = L10n.tr("Localizable", "accountSettings_behaviors_removableByAnyone", fallback: "Anyone can remove this asset from accounts and dApps.")
      /// A third party can remove this asset from accounts and dApps.
      public static let removableByThirdParty = L10n.tr("Localizable", "accountSettings_behaviors_removableByThirdParty", fallback: "A third party can remove this asset from accounts and dApps.")
      /// This is a simple asset
      public static let simpleAsset = L10n.tr("Localizable", "accountSettings_behaviors_simpleAsset", fallback: "This is a simple asset")
      /// The supply of this asset can be decreased.
      public static let supplyDecreasable = L10n.tr("Localizable", "accountSettings_behaviors_supplyDecreasable", fallback: "The supply of this asset can be decreased.")
      /// Anyone can decrease the supply of this asset.
      public static let supplyDecreasableByAnyone = L10n.tr("Localizable", "accountSettings_behaviors_supplyDecreasableByAnyone", fallback: "Anyone can decrease the supply of this asset.")
      /// The supply of this asset can be increased or decreased.
      public static let supplyFlexible = L10n.tr("Localizable", "accountSettings_behaviors_supplyFlexible", fallback: "The supply of this asset can be increased or decreased.")
      /// Anyone can increase or decrease the supply of this asset.
      public static let supplyFlexibleByAnyone = L10n.tr("Localizable", "accountSettings_behaviors_supplyFlexibleByAnyone", fallback: "Anyone can increase or decrease the supply of this asset.")
      /// The supply of this asset can be increased.
      public static let supplyIncreasable = L10n.tr("Localizable", "accountSettings_behaviors_supplyIncreasable", fallback: "The supply of this asset can be increased.")
      /// Anyone can increase the supply of this asset.
      public static let supplyIncreasableByAnyone = L10n.tr("Localizable", "accountSettings_behaviors_supplyIncreasableByAnyone", fallback: "Anyone can increase the supply of this asset.")
    }
    public enum HideAccount {
      /// Hide Account
      public static let button = L10n.tr("Localizable", "accountSettings_hideAccount_button", fallback: "Hide Account")
      /// Hide this account in your wallet? You can always unhide it from the main application settings.
      public static let message = L10n.tr("Localizable", "accountSettings_hideAccount_message", fallback: "Hide this account in your wallet? You can always unhide it from the main application settings.")
      /// Hide This Account
      public static let title = L10n.tr("Localizable", "accountSettings_hideAccount_title", fallback: "Hide This Account")
    }
    public enum RenameAccount {
      /// Enter a new label for this account
      public static let subtitle = L10n.tr("Localizable", "accountSettings_renameAccount_subtitle", fallback: "Enter a new label for this account")
      /// Rename Account
      public static let title = L10n.tr("Localizable", "accountSettings_renameAccount_title", fallback: "Rename Account")
    }
    public enum ShowAssets {
      /// Recommended
      public static let recommended = L10n.tr("Localizable", "accountSettings_showAssets_recommended", fallback: "Recommended")
      /// Select the ones you’d like shown on all your assets.
      public static let selectShown = L10n.tr("Localizable", "accountSettings_showAssets_selectShown", fallback: "Select the ones you’d like shown on all your assets.")
      /// Asset creators can add tags to them. You can choose which tags you want to see in this account.
      public static let text = L10n.tr("Localizable", "accountSettings_showAssets_text", fallback: "Asset creators can add tags to them. You can choose which tags you want to see in this account.")
    }
    public enum ThirdPartyDeposits {
      /// Accept all deposits
      public static let acceptAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAll", fallback: "Accept all deposits")
      /// Allow third-parties to deposit any asset
      public static let acceptAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAllSubtitle", fallback: "Allow third-parties to deposit any asset")
      /// Deny all
      public static let denyAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAll", fallback: "Deny all")
      /// Deny all third-parties deposits
      public static let denyAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAllSubtitle", fallback: "Deny all third-parties deposits")
      /// Only accept known
      public static let onlyKnown = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_onlyKnown", fallback: "Only accept known")
      /// Allow  third-parties to deposit only assets this account already holds
      public static let onlyKnownSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_onlyKnownSubtitle", fallback: "Allow  third-parties to deposit only assets this account already holds")
      /// This account will not be able to receive “air drops” or be used by a trusted contact to assist with account recovery.
      public static let text = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_text", fallback: "This account will not be able to receive “air drops” or be used by a trusted contact to assist with account recovery.")
    }
  }
  public enum AddressAction {
    /// Copy Address
    public static let copyAddress = L10n.tr("Localizable", "addressAction_copyAddress", fallback: "Copy Address")
    /// Copy NFT ID
    public static let copyNftId = L10n.tr("Localizable", "addressAction_copyNftId", fallback: "Copy NFT ID")
    /// Copy Transaction ID
    public static let copyTransactionId = L10n.tr("Localizable", "addressAction_copyTransactionId", fallback: "Copy Transaction ID")
    /// There is no web browser installed in this device
    public static let noWebBrowserInstalled = L10n.tr("Localizable", "addressAction_noWebBrowserInstalled", fallback: "There is no web browser installed in this device")
    /// View on Radix Dashboard
    public static let viewOnDashboard = L10n.tr("Localizable", "addressAction_viewOnDashboard", fallback: "View on Radix Dashboard")
  }
  public enum AppSettings {
    /// Customize your Radix Wallet
    public static let subtitle = L10n.tr("Localizable", "appSettings_subtitle", fallback: "Customize your Radix Wallet")
    /// App Settings
    public static let title = L10n.tr("Localizable", "appSettings_title", fallback: "App Settings")
    public enum DeveloperMode {
      /// Warning: Disables website validity checks
      public static let subtitle = L10n.tr("Localizable", "appSettings_developerMode_subtitle", fallback: "Warning: Disables website validity checks")
      /// Developer Mode
      public static let title = L10n.tr("Localizable", "appSettings_developerMode_title", fallback: "Developer Mode")
    }
  }
  public enum AssetDetails {
    /// Associated dApps
    public static let associatedDapps = L10n.tr("Localizable", "assetDetails_associatedDapps", fallback: "Associated dApps")
    /// Behavior
    public static let behavior = L10n.tr("Localizable", "assetDetails_behavior", fallback: "Behavior")
    /// Current Supply
    public static let currentSupply = L10n.tr("Localizable", "assetDetails_currentSupply", fallback: "Current Supply")
    /// Name
    public static let name = L10n.tr("Localizable", "assetDetails_name", fallback: "Name")
    /// Address
    public static let resourceAddress = L10n.tr("Localizable", "assetDetails_resourceAddress", fallback: "Address")
    /// Unknown
    public static let supplyUnkown = L10n.tr("Localizable", "assetDetails_supplyUnkown", fallback: "Unknown")
    public enum NFTDetails {
      /// ID
      public static let id = L10n.tr("Localizable", "assetDetails_NFTDetails_id", fallback: "ID")
      /// Name
      public static let name = L10n.tr("Localizable", "assetDetails_NFTDetails_name", fallback: "Name")
      /// %d NFTs
      public static func nftPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_NFTDetails_nftPlural", p1, fallback: "%d NFTs")
      }
      /// You have no NFTs
      public static let noNfts = L10n.tr("Localizable", "assetDetails_NFTDetails_noNfts", fallback: "You have no NFTs")
      /// %d of %d
      public static func ownedOfTotal(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_NFTDetails_ownedOfTotal", p1, p2, fallback: "%d of %d")
      }
      /// Name
      public static let resourceName = L10n.tr("Localizable", "assetDetails_NFTDetails_resourceName", fallback: "Name")
      /// What are NFTs?
      public static let whatAreNfts = L10n.tr("Localizable", "assetDetails_NFTDetails_whatAreNfts", fallback: "What are NFTs?")
    }
    public enum AssetBehavior {
      /// Naming and information about this asset can be changed.
      public static let canChangeName = L10n.tr("Localizable", "assetDetails_assetBehavior_canChangeName", fallback: "Naming and information about this asset can be changed.")
      /// The supply of this asset can be increased or decreased
      public static let canIncreaseSupply = L10n.tr("Localizable", "assetDetails_assetBehavior_canIncreaseSupply", fallback: "The supply of this asset can be increased or decreased")
      /// Movement of this asset can be restricted in the future.
      public static let canRestrictMovement = L10n.tr("Localizable", "assetDetails_assetBehavior_canRestrictMovement", fallback: "Movement of this asset can be restricted in the future.")
    }
    public enum BadgeDetails {
      /// You have no badges
      public static let noBadges = L10n.tr("Localizable", "assetDetails_badgeDetails_noBadges", fallback: "You have no badges")
      /// What are badges?
      public static let whatAreBadges = L10n.tr("Localizable", "assetDetails_badgeDetails_whatAreBadges", fallback: "What are badges?")
    }
    public enum HideAsset {
      /// Hide Asset
      public static let button = L10n.tr("Localizable", "assetDetails_hideAsset_button", fallback: "Hide Asset")
      /// Hide this asset in your Radix Wallet? You can always unhide it in your account settings.
      public static let message = L10n.tr("Localizable", "assetDetails_hideAsset_message", fallback: "Hide this asset in your Radix Wallet? You can always unhide it in your account settings.")
      /// Hide Asset
      public static let title = L10n.tr("Localizable", "assetDetails_hideAsset_title", fallback: "Hide Asset")
    }
    public enum PoolUnitDetails {
      /// You have no Pool units
      public static let noPoolUnits = L10n.tr("Localizable", "assetDetails_poolUnitDetails_noPoolUnits", fallback: "You have no Pool units")
      /// What are Pool units?
      public static let whatArePoolUnits = L10n.tr("Localizable", "assetDetails_poolUnitDetails_whatArePoolUnits", fallback: "What are Pool units?")
    }
    public enum TokenDetails {
      /// You have no Tokens
      public static let noTokens = L10n.tr("Localizable", "assetDetails_tokenDetails_noTokens", fallback: "You have no Tokens")
      /// What are Tokens?
      public static let whatAreTokens = L10n.tr("Localizable", "assetDetails_tokenDetails_whatAreTokens", fallback: "What are Tokens?")
    }
  }
  public enum AuthorizedDapps {
    /// Here are all the dApps that you have logged into using this Radix Wallet.
    public static let subtitle = L10n.tr("Localizable", "authorizedDapps_subtitle", fallback: "Here are all the dApps that you have logged into using this Radix Wallet.")
    /// Authorized dApps
    public static let title = L10n.tr("Localizable", "authorizedDapps_title", fallback: "Authorized dApps")
    /// What is a dApp
    public static let whatIsDapp = L10n.tr("Localizable", "authorizedDapps_whatIsDapp", fallback: "What is a dApp")
    public enum DAppDetails {
      /// dApp Definition
      public static let dAppDefinition = L10n.tr("Localizable", "authorizedDapps_dAppDetails_dAppDefinition", fallback: "dApp Definition")
      /// Forget this dApp
      public static let forgetDapp = L10n.tr("Localizable", "authorizedDapps_dAppDetails_forgetDapp", fallback: "Forget this dApp")
      /// Missing description
      public static let missingDescription = L10n.tr("Localizable", "authorizedDapps_dAppDetails_missingDescription", fallback: "Missing description")
      /// Associated NFTs
      public static let nfts = L10n.tr("Localizable", "authorizedDapps_dAppDetails_nfts", fallback: "Associated NFTs")
      /// No Personas have been used to connect to this dApp.
      public static let noPersonasHeading = L10n.tr("Localizable", "authorizedDapps_dAppDetails_noPersonasHeading", fallback: "No Personas have been used to connect to this dApp.")
      /// Here are the Personas that you have previously used to connect to this dApp.
      public static let personasHeading = L10n.tr("Localizable", "authorizedDapps_dAppDetails_personasHeading", fallback: "Here are the Personas that you have previously used to connect to this dApp.")
      /// Associated Tokens
      public static let tokens = L10n.tr("Localizable", "authorizedDapps_dAppDetails_tokens", fallback: "Associated Tokens")
      /// Unknown name
      public static let unknownTokenName = L10n.tr("Localizable", "authorizedDapps_dAppDetails_unknownTokenName", fallback: "Unknown name")
      /// Website
      public static let website = L10n.tr("Localizable", "authorizedDapps_dAppDetails_website", fallback: "Website")
    }
    public enum ForgetDappAlert {
      /// Forget
      public static let forget = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_forget", fallback: "Forget")
      /// Do you really want to forget this dApp?
      public static let message = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_message", fallback: "Do you really want to forget this dApp?")
      /// Forget dApp?
      public static let title = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_title", fallback: "Forget dApp?")
    }
    public enum PersonaDetails {
      /// Here are the account names and addresses that you are currently sharing with %@.
      public static func accountSharingDescription(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_accountSharingDescription", String(describing: p1), fallback: "Here are the account names and addresses that you are currently sharing with %@.")
      }
      /// Here are the dApps you have logged into with this persona.
      public static let authorizedDappsHeading = L10n.tr("Localizable", "authorizedDapps_personaDetails_authorizedDappsHeading", fallback: "Here are the dApps you have logged into with this persona.")
      /// Edit Account Sharing
      public static let editAccountSharing = L10n.tr("Localizable", "authorizedDapps_personaDetails_editAccountSharing", fallback: "Edit Account Sharing")
      /// Edit Avatar
      public static let editAvatarButtonTitle = L10n.tr("Localizable", "authorizedDapps_personaDetails_editAvatarButtonTitle", fallback: "Edit Avatar")
      /// Edit Persona
      public static let editPersona = L10n.tr("Localizable", "authorizedDapps_personaDetails_editPersona", fallback: "Edit Persona")
      /// Email Address
      public static let emailAddress = L10n.tr("Localizable", "authorizedDapps_personaDetails_emailAddress", fallback: "Email Address")
      /// First Name
      public static let firstName = L10n.tr("Localizable", "authorizedDapps_personaDetails_firstName", fallback: "First Name")
      /// Last Name
      public static let lastName = L10n.tr("Localizable", "authorizedDapps_personaDetails_lastName", fallback: "Last Name")
      /// You are not sharing any personal data with %@
      public static func notSharingAnything(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_notSharingAnything", String(describing: p1), fallback: "You are not sharing any personal data with %@")
      }
      /// Persona Label
      public static let personaLabelHeading = L10n.tr("Localizable", "authorizedDapps_personaDetails_personaLabelHeading", fallback: "Persona Label")
      /// Here is the personal data that you are sharing with %@
      public static func personalDataSharingDescription(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_personalDataSharingDescription", String(describing: p1), fallback: "Here is the personal data that you are sharing with %@")
      }
      /// Phone Number
      public static let phoneNumber = L10n.tr("Localizable", "authorizedDapps_personaDetails_phoneNumber", fallback: "Phone Number")
      /// Disconnect Persona from this dApp
      public static let removeAuthorization = L10n.tr("Localizable", "authorizedDapps_personaDetails_removeAuthorization", fallback: "Disconnect Persona from this dApp")
    }
    public enum RemoveAuthorizationAlert {
      /// This dApp will no longer have authorization to see data associated with this persona, unless you choose to login with it again in the future.
      public static let message = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_message", fallback: "This dApp will no longer have authorization to see data associated with this persona, unless you choose to login with it again in the future.")
      /// Remove Authorization
      public static let title = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_title", fallback: "Remove Authorization")
    }
  }
  public enum Backup {
    /// Back up is turned off
    public static let disabledText = L10n.tr("Localizable", "backup_disabledText", fallback: "Back up is turned off")
    /// Last Backed up: %@
    public static func lastBackedUp(_ p1: Any) -> String {
      return L10n.tr("Localizable", "backup_lastBackedUp", String(describing: p1), fallback: "Last Backed up: %@")
    }
    /// Not Backed up yet
    public static let noLastBackUp = L10n.tr("Localizable", "backup_noLastBackUp", fallback: "Not Backed up yet")
    /// Open System Backup Settings
    public static let openSystemBackupSettings = L10n.tr("Localizable", "backup_openSystemBackupSettings", fallback: "Open System Backup Settings")
    public enum BackupWalletData {
      /// Warning: If disabled you might lose access to accounts/personas.
      public static let message = L10n.tr("Localizable", "backup_backupWalletData_message", fallback: "Warning: If disabled you might lose access to accounts/personas.")
      /// Backup Wallet Data
      public static let title = L10n.tr("Localizable", "backup_backupWalletData_title", fallback: "Backup Wallet Data")
    }
  }
  public enum Biometrics {
    public enum DeviceNotSecureAlert {
      /// Do you want to continue?
      public static let message = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_message", fallback: "Do you want to continue?")
      /// Your device is not secured
      public static let title = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_title", fallback: "Your device is not secured")
    }
    public enum Prompt {
      /// Authenticate to create new %@ with this phone.
      public static func creationOfEntity(_ p1: Any) -> String {
        return L10n.tr("Localizable", "biometrics_prompt_creationOfEntity", String(describing: p1), fallback: "Authenticate to create new %@ with this phone.")
      }
      /// Validate seed phrase exists.
      public static let importOlympiaAccounts = L10n.tr("Localizable", "biometrics_prompt_importOlympiaAccounts", fallback: "Validate seed phrase exists.")
      /// Authenticate to sign auth chellenge with this phone.
      public static let signAuthChallenge = L10n.tr("Localizable", "biometrics_prompt_signAuthChallenge", fallback: "Authenticate to sign auth chellenge with this phone.")
      /// Authenticate to sign transaction with this phone.
      public static let signTransaction = L10n.tr("Localizable", "biometrics_prompt_signTransaction", fallback: "Authenticate to sign transaction with this phone.")
      /// Use your biometric to continue
      public static let title = L10n.tr("Localizable", "biometrics_prompt_title", fallback: "Use your biometric to continue")
    }
  }
  public enum Common {
    /// Account
    public static let account = L10n.tr("Localizable", "common_account", fallback: "Account")
    /// Cancel
    public static let cancel = L10n.tr("Localizable", "common_cancel", fallback: "Cancel")
    /// Confirm
    public static let confirm = L10n.tr("Localizable", "common_confirm", fallback: "Confirm")
    /// Continue
    public static let `continue` = L10n.tr("Localizable", "common_continue", fallback: "Continue")
    /// Development use only. Not usable on Radix mainnet.
    public static let developerDisclaimerText = L10n.tr("Localizable", "common_developerDisclaimerText", fallback: "Development use only. Not usable on Radix mainnet.")
    /// An Error Occurred
    public static let errorAlertTitle = L10n.tr("Localizable", "common_errorAlertTitle", fallback: "An Error Occurred")
    /// History
    public static let history = L10n.tr("Localizable", "common_history", fallback: "History")
    /// None
    public static let `none` = L10n.tr("Localizable", "common_none", fallback: "None")
    /// OK
    public static let ok = L10n.tr("Localizable", "common_ok", fallback: "OK")
    /// Persona
    public static let persona = L10n.tr("Localizable", "common_persona", fallback: "Persona")
    /// Remove
    public static let remove = L10n.tr("Localizable", "common_remove", fallback: "Remove")
    /// Retry
    public static let retry = L10n.tr("Localizable", "common_retry", fallback: "Retry")
    /// Save
    public static let save = L10n.tr("Localizable", "common_save", fallback: "Save")
    /// Something went wrong
    public static let somethingWentWrong = L10n.tr("Localizable", "common_somethingWentWrong", fallback: "Something went wrong")
    /// Settings
    public static let systemSettings = L10n.tr("Localizable", "common_systemSettings", fallback: "Settings")
  }
  public enum CreateAccount {
    /// Create First Account
    public static let titleFirst = L10n.tr("Localizable", "createAccount_titleFirst", fallback: "Create First Account")
    /// Create New Account
    public static let titleNotFirst = L10n.tr("Localizable", "createAccount_titleNotFirst", fallback: "Create New Account")
    public enum Completion {
      /// Your account lives on the Radix Network and you can access it anytime in your Radix Wallet.
      public static let explanation = L10n.tr("Localizable", "createAccount_completion_explanation", fallback: "Your account lives on the Radix Network and you can access it anytime in your Radix Wallet.")
      /// You’ve created your first Account.
      public static let subtitleFirst = L10n.tr("Localizable", "createAccount_completion_subtitleFirst", fallback: "You’ve created your first Account.")
      /// Your Account has been created.
      public static let subtitleNotFirst = L10n.tr("Localizable", "createAccount_completion_subtitleNotFirst", fallback: "Your Account has been created.")
    }
    public enum Introduction {
      /// Create an Account
      public static let title = L10n.tr("Localizable", "createAccount_introduction_title", fallback: "Create an Account")
    }
    public enum NameNewAccount {
      /// e.g. My Main Account
      public static let placeholder = L10n.tr("Localizable", "createAccount_nameNewAccount_placeholder", fallback: "e.g. My Main Account")
      /// What would you like to call your account?
      public static let subtitle = L10n.tr("Localizable", "createAccount_nameNewAccount_subtitle", fallback: "What would you like to call your account?")
    }
  }
  public enum CreateEntity {
    public enum Completion {
      /// Choose Accounts
      public static let destinationChooseAccounts = L10n.tr("Localizable", "createEntity_completion_destinationChooseAccounts", fallback: "Choose Accounts")
      /// Choose Personas
      public static let destinationChoosePersonas = L10n.tr("Localizable", "createEntity_completion_destinationChoosePersonas", fallback: "Choose Personas")
      /// Gateways
      public static let destinationGateways = L10n.tr("Localizable", "createEntity_completion_destinationGateways", fallback: "Gateways")
      /// Account List
      public static let destinationHome = L10n.tr("Localizable", "createEntity_completion_destinationHome", fallback: "Account List")
      /// Persona List
      public static let destinationPersonaList = L10n.tr("Localizable", "createEntity_completion_destinationPersonaList", fallback: "Persona List")
      /// Go to %@
      public static func goToDestination(_ p1: Any) -> String {
        return L10n.tr("Localizable", "createEntity_completion_goToDestination", String(describing: p1), fallback: "Go to %@")
      }
      /// Congratulations
      public static let title = L10n.tr("Localizable", "createEntity_completion_title", fallback: "Congratulations")
    }
    public enum Ledger {
      /// Added
      public static let addedHeading = L10n.tr("Localizable", "createEntity_ledger_addedHeading", fallback: "Added")
      /// Add New Ledger
      public static let addNewLedger = L10n.tr("Localizable", "createEntity_ledger_addNewLedger", fallback: "Add New Ledger")
      /// Create Ledger Account
      public static let createAccount = L10n.tr("Localizable", "createEntity_ledger_createAccount", fallback: "Create Ledger Account")
      /// Create Ledger Persona
      public static let createPersona = L10n.tr("Localizable", "createEntity_ledger_createPersona", fallback: "Create Ledger Persona")
      /// You have no Ledgers added, add a ledger to get started...
      public static let subtitleNoLedgers = L10n.tr("Localizable", "createEntity_ledger_subtitleNoLedgers", fallback: "You have no Ledgers added, add a ledger to get started...")
      /// Select Ledger to use
      public static let subtitleSelectLedger = L10n.tr("Localizable", "createEntity_ledger_subtitleSelectLedger", fallback: "Select Ledger to use")
      /// Used
      public static let usedHeading = L10n.tr("Localizable", "createEntity_ledger_usedHeading", fallback: "Used")
      /// Use Ledger
      public static let useLedger = L10n.tr("Localizable", "createEntity_ledger_useLedger", fallback: "Use Ledger")
    }
    public enum NameNewEntity {
      /// This can be changed any time
      public static let explanation = L10n.tr("Localizable", "createEntity_nameNewEntity_explanation", fallback: "This can be changed any time")
      /// Requires you to sign transactions using your Ledger
      public static let ledgerSubtitle = L10n.tr("Localizable", "createEntity_nameNewEntity_ledgerSubtitle", fallback: "Requires you to sign transactions using your Ledger")
      /// Create with Ledger hardware wallet
      public static let ledgerTitle = L10n.tr("Localizable", "createEntity_nameNewEntity_ledgerTitle", fallback: "Create with Ledger hardware wallet")
    }
  }
  public enum CreatePersona {
    /// Empty display name
    public static let emptyDisplayName = L10n.tr("Localizable", "createPersona_emptyDisplayName", fallback: "Empty display name")
    /// Required field
    public static let requiredField = L10n.tr("Localizable", "createPersona_requiredField", fallback: "Required field")
    /// Save and Continue
    public static let saveAndContinueButtonTitle = L10n.tr("Localizable", "createPersona_saveAndContinueButtonTitle", fallback: "Save and Continue")
    public enum Completion {
      /// Personal data that you add to your Persona will only be shared with dApp websites with your permission in the Radix Wallet.
      public static let explanation = L10n.tr("Localizable", "createPersona_completion_explanation", fallback: "Personal data that you add to your Persona will only be shared with dApp websites with your permission in the Radix Wallet.")
      /// You’ve created your first Persona.
      public static let subtitleFirst = L10n.tr("Localizable", "createPersona_completion_subtitleFirst", fallback: "You’ve created your first Persona.")
      /// Your Persona has been created.
      public static let subtitleNotFirst = L10n.tr("Localizable", "createPersona_completion_subtitleNotFirst", fallback: "Your Persona has been created.")
    }
    public enum Explanation {
      /// Some dApps may request personal information, like name or email address, that can be added to your Persona. Add some of this data now if you like.
      public static let someDappsMayRequest = L10n.tr("Localizable", "createPersona_explanation_someDappsMayRequest", fallback: "Some dApps may request personal information, like name or email address, that can be added to your Persona. Add some of this data now if you like.")
      /// This will be shared with dApps you login to
      public static let thisWillBeShared = L10n.tr("Localizable", "createPersona_explanation_thisWillBeShared", fallback: "This will be shared with dApps you login to")
    }
    public enum Introduction {
      /// Learn about Personas
      public static let learnAboutPersonas = L10n.tr("Localizable", "createPersona_introduction_learnAboutPersonas", fallback: "Learn about Personas")
      /// A Persona is an identity that you own and control. You can have as many as you like.
      public static let subtitle1 = L10n.tr("Localizable", "createPersona_introduction_subtitle1", fallback: "A Persona is an identity that you own and control. You can have as many as you like.")
      /// You will chosose Peronas to login to dApps, and dApps may request access to personal information associated with that Persona.
      public static let subtitle2 = L10n.tr("Localizable", "createPersona_introduction_subtitle2", fallback: "You will chosose Peronas to login to dApps, and dApps may request access to personal information associated with that Persona.")
      /// Create a Persona
      public static let title = L10n.tr("Localizable", "createPersona_introduction_title", fallback: "Create a Persona")
    }
    public enum NameNewPersona {
      /// e.g. My Main Persona
      public static let placeholder = L10n.tr("Localizable", "createPersona_nameNewPersona_placeholder", fallback: "e.g. My Main Persona")
      /// What would you like to call your persona?
      public static let subtitle = L10n.tr("Localizable", "createPersona_nameNewPersona_subtitle", fallback: "What would you like to call your persona?")
    }
  }
  public enum DAppRequest {
    /// Loading...
    public static let metadataLoadingPrompt = L10n.tr("Localizable", "dAppRequest_metadataLoadingPrompt", fallback: "Loading...")
    public enum AccountPermission {
      /// %d or more accounts
      public static func numberOfAccountsAtLeast(_ p1: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsAtLeast", p1, fallback: "%d or more accounts")
      }
      /// Any number of accounts
      public static let numberOfAccountsAtLeastZero = L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsAtLeastZero", fallback: "Any number of accounts")
      /// %d accounts
      public static func numberOfAccountsExactly(_ p1: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsExactly", p1, fallback: "%d accounts")
      }
      /// 1 account
      public static let numberOfAccountsExactlyOne = L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsExactlyOne", fallback: "1 account")
      /// *%s* is requesting permission to *always* be able to view account information when you login with this Persona.
      public static func subtitle(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_subtitle", p1, fallback: "*%s* is requesting permission to *always* be able to view account information when you login with this Persona.")
      }
      /// Account Permission
      public static let title = L10n.tr("Localizable", "dAppRequest_accountPermission_title", fallback: "Account Permission")
      /// You can update this permission in your settings at anA time.
      public static let updateInSettingsExplanation = L10n.tr("Localizable", "dAppRequest_accountPermission_updateInSettingsExplanation", fallback: "You can update this permission in your settings at anA time.")
    }
    public enum ChooseAccounts {
      /// Create a New Account
      public static let createNewAccount = L10n.tr("Localizable", "dAppRequest_chooseAccounts_createNewAccount", fallback: "Create a New Account")
      /// You are now connected to %s. You can change your preferences for this dApp in your Settings at any time.
      public static func successMessage(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccounts_successMessage", p1, fallback: "You are now connected to %s. You can change your preferences for this dApp in your Settings at any time.")
      }
      /// dApp Connection Successful
      public static let successTitle = L10n.tr("Localizable", "dAppRequest_chooseAccounts_successTitle", fallback: "dApp Connection Successful")
      /// DApp error
      public static let verificationErrorTitle = L10n.tr("Localizable", "dAppRequest_chooseAccounts_verificationErrorTitle", fallback: "DApp error")
    }
    public enum ChooseAccountsOneTime {
      /// *%s* is making a one-time request for at least %d accounts.
      public static func subtitleAtLeast(_ p1: UnsafePointer<CChar>, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeast", p1, p2, fallback: "*%s* is making a one-time request for at least %d accounts.")
      }
      /// *%s* is making a one-time request for at least 1 account.
      public static func subtitleAtLeastOne(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastOne", p1, fallback: "*%s* is making a one-time request for at least 1 account.")
      }
      /// *%s* is making a one-time request for any number of accounts.
      public static func subtitleAtLeastZero(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastZero", p1, fallback: "*%s* is making a one-time request for any number of accounts.")
      }
      /// *%s* is making a one-time request for at least %d accounts.
      public static func subtitleExactly(_ p1: UnsafePointer<CChar>, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactly", p1, p2, fallback: "*%s* is making a one-time request for at least %d accounts.")
      }
      /// *%s* is making a one-time request for 1 account.
      public static func subtitleExactlyOne(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactlyOne", p1, fallback: "*%s* is making a one-time request for 1 account.")
      }
      /// Account Request
      public static let title = L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_title", fallback: "Account Request")
    }
    public enum ChooseAccountsOngoing {
      /// Choose at least %d accounts you wish to use with *%s*.
      public static func subtitleAtLeast(_ p1: Int, _ p2: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeast", p1, p2, fallback: "Choose at least %d accounts you wish to use with *%s*.")
      }
      /// Choose at least 1 account you wish to use with *%s*.
      public static func subtitleAtLeastOne(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastOne", p1, fallback: "Choose at least 1 account you wish to use with *%s*.")
      }
      /// Choose any accounts you wish to use with *%s*.
      public static func subtitleAtLeastZero(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastZero", p1, fallback: "Choose any accounts you wish to use with *%s*.")
      }
      /// Choose %d accounts you wish to use with *%s*.
      public static func subtitleExactly(_ p1: Int, _ p2: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactly", p1, p2, fallback: "Choose %d accounts you wish to use with *%s*.")
      }
      /// Choose 1 account you wish to use with *%s*.
      public static func subtitleExactlyOne(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactlyOne", p1, fallback: "Choose 1 account you wish to use with *%s*.")
      }
      /// Account Permission
      public static let title = L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_title", fallback: "Account Permission")
    }
    public enum Completion {
      /// Request from %s complete
      public static func subtitle(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_completion_subtitle", p1, fallback: "Request from %s complete")
      }
      /// Success
      public static let title = L10n.tr("Localizable", "dAppRequest_completion_title", fallback: "Success")
    }
    public enum Login {
      /// Choose a Persona
      public static let choosePersona = L10n.tr("Localizable", "dAppRequest_login_choosePersona", fallback: "Choose a Persona")
      /// Your last login was on %@
      public static func lastLoginWasOn(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_lastLoginWasOn", String(describing: p1), fallback: "Your last login was on %@")
      }
      /// %s is requesting you to login with a Persona.
      public static func subtitleKnownDapp(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_subtitleKnownDapp", p1, fallback: "%s is requesting you to login with a Persona.")
      }
      /// %s  is requesting you to login for the first time with a Persona.
      public static func subtitleNewDapp(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_subtitleNewDapp", p1, fallback: "%s  is requesting you to login for the first time with a Persona.")
      }
      /// Login Request
      public static let titleKnownDapp = L10n.tr("Localizable", "dAppRequest_login_titleKnownDapp", fallback: "Login Request")
      /// New Login Request
      public static let titleNewDapp = L10n.tr("Localizable", "dAppRequest_login_titleNewDapp", fallback: "New Login Request")
    }
    public enum Metadata {
      /// Unknown dApp
      public static let unknownName = L10n.tr("Localizable", "dAppRequest_metadata_unknownName", fallback: "Unknown dApp")
    }
    public enum MetadataLoadingAlert {
      /// Danger! Bad dApp config or you're being spoofed!
      public static let message = L10n.tr("Localizable", "dAppRequest_metadataLoadingAlert_message", fallback: "Danger! Bad dApp config or you're being spoofed!")
    }
    public enum PersonalDataBox {
      /// Edit
      public static let edit = L10n.tr("Localizable", "dAppRequest_personalDataBox_edit", fallback: "Edit")
      /// Required information:
      public static let requiredInformation = L10n.tr("Localizable", "dAppRequest_personalDataBox_requiredInformation", fallback: "Required information:")
    }
    public enum PersonalDataOneTime {
      /// Choose the data to provide
      public static let chooseDataToProvide = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_chooseDataToProvide", fallback: "Choose the data to provide")
      /// *%s* is requesting that you provide some pieces of personal data *just one time*
      public static func subtitle(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataOneTime_subtitle", p1, fallback: "*%s* is requesting that you provide some pieces of personal data *just one time*")
      }
      /// One-Time Data Request
      public static let title = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_title", fallback: "One-Time Data Request")
    }
    public enum PersonalDataPermission {
      /// *%s* is requesting permission to *always* be able to view the following personal data when you login with this Persona.
      public static func subtitle(_ p1: UnsafePointer<CChar>) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataPermission_subtitle", p1, fallback: "*%s* is requesting permission to *always* be able to view the following personal data when you login with this Persona.")
      }
      /// Personal Data Permission
      public static let title = L10n.tr("Localizable", "dAppRequest_personalDataPermission_title", fallback: "Personal Data Permission")
      /// You can update this permission in your settings at anA time.
      public static let updateInSettingsExplanation = L10n.tr("Localizable", "dAppRequest_personalDataPermission_updateInSettingsExplanation", fallback: "You can update this permission in your settings at anA time.")
    }
    public enum RequestMalformedAlert {
      /// Interaction received from dApp does not contain any valid requests.
      public static let message = L10n.tr("Localizable", "dAppRequest_requestMalformedAlert_message", fallback: "Interaction received from dApp does not contain any valid requests.")
    }
    public enum RequestPersonaNotFoundAlert {
      /// Persona specified by dApp does not exist.
      public static let message = L10n.tr("Localizable", "dAppRequest_requestPersonaNotFoundAlert_message", fallback: "Persona specified by dApp does not exist.")
    }
    public enum RequestWrongNetworkAlert {
      /// Request received from dApp for network %@, but you are currentlA connected to %@.
      public static func message(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_requestWrongNetworkAlert_message", String(describing: p1), String(describing: p2), fallback: "Request received from dApp for network %@, but you are currentlA connected to %@.")
      }
    }
    public enum ResponseFailureAlert {
      /// Failed to send response payload back to dApp.
      public static let message = L10n.tr("Localizable", "dAppRequest_responseFailureAlert_message", fallback: "Failed to send response payload back to dApp.")
    }
  }
  public enum EditPersona {
    /// Add a Field
    public static let addAField = L10n.tr("Localizable", "editPersona_addAField", fallback: "Add a Field")
    /// Required by dApp
    public static let requiredByDapp = L10n.tr("Localizable", "editPersona_requiredByDapp", fallback: "Required by dApp")
    /// The following information can be seen if requested by the dApp
    public static let sharedInformationHeading = L10n.tr("Localizable", "editPersona_sharedInformationHeading", fallback: "The following information can be seen if requested by the dApp")
    public enum AddAField {
      /// Add
      public static let add = L10n.tr("Localizable", "editPersona_addAField_add", fallback: "Add")
      /// Select from the following fields to add them to this persona.
      public static let subtitle = L10n.tr("Localizable", "editPersona_addAField_subtitle", fallback: "Select from the following fields to add them to this persona.")
      /// Add a Field
      public static let title = L10n.tr("Localizable", "editPersona_addAField_title", fallback: "Add a Field")
    }
    public enum CloseConfirmationDialog {
      /// Discard Changes
      public static let discardChanges = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_discardChanges", fallback: "Discard Changes")
      /// Keep Editing
      public static let keepEditing = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_keepEditing", fallback: "Keep Editing")
      /// Are you sure you want to discard changes to this persona?
      public static let message = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_message", fallback: "Are you sure you want to discard changes to this persona?")
    }
    public enum Error {
      /// Label cannot be blank
      public static let blank = L10n.tr("Localizable", "editPersona_error_blank", fallback: "Label cannot be blank")
      /// Invalid email address
      public static let invalidEmailAddress = L10n.tr("Localizable", "editPersona_error_invalidEmailAddress", fallback: "Invalid email address")
      /// Required field for this dApp
      public static let requiredByDapp = L10n.tr("Localizable", "editPersona_error_requiredByDapp", fallback: "Required field for this dApp")
    }
  }
  public enum Error {
    public enum DappRequest {
      /// Invalid persona id specified by dApp
      public static let invalidPersonaId = L10n.tr("Localizable", "error_dappRequest_invalidPersonaId", fallback: "Invalid persona id specified by dApp")
      /// Invalid request
      public static let invalidRequest = L10n.tr("Localizable", "error_dappRequest_invalidRequest", fallback: "Invalid request")
    }
    public enum ProfileLoad {
      /// Failed to create Wallet from backup: %@
      public static func decodingError(_ p1: Any) -> String {
        return L10n.tr("Localizable", "error_profileLoad_decodingError", String(describing: p1), fallback: "Failed to create Wallet from backup: %@")
      }
      /// Failed to create Wallet from backup, error: %@, version: %@
      public static func failedToCreateProfileFromSnapshot(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "error_profileLoad_failedToCreateProfileFromSnapshot", String(describing: p1), String(describing: p2), fallback: "Failed to create Wallet from backup, error: %@, version: %@")
      }
    }
    public enum TransactionFailure {
      /// Failed to commit transaction
      public static let commit = L10n.tr("Localizable", "error_transactionFailure_commit", fallback: "Failed to commit transaction")
      /// Failed to convert transaction manifest
      public static let duplicate = L10n.tr("Localizable", "error_transactionFailure_duplicate", fallback: "Failed to convert transaction manifest")
      /// Failed to get epoch
      public static let epoch = L10n.tr("Localizable", "error_transactionFailure_epoch", fallback: "Failed to get epoch")
      /// Failed to build transaction header
      public static let header = L10n.tr("Localizable", "error_transactionFailure_header", fallback: "Failed to build transaction header")
      /// Failed to convert transaction manifest
      public static let manifest = L10n.tr("Localizable", "error_transactionFailure_manifest", fallback: "Failed to convert transaction manifest")
      /// Wrong network
      public static let network = L10n.tr("Localizable", "error_transactionFailure_network", fallback: "Wrong network")
      /// No funds to approve transaction
      public static let noFundsToApproveTransaction = L10n.tr("Localizable", "error_transactionFailure_noFundsToApproveTransaction", fallback: "No funds to approve transaction")
      /// Failed to poll transaction status
      public static let pollStatus = L10n.tr("Localizable", "error_transactionFailure_pollStatus", fallback: "Failed to poll transaction status")
      /// Failed to prepare transaction
      public static let prepare = L10n.tr("Localizable", "error_transactionFailure_prepare", fallback: "Failed to prepare transaction")
      /// Transaction rejected
      public static let rejected = L10n.tr("Localizable", "error_transactionFailure_rejected", fallback: "Transaction rejected")
      /// Failed to convert transaction manifest
      public static let rejectedByUser = L10n.tr("Localizable", "error_transactionFailure_rejectedByUser", fallback: "Failed to convert transaction manifest")
      /// Failed to submit transaction
      public static let submit = L10n.tr("Localizable", "error_transactionFailure_submit", fallback: "Failed to submit transaction")
    }
  }
  public enum Gateways {
    /// Add New Gateway
    public static let addNewGatewayButtonTitle = L10n.tr("Localizable", "gateways_addNewGatewayButtonTitle", fallback: "Add New Gateway")
    /// RCnet Gateway
    public static let rcNetGateway = L10n.tr("Localizable", "gateways_rcNetGateway", fallback: "RCnet Gateway")
    /// Choose the gateway your wallet will use to connect. Only change this if you know what you’re doing.
    public static let subtitle = L10n.tr("Localizable", "gateways_subtitle", fallback: "Choose the gateway your wallet will use to connect. Only change this if you know what you’re doing.")
    /// Gateways
    public static let title = L10n.tr("Localizable", "gateways_title", fallback: "Gateways")
    /// What is a Gateway
    public static let whatIsAGateway = L10n.tr("Localizable", "gateways_whatIsAGateway", fallback: "What is a Gateway")
    public enum AddNewGateway {
      /// Add Gateway
      public static let addGatewayButtonTitle = L10n.tr("Localizable", "gateways_addNewGateway_addGatewayButtonTitle", fallback: "Add Gateway")
      /// This url is already added
      public static let errorDuplicateURL = L10n.tr("Localizable", "gateways_addNewGateway_errorDuplicateURL", fallback: "This url is already added")
      /// No Gateway found at specified URL
      public static let errorNoGatewayFound = L10n.tr("Localizable", "gateways_addNewGateway_errorNoGatewayFound", fallback: "No Gateway found at specified URL")
      /// There was an error in establishing a connection
      public static let establishingConnectionErrorMessage = L10n.tr("Localizable", "gateways_addNewGateway_establishingConnectionErrorMessage", fallback: "There was an error in establishing a connection")
      /// Enter a Gateway URL
      public static let subtitle = L10n.tr("Localizable", "gateways_addNewGateway_subtitle", fallback: "Enter a Gateway URL")
      /// Enter full URL
      public static let textFieldPlaceholder = L10n.tr("Localizable", "gateways_addNewGateway_textFieldPlaceholder", fallback: "Enter full URL")
      /// Add New Gateway
      public static let title = L10n.tr("Localizable", "gateways_addNewGateway_title", fallback: "Add New Gateway")
    }
    public enum RemoveGatewayAlert {
      /// You will no longer be able to connect to this Gateway
      public static let message = L10n.tr("Localizable", "gateways_removeGatewayAlert_message", fallback: "You will no longer be able to connect to this Gateway")
      /// Remove Gateway
      public static let title = L10n.tr("Localizable", "gateways_removeGatewayAlert_title", fallback: "Remove Gateway")
    }
  }
  public enum HomePage {
    /// Apply Security Settings
    public static let applySecuritySettings = L10n.tr("Localizable", "homePage_applySecuritySettings", fallback: "Apply Security Settings")
    /// I have backed up this mnemonic
    public static let backedUpMnemonicHeading = L10n.tr("Localizable", "homePage_backedUpMnemonicHeading", fallback: "I have backed up this mnemonic")
    /// Create a New Account
    public static let createNewAccount = L10n.tr("Localizable", "homePage_createNewAccount", fallback: "Create a New Account")
    /// Legacy
    public static let legacyAccountHeading = L10n.tr("Localizable", "homePage_legacyAccountHeading", fallback: "Legacy")
    /// Welcome, here are all your accounts on the Radix Network
    public static let subtitle = L10n.tr("Localizable", "homePage_subtitle", fallback: "Welcome, here are all your accounts on the Radix Network")
    /// Radix Wallet
    public static let title = L10n.tr("Localizable", "homePage_title", fallback: "Radix Wallet")
    /// Total value
    public static let totalValue = L10n.tr("Localizable", "homePage_totalValue", fallback: "Total value")
    public enum VisitDashboard {
      /// Ready to get started using the Radix Network and your Wallet?
      public static let subtitle = L10n.tr("Localizable", "homePage_visitDashboard_subtitle", fallback: "Ready to get started using the Radix Network and your Wallet?")
      /// Visit the Radix Dashboard
      public static let title = L10n.tr("Localizable", "homePage_visitDashboard_title", fallback: "Visit the Radix Dashboard")
    }
  }
  public enum ImportLegacyWallet {
    /// Open your Olympia Wallet and export the accounts you would like to migrate to this wallet.
    public static let scanQRCodeInstructions = L10n.tr("Localizable", "importLegacyWallet_scanQRCodeInstructions", fallback: "Open your Olympia Wallet and export the accounts you would like to migrate to this wallet.")
    /// Import Legacy Wallet
    public static let title = L10n.tr("Localizable", "importLegacyWallet_title", fallback: "Import Legacy Wallet")
    public enum Completion {
      /// Imported #%d accounts.
      public static func titleManyAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "importLegacyWallet_completion_titleManyAccounts", p1, fallback: "Imported #%d accounts.")
      }
      /// No accounts imported.
      public static let titleNoAccounts = L10n.tr("Localizable", "importLegacyWallet_completion_titleNoAccounts", fallback: "No accounts imported.")
      /// Imported 1 account.
      public static let titleOneAccount = L10n.tr("Localizable", "importLegacyWallet_completion_titleOneAccount", fallback: "Imported 1 account.")
    }
    public enum SelectAccountsToImport {
      /// Type
      public static let accountType = L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_accountType", fallback: "Type")
      /// Path
      public static let derivationPath = L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_derivationPath", fallback: "Path")
      /// Deselect all
      public static let deselectAll = L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_deselectAll", fallback: "Deselect all")
      /// Import %d accounts
      public static func importManyAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_importManyAccounts", p1, fallback: "Import %d accounts")
      }
      /// Import 1 account
      public static let importOneAcccount = L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_importOneAcccount", fallback: "Import 1 account")
      /// Import accounts
      public static let importZeroAccounts = L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_importZeroAccounts", fallback: "Import accounts")
      /// Name
      public static let name = L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_name", fallback: "Name")
      /// Olympia Address
      public static let olympiaAddress = L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_olympiaAddress", fallback: "Olympia Address")
      /// Select all non imported
      public static let selectAllNonImported = L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_selectAllNonImported", fallback: "Select all non imported")
      /// Unnamed
      public static let unnamed = L10n.tr("Localizable", "importLegacyWallet_selectAccountsToImport_unnamed", fallback: "Unnamed")
    }
  }
  public enum ImportOlympiaAccounts {
    /// Account already imported
    public static let accountAlreadyImported = L10n.tr("Localizable", "importOlympiaAccounts_accountAlreadyImported", fallback: "Account already imported")
    /// Here are all your Mnemonics. Tap one to display
    public static let allMnemonicsHeading = L10n.tr("Localizable", "importOlympiaAccounts_allMnemonicsHeading", fallback: "Here are all your Mnemonics. Tap one to display")
    /// Already imported
    public static let alreadyImported = L10n.tr("Localizable", "importOlympiaAccounts_alreadyImported", fallback: "Already imported")
    /// BIP39 passphrase
    public static let bip39passphrase = L10n.tr("Localizable", "importOlympiaAccounts_bip39passphrase", fallback: "BIP39 passphrase")
    /// Import
    public static let importLabel = L10n.tr("Localizable", "importOlympiaAccounts_importLabel", fallback: "Import")
    /// Invalid Mnemonic
    public static let invalidMnemonic = L10n.tr("Localizable", "importOlympiaAccounts_invalidMnemonic", fallback: "Invalid Mnemonic")
    /// Invalid QR code
    public static let invalidPayload = L10n.tr("Localizable", "importOlympiaAccounts_invalidPayload", fallback: "Invalid QR code")
    /// Mnemonic
    public static let mnemonic = L10n.tr("Localizable", "importOlympiaAccounts_mnemonic", fallback: "Mnemonic")
    /// Mnemonic: %@ Passphrase: %@
    public static func mnemonicAndPassphrase(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "importOlympiaAccounts_mnemonicAndPassphrase", String(describing: p1), String(describing: p2), fallback: "Mnemonic: %@ Passphrase: %@")
    }
    /// Mnemonics
    public static let mnemonics = L10n.tr("Localizable", "importOlympiaAccounts_mnemonics", fallback: "Mnemonics")
    /// No mnemonic found for accounts
    public static let noMnemonicFound = L10n.tr("Localizable", "importOlympiaAccounts_noMnemonicFound", fallback: "No mnemonic found for accounts")
    /// Passphrase
    public static let passphrase = L10n.tr("Localizable", "importOlympiaAccounts_passphrase", fallback: "Passphrase")
    /// Scanned %d/%d
    public static func scannedProgress(_ p1: Int, _ p2: Int) -> String {
      return L10n.tr("Localizable", "importOlympiaAccounts_scannedProgress", p1, p2, fallback: "Scanned %d/%d")
    }
    /// Please scan next qr code
    public static let scanNextQrCode = L10n.tr("Localizable", "importOlympiaAccounts_scanNextQrCode", fallback: "Please scan next qr code")
    /// Seed phrase
    public static let seedPhrase = L10n.tr("Localizable", "importOlympiaAccounts_seedPhrase", fallback: "Seed phrase")
    /// Import Olympia Accounts
    public static let title = L10n.tr("Localizable", "importOlympiaAccounts_title", fallback: "Import Olympia Accounts")
    /// Type
    public static let typeLabel = L10n.tr("Localizable", "importOlympiaAccounts_typeLabel", fallback: "Type")
    /// View Mnemonics
    public static let viewMnemonics = L10n.tr("Localizable", "importOlympiaAccounts_viewMnemonics", fallback: "View Mnemonics")
    /// What is a Mnemonic
    public static let whatIsMnemonic = L10n.tr("Localizable", "importOlympiaAccounts_whatIsMnemonic", fallback: "What is a Mnemonic")
  }
  public enum ImportProfile {
    /// Import Radix Wallet backup
    public static let importProfile = L10n.tr("Localizable", "importProfile_importProfile", fallback: "Import Radix Wallet backup")
  }
  public enum LinkedConnectors {
    /// Last connected %s
    public static func lastConnected(_ p1: UnsafePointer<CChar>) -> String {
      return L10n.tr("Localizable", "linkedConnectors_lastConnected", p1, fallback: "Last connected %s")
    }
    /// Link New Connector
    public static let linkNewConnector = L10n.tr("Localizable", "linkedConnectors_linkNewConnector", fallback: "Link New Connector")
    /// Your Radix Wallet is linked to the following desktop browser using the Connector browser extension.
    public static let subtitle = L10n.tr("Localizable", "linkedConnectors_subtitle", fallback: "Your Radix Wallet is linked to the following desktop browser using the Connector browser extension.")
    /// Linked Connectors
    public static let title = L10n.tr("Localizable", "linkedConnectors_title", fallback: "Linked Connectors")
    public enum CameraPermissionDeniedAlert {
      /// Camera access is required to link to connector.
      public static let message = L10n.tr("Localizable", "linkedConnectors_cameraPermissionDeniedAlert_message", fallback: "Camera access is required to link to connector.")
      /// Access Required
      public static let title = L10n.tr("Localizable", "linkedConnectors_cameraPermissionDeniedAlert_title", fallback: "Access Required")
    }
    public enum LocalNetworkPermissionDeniedAlert {
      /// Local Network access is required to link to connector.
      public static let message = L10n.tr("Localizable", "linkedConnectors_localNetworkPermissionDeniedAlert_message", fallback: "Local Network access is required to link to connector.")
      /// Access Required
      public static let title = L10n.tr("Localizable", "linkedConnectors_localNetworkPermissionDeniedAlert_title", fallback: "Access Required")
    }
    public enum NewConnection {
      /// Unnamed
      public static let connectionDefaultName = L10n.tr("Localizable", "linkedConnectors_newConnection_connectionDefaultName", fallback: "Unnamed")
      /// Linking...
      public static let linking = L10n.tr("Localizable", "linkedConnectors_newConnection_linking", fallback: "Linking...")
      /// Save Link
      public static let saveLinkButtonTitle = L10n.tr("Localizable", "linkedConnectors_newConnection_saveLinkButtonTitle", fallback: "Save Link")
      /// Scan your QR code to link your wallet with a browser extension
      public static let subtitle = L10n.tr("Localizable", "linkedConnectors_newConnection_subtitle", fallback: "Scan your QR code to link your wallet with a browser extension")
      /// Name this Connector, e.g. "Chrome on Macbook Pro"
      public static let textFieldHint = L10n.tr("Localizable", "linkedConnectors_newConnection_textFieldHint", fallback: "Name this Connector, e.g. \"Chrome on Macbook Pro\"")
      /// Name of Connector
      public static let textFieldPlaceholder = L10n.tr("Localizable", "linkedConnectors_newConnection_textFieldPlaceholder", fallback: "Name of Connector")
      /// Link New Connector
      public static let title = L10n.tr("Localizable", "linkedConnectors_newConnection_title", fallback: "Link New Connector")
    }
    public enum RemoveConnectionAlert {
      /// You will no longer be able to connect your wallet to this device and browser combination
      public static let message = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_message", fallback: "You will no longer be able to connect your wallet to this device and browser combination")
      /// Remove Connection
      public static let title = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_title", fallback: "Remove Connection")
    }
  }
  public enum Onboarding {
    /// I'm a new Radix Wallet user
    public static let newUser = L10n.tr("Localizable", "onboarding_newUser", fallback: "I'm a new Radix Wallet user")
    /// Restore Wallet from Backup
    public static let restoreFromBackup = L10n.tr("Localizable", "onboarding_restoreFromBackup", fallback: "Restore Wallet from Backup")
    public enum Step1 {
      /// Your direct connection to the Radix Network
      public static let subtitle = L10n.tr("Localizable", "onboarding_step1_subtitle", fallback: "Your direct connection to the Radix Network")
      /// Welcome to the Radix Wallet
      public static let title = L10n.tr("Localizable", "onboarding_step1_title", fallback: "Welcome to the Radix Wallet")
    }
    public enum Step2 {
      /// Let's get started
      public static let subtitle = L10n.tr("Localizable", "onboarding_step2_subtitle", fallback: "Let's get started")
      /// A World of Possibilities
      public static let title = L10n.tr("Localizable", "onboarding_step2_title", fallback: "A World of Possibilities")
    }
    public enum Step3 {
      /// Connect and transact securely with a world of web3 dApps, tokens, NFTs, and much more
      public static let subtitle = L10n.tr("Localizable", "onboarding_step3_subtitle", fallback: "Connect and transact securely with a world of web3 dApps, tokens, NFTs, and much more")
      /// Your phone is your login
      public static let title = L10n.tr("Localizable", "onboarding_step3_title", fallback: "Your phone is your login")
    }
  }
  public enum Personas {
    /// Create a New Persona
    public static let createNewPersona = L10n.tr("Localizable", "personas_createNewPersona", fallback: "Create a New Persona")
    /// Here are all of your current Personas in your Wallet.
    public static let subtitle = L10n.tr("Localizable", "personas_subtitle", fallback: "Here are all of your current Personas in your Wallet.")
    /// Personas
    public static let title = L10n.tr("Localizable", "personas_title", fallback: "Personas")
    /// What is a Persona
    public static let whatIsPersona = L10n.tr("Localizable", "personas_whatIsPersona", fallback: "What is a Persona")
  }
  public enum Settings {
    /// App Settings
    public static let appSettings = L10n.tr("Localizable", "settings_appSettings", fallback: "App Settings")
    /// Version: %@ build #%@
    public static func appVersion(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "settings_appVersion", String(describing: p1), String(describing: p2), fallback: "Version: %@ build #%@")
    }
    /// Authorized dApps
    public static let authorizedDapps = L10n.tr("Localizable", "settings_authorizedDapps", fallback: "Authorized dApps")
    /// Backups
    public static let backups = L10n.tr("Localizable", "settings_backups", fallback: "Backups")
    /// Delete Wallet Data
    public static let deleteWalletData = L10n.tr("Localizable", "settings_deleteWalletData", fallback: "Delete Wallet Data")
    /// Gateways
    public static let gateways = L10n.tr("Localizable", "settings_gateways", fallback: "Gateways")
    /// Import from a Legacy Wallet
    public static let importFromLegacyWallet = L10n.tr("Localizable", "settings_importFromLegacyWallet", fallback: "Import from a Legacy Wallet")
    /// Inspect Profile
    public static let inspectProfile = L10n.tr("Localizable", "settings_inspectProfile", fallback: "Inspect Profile")
    /// Linked Connectors
    public static let linkedConnectors = L10n.tr("Localizable", "settings_linkedConnectors", fallback: "Linked Connectors")
    /// No Wallet Data Found
    public static let noProfileText = L10n.tr("Localizable", "settings_noProfileText", fallback: "No Wallet Data Found")
    /// Personas
    public static let personas = L10n.tr("Localizable", "settings_personas", fallback: "Personas")
    /// Settings
    public static let title = L10n.tr("Localizable", "settings_title", fallback: "Settings")
    public enum LinkToConnectorHeader {
      /// Link to Connector
      public static let linkToConnector = L10n.tr("Localizable", "settings_linkToConnectorHeader_linkToConnector", fallback: "Link to Connector")
      /// Scan the QR code in the Radix Wallet Connector extension
      public static let subtitle = L10n.tr("Localizable", "settings_linkToConnectorHeader_subtitle", fallback: "Scan the QR code in the Radix Wallet Connector extension")
      /// Link your Wallet to a Desktop Browser
      public static let title = L10n.tr("Localizable", "settings_linkToConnectorHeader_title", fallback: "Link your Wallet to a Desktop Browser")
    }
  }
  public enum Splash {
    /// This app requires your phone to have a passcode set up
    public static let passcodeNotSetMessage = L10n.tr("Localizable", "splash_passcodeNotSetMessage", fallback: "This app requires your phone to have a passcode set up")
    /// Passcode not set up
    public static let passcodeNotSetTitle = L10n.tr("Localizable", "splash_passcodeNotSetTitle", fallback: "Passcode not set up")
    public enum IncompatibleProfileVersionAlert {
      /// Delete Wallet Data
      public static let delete = L10n.tr("Localizable", "splash_incompatibleProfileVersionAlert_delete", fallback: "Delete Wallet Data")
      /// For this Preview wallet version, you must delete your wallet data to continue.
      public static let message = L10n.tr("Localizable", "splash_incompatibleProfileVersionAlert_message", fallback: "For this Preview wallet version, you must delete your wallet data to continue.")
      /// Wallet Data is Incompatible
      public static let title = L10n.tr("Localizable", "splash_incompatibleProfileVersionAlert_title", fallback: "Wallet Data is Incompatible")
    }
    public enum PasscodeCheckFailedAlert {
      /// Passcode is not set up. Please update settings.
      public static let message = L10n.tr("Localizable", "splash_passcodeCheckFailedAlert_message", fallback: "Passcode is not set up. Please update settings.")
      /// Warning
      public static let title = L10n.tr("Localizable", "splash_passcodeCheckFailedAlert_title", fallback: "Warning")
    }
  }
  public enum Transaction {
    public enum Status {
      public enum Completing {
        /// Completing Transaction…
        public static let text = L10n.tr("Localizable", "transaction_status_completing_text", fallback: "Completing Transaction…")
      }
      public enum Failure {
        /// Something went wrong
        public static let title = L10n.tr("Localizable", "transaction_status_failure_title", fallback: "Something went wrong")
      }
      public enum Success {
        /// Your transaction was successful
        public static let text = L10n.tr("Localizable", "transaction_status_success_text", fallback: "Your transaction was successful")
        /// Success
        public static let title = L10n.tr("Localizable", "transaction_status_success_title", fallback: "Success")
      }
    }
  }
  public enum TransactionReview {
    /// Approve
    public static let approveButtonTitle = L10n.tr("Localizable", "transactionReview_approveButtonTitle", fallback: "Approve")
    /// Customize Guarantees
    public static let customizeGuaranteesButtonTitle = L10n.tr("Localizable", "transactionReview_customizeGuaranteesButtonTitle", fallback: "Customize Guarantees")
    /// Depositing
    public static let depositsHeading = L10n.tr("Localizable", "transactionReview_depositsHeading", fallback: "Depositing")
    /// Estimated
    public static let estimated = L10n.tr("Localizable", "transactionReview_estimated", fallback: "Estimated")
    /// Account
    public static let externalAccountName = L10n.tr("Localizable", "transactionReview_externalAccountName", fallback: "Account")
    /// Guaranteed
    public static let guaranteed = L10n.tr("Localizable", "transactionReview_guaranteed", fallback: "Guaranteed")
    /// Message
    public static let messageHeading = L10n.tr("Localizable", "transactionReview_messageHeading", fallback: "Message")
    /// Presenting
    public static let presentingHeading = L10n.tr("Localizable", "transactionReview_presentingHeading", fallback: "Presenting")
    /// Raw Transaction
    public static let rawTransactionTitle = L10n.tr("Localizable", "transactionReview_rawTransactionTitle", fallback: "Raw Transaction")
    /// Sending to
    public static let sendingToHeading = L10n.tr("Localizable", "transactionReview_sendingToHeading", fallback: "Sending to")
    /// Review Transaction
    public static let title = L10n.tr("Localizable", "transactionReview_title", fallback: "Review Transaction")
    /// Unknown
    public static let unknown = L10n.tr("Localizable", "transactionReview_unknown", fallback: "Unknown")
    /// %d Unknown Components
    public static func unknownComponents(_ p1: Int) -> String {
      return L10n.tr("Localizable", "transactionReview_unknownComponents", p1, fallback: "%d Unknown Components")
    }
    /// Using dApps
    public static let usingDappsHeading = L10n.tr("Localizable", "transactionReview_usingDappsHeading", fallback: "Using dApps")
    /// Withdrawing
    public static let withdrawalsHeading = L10n.tr("Localizable", "transactionReview_withdrawalsHeading", fallback: "Withdrawing")
    /// XRD %@
    public static func xrdAmount(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transactionReview_xrdAmount", String(describing: p1), fallback: "XRD %@")
    }
    public enum Guarantees {
      /// Apply
      public static let applyButtonText = L10n.tr("Localizable", "transactionReview_guarantees_applyButtonText", fallback: "Apply")
      /// How do Guarantees work
      public static let howDoGuaranteesWork = L10n.tr("Localizable", "transactionReview_guarantees_howDoGuaranteesWork", fallback: "How do Guarantees work")
      /// Set guaranteed minimum %%
      public static let setGuaranteedMinimum = L10n.tr("Localizable", "transactionReview_guarantees_setGuaranteedMinimum", fallback: "Set guaranteed minimum %%")
      /// Protect yourself by setting guaranteed minimums for estimated deposits
      public static let subtitle = L10n.tr("Localizable", "transactionReview_guarantees_subtitle", fallback: "Protect yourself by setting guaranteed minimums for estimated deposits")
      /// Customize Guarantees
      public static let title = L10n.tr("Localizable", "transactionReview_guarantees_title", fallback: "Customize Guarantees")
    }
    public enum NetworkFee {
      /// The network is currently congested. Add a tip to speed up your transfer.
      public static let congestedText = L10n.tr("Localizable", "transactionReview_networkFee_congestedText", fallback: "The network is currently congested. Add a tip to speed up your transfer.")
      /// Customize
      public static let customizeButtonTitle = L10n.tr("Localizable", "transactionReview_networkFee_customizeButtonTitle", fallback: "Customize")
      /// Network Fee
      public static let heading = L10n.tr("Localizable", "transactionReview_networkFee_heading", fallback: "Network Fee")
    }
  }
  public enum TransactionSigning {
    /// Preparing transaction...
    public static let preparingTransaction = L10n.tr("Localizable", "transactionSigning_preparingTransaction", fallback: "Preparing transaction...")
    /// Submitting transaction...
    public static let signingAndSubmittingTransaction = L10n.tr("Localizable", "transactionSigning_signingAndSubmittingTransaction", fallback: "Submitting transaction...")
    /// Approve Transaction
    public static let signTransactionButtonTitle = L10n.tr("Localizable", "transactionSigning_signTransactionButtonTitle", fallback: "Approve Transaction")
    /// Approve Transaction
    public static let title = L10n.tr("Localizable", "transactionSigning_title", fallback: "Approve Transaction")
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
