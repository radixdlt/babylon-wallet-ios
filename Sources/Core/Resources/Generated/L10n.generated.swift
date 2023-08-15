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
    public enum PoolUnits {
      /// LIQUID STAKE UNITS
      public static let liquidStakeUnits = L10n.tr("Localizable", "account_poolUnits_liquidStakeUnits", fallback: "LIQUID STAKE UNITS")
      /// Radix Network XRD Stake
      public static let lsuResourceHeader = L10n.tr("Localizable", "account_poolUnits_lsuResourceHeader", fallback: "Radix Network XRD Stake")
      /// %d Stakes
      public static func numberOfStakes(_ p1: Int) -> String {
        return L10n.tr("Localizable", "account_poolUnits_numberOfStakes", p1, fallback: "%d Stakes")
      }
      /// Ready to Claim
      public static let readyToClaim = L10n.tr("Localizable", "account_poolUnits_readyToClaim", fallback: "Ready to Claim")
      /// STAKE CLAIM NFTS
      public static let stakeClaimNFTs = L10n.tr("Localizable", "account_poolUnits_stakeClaimNFTs", fallback: "STAKE CLAIM NFTS")
      /// Staked
      public static let staked = L10n.tr("Localizable", "account_poolUnits_staked", fallback: "Staked")
      /// Unknown
      public static let unknownPoolUnitName = L10n.tr("Localizable", "account_poolUnits_unknownPoolUnitName", fallback: "Unknown")
      /// Unknown
      public static let unknownSymbolName = L10n.tr("Localizable", "account_poolUnits_unknownSymbolName", fallback: "Unknown")
      /// Unknown
      public static let unknownValidatorName = L10n.tr("Localizable", "account_poolUnits_unknownValidatorName", fallback: "Unknown")
      /// Unstaking
      public static let unstaking = L10n.tr("Localizable", "account_poolUnits_unstaking", fallback: "Unstaking")
      public enum Details {
        /// Current Redeemable Value
        public static let currentRedeemableValue = L10n.tr("Localizable", "account_poolUnits_details_currentRedeemableValue", fallback: "Current Redeemable Value")
      }
    }
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
    /// Set how you want this Account to work
    public static let accountSecuritySubtitle = L10n.tr("Localizable", "accountSettings_accountSecuritySubtitle", fallback: "Set how you want this Account to work")
    /// Get XRD Test Tokens
    public static let getXrdTestTokens = L10n.tr("Localizable", "accountSettings_getXrdTestTokens", fallback: "Get XRD Test Tokens")
    /// Hide Account
    public static let hideAccount = L10n.tr("Localizable", "accountSettings_hideAccount", fallback: "Hide Account")
    /// This may take several seconds, please wait for completion
    public static let loadingPrompt = L10n.tr("Localizable", "accountSettings_loadingPrompt", fallback: "This may take several seconds, please wait for completion")
    /// Personalize this Account
    public static let personalizeHeading = L10n.tr("Localizable", "accountSettings_personalizeHeading", fallback: "Personalize this Account")
    /// Set how you want this Account to work
    public static let setBehaviorHeading = L10n.tr("Localizable", "accountSettings_setBehaviorHeading", fallback: "Set how you want this Account to work")
    /// Show Assets with Tags
    public static let showAssets = L10n.tr("Localizable", "accountSettings_showAssets", fallback: "Show Assets with Tags")
    /// Select which tags to show for assets in this Account
    public static let showAssetsSubtitle = L10n.tr("Localizable", "accountSettings_showAssetsSubtitle", fallback: "Select which tags to show for assets in this Account")
    /// Show Account QR Code
    public static let showQR = L10n.tr("Localizable", "accountSettings_showQR", fallback: "Show Account QR Code")
    /// Third-party Deposits
    public static let thirdPartyDeposits = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits", fallback: "Third-party Deposits")
    /// Account Settings
    public static let title = L10n.tr("Localizable", "accountSettings_title", fallback: "Account Settings")
    public enum AccountColor {
      /// Selected
      public static let selected = L10n.tr("Localizable", "accountSettings_accountColor_selected", fallback: "Selected")
      /// Select the color for this Account
      public static let text = L10n.tr("Localizable", "accountSettings_accountColor_text", fallback: "Select the color for this Account")
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
      /// Hide this Account in your wallet? You can always unhide it from the main application settings.
      public static let message = L10n.tr("Localizable", "accountSettings_hideAccount_message", fallback: "Hide this Account in your wallet? You can always unhide it from the main application settings.")
      /// Hide This Account
      public static let title = L10n.tr("Localizable", "accountSettings_hideAccount_title", fallback: "Hide This Account")
    }
    public enum RenameAccount {
      /// Enter a new label for this Account
      public static let subtitle = L10n.tr("Localizable", "accountSettings_renameAccount_subtitle", fallback: "Enter a new label for this Account")
      /// Rename Account
      public static let title = L10n.tr("Localizable", "accountSettings_renameAccount_title", fallback: "Rename Account")
    }
    public enum ShowAssets {
      /// Recommended
      public static let recommended = L10n.tr("Localizable", "accountSettings_showAssets_recommended", fallback: "Recommended")
      /// Select the ones you’d like shown on all your assets.
      public static let selectShown = L10n.tr("Localizable", "accountSettings_showAssets_selectShown", fallback: "Select the ones you’d like shown on all your assets.")
      /// Asset creators can add tags to them. You can choose which tags you want to see in this Account.
      public static let text = L10n.tr("Localizable", "accountSettings_showAssets_text", fallback: "Asset creators can add tags to them. You can choose which tags you want to see in this Account.")
    }
    public enum ThirdPartyDeposits {
      /// Accept all deposits
      public static let acceptAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAll", fallback: "Accept all deposits")
      /// Allow third-parties to deposit any asset
      public static let acceptAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAllSubtitle", fallback: "Allow third-parties to deposit any asset")
      /// Deny all
      public static let denyAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAll", fallback: "Deny all")
      /// Deny all third-party deposits
      public static let denyAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAllSubtitle", fallback: "Deny all third-party deposits")
      /// This account will not be able to receive "air drops" or be used by a trusted contact to assist with account recovery.
      public static let denyAllWarning = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAllWarning", fallback: "This account will not be able to receive \"air drops\" or be used by a trusted contact to assist with account recovery.")
      /// Only accept known
      public static let onlyKnown = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_onlyKnown", fallback: "Only accept known")
      /// Allow third-parties to deposit only assets this Account already holds
      public static let onlyKnownSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_onlyKnownSubtitle", fallback: "Allow third-parties to deposit only assets this Account already holds")
      /// Choose if you want to allow third parties to directly deposit assets into your Account. Deposits that you approve yourself in your Radix Wallet are always accepted.
      public static let text = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_text", fallback: "Choose if you want to allow third parties to directly deposit assets into your Account. Deposits that you approve yourself in your Radix Wallet are always accepted.")
    }
  }
  public enum AddLedgerDevice {
    public enum AddDevice {
      /// Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.
      public static let body1 = L10n.tr("Localizable", "addLedgerDevice_addDevice_body1", fallback: "Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.")
      /// Connect your Ledger to a computer running a linked Radix Connector browser extension, and make sure the Radix Babylon app is running on the Ledger device.
      public static let body2 = L10n.tr("Localizable", "addLedgerDevice_addDevice_body2", fallback: "Connect your Ledger to a computer running a linked Radix Connector browser extension, and make sure the Radix Babylon app is running on the Ledger device.")
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "addLedgerDevice_addDevice_continue", fallback: "Continue")
      /// Add Ledger Device
      public static let title = L10n.tr("Localizable", "addLedgerDevice_addDevice_title", fallback: "Add Ledger Device")
    }
    public enum AlreadyAddedAlert {
      /// You have already added this Ledger as: %@
      public static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "addLedgerDevice_alreadyAddedAlert_message", String(describing: p1), fallback: "You have already added this Ledger as: %@")
      }
      /// Ledger Already Added
      public static let title = L10n.tr("Localizable", "addLedgerDevice_alreadyAddedAlert_title", fallback: "Ledger Already Added")
    }
    public enum NameLedger {
      /// Save and Continue
      public static let continueButtonTitle = L10n.tr("Localizable", "addLedgerDevice_nameLedger_continueButtonTitle", fallback: "Save and Continue")
      /// Detected type: %@
      public static func detectedType(_ p1: Any) -> String {
        return L10n.tr("Localizable", "addLedgerDevice_nameLedger_detectedType", String(describing: p1), fallback: "Detected type: %@")
      }
      /// This will be displayed when you’re prompted to sign with this ledger
      public static let fieldHint = L10n.tr("Localizable", "addLedgerDevice_nameLedger_fieldHint", fallback: "This will be displayed when you’re prompted to sign with this ledger")
      /// Green Ledger Nano S+
      public static let namePlaceholder = L10n.tr("Localizable", "addLedgerDevice_nameLedger_namePlaceholder", fallback: "Green Ledger Nano S+")
      /// What would you like to call this Ledger device?
      public static let subtitle = L10n.tr("Localizable", "addLedgerDevice_nameLedger_subtitle", fallback: "What would you like to call this Ledger device?")
      /// Name Your Ledger
      public static let title = L10n.tr("Localizable", "addLedgerDevice_nameLedger_title", fallback: "Name Your Ledger")
    }
  }
  public enum AddressAction {
    /// Copied to Clipboard
    public static let copiedToClipboard = L10n.tr("Localizable", "addressAction_copiedToClipboard", fallback: "Copied to Clipboard")
    /// Copy Address
    public static let copyAddress = L10n.tr("Localizable", "addressAction_copyAddress", fallback: "Copy Address")
    /// Copy NFT ID
    public static let copyNftId = L10n.tr("Localizable", "addressAction_copyNftId", fallback: "Copy NFT ID")
    /// Copy Transaction ID
    public static let copyTransactionId = L10n.tr("Localizable", "addressAction_copyTransactionId", fallback: "Copy Transaction ID")
    /// There is no web browser installed in this device
    public static let noWebBrowserInstalled = L10n.tr("Localizable", "addressAction_noWebBrowserInstalled", fallback: "There is no web browser installed in this device")
    /// Show Address QR Code
    public static let showAccountQR = L10n.tr("Localizable", "addressAction_showAccountQR", fallback: "Show Address QR Code")
    /// View on Radix Dashboard
    public static let viewOnDashboard = L10n.tr("Localizable", "addressAction_viewOnDashboard", fallback: "View on Radix Dashboard")
    public enum QrCodeView {
      /// Could not create QR code
      public static let failureLabel = L10n.tr("Localizable", "addressAction_qrCodeView_failureLabel", fallback: "Could not create QR code")
      /// QR code for an account
      public static let qrCodeLabel = L10n.tr("Localizable", "addressAction_qrCodeView_qrCodeLabel", fallback: "QR code for an account")
    }
  }
  public enum AndroidProfileBackup {
    /// Back up is turned off
    public static let disabledText = L10n.tr("Localizable", "androidProfileBackup_disabledText", fallback: "Back up is turned off")
    /// Last Backed up: %@
    public static func lastBackedUp(_ p1: Any) -> String {
      return L10n.tr("Localizable", "androidProfileBackup_lastBackedUp", String(describing: p1), fallback: "Last Backed up: %@")
    }
    /// Not backed up yet
    public static let noLastBackUp = L10n.tr("Localizable", "androidProfileBackup_noLastBackUp", fallback: "Not backed up yet")
    /// Open System Backup Settings
    public static let openSystemBackupSettings = L10n.tr("Localizable", "androidProfileBackup_openSystemBackupSettings", fallback: "Open System Backup Settings")
    public enum BackupWalletData {
      /// Warning: If disabled you might lose access to your Accounts and Personas.
      public static let message = L10n.tr("Localizable", "androidProfileBackup_backupWalletData_message", fallback: "Warning: If disabled you might lose access to your Accounts and Personas.")
      /// Backup Wallet Data
      public static let title = L10n.tr("Localizable", "androidProfileBackup_backupWalletData_title", fallback: "Backup Wallet Data")
    }
  }
  public enum AppSettings {
    /// Customize your Radix Wallet
    public static let subtitle = L10n.tr("Localizable", "appSettings_subtitle", fallback: "Customize your Radix Wallet")
    /// App Settings
    public static let title = L10n.tr("Localizable", "appSettings_title", fallback: "App Settings")
    public enum ConfirmCloudSyncDisableAlert {
      /// Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?
      public static let title = L10n.tr("Localizable", "appSettings_confirmCloudSyncDisableAlert_title", fallback: "Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?")
    }
    public enum DeveloperMode {
      /// Warning: Disables website validity checks
      public static let subtitle = L10n.tr("Localizable", "appSettings_developerMode_subtitle", fallback: "Warning: Disables website validity checks")
      /// Developer Mode
      public static let title = L10n.tr("Localizable", "appSettings_developerMode_title", fallback: "Developer Mode")
    }
    public enum ResetWallet {
      /// Reset
      public static let buttonTitle = L10n.tr("Localizable", "appSettings_resetWallet_buttonTitle", fallback: "Reset")
      /// Clear all data in this Wallet
      public static let subtitle = L10n.tr("Localizable", "appSettings_resetWallet_subtitle", fallback: "Clear all data in this Wallet")
      /// Reset Wallet
      public static let title = L10n.tr("Localizable", "appSettings_resetWallet_title", fallback: "Reset Wallet")
    }
    public enum ResetWalletDialog {
      /// WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.
      public static let message = L10n.tr("Localizable", "appSettings_resetWalletDialog_message", fallback: "WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.")
      /// Reset and Delete iCloud Backup
      public static let resetAndDeleteBackupButtonTitle = L10n.tr("Localizable", "appSettings_resetWalletDialog_resetAndDeleteBackupButtonTitle", fallback: "Reset and Delete iCloud Backup")
      /// Reset Wallet
      public static let resetButtonTitle = L10n.tr("Localizable", "appSettings_resetWalletDialog_resetButtonTitle", fallback: "Reset Wallet")
      /// Reset Wallet?
      public static let title = L10n.tr("Localizable", "appSettings_resetWalletDialog_title", fallback: "Reset Wallet?")
    }
    public enum VerboseLedgerMode {
      /// When signing with your Ledger hardware wallet, should all instructions be displayed?
      public static let subtitle = L10n.tr("Localizable", "appSettings_verboseLedgerMode_subtitle", fallback: "When signing with your Ledger hardware wallet, should all instructions be displayed?")
      /// Verbose Ledger transaction signing
      public static let title = L10n.tr("Localizable", "appSettings_verboseLedgerMode_title", fallback: "Verbose Ledger transaction signing")
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
    /// Tags
    public static let tags = L10n.tr("Localizable", "assetDetails_tags", fallback: "Tags")
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
  public enum AssetTransfer {
    /// Scan a QR code of a Radix Account address from another wallet or an exchange.
    public static let qrScanInstructions = L10n.tr("Localizable", "assetTransfer_qrScanInstructions", fallback: "Scan a QR code of a Radix Account address from another wallet or an exchange.")
    /// Continue
    public static let sendTransferButton = L10n.tr("Localizable", "assetTransfer_sendTransferButton", fallback: "Continue")
    /// Message
    public static let transactionMessage = L10n.tr("Localizable", "assetTransfer_transactionMessage", fallback: "Message")
    public enum AccountList {
      /// Add Account
      public static let addAccountButton = L10n.tr("Localizable", "assetTransfer_accountList_addAccountButton", fallback: "Add Account")
      /// Account
      public static let externalAccountName = L10n.tr("Localizable", "assetTransfer_accountList_externalAccountName", fallback: "Account")
      /// From
      public static let fromLabel = L10n.tr("Localizable", "assetTransfer_accountList_fromLabel", fallback: "From")
      /// To
      public static let toLabel = L10n.tr("Localizable", "assetTransfer_accountList_toLabel", fallback: "To")
    }
    public enum AddAssets {
      /// Choose %d Assets
      public static func buttonAssets(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetTransfer_addAssets_buttonAssets", p1, fallback: "Choose %d Assets")
      }
      /// Select Assets
      public static let buttonAssetsNone = L10n.tr("Localizable", "assetTransfer_addAssets_buttonAssetsNone", fallback: "Select Assets")
      /// Choose 1 Asset
      public static let buttonAssetsOne = L10n.tr("Localizable", "assetTransfer_addAssets_buttonAssetsOne", fallback: "Choose 1 Asset")
      /// Choose Asset(s) to Send
      public static let navigationTitle = L10n.tr("Localizable", "assetTransfer_addAssets_navigationTitle", fallback: "Choose Asset(s) to Send")
    }
    public enum ChooseReceivingAccount {
      /// Enter Radix Account address
      public static let addressFieldPlaceholder = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_addressFieldPlaceholder", fallback: "Enter Radix Account address")
      /// Account already added
      public static let alreadyAddedError = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_alreadyAddedError", fallback: "Account already added")
      /// Or: Choose one of your own Accounts
      public static let chooseOwnAccount = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_chooseOwnAccount", fallback: "Or: Choose one of your own Accounts")
      /// Enter or scan an Account address
      public static let enterManually = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_enterManually", fallback: "Enter or scan an Account address")
      /// Invalid address
      public static let invalidAddressError = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_invalidAddressError", fallback: "Invalid address")
      /// Choose Receiving Account
      public static let navigationTitle = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_navigationTitle", fallback: "Choose Receiving Account")
      /// Scan Account QR Code
      public static let scanQRNavigationTitle = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_scanQRNavigationTitle", fallback: "Scan Account QR Code")
    }
    public enum FungibleResource {
      /// Balance: %@
      public static func balance(_ p1: Any) -> String {
        return L10n.tr("Localizable", "assetTransfer_fungibleResource_balance", String(describing: p1), fallback: "Balance: %@")
      }
      /// Total exceeds your current balance
      public static let totalExceedsBalance = L10n.tr("Localizable", "assetTransfer_fungibleResource_totalExceedsBalance", fallback: "Total exceeds your current balance")
    }
    public enum Header {
      /// Add Message
      public static let addMessageButton = L10n.tr("Localizable", "assetTransfer_header_addMessageButton", fallback: "Add Message")
      /// Transfer
      public static let transfer = L10n.tr("Localizable", "assetTransfer_header_transfer", fallback: "Transfer")
    }
    public enum ReceivingAccount {
      /// Add Assets
      public static let addAssetsButton = L10n.tr("Localizable", "assetTransfer_receivingAccount_addAssetsButton", fallback: "Add Assets")
      /// Choose Account
      public static let chooseAccountButton = L10n.tr("Localizable", "assetTransfer_receivingAccount_chooseAccountButton", fallback: "Choose Account")
    }
  }
  public enum AuthorizedDapps {
    /// These are the dApps that you have logged into using the Radix Wallet.
    public static let subtitle = L10n.tr("Localizable", "authorizedDapps_subtitle", fallback: "These are the dApps that you have logged into using the Radix Wallet.")
    /// Authorized dApps
    public static let title = L10n.tr("Localizable", "authorizedDapps_title", fallback: "Authorized dApps")
    /// What is a dApp?
    public static let whatIsDapp = L10n.tr("Localizable", "authorizedDapps_whatIsDapp", fallback: "What is a dApp?")
    public enum DAppDetails {
      /// dApp Definition
      public static let dAppDefinition = L10n.tr("Localizable", "authorizedDapps_dAppDetails_dAppDefinition", fallback: "dApp Definition")
      /// Forget this dApp
      public static let forgetDapp = L10n.tr("Localizable", "authorizedDapps_dAppDetails_forgetDapp", fallback: "Forget this dApp")
      /// Missing description
      public static let missingDescription = L10n.tr("Localizable", "authorizedDapps_dAppDetails_missingDescription", fallback: "Missing description")
      /// Associated NFTs
      public static let nfts = L10n.tr("Localizable", "authorizedDapps_dAppDetails_nfts", fallback: "Associated NFTs")
      /// No Personas have been used to login to this dApp.
      public static let noPersonasHeading = L10n.tr("Localizable", "authorizedDapps_dAppDetails_noPersonasHeading", fallback: "No Personas have been used to login to this dApp.")
      /// Here are the Personas that you have used to login to this dApp.
      public static let personasHeading = L10n.tr("Localizable", "authorizedDapps_dAppDetails_personasHeading", fallback: "Here are the Personas that you have used to login to this dApp.")
      /// Associated Tokens
      public static let tokens = L10n.tr("Localizable", "authorizedDapps_dAppDetails_tokens", fallback: "Associated Tokens")
      /// Unknown name
      public static let unknownTokenName = L10n.tr("Localizable", "authorizedDapps_dAppDetails_unknownTokenName", fallback: "Unknown name")
      /// Website
      public static let website = L10n.tr("Localizable", "authorizedDapps_dAppDetails_website", fallback: "Website")
    }
    public enum ForgetDappAlert {
      /// Forget dApp?
      public static let forget = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_forget", fallback: "Forget dApp?")
      /// Do you really want to forget this dApp and remove its permissions for all Personas?
      public static let message = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_message", fallback: "Do you really want to forget this dApp and remove its permissions for all Personas?")
      /// Forget This dApp
      public static let title = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_title", fallback: "Forget This dApp")
    }
    public enum PersonaDetails {
      /// Here are the Account names and addresses that you are currently sharing with %@.
      public static func accountSharingDescription(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_accountSharingDescription", String(describing: p1), fallback: "Here are the Account names and addresses that you are currently sharing with %@.")
      }
      /// Here are the dApps you have logged into with this Persona.
      public static let authorizedDappsHeading = L10n.tr("Localizable", "authorizedDapps_personaDetails_authorizedDappsHeading", fallback: "Here are the dApps you have logged into with this Persona.")
      /// Edit Account Sharing
      public static let editAccountSharing = L10n.tr("Localizable", "authorizedDapps_personaDetails_editAccountSharing", fallback: "Edit Account Sharing")
      /// Edit Avatar
      public static let editAvatarButtonTitle = L10n.tr("Localizable", "authorizedDapps_personaDetails_editAvatarButtonTitle", fallback: "Edit Avatar")
      /// Edit Persona Data
      public static let editPersona = L10n.tr("Localizable", "authorizedDapps_personaDetails_editPersona", fallback: "Edit Persona Data")
      /// Email Address
      public static let emailAddress = L10n.tr("Localizable", "authorizedDapps_personaDetails_emailAddress", fallback: "Email Address")
      /// First Name
      public static let firstName = L10n.tr("Localizable", "authorizedDapps_personaDetails_firstName", fallback: "First Name")
      /// Full Name
      public static let fullName = L10n.tr("Localizable", "authorizedDapps_personaDetails_fullName", fallback: "Full Name")
      /// Given Name(s)
      public static let givenName = L10n.tr("Localizable", "authorizedDapps_personaDetails_givenName", fallback: "Given Name(s)")
      /// Last Name
      public static let lastName = L10n.tr("Localizable", "authorizedDapps_personaDetails_lastName", fallback: "Last Name")
      /// Family Name
      public static let nameFamily = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameFamily", fallback: "Family Name")
      /// Name Order
      public static let nameVariant = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameVariant", fallback: "Name Order")
      /// Eastern style (family name first)
      public static let nameVariantEastern = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameVariantEastern", fallback: "Eastern style (family name first)")
      /// Western style (given name(s) first)
      public static let nameVariantWestern = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameVariantWestern", fallback: "Western style (given name(s) first)")
      /// Nickname
      public static let nickname = L10n.tr("Localizable", "authorizedDapps_personaDetails_nickname", fallback: "Nickname")
      /// You are not sharing any personal data with %@.
      public static func notSharingAnything(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_notSharingAnything", String(describing: p1), fallback: "You are not sharing any personal data with %@.")
      }
      /// Persona Label
      public static let personaLabelHeading = L10n.tr("Localizable", "authorizedDapps_personaDetails_personaLabelHeading", fallback: "Persona Label")
      /// Here is the personal data that you are sharing with %@.
      public static func personalDataSharingDescription(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_personalDataSharingDescription", String(describing: p1), fallback: "Here is the personal data that you are sharing with %@.")
      }
      /// Phone Number
      public static let phoneNumber = L10n.tr("Localizable", "authorizedDapps_personaDetails_phoneNumber", fallback: "Phone Number")
      /// Disconnect Persona from this dApp
      public static let removeAuthorization = L10n.tr("Localizable", "authorizedDapps_personaDetails_removeAuthorization", fallback: "Disconnect Persona from this dApp")
    }
    public enum RemoveAuthorizationAlert {
      /// Continue
      public static let confirm = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_confirm", fallback: "Continue")
      /// This dApp will no longer have authorization to see data associated with this Persona, unless you choose to login with it again in the future.
      public static let message = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_message", fallback: "This dApp will no longer have authorization to see data associated with this Persona, unless you choose to login with it again in the future.")
      /// Remove Authorization
      public static let title = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_title", fallback: "Remove Authorization")
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
      /// Checking accounts.
      public static let checkingAccounts = L10n.tr("Localizable", "biometrics_prompt_checkingAccounts", fallback: "Checking accounts.")
      /// Create Auth signing key.
      public static let createSignAuthKey = L10n.tr("Localizable", "biometrics_prompt_createSignAuthKey", fallback: "Create Auth signing key.")
      /// Authenticate to create new %@ with this phone.
      public static func creationOfEntity(_ p1: Any) -> String {
        return L10n.tr("Localizable", "biometrics_prompt_creationOfEntity", String(describing: p1), fallback: "Authenticate to create new %@ with this phone.")
      }
      /// Display seed phrase.
      public static let displaySeedPhrase = L10n.tr("Localizable", "biometrics_prompt_displaySeedPhrase", fallback: "Display seed phrase.")
      /// Check if seed phrase already exists.
      public static let importOlympiaAccounts = L10n.tr("Localizable", "biometrics_prompt_importOlympiaAccounts", fallback: "Check if seed phrase already exists.")
      /// Authenticate to sign proof with this phone.
      public static let signAuthChallenge = L10n.tr("Localizable", "biometrics_prompt_signAuthChallenge", fallback: "Authenticate to sign proof with this phone.")
      /// Authenticate to sign transaction with this phone.
      public static let signTransaction = L10n.tr("Localizable", "biometrics_prompt_signTransaction", fallback: "Authenticate to sign transaction with this phone.")
      /// Authenticate to continue
      public static let title = L10n.tr("Localizable", "biometrics_prompt_title", fallback: "Authenticate to continue")
      /// Update account metadata.
      public static let updateAccountMetadata = L10n.tr("Localizable", "biometrics_prompt_updateAccountMetadata", fallback: "Update account metadata.")
    }
  }
  public enum Common {
    /// Account
    public static let account = L10n.tr("Localizable", "common_account", fallback: "Account")
    /// Cancel
    public static let cancel = L10n.tr("Localizable", "common_cancel", fallback: "Cancel")
    /// Choose
    public static let choose = L10n.tr("Localizable", "common_choose", fallback: "Choose")
    /// Confirm
    public static let confirm = L10n.tr("Localizable", "common_confirm", fallback: "Confirm")
    /// Continue
    public static let `continue` = L10n.tr("Localizable", "common_continue", fallback: "Continue")
    /// For development only. Not usable on Radix mainnet.
    public static let developerDisclaimerText = L10n.tr("Localizable", "common_developerDisclaimerText", fallback: "For development only. Not usable on Radix mainnet.")
    /// Done
    public static let done = L10n.tr("Localizable", "common_done", fallback: "Done")
    /// An Error Occurred
    public static let errorAlertTitle = L10n.tr("Localizable", "common_errorAlertTitle", fallback: "An Error Occurred")
    /// History
    public static let history = L10n.tr("Localizable", "common_history", fallback: "History")
    /// Invalid
    public static let invalid = L10n.tr("Localizable", "common_invalid", fallback: "Invalid")
    /// Max
    public static let max = L10n.tr("Localizable", "common_max", fallback: "Max")
    /// None
    public static let `none` = L10n.tr("Localizable", "common_none", fallback: "None")
    /// OK
    public static let ok = L10n.tr("Localizable", "common_ok", fallback: "OK")
    /// Optional
    public static let `optional` = L10n.tr("Localizable", "common_optional", fallback: "Optional")
    /// Persona
    public static let persona = L10n.tr("Localizable", "common_persona", fallback: "Persona")
    /// Public
    public static let `public` = L10n.tr("Localizable", "common_public", fallback: "Public")
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
      /// Your Account lives on the Radix Network and you can access it any time in your Radix Wallet.
      public static let explanation = L10n.tr("Localizable", "createAccount_completion_explanation", fallback: "Your Account lives on the Radix Network and you can access it any time in your Radix Wallet.")
      /// You’ve created your first Account!
      public static let subtitleFirst = L10n.tr("Localizable", "createAccount_completion_subtitleFirst", fallback: "You’ve created your first Account!")
      /// Your Account has been created.
      public static let subtitleNotFirst = L10n.tr("Localizable", "createAccount_completion_subtitleNotFirst", fallback: "Your Account has been created.")
    }
    public enum DerivePublicKeys {
      /// Deriving public keys
      public static let subtitle = L10n.tr("Localizable", "createAccount_derivePublicKeys_subtitle", fallback: "Deriving public keys")
      /// Creating Account
      public static let title = L10n.tr("Localizable", "createAccount_derivePublicKeys_title", fallback: "Creating Account")
    }
    public enum Introduction {
      /// Create an Account
      public static let title = L10n.tr("Localizable", "createAccount_introduction_title", fallback: "Create an Account")
    }
    public enum NameNewAccount {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "createAccount_nameNewAccount_continue", fallback: "Continue")
      /// This can be changed any time
      public static let explanation = L10n.tr("Localizable", "createAccount_nameNewAccount_explanation", fallback: "This can be changed any time")
      /// e.g. My Main Account
      public static let placeholder = L10n.tr("Localizable", "createAccount_nameNewAccount_placeholder", fallback: "e.g. My Main Account")
      /// What would you like to call your Account?
      public static let subtitle = L10n.tr("Localizable", "createAccount_nameNewAccount_subtitle", fallback: "What would you like to call your Account?")
    }
  }
  public enum CreateEntity {
    public enum Completion {
      /// Choose Accounts
      public static let destinationChooseAccounts = L10n.tr("Localizable", "createEntity_completion_destinationChooseAccounts", fallback: "Choose Accounts")
      /// Persona Selection
      public static let destinationChoosePersonas = L10n.tr("Localizable", "createEntity_completion_destinationChoosePersonas", fallback: "Persona Selection")
      /// Gateways
      public static let destinationGateways = L10n.tr("Localizable", "createEntity_completion_destinationGateways", fallback: "Gateways")
      /// Account List
      public static let destinationHome = L10n.tr("Localizable", "createEntity_completion_destinationHome", fallback: "Account List")
      /// Persona List
      public static let destinationPersonaList = L10n.tr("Localizable", "createEntity_completion_destinationPersonaList", fallback: "Persona List")
      /// Continue to %@
      public static func goToDestination(_ p1: Any) -> String {
        return L10n.tr("Localizable", "createEntity_completion_goToDestination", String(describing: p1), fallback: "Continue to %@")
      }
      /// Congratulations
      public static let title = L10n.tr("Localizable", "createEntity_completion_title", fallback: "Congratulations")
    }
    public enum Ledger {
      /// Create Ledger Account
      public static let createAccount = L10n.tr("Localizable", "createEntity_ledger_createAccount", fallback: "Create Ledger Account")
      /// Create Ledger Persona
      public static let createPersona = L10n.tr("Localizable", "createEntity_ledger_createPersona", fallback: "Create Ledger Persona")
    }
    public enum NameNewEntity {
      /// Your Account lives on the Radix Network and you can access it any time in your Wallet.
      public static let explanation = L10n.tr("Localizable", "createEntity_nameNewEntity_explanation", fallback: "Your Account lives on the Radix Network and you can access it any time in your Wallet.")
      /// You will be asked to sign transactions with the Ledger device you select
      public static let ledgerSubtitle = L10n.tr("Localizable", "createEntity_nameNewEntity_ledgerSubtitle", fallback: "You will be asked to sign transactions with the Ledger device you select")
      /// Create with Ledger Hardware Wallet
      public static let ledgerTitle = L10n.tr("Localizable", "createEntity_nameNewEntity_ledgerTitle", fallback: "Create with Ledger Hardware Wallet")
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
      /// Personal data that you add to your Persona will only be shared with dApps with your permission.
      public static let explanation = L10n.tr("Localizable", "createPersona_completion_explanation", fallback: "Personal data that you add to your Persona will only be shared with dApps with your permission.")
      /// You’ve created your first Persona!
      public static let subtitleFirst = L10n.tr("Localizable", "createPersona_completion_subtitleFirst", fallback: "You’ve created your first Persona!")
      /// Your Persona has been created.
      public static let subtitleNotFirst = L10n.tr("Localizable", "createPersona_completion_subtitleNotFirst", fallback: "Your Persona has been created.")
    }
    public enum DerivePublicKeys {
      /// Creating Persona
      public static let title = L10n.tr("Localizable", "createPersona_derivePublicKeys_title", fallback: "Creating Persona")
    }
    public enum Explanation {
      /// Some dApps may request personal information, like name or email address, that can be added to your Persona. Add some data now if you like.
      public static let someDappsMayRequest = L10n.tr("Localizable", "createPersona_explanation_someDappsMayRequest", fallback: "Some dApps may request personal information, like name or email address, that can be added to your Persona. Add some data now if you like.")
      /// This will be shared with dApps you login to
      public static let thisWillBeShared = L10n.tr("Localizable", "createPersona_explanation_thisWillBeShared", fallback: "This will be shared with dApps you login to")
    }
    public enum Introduction {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "createPersona_introduction_continue", fallback: "Continue")
      /// Learn about Personas
      public static let learnAboutPersonas = L10n.tr("Localizable", "createPersona_introduction_learnAboutPersonas", fallback: "Learn about Personas")
      /// A Persona is an identity that you own and control. You can have as many as you like.
      public static let subtitle1 = L10n.tr("Localizable", "createPersona_introduction_subtitle1", fallback: "A Persona is an identity that you own and control. You can have as many as you like.")
      /// You will chosose a Persona when you login to dApps on Radix, and dApps may request access to personal information associated with that persona.
      public static let subtitle2 = L10n.tr("Localizable", "createPersona_introduction_subtitle2", fallback: "You will chosose a Persona when you login to dApps on Radix, and dApps may request access to personal information associated with that persona.")
      /// Create a Persona
      public static let title = L10n.tr("Localizable", "createPersona_introduction_title", fallback: "Create a Persona")
    }
    public enum NameNewPersona {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "createPersona_nameNewPersona_continue", fallback: "Continue")
      /// e.g. My Main Persona
      public static let placeholder = L10n.tr("Localizable", "createPersona_nameNewPersona_placeholder", fallback: "e.g. My Main Persona")
      /// What would you like to call your Persona?
      public static let subtitle = L10n.tr("Localizable", "createPersona_nameNewPersona_subtitle", fallback: "What would you like to call your Persona?")
    }
  }
  public enum DAppRequest {
    /// Loading…
    public static let metadataLoadingPrompt = L10n.tr("Localizable", "dAppRequest_metadataLoadingPrompt", fallback: "Loading…")
    public enum AccountPermission {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "dAppRequest_accountPermission_continue", fallback: "Continue")
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
      /// *%@* is requesting permission to *always* be able to view Account information when you login with this Persona.
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_subtitle", String(describing: p1), fallback: "*%@* is requesting permission to *always* be able to view Account information when you login with this Persona.")
      }
      /// Account Permission
      public static let title = L10n.tr("Localizable", "dAppRequest_accountPermission_title", fallback: "Account Permission")
      /// You can update this permission in wallet settings for this dApp at any time.
      public static let updateInSettingsExplanation = L10n.tr("Localizable", "dAppRequest_accountPermission_updateInSettingsExplanation", fallback: "You can update this permission in wallet settings for this dApp at any time.")
    }
    public enum ChooseAccounts {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "dAppRequest_chooseAccounts_continue", fallback: "Continue")
      /// Create a New Account
      public static let createNewAccount = L10n.tr("Localizable", "dAppRequest_chooseAccounts_createNewAccount", fallback: "Create a New Account")
      /// You are now connected to %@. You can change your preferences for this dApp in wallet settings at any time.
      public static func successMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccounts_successMessage", String(describing: p1), fallback: "You are now connected to %@. You can change your preferences for this dApp in wallet settings at any time.")
      }
      /// dApp Connection Successful
      public static let successTitle = L10n.tr("Localizable", "dAppRequest_chooseAccounts_successTitle", fallback: "dApp Connection Successful")
      /// DApp error
      public static let verificationErrorTitle = L10n.tr("Localizable", "dAppRequest_chooseAccounts_verificationErrorTitle", fallback: "DApp error")
    }
    public enum ChooseAccountsOneTime {
      /// *%@* is making a one-time request for at least %d accounts.
      public static func subtitleAtLeast(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeast", String(describing: p1), p2, fallback: "*%@* is making a one-time request for at least %d accounts.")
      }
      /// *%@* is making a one-time request for at least 1 account.
      public static func subtitleAtLeastOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastOne", String(describing: p1), fallback: "*%@* is making a one-time request for at least 1 account.")
      }
      /// *%@* is making a one-time request for any number of accounts.
      public static func subtitleAtLeastZero(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastZero", String(describing: p1), fallback: "*%@* is making a one-time request for any number of accounts.")
      }
      /// *%@* is making a one-time request for at least %d accounts.
      public static func subtitleExactly(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactly", String(describing: p1), p2, fallback: "*%@* is making a one-time request for at least %d accounts.")
      }
      /// *%@* is making a one-time request for 1 account.
      public static func subtitleExactlyOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactlyOne", String(describing: p1), fallback: "*%@* is making a one-time request for 1 account.")
      }
      /// Account Request
      public static let title = L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_title", fallback: "Account Request")
    }
    public enum ChooseAccountsOngoing {
      /// Choose at least %d accounts you wish to use with *%@*.
      public static func subtitleAtLeast(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeast", p1, String(describing: p2), fallback: "Choose at least %d accounts you wish to use with *%@*.")
      }
      /// Choose at least 1 account you wish to use with *%@*.
      public static func subtitleAtLeastOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastOne", String(describing: p1), fallback: "Choose at least 1 account you wish to use with *%@*.")
      }
      /// Choose any accounts you wish to use with *%@*.
      public static func subtitleAtLeastZero(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastZero", String(describing: p1), fallback: "Choose any accounts you wish to use with *%@*.")
      }
      /// Choose %d accounts you wish to use with *%@*.
      public static func subtitleExactly(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactly", p1, String(describing: p2), fallback: "Choose %d accounts you wish to use with *%@*.")
      }
      /// Choose 1 account you wish to use with *%@*.
      public static func subtitleExactlyOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactlyOne", String(describing: p1), fallback: "Choose 1 account you wish to use with *%@*.")
      }
      /// Account Permission
      public static let title = L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_title", fallback: "Account Permission")
    }
    public enum Completion {
      /// Request from %@ complete
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_completion_subtitle", String(describing: p1), fallback: "Request from %@ complete")
      }
      /// Success
      public static let title = L10n.tr("Localizable", "dAppRequest_completion_title", fallback: "Success")
    }
    public enum Login {
      /// Choose a Persona
      public static let choosePersona = L10n.tr("Localizable", "dAppRequest_login_choosePersona", fallback: "Choose a Persona")
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "dAppRequest_login_continue", fallback: "Continue")
      /// Your last login was on %@
      public static func lastLoginWasOn(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_lastLoginWasOn", String(describing: p1), fallback: "Your last login was on %@")
      }
      /// %@ is requesting that you login with a Persona.
      public static func subtitleKnownDapp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_subtitleKnownDapp", String(describing: p1), fallback: "%@ is requesting that you login with a Persona.")
      }
      /// %@ is requesting that you login for the *first time* with a Persona.
      public static func subtitleNewDapp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_subtitleNewDapp", String(describing: p1), fallback: "%@ is requesting that you login for the *first time* with a Persona.")
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
      /// Danger! Bad dApp configuration, or you're being spoofed!
      public static let message = L10n.tr("Localizable", "dAppRequest_metadataLoadingAlert_message", fallback: "Danger! Bad dApp configuration, or you're being spoofed!")
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
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_continue", fallback: "Continue")
      /// *%@* is requesting that you provide some pieces of personal data *just one time*
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataOneTime_subtitle", String(describing: p1), fallback: "*%@* is requesting that you provide some pieces of personal data *just one time*")
      }
      /// One-Time Data Request
      public static let title = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_title", fallback: "One-Time Data Request")
    }
    public enum PersonalDataPermission {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "dAppRequest_personalDataPermission_continue", fallback: "Continue")
      /// *%@* is requesting permission to *always* be able to view the following personal data when you login with this Persona.
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataPermission_subtitle", String(describing: p1), fallback: "*%@* is requesting permission to *always* be able to view the following personal data when you login with this Persona.")
      }
      /// Personal Data Permission
      public static let title = L10n.tr("Localizable", "dAppRequest_personalDataPermission_title", fallback: "Personal Data Permission")
      /// You can update this permission in your Settings at any time.
      public static let updateInSettingsExplanation = L10n.tr("Localizable", "dAppRequest_personalDataPermission_updateInSettingsExplanation", fallback: "You can update this permission in your Settings at any time.")
    }
    public enum RequestMalformedAlert {
      /// Request received from dApp is invalid.
      public static let message = L10n.tr("Localizable", "dAppRequest_requestMalformedAlert_message", fallback: "Request received from dApp is invalid.")
    }
    public enum RequestPersonaNotFoundAlert {
      /// dApp specified an invalid Persona.
      public static let message = L10n.tr("Localizable", "dAppRequest_requestPersonaNotFoundAlert_message", fallback: "dApp specified an invalid Persona.")
    }
    public enum RequestWrongNetworkAlert {
      /// dApp made a requested intended for network %@, but you are currently connected to %@.
      public static func message(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_requestWrongNetworkAlert_message", String(describing: p1), String(describing: p2), fallback: "dApp made a requested intended for network %@, but you are currently connected to %@.")
      }
    }
    public enum ResponseFailureAlert {
      /// Failed to send request response to dApp.
      public static let message = L10n.tr("Localizable", "dAppRequest_responseFailureAlert_message", fallback: "Failed to send request response to dApp.")
    }
    public enum ValidationOutcome {
      /// Invalid value of `numberOfAccountsInvalid`: must not be be `exactly(0)` nor can `quantity` be negative
      public static let devExplanationBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationBadContent", fallback: "Invalid value of `numberOfAccountsInvalid`: must not be be `exactly(0)` nor can `quantity` be negative")
      /// %@ (CE: %@, wallet: %@)
      public static func devExplanationIncompatibleVersion(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationIncompatibleVersion", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "%@ (CE: %@, wallet: %@)")
      }
      /// '%@' is not valid account address.
      public static func devExplanationInvalidDappDefinitionAddress(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationInvalidDappDefinitionAddress", String(describing: p1), fallback: "'%@' is not valid account address.")
      }
      /// '%@' is not valid origin.
      public static func devExplanationInvalidOrigin(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationInvalidOrigin", String(describing: p1), fallback: "'%@' is not valid origin.")
      }
      /// Invalid data in request
      public static let shortExplanationBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationBadContent", fallback: "Invalid data in request")
      /// Please update Radix Wallet
      public static let shortExplanationIncompatibleVersionCEGreater = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationIncompatibleVersionCEGreater", fallback: "Please update Radix Wallet")
      /// Please update Radix Connector browser extension
      public static let shortExplanationIncompatibleVersionCENotGreater = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationIncompatibleVersionCENotGreater", fallback: "Please update Radix Connector browser extension")
      /// Invalid dApp Definition Address
      public static let shortExplanationInvalidDappDefinitionAddress = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationInvalidDappDefinitionAddress", fallback: "Invalid dApp Definition Address")
      /// Invalid origin
      public static let shortExplanationInvalidOrigin = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationInvalidOrigin", fallback: "Invalid origin")
      /// Radix Connect connection error
      public static let shortExplanationP2PError = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationP2PError", fallback: "Radix Connect connection error")
      /// Invalid content
      public static let subtitleBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_subtitleBadContent", fallback: "Invalid content")
      /// Incompatible connector extension
      public static let subtitleIncompatibleVersion = L10n.tr("Localizable", "dAppRequest_validationOutcome_subtitleIncompatibleVersion", fallback: "Incompatible connector extension")
      /// Network mismatch
      public static let subtitleWrongNetworkID = L10n.tr("Localizable", "dAppRequest_validationOutcome_subtitleWrongNetworkID", fallback: "Network mismatch")
    }
  }
  public enum DisplayMnemonics {
    /// Back up this Seed Phrase
    public static let backUpWarning = L10n.tr("Localizable", "displayMnemonics_backUpWarning", fallback: "Back up this Seed Phrase")
    /// Seed Phrases
    public static let seedPhrases = L10n.tr("Localizable", "displayMnemonics_seedPhrases", fallback: "Seed Phrases")
    /// You are responsible for the security of your Seed Phrase
    public static let seedPhraseSecurityInfo = L10n.tr("Localizable", "displayMnemonics_seedPhraseSecurityInfo", fallback: "You are responsible for the security of your Seed Phrase")
    public enum CautionAlert {
      /// A seed phrase provides full control of its Accounts. Do not view in a public area. Back up the seed phrase words securely. Screenshots are disabled.
      public static let message = L10n.tr("Localizable", "displayMnemonics_cautionAlert_message", fallback: "A seed phrase provides full control of its Accounts. Do not view in a public area. Back up the seed phrase words securely. Screenshots are disabled.")
      /// Reveal Seed Phrase
      public static let revealButtonLabel = L10n.tr("Localizable", "displayMnemonics_cautionAlert_revealButtonLabel", fallback: "Reveal Seed Phrase")
      /// Use Caution
      public static let title = L10n.tr("Localizable", "displayMnemonics_cautionAlert_title", fallback: "Use Caution")
    }
    public enum ConnectedAccountsLabel {
      /// Connected to %d accounts
      public static func many(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsLabel_many", p1, fallback: "Connected to %d accounts")
      }
      /// Connected to %d account
      public static func one(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsLabel_one", p1, fallback: "Connected to %d account")
      }
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
      /// Add Data Fields
      public static let add = L10n.tr("Localizable", "editPersona_addAField_add", fallback: "Add Data Fields")
      /// Choose one or more data fields to add to this Persona.
      public static let subtitle = L10n.tr("Localizable", "editPersona_addAField_subtitle", fallback: "Choose one or more data fields to add to this Persona.")
      /// Add a Field
      public static let title = L10n.tr("Localizable", "editPersona_addAField_title", fallback: "Add a Field")
    }
    public enum CloseConfirmationDialog {
      /// Discard Changes
      public static let discardChanges = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_discardChanges", fallback: "Discard Changes")
      /// Keep Editing
      public static let keepEditing = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_keepEditing", fallback: "Keep Editing")
      /// Are you sure you want to discard changes to this Persona?
      public static let message = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_message", fallback: "Are you sure you want to discard changes to this Persona?")
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
      /// Invalid Persona specified by dApp
      public static let invalidPersonaId = L10n.tr("Localizable", "error_dappRequest_invalidPersonaId", fallback: "Invalid Persona specified by dApp")
      /// Invalid request
      public static let invalidRequest = L10n.tr("Localizable", "error_dappRequest_invalidRequest", fallback: "Invalid request")
    }
    public enum ProfileLoad {
      /// Failed to import Radix Wallet backup: %@
      public static func decodingError(_ p1: Any) -> String {
        return L10n.tr("Localizable", "error_profileLoad_decodingError", String(describing: p1), fallback: "Failed to import Radix Wallet backup: %@")
      }
      /// Failed to import Radix Wallet backup, error: %@, version: %@
      public static func failedToCreateProfileFromSnapshot(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "error_profileLoad_failedToCreateProfileFromSnapshot", String(describing: p1), String(describing: p2), fallback: "Failed to import Radix Wallet backup, error: %@, version: %@")
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
    /// Choose the gateway your wallet will use to connect to the Radix Network or test networks. Only change this if you know what you’re doing.
    public static let subtitle = L10n.tr("Localizable", "gateways_subtitle", fallback: "Choose the gateway your wallet will use to connect to the Radix Network or test networks. Only change this if you know what you’re doing.")
    /// Gateways
    public static let title = L10n.tr("Localizable", "gateways_title", fallback: "Gateways")
    /// What is a Gateway?
    public static let whatIsAGateway = L10n.tr("Localizable", "gateways_whatIsAGateway", fallback: "What is a Gateway?")
    public enum AddNewGateway {
      /// Add Gateway
      public static let addGatewayButtonTitle = L10n.tr("Localizable", "gateways_addNewGateway_addGatewayButtonTitle", fallback: "Add Gateway")
      /// This gateway is already added
      public static let errorDuplicateURL = L10n.tr("Localizable", "gateways_addNewGateway_errorDuplicateURL", fallback: "This gateway is already added")
      /// No gateway found at specified URL
      public static let errorNoGatewayFound = L10n.tr("Localizable", "gateways_addNewGateway_errorNoGatewayFound", fallback: "No gateway found at specified URL")
      /// There was an error establishing a connection
      public static let establishingConnectionErrorMessage = L10n.tr("Localizable", "gateways_addNewGateway_establishingConnectionErrorMessage", fallback: "There was an error establishing a connection")
      /// Enter a gateway URL
      public static let subtitle = L10n.tr("Localizable", "gateways_addNewGateway_subtitle", fallback: "Enter a gateway URL")
      /// Enter full URL
      public static let textFieldPlaceholder = L10n.tr("Localizable", "gateways_addNewGateway_textFieldPlaceholder", fallback: "Enter full URL")
      /// Add New Gateway
      public static let title = L10n.tr("Localizable", "gateways_addNewGateway_title", fallback: "Add New Gateway")
    }
    public enum RemoveGatewayAlert {
      /// You will no longer be able to connect to this gateway.
      public static let message = L10n.tr("Localizable", "gateways_removeGatewayAlert_message", fallback: "You will no longer be able to connect to this gateway.")
      /// Remove Gateway
      public static let title = L10n.tr("Localizable", "gateways_removeGatewayAlert_title", fallback: "Remove Gateway")
    }
  }
  public enum HomePage {
    /// Please back up your seed phrase
    public static let applySecuritySettings = L10n.tr("Localizable", "homePage_applySecuritySettings", fallback: "Please back up your seed phrase")
    /// I have backed up this seed phrase
    public static let backedUpMnemonicHeading = L10n.tr("Localizable", "homePage_backedUpMnemonicHeading", fallback: "I have backed up this seed phrase")
    /// Create a New Account
    public static let createNewAccount = L10n.tr("Localizable", "homePage_createNewAccount", fallback: "Create a New Account")
    /// Legacy
    public static let legacyAccountHeading = L10n.tr("Localizable", "homePage_legacyAccountHeading", fallback: "Legacy")
    /// Welcome. Here are all your Accounts on the Radix Network.
    public static let subtitle = L10n.tr("Localizable", "homePage_subtitle", fallback: "Welcome. Here are all your Accounts on the Radix Network.")
    /// Radix Wallet
    public static let title = L10n.tr("Localizable", "homePage_title", fallback: "Radix Wallet")
    /// Total value
    public static let totalValue = L10n.tr("Localizable", "homePage_totalValue", fallback: "Total value")
    public enum AccountsTag {
      /// dApp Definition
      public static let dAppDefinition = L10n.tr("Localizable", "homePage_accountsTag_dAppDefinition", fallback: "dApp Definition")
      /// Ledger
      public static let ledgerBabylon = L10n.tr("Localizable", "homePage_accountsTag_ledgerBabylon", fallback: "Ledger")
      /// Legacy (Ledger)
      public static let ledgerLegacy = L10n.tr("Localizable", "homePage_accountsTag_ledgerLegacy", fallback: "Legacy (Ledger)")
      /// Legacy
      public static let legacySoftware = L10n.tr("Localizable", "homePage_accountsTag_legacySoftware", fallback: "Legacy")
    }
    public enum VisitDashboard {
      /// Ready to get started using the Radix Network and your Wallet?
      public static let subtitle = L10n.tr("Localizable", "homePage_visitDashboard_subtitle", fallback: "Ready to get started using the Radix Network and your Wallet?")
      /// Visit the Radix Dashboard
      public static let title = L10n.tr("Localizable", "homePage_visitDashboard_title", fallback: "Visit the Radix Dashboard")
    }
  }
  public enum IOSProfileBackup {
    /// Available backups:
    public static let cloudBackupWallet = L10n.tr("Localizable", "iOSProfileBackup_cloudBackupWallet", fallback: "Available backups:")
    /// Backup created by: %@
    public static func creatingDevice(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_creatingDevice", String(describing: p1), fallback: "Backup created by: %@")
    }
    /// Creation date: %@
    public static func creationDateLabel(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_creationDateLabel", String(describing: p1), fallback: "Creation date: %@")
    }
    /// Import From Backup
    public static let importBackupWallet = L10n.tr("Localizable", "iOSProfileBackup_importBackupWallet", fallback: "Import From Backup")
    /// Incompatible Wallet data
    public static let incompatibleWalletDataLabel = L10n.tr("Localizable", "iOSProfileBackup_incompatibleWalletDataLabel", fallback: "Incompatible Wallet data")
    /// Last modified date: %@
    public static func lastModifedDateLabel(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_lastModifedDateLabel", String(describing: p1), fallback: "Last modified date: %@")
    }
    /// Last used on device: %@
    public static func lastUsedOnDeviceLabel(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_lastUsedOnDeviceLabel", String(describing: p1), fallback: "Last used on device: %@")
    }
    /// Wallet Data Backup
    public static let navigationTitle = L10n.tr("Localizable", "iOSProfileBackup_navigationTitle", fallback: "Wallet Data Backup")
    /// No backups found in iCloud
    public static let noCloudBackup = L10n.tr("Localizable", "iOSProfileBackup_noCloudBackup", fallback: "No backups found in iCloud")
    /// Number of networks: %d
    public static func numberOfNetworksLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_numberOfNetworksLabel", p1, fallback: "Number of networks: %d")
    }
    /// This Device
    public static let thisDevice = L10n.tr("Localizable", "iOSProfileBackup_thisDevice", fallback: "This Device")
    /// Number of Accounts: %d
    public static func totalAccountsNumberLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_totalAccountsNumberLabel", p1, fallback: "Number of Accounts: %d")
    }
    /// Number of Personas: %d
    public static func totalPersonasNumberLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_totalPersonasNumberLabel", p1, fallback: "Number of Personas: %d")
    }
    /// Use iCloud Backup Data
    public static let useICloudBackup = L10n.tr("Localizable", "iOSProfileBackup_useICloudBackup", fallback: "Use iCloud Backup Data")
    public enum ProfileSync {
      /// Warning: If disabled you might lose access to your Accounts and Personas.
      public static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_profileSync_subtitle", fallback: "Warning: If disabled you might lose access to your Accounts and Personas.")
      /// Sync Wallet Data to iCloud
      public static let title = L10n.tr("Localizable", "iOSProfileBackup_profileSync_title", fallback: "Sync Wallet Data to iCloud")
    }
  }
  public enum ImportMnemonic {
    /// Advanced Mode
    public static let advancedModeButton = L10n.tr("Localizable", "importMnemonic_advancedModeButton", fallback: "Advanced Mode")
    /// Incorrect seed phrase
    public static let checksumFailure = L10n.tr("Localizable", "importMnemonic_checksumFailure", fallback: "Incorrect seed phrase")
    /// Fewer words
    public static let fewerWords = L10n.tr("Localizable", "importMnemonic_fewerWords", fallback: "Fewer words")
    /// Import
    public static let importSeedPhrase = L10n.tr("Localizable", "importMnemonic_importSeedPhrase", fallback: "Import")
    /// More words
    public static let moreWords = L10n.tr("Localizable", "importMnemonic_moreWords", fallback: "More words")
    /// Import Seed Phrase
    public static let navigationTitle = L10n.tr("Localizable", "importMnemonic_navigationTitle", fallback: "Import Seed Phrase")
    /// Passphrase
    public static let passphrase = L10n.tr("Localizable", "importMnemonic_passphrase", fallback: "Passphrase")
    /// Optional BIP39 Passphrase. This is not your wallet password, and the Radix Desktop Wallet did not use a BIP39 passphrase. This is only to support import from other wallets that may have used one.
    public static let passphraseHint = L10n.tr("Localizable", "importMnemonic_passphraseHint", fallback: "Optional BIP39 Passphrase. This is not your wallet password, and the Radix Desktop Wallet did not use a BIP39 passphrase. This is only to support import from other wallets that may have used one.")
    /// Passphrase
    public static let passphrasePlaceholder = L10n.tr("Localizable", "importMnemonic_passphrasePlaceholder", fallback: "Passphrase")
    /// Regular Mode
    public static let regularModeButton = L10n.tr("Localizable", "importMnemonic_regularModeButton", fallback: "Regular Mode")
    /// Word %d
    public static func wordHeading(_ p1: Int) -> String {
      return L10n.tr("Localizable", "importMnemonic_wordHeading", p1, fallback: "Word %d")
    }
    public enum OffDevice {
      /// Without revealing location, vague hint on where this mnemonic is backed up, if anywhere.
      public static let locationHint = L10n.tr("Localizable", "importMnemonic_offDevice_locationHint", fallback: "Without revealing location, vague hint on where this mnemonic is backed up, if anywhere.")
      /// In that book my mother used to read to me at my best childhoods summer vacation place
      public static let locationPlaceholder = L10n.tr("Localizable", "importMnemonic_offDevice_locationPlaceholder", fallback: "In that book my mother used to read to me at my best childhoods summer vacation place")
      /// Backup location?
      public static let locationPrimaryHeading = L10n.tr("Localizable", "importMnemonic_offDevice_locationPrimaryHeading", fallback: "Backup location?")
      /// Save with description
      public static let saveWithDescription = L10n.tr("Localizable", "importMnemonic_offDevice_saveWithDescription", fallback: "Save with description")
      /// Save without description
      public static let saveWithoutDescription = L10n.tr("Localizable", "importMnemonic_offDevice_saveWithoutDescription", fallback: "Save without description")
      /// Without revealing the words, what comes to mind when reading this seed phrase?
      public static let storyHint = L10n.tr("Localizable", "importMnemonic_offDevice_storyHint", fallback: "Without revealing the words, what comes to mind when reading this seed phrase?")
      /// Hitchcock's The Birds mixed with Office space
      public static let storyPlaceholder = L10n.tr("Localizable", "importMnemonic_offDevice_storyPlaceholder", fallback: "Hitchcock's The Birds mixed with Office space")
      /// Tell a story
      public static let storyPrimaryHeading = L10n.tr("Localizable", "importMnemonic_offDevice_storyPrimaryHeading", fallback: "Tell a story")
    }
    public enum TempAndroid {
      /// Change seed phrase length
      public static let changeSeedPhrase = L10n.tr("Localizable", "importMnemonic_tempAndroid_changeSeedPhrase", fallback: "Change seed phrase length")
      /// Recover Mnemonic
      public static let heading = L10n.tr("Localizable", "importMnemonic_tempAndroid_heading", fallback: "Recover Mnemonic")
      /// %d word seed phrase
      public static func seedLength(_ p1: Int) -> String {
        return L10n.tr("Localizable", "importMnemonic_tempAndroid_seedLength", p1, fallback: "%d word seed phrase")
      }
    }
  }
  public enum ImportOlympiaAccounts {
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
    /// No mnemonic found for accounts
    public static let noMnemonicFound = L10n.tr("Localizable", "importOlympiaAccounts_noMnemonicFound", fallback: "No mnemonic found for accounts")
    /// Passphrase
    public static let passphrase = L10n.tr("Localizable", "importOlympiaAccounts_passphrase", fallback: "Passphrase")
    /// Seed phrase
    public static let seedPhrase = L10n.tr("Localizable", "importOlympiaAccounts_seedPhrase", fallback: "Seed phrase")
    public enum AccountsToImport {
      /// Import %d accounts
      public static func buttonManyAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_buttonManyAccounts", p1, fallback: "Import %d accounts")
      }
      /// Import 1 account
      public static let buttonOneAcccount = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_buttonOneAcccount", fallback: "Import 1 account")
      /// Ledger (Legacy)
      public static let ledgerAccount = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_ledgerAccount", fallback: "Ledger (Legacy)")
      /// Legacy Account
      public static let legacyAccount = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_legacyAccount", fallback: "Legacy Account")
      /// New Address
      public static let newAddressLabel = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_newAddressLabel", fallback: "New Address")
      /// Olympia Address (Obsolete)
      public static let olympiaAddressLabel = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_olympiaAddressLabel", fallback: "Olympia Address (Obsolete)")
      /// The following accounts will be imported to your new wallet.
      public static let subtitle = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_subtitle", fallback: "The following accounts will be imported to your new wallet.")
      /// Import Accounts
      public static let title = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_title", fallback: "Import Accounts")
      /// Unnamed
      public static let unnamed = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_unnamed", fallback: "Unnamed")
    }
    public enum Completion {
      /// Continue to Account List
      public static let accountListButtonTitle = L10n.tr("Localizable", "importOlympiaAccounts_completion_accountListButtonTitle", fallback: "Continue to Account List")
      /// They will live on the Radix Network and you can access them anytime in your Wallet.
      public static let explanation = L10n.tr("Localizable", "importOlympiaAccounts_completion_explanation", fallback: "They will live on the Radix Network and you can access them anytime in your Wallet.")
      /// You've imported your accounts
      public static let subtitleMultiple = L10n.tr("Localizable", "importOlympiaAccounts_completion_subtitleMultiple", fallback: "You've imported your accounts")
      /// You've imported your account
      public static let subtitleSingle = L10n.tr("Localizable", "importOlympiaAccounts_completion_subtitleSingle", fallback: "You've imported your account")
      /// Congratulations
      public static let title = L10n.tr("Localizable", "importOlympiaAccounts_completion_title", fallback: "Congratulations")
    }
    public enum ScanQR {
      /// Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.
      public static let instructions = L10n.tr("Localizable", "importOlympiaAccounts_scanQR_instructions", fallback: "Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.")
      /// Scanned: %d/%d
      public static func scannedLabel(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "importOlympiaAccounts_scanQR_scannedLabel", p1, p2, fallback: "Scanned: %d/%d")
      }
      /// Import Legacy Olympia Accounts
      public static let title = L10n.tr("Localizable", "importOlympiaAccounts_scanQR_title", fallback: "Import Legacy Olympia Accounts")
    }
    public enum VerifySeedPhrase {
      /// To complete importing your accounts, please view your seed phrase in the Radix Desktop Wallet and enter the words here.
      public static let subtitle = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_subtitle", fallback: "To complete importing your accounts, please view your seed phrase in the Radix Desktop Wallet and enter the words here.")
      /// Verify With Your Seed Phrase
      public static let title = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_title", fallback: "Verify With Your Seed Phrase")
      /// This is a one-time process to import your accounts. Never give your seed phrase to anyone for any reason.
      public static let warning = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_warning", fallback: "This is a one-time process to import your accounts. Never give your seed phrase to anyone for any reason.")
    }
  }
  public enum ImportOlympiaLedgerAccounts {
    /// Accounts remaining to verify: %d
    public static func accountCount(_ p1: Int) -> String {
      return L10n.tr("Localizable", "importOlympiaLedgerAccounts_accountCount", p1, fallback: "Accounts remaining to verify: %d")
    }
    /// Continue
    public static let continueButtonTitle = L10n.tr("Localizable", "importOlympiaLedgerAccounts_continueButtonTitle", fallback: "Continue")
    /// Connect your next Ledger device, launch the Radix Babylon app on it, and tap Continue here.
    public static let instruction = L10n.tr("Localizable", "importOlympiaLedgerAccounts_instruction", fallback: "Connect your next Ledger device, launch the Radix Babylon app on it, and tap Continue here.")
    /// Already verified Ledger devices:
    public static let listHeading = L10n.tr("Localizable", "importOlympiaLedgerAccounts_listHeading", fallback: "Already verified Ledger devices:")
    /// You are attempting to import one or more Olympia accounts that must be verified with a Ledger hardware wallet device.
    public static let subtitle = L10n.tr("Localizable", "importOlympiaLedgerAccounts_subtitle", fallback: "You are attempting to import one or more Olympia accounts that must be verified with a Ledger hardware wallet device.")
    /// Verify With Ledger Device
    public static let title = L10n.tr("Localizable", "importOlympiaLedgerAccounts_title", fallback: "Verify With Ledger Device")
  }
  public enum ImportProfile {
    /// Import Radix Wallet backup
    public static let importProfile = L10n.tr("Localizable", "importProfile_importProfile", fallback: "Import Radix Wallet backup")
  }
  public enum LedgerHardwareDevices {
    /// Added
    public static let addedHeading = L10n.tr("Localizable", "ledgerHardwareDevices_addedHeading", fallback: "Added")
    /// Add Ledger Device
    public static let addNewLedger = L10n.tr("Localizable", "ledgerHardwareDevices_addNewLedger", fallback: "Add Ledger Device")
    /// Continue
    public static let continueWithLedger = L10n.tr("Localizable", "ledgerHardwareDevices_continueWithLedger", fallback: "Continue")
    /// What is a Ledger Factor Source
    public static let ledgerFactorSourceInfoCaption = L10n.tr("Localizable", "ledgerHardwareDevices_ledgerFactorSourceInfoCaption", fallback: "What is a Ledger Factor Source")
    /// Choose Ledger
    public static let navigationTitleAllowSelection = L10n.tr("Localizable", "ledgerHardwareDevices_navigationTitleAllowSelection", fallback: "Choose Ledger")
    /// Ledger Devices
    public static let navigationTitleGeneral = L10n.tr("Localizable", "ledgerHardwareDevices_navigationTitleGeneral", fallback: "Ledger Devices")
    /// Choose Ledger Device
    public static let navigationTitleNoSelection = L10n.tr("Localizable", "ledgerHardwareDevices_navigationTitleNoSelection", fallback: "Choose Ledger Device")
    /// Here are all the Ledger devices you have added.
    public static let subtitleAllLedgers = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleAllLedgers", fallback: "Here are all the Ledger devices you have added.")
    /// Could not find Ledger devices
    public static let subtitleFailure = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleFailure", fallback: "Could not find Ledger devices")
    /// No Ledger devices currently added to your Radix Wallet
    public static let subtitleNoLedgers = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleNoLedgers", fallback: "No Ledger devices currently added to your Radix Wallet")
    /// Choose a Ledger device to use
    public static let subtitleSelectLedger = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleSelectLedger", fallback: "Choose a Ledger device to use")
    /// Choose an existing Ledger or add a new one
    public static let subtitleSelectLedgerExisting = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleSelectLedgerExisting", fallback: "Choose an existing Ledger or add a new one")
    /// Last Used
    public static let usedHeading = L10n.tr("Localizable", "ledgerHardwareDevices_usedHeading", fallback: "Last Used")
    public enum LinkConnectorAlert {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_continue", fallback: "Continue")
      /// To use a Ledger hardware wallet device, it must be connected to a computer running the Radix Connector browser extension.
      public static let message = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_message", fallback: "To use a Ledger hardware wallet device, it must be connected to a computer running the Radix Connector browser extension.")
      /// Link a Connector
      public static let title = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_title", fallback: "Link a Connector")
    }
  }
  public enum LinkedConnectors {
    /// Last connected %@
    public static func lastConnected(_ p1: Any) -> String {
      return L10n.tr("Localizable", "linkedConnectors_lastConnected", String(describing: p1), fallback: "Last connected %@")
    }
    /// Link New Connector
    public static let linkNewConnector = L10n.tr("Localizable", "linkedConnectors_linkNewConnector", fallback: "Link New Connector")
    /// Connect your Radix Wallet to desktop web browsers by linking to the Radix Connector browser extension. Here are your linked Connectors.
    public static let subtitle = L10n.tr("Localizable", "linkedConnectors_subtitle", fallback: "Connect your Radix Wallet to desktop web browsers by linking to the Radix Connector browser extension. Here are your linked Connectors.")
    /// Linked Connectors
    public static let title = L10n.tr("Localizable", "linkedConnectors_title", fallback: "Linked Connectors")
    public enum CameraPermissionDeniedAlert {
      /// Camera access is required to link to a Connector.
      public static let message = L10n.tr("Localizable", "linkedConnectors_cameraPermissionDeniedAlert_message", fallback: "Camera access is required to link to a Connector.")
      /// Access Required
      public static let title = L10n.tr("Localizable", "linkedConnectors_cameraPermissionDeniedAlert_title", fallback: "Access Required")
    }
    public enum LocalNetworkPermissionDeniedAlert {
      /// Local network access is required to link to a Connector.
      public static let message = L10n.tr("Localizable", "linkedConnectors_localNetworkPermissionDeniedAlert_message", fallback: "Local network access is required to link to a Connector.")
      /// Access Required
      public static let title = L10n.tr("Localizable", "linkedConnectors_localNetworkPermissionDeniedAlert_title", fallback: "Access Required")
    }
    public enum NameNewConnector {
      /// Continue
      public static let saveLinkButtonTitle = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_saveLinkButtonTitle", fallback: "Continue")
      /// What would you like to call this Connector?
      public static let subtitle = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_subtitle", fallback: "What would you like to call this Connector?")
      /// Name this connector e.g. ‘Chrome on MacBook Pro’
      public static let textFieldHint = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_textFieldHint", fallback: "Name this connector e.g. ‘Chrome on MacBook Pro’")
      /// e.g. Chrome on Personal Laptop
      public static let textFieldPlaceholder = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_textFieldPlaceholder", fallback: "e.g. Chrome on Personal Laptop")
      /// Name New Connector
      public static let title = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_title", fallback: "Name New Connector")
    }
    public enum NewConnection {
      /// Linking…
      public static let linking = L10n.tr("Localizable", "linkedConnectors_newConnection_linking", fallback: "Linking…")
      /// Scan the QR code shown in the Radix Connector browser extension
      public static let subtitle = L10n.tr("Localizable", "linkedConnectors_newConnection_subtitle", fallback: "Scan the QR code shown in the Radix Connector browser extension")
      /// Link New Connector
      public static let title = L10n.tr("Localizable", "linkedConnectors_newConnection_title", fallback: "Link New Connector")
    }
    public enum RemoveConnectionAlert {
      /// You will no longer be able to connect your wallet to this device and browser combination.
      public static let message = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_message", fallback: "You will no longer be able to connect your wallet to this device and browser combination.")
      /// Remove
      public static let removeButtonTitle = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_removeButtonTitle", fallback: "Remove")
      /// Remove Connection
      public static let title = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_title", fallback: "Remove Connection")
    }
  }
  public enum Misc {
    public enum RemoteThumbnails {
      /// Can't load image
      public static let loadingFailure = L10n.tr("Localizable", "misc_remoteThumbnails_loadingFailure", fallback: "Can't load image")
      /// Can't displays image of vector type
      public static let vectorImageFailure = L10n.tr("Localizable", "misc_remoteThumbnails_vectorImageFailure", fallback: "Can't displays image of vector type")
    }
  }
  public enum Onboarding {
    /// I'm a New Radix Wallet User
    public static let newUser = L10n.tr("Localizable", "onboarding_newUser", fallback: "I'm a New Radix Wallet User")
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
    /// Here are all of your current Personas.
    public static let subtitle = L10n.tr("Localizable", "personas_subtitle", fallback: "Here are all of your current Personas.")
    /// Personas
    public static let title = L10n.tr("Localizable", "personas_title", fallback: "Personas")
    /// What is a Persona?
    public static let whatIsPersona = L10n.tr("Localizable", "personas_whatIsPersona", fallback: "What is a Persona?")
  }
  public enum RevealSeedPhrase {
    /// Passphrase
    public static let passphrase = L10n.tr("Localizable", "revealSeedPhrase_passphrase", fallback: "Passphrase")
    /// Reveal Seed Phrase
    public static let title = L10n.tr("Localizable", "revealSeedPhrase_title", fallback: "Reveal Seed Phrase")
    /// For your safety, make sure no one is looking at your screen. Taking a screen shot has been disabled.
    public static let warning = L10n.tr("Localizable", "revealSeedPhrase_warning", fallback: "For your safety, make sure no one is looking at your screen. Taking a screen shot has been disabled.")
    /// Word %d
    public static func wordLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "revealSeedPhrase_wordLabel", p1, fallback: "Word %d")
    }
    public enum WarningDialog {
      /// I have backed up this seed phrase
      public static let confirmButton = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_confirmButton", fallback: "I have backed up this seed phrase")
      /// Are you sure you have backed up your seed phrase?
      public static let subtitle = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_subtitle", fallback: "Are you sure you have backed up your seed phrase?")
      /// Use Caution
      public static let title = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_title", fallback: "Use Caution")
    }
  }
  public enum SeedPhrases {
    /// A Seed Phrase provides full access to your accounts and funds. When viewing, ensure you’re in a safe environment and no one is looking at your screen.
    public static let message = L10n.tr("Localizable", "seedPhrases_message", fallback: "A Seed Phrase provides full access to your accounts and funds. When viewing, ensure you’re in a safe environment and no one is looking at your screen.")
    /// Seed Phrases
    public static let title = L10n.tr("Localizable", "seedPhrases_title", fallback: "Seed Phrases")
    /// You are responsible for the security of your Seed Phrase
    public static let warning = L10n.tr("Localizable", "seedPhrases_warning", fallback: "You are responsible for the security of your Seed Phrase")
    public enum SeedPhrase {
      /// Connected to %d accounts
      public static func multipleConnectedAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "seedPhrases_seedPhrase_multipleConnectedAccounts", p1, fallback: "Connected to %d accounts")
      }
      /// Connected to 1 account
      public static let oneConnectedAccount = L10n.tr("Localizable", "seedPhrases_seedPhrase_oneConnectedAccount", fallback: "Connected to 1 account")
      /// Reveal Seed Phrase
      public static let reveal = L10n.tr("Localizable", "seedPhrases_seedPhrase_reveal", fallback: "Reveal Seed Phrase")
    }
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
    /// Ledger Hardware Wallets
    public static let ledgerHardwareWallets = L10n.tr("Localizable", "settings_ledgerHardwareWallets", fallback: "Ledger Hardware Wallets")
    /// Linked Connectors
    public static let linkedConnectors = L10n.tr("Localizable", "settings_linkedConnectors", fallback: "Linked Connectors")
    /// Multi-Factor Setup
    public static let multiFactor = L10n.tr("Localizable", "settings_multiFactor", fallback: "Multi-Factor Setup")
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
  public enum Signing {
    public enum SignatureRequest {
      /// Make sure the following **Ledger hardware wallet device** is connected to a computer with a linked Radix Connector browser extension, and the Radix Babylon app is launched on the device.
      public static let body = L10n.tr("Localizable", "signing_signatureRequest_body", fallback: "Make sure the following **Ledger hardware wallet device** is connected to a computer with a linked Radix Connector browser extension, and the Radix Babylon app is launched on the device.")
      /// Review and sign the transaction on the Ledger device to continue.
      public static let instructions = L10n.tr("Localizable", "signing_signatureRequest_instructions", fallback: "Review and sign the transaction on the Ledger device to continue.")
      /// Signature Request
      public static let title = L10n.tr("Localizable", "signing_signatureRequest_title", fallback: "Signature Request")
    }
    public enum SignatureSuccessful {
      /// Signature successful
      public static let body = L10n.tr("Localizable", "signing_signatureSuccessful_body", fallback: "Signature successful")
      /// Signed
      public static let title = L10n.tr("Localizable", "signing_signatureSuccessful_title", fallback: "Signed")
    }
    public enum UseLedgerLabel {
      /// Added on
      public static let addedOn = L10n.tr("Localizable", "signing_useLedgerLabel_addedOn", fallback: "Added on")
      /// Last used
      public static let lastUsed = L10n.tr("Localizable", "signing_useLedgerLabel_lastUsed", fallback: "Last used")
      /// Ledger
      public static let ledger = L10n.tr("Localizable", "signing_useLedgerLabel_Ledger", fallback: "Ledger")
    }
    public enum WithDeviceFactorSource {
      /// Factor Source ID: %@
      public static func idLabel(_ p1: Any) -> String {
        return L10n.tr("Localizable", "signing_withDeviceFactorSource_idLabel", String(describing: p1), fallback: "Factor Source ID: %@")
      }
      /// Sign transaction with phone
      public static let signTransaction = L10n.tr("Localizable", "signing_withDeviceFactorSource_signTransaction", fallback: "Sign transaction with phone")
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
      public enum Dismiss {
        public enum Dialog {
          /// Stop waiting for transaction result? The transaction will not be canceled.
          public static let message = L10n.tr("Localizable", "transaction_status_dismiss_dialog_message", fallback: "Stop waiting for transaction result? The transaction will not be canceled.")
        }
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
    /// Depositing To
    public static let depositsHeading = L10n.tr("Localizable", "transactionReview_depositsHeading", fallback: "Depositing To")
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
    /// Withdrawing From
    public static let withdrawalsHeading = L10n.tr("Localizable", "transactionReview_withdrawalsHeading", fallback: "Withdrawing From")
    /// %@ XRD
    public static func xrdAmount(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transactionReview_xrdAmount", String(describing: p1), fallback: "%@ XRD")
    }
    public enum CustomizeNetworkFeeSheet {
      /// Change
      public static let changeButtonTitle = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_changeButtonTitle", fallback: "Change")
      /// Effective Tip
      public static let effectiveTip = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_effectiveTip", fallback: "Effective Tip")
      /// Network Execution
      public static let networkExecution = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_networkExecution", fallback: "Network Execution")
      /// Network Fee
      public static let networkFee = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_networkFee", fallback: "Network Fee")
      /// Network Finalization
      public static let networkFinalization = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_networkFinalization", fallback: "Network Finalization")
      /// Network Storage
      public static let networkStorage = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_networkStorage", fallback: "Network Storage")
      /// None due
      public static let noneDue = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_noneDue", fallback: "None due")
      /// None required
      public static let noneRequired = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_noneRequired", fallback: "None required")
      /// Padding
      public static let padding = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_padding", fallback: "Padding")
      /// Adjust Fee Padding Amount (XRD)
      public static let paddingField = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_paddingField", fallback: "Adjust Fee Padding Amount (XRD)")
      /// Pay fee from
      public static let payFeeFrom = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_payFeeFrom", fallback: "Pay fee from")
      /// Royalties
      public static let royalties = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_royalties", fallback: "Royalties")
      /// Royalty fee
      public static let royaltyFee = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_royaltyFee", fallback: "Royalty fee")
      /// Select Fee Payer
      public static let selectFeePayerButtonTitle = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_selectFeePayerButtonTitle", fallback: "Select Fee Payer")
      /// (% of Execution + Finalization Fees)
      public static func tipFieldInfo(_ p1: Int) -> String {
        return L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_tipFieldInfo", p1, fallback: "(% of Execution + Finalization Fees)")
      }
      /// Adjust Tip to Lock
      public static let tipFieldLabel = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_tipFieldLabel", fallback: "Adjust Tip to Lock")
      /// Transaction Fee
      public static let totalFee = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_totalFee", fallback: "Transaction Fee")
      /// View Advanced Mode
      public static let viewAdvancedModeButtonTitle = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_viewAdvancedModeButtonTitle", fallback: "View Advanced Mode")
      /// View Normal Mode
      public static let viewNormalModeButtonTitle = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_viewNormalModeButtonTitle", fallback: "View Normal Mode")
      public enum AdvancedMode {
        /// Fully customize fee payment for this transaction. Not recommended unless you are a developer or advanced user.
        public static let subtitle = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_advancedMode_subtitle", fallback: "Fully customize fee payment for this transaction. Not recommended unless you are a developer or advanced user.")
        /// Advanced Customize Fees
        public static let title = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_advancedMode_title", fallback: "Advanced Customize Fees")
      }
      public enum InsufficientBalance {
        /// Insufficient balance to pay the transaction fee
        public static let warning = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_insufficientBalance_warning", fallback: "Insufficient balance to pay the transaction fee")
      }
      public enum NormalMode {
        /// Choose what account to pay the transaction fee from, or add a “tip” to speed up your transaction if necessary.
        public static let subtitle = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_normalMode_subtitle", fallback: "Choose what account to pay the transaction fee from, or add a “tip” to speed up your transaction if necessary.")
        /// Customize Fees
        public static let title = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_normalMode_title", fallback: "Customize Fees")
      }
      public enum SelectFeePayer {
        /// Select an account to pay %@ XRD transaction fee
        public static func subtitle(_ p1: Any) -> String {
          return L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_selectFeePayer_subtitle", String(describing: p1), fallback: "Select an account to pay %@ XRD transaction fee")
        }
        /// Please select a fee payer for the transaction fee
        public static let warning = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_selectFeePayer_warning", fallback: "Please select a fee payer for the transaction fee")
      }
      public enum TotalFee {
        /// (maximum to lock)
        public static let info = L10n.tr("Localizable", "transactionReview_customizeNetworkFeeSheet_totalFee_info", fallback: "(maximum to lock)")
      }
    }
    public enum Guarantees {
      /// Apply
      public static let applyButtonText = L10n.tr("Localizable", "transactionReview_guarantees_applyButtonText", fallback: "Apply")
      /// How do guarantees work?
      public static let howDoGuaranteesWork = L10n.tr("Localizable", "transactionReview_guarantees_howDoGuaranteesWork", fallback: "How do guarantees work?")
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
      /// Transaction Fee
      public static let heading = L10n.tr("Localizable", "transactionReview_networkFee_heading", fallback: "Transaction Fee")
    }
    public enum PrepareForSigning {
      /// Preparing transaction for signing
      public static let body = L10n.tr("Localizable", "transactionReview_prepareForSigning_body", fallback: "Preparing transaction for signing")
      /// Preparing Transaction
      public static let navigationTitle = L10n.tr("Localizable", "transactionReview_prepareForSigning_navigationTitle", fallback: "Preparing Transaction")
    }
    public enum SelectFeePayer {
      /// Please select an Account with enough XRD to pay 10 XRD fee for this transaction.
      public static let body = L10n.tr("Localizable", "transactionReview_selectFeePayer_body", fallback: "Please select an Account with enough XRD to pay 10 XRD fee for this transaction.")
      /// Continue
      public static let confirmButton = L10n.tr("Localizable", "transactionReview_selectFeePayer_confirmButton", fallback: "Continue")
      /// Select Fee Account
      public static let navigationTitle = L10n.tr("Localizable", "transactionReview_selectFeePayer_navigationTitle", fallback: "Select Fee Account")
      /// Select Account:
      public static let selectAccount = L10n.tr("Localizable", "transactionReview_selectFeePayer_selectAccount", fallback: "Select Account:")
    }
    public enum SubmitTransaction {
      /// Successfully committed
      public static let displayCommitted = L10n.tr("Localizable", "transactionReview_submitTransaction_displayCommitted", fallback: "Successfully committed")
      /// Failed
      public static let displayFailed = L10n.tr("Localizable", "transactionReview_submitTransaction_displayFailed", fallback: "Failed")
      /// Rejected
      public static let displayRejected = L10n.tr("Localizable", "transactionReview_submitTransaction_displayRejected", fallback: "Rejected")
      /// Submitted but not confirmed
      public static let displaySubmittedUnknown = L10n.tr("Localizable", "transactionReview_submitTransaction_displaySubmittedUnknown", fallback: "Submitted but not confirmed")
      /// Submitting
      public static let displaySubmitting = L10n.tr("Localizable", "transactionReview_submitTransaction_displaySubmitting", fallback: "Submitting")
      /// Submitting Transaction
      public static let navigationTitle = L10n.tr("Localizable", "transactionReview_submitTransaction_navigationTitle", fallback: "Submitting Transaction")
      /// Status
      public static let status = L10n.tr("Localizable", "transactionReview_submitTransaction_status", fallback: "Status")
      /// Transaction ID
      public static let txID = L10n.tr("Localizable", "transactionReview_submitTransaction_txID", fallback: "Transaction ID")
    }
  }
  public enum TransactionSigning {
    /// Preparing transaction…
    public static let preparingTransaction = L10n.tr("Localizable", "transactionSigning_preparingTransaction", fallback: "Preparing transaction…")
    /// Submitting transaction…
    public static let signingAndSubmittingTransaction = L10n.tr("Localizable", "transactionSigning_signingAndSubmittingTransaction", fallback: "Submitting transaction…")
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
