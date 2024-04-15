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
    /// Staking
    public static let staking = L10n.tr("Localizable", "account_staking", fallback: "Staking")
    /// Tokens
    public static let tokens = L10n.tr("Localizable", "account_tokens", fallback: "Tokens")
    /// Transfer
    public static let transfer = L10n.tr("Localizable", "account_transfer", fallback: "Transfer")
    public enum PoolUnits {
      /// Missing Total supply - could not calculate redemption value
      public static let noTotalSupply = L10n.tr("Localizable", "account_poolUnits_noTotalSupply", fallback: "Missing Total supply - could not calculate redemption value")
      /// Unknown
      public static let unknownPoolUnitName = L10n.tr("Localizable", "account_poolUnits_unknownPoolUnitName", fallback: "Unknown")
      /// Unknown
      public static let unknownSymbolName = L10n.tr("Localizable", "account_poolUnits_unknownSymbolName", fallback: "Unknown")
      /// Unknown
      public static let unknownValidatorName = L10n.tr("Localizable", "account_poolUnits_unknownValidatorName", fallback: "Unknown")
      public enum Details {
        /// Current Redeemable Value
        public static let currentRedeemableValue = L10n.tr("Localizable", "account_poolUnits_details_currentRedeemableValue", fallback: "Current Redeemable Value")
      }
    }
    public enum Staking {
      /// Claim
      public static let claim = L10n.tr("Localizable", "account_staking_claim", fallback: "Claim")
      /// Current Stake: %@
      public static func currentStake(_ p1: Any) -> String {
        return L10n.tr("Localizable", "account_staking_currentStake", String(describing: p1), fallback: "Current Stake: %@")
      }
      /// Liquid Stake Units
      public static let liquidStakeUnits = L10n.tr("Localizable", "account_staking_liquidStakeUnits", fallback: "Liquid Stake Units")
      /// Radix Network XRD Stake Summary
      public static let lsuResourceHeader = L10n.tr("Localizable", "account_staking_lsuResourceHeader", fallback: "Radix Network XRD Stake Summary")
      /// Ready to be claimed
      public static let readyToBeClaimed = L10n.tr("Localizable", "account_staking_readyToBeClaimed", fallback: "Ready to be claimed")
      /// Ready to Claim
      public static let readyToClaim = L10n.tr("Localizable", "account_staking_readyToClaim", fallback: "Ready to Claim")
      /// Stake Claim NFTs
      public static let stakeClaimNFTs = L10n.tr("Localizable", "account_staking_stakeClaimNFTs", fallback: "Stake Claim NFTs")
      /// Staked
      public static let staked = L10n.tr("Localizable", "account_staking_staked", fallback: "Staked")
      /// STAKED VALIDATORS (%d)
      public static func stakedValidators(_ p1: Int) -> String {
        return L10n.tr("Localizable", "account_staking_stakedValidators", p1, fallback: "STAKED VALIDATORS (%d)")
      }
      /// Unstaking
      public static let unstaking = L10n.tr("Localizable", "account_staking_unstaking", fallback: "Unstaking")
      /// WORTH
      public static let worth = L10n.tr("Localizable", "account_staking_worth", fallback: "WORTH")
    }
  }
  public enum AccountRecoveryScan {
    /// Deriving Accounts
    public static let derivingAccounts = L10n.tr("Localizable", "accountRecoveryScan_derivingAccounts", fallback: "Deriving Accounts")
    /// Use Ledger Hardware Wallet
    public static let ledgerButtonTitle = L10n.tr("Localizable", "accountRecoveryScan_ledgerButtonTitle", fallback: "Use Ledger Hardware Wallet")
    /// Note: You must still use the new *Radix Babylon* app on your Ledger device, not the old Radix Ledger app.
    public static let olympiaLedgerNote = L10n.tr("Localizable", "accountRecoveryScan_olympiaLedgerNote", fallback: "Note: You must still use the new *Radix Babylon* app on your Ledger device, not the old Radix Ledger app.")
    /// Use Seed Phrase
    public static let seedPhraseButtonTitle = L10n.tr("Localizable", "accountRecoveryScan_seedPhraseButtonTitle", fallback: "Use Seed Phrase")
    /// The Radix Wallet can scan for previously used accounts using a bare seed phrase or Ledger hardware wallet device
    public static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_subtitle", fallback: "The Radix Wallet can scan for previously used accounts using a bare seed phrase or Ledger hardware wallet device")
    /// Account Recovery Scan
    public static let title = L10n.tr("Localizable", "accountRecoveryScan_title", fallback: "Account Recovery Scan")
    public enum BabylonSection {
      /// Scan for Accounts originally created on the **Babylon** network.
      public static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_babylonSection_subtitle", fallback: "Scan for Accounts originally created on the **Babylon** network.")
      /// Babylon Accounts
      public static let title = L10n.tr("Localizable", "accountRecoveryScan_babylonSection_title", fallback: "Babylon Accounts")
    }
    public enum ChooseSeedPhrase {
      /// Add Babylon Seed Phrase
      public static let addButtonBabylon = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_addButtonBabylon", fallback: "Add Babylon Seed Phrase")
      /// Add Olympia Seed Phrase
      public static let addButtonOlympia = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_addButtonOlympia", fallback: "Add Olympia Seed Phrase")
      /// Continue
      public static let continueButton = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_continueButton", fallback: "Continue")
      /// Enter Seed Phrase
      public static let importMnemonicTitleBabylon = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_importMnemonicTitleBabylon", fallback: "Enter Seed Phrase")
      /// Enter Legacy Seed Phrase
      public static let importMnemonicTitleOlympia = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_importMnemonicTitleOlympia", fallback: "Enter Legacy Seed Phrase")
      /// Choose the Babylon seed phrase for use for derivation:
      public static let subtitleBabylon = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_subtitleBabylon", fallback: "Choose the Babylon seed phrase for use for derivation:")
      /// Choose the "Legacy" Olympia seed phrase for use for derivation:
      public static let subtitleOlympia = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_subtitleOlympia", fallback: "Choose the \"Legacy\" Olympia seed phrase for use for derivation:")
      /// Choose Seed Phrase
      public static let title = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_title", fallback: "Choose Seed Phrase")
    }
    public enum InProgress {
      /// **Babylon Seed Phrase**
      public static let factorSourceBabylonSeedPhrase = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceBabylonSeedPhrase", fallback: "**Babylon Seed Phrase**")
      /// Signing Factor
      public static let factorSourceFallback = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceFallback", fallback: "Signing Factor")
      /// **Ledger hardware wallet device**
      public static let factorSourceLedgerHardwareDevice = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceLedgerHardwareDevice", fallback: "**Ledger hardware wallet device**")
      /// **Olympia Seed Phrase**
      public static let factorSourceOlympiaSeedPhrase = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceOlympiaSeedPhrase", fallback: "**Olympia Seed Phrase**")
      /// Scanning for Accounts that have been included in at least one transaction, using:
      public static let headerSubtitle = L10n.tr("Localizable", "accountRecoveryScan_inProgress_headerSubtitle", fallback: "Scanning for Accounts that have been included in at least one transaction, using:")
      /// Scanning in progress
      public static let headerTitle = L10n.tr("Localizable", "accountRecoveryScan_inProgress_headerTitle", fallback: "Scanning in progress")
      /// Unnamed
      public static let nameOfRecoveredAccount = L10n.tr("Localizable", "accountRecoveryScan_inProgress_nameOfRecoveredAccount", fallback: "Unnamed")
      /// Scanning network
      public static let scanningNetwork = L10n.tr("Localizable", "accountRecoveryScan_inProgress_scanningNetwork", fallback: "Scanning network")
    }
    public enum OlympiaSection {
      /// Note: You will still use the new **Radix Babylon** app on your Ledger device, not the old Radix Ledger app.
      public static let footnote = L10n.tr("Localizable", "accountRecoveryScan_olympiaSection_footnote", fallback: "Note: You will still use the new **Radix Babylon** app on your Ledger device, not the old Radix Ledger app.")
      /// Scan for Accounts originally created on the **Olympia** network.
      /// 
      /// (If you have Olympia Accounts in the Radix Olympia Desktop Wallet, consider using **Import from a Legacy Wallet** instead.
      public static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_olympiaSection_subtitle", fallback: "Scan for Accounts originally created on the **Olympia** network.\n\n(If you have Olympia Accounts in the Radix Olympia Desktop Wallet, consider using **Import from a Legacy Wallet** instead.")
      /// Olympia Accounts
      public static let title = L10n.tr("Localizable", "accountRecoveryScan_olympiaSection_title", fallback: "Olympia Accounts")
    }
    public enum ScanComplete {
      /// Continue
      public static let continueButton = L10n.tr("Localizable", "accountRecoveryScan_scanComplete_continueButton", fallback: "Continue")
      /// The first **%d** potential Accounts from this signing factor were scanned. The following Accounts had at least one transaction:
      public static func headerSubtitle(_ p1: Int) -> String {
        return L10n.tr("Localizable", "accountRecoveryScan_scanComplete_headerSubtitle", p1, fallback: "The first **%d** potential Accounts from this signing factor were scanned. The following Accounts had at least one transaction:")
      }
      /// Scan Complete
      public static let headerTitle = L10n.tr("Localizable", "accountRecoveryScan_scanComplete_headerTitle", fallback: "Scan Complete")
      /// No new accounts found
      public static let noAccounts = L10n.tr("Localizable", "accountRecoveryScan_scanComplete_noAccounts", fallback: "No new accounts found")
      /// Tap here to scan the next %d
      public static func scanNextBatchButton(_ p1: Int) -> String {
        return L10n.tr("Localizable", "accountRecoveryScan_scanComplete_scanNextBatchButton", p1, fallback: "Tap here to scan the next %d")
      }
    }
    public enum SelectInactiveAccounts {
      /// Continue
      public static let continueButton = L10n.tr("Localizable", "accountRecoveryScan_selectInactiveAccounts_continueButton", fallback: "Continue")
      public enum Header {
        /// These Accounts were never used, but you **may** have created them. Select any addresses that you wish to keep:
        public static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_selectInactiveAccounts_header_subtitle", fallback: "These Accounts were never used, but you **may** have created them. Select any addresses that you wish to keep:")
        /// Add Inactive Accounts?
        public static let title = L10n.tr("Localizable", "accountRecoveryScan_selectInactiveAccounts_header_title", fallback: "Add Inactive Accounts?")
      }
    }
  }
  public enum AccountSecuritySettings {
    public enum AccountRecoveryScan {
      /// Using seed phrase or Ledger device
      public static let subtitle = L10n.tr("Localizable", "accountSecuritySettings_accountRecoveryScan_subtitle", fallback: "Using seed phrase or Ledger device")
      /// Account Recovery Scan
      public static let title = L10n.tr("Localizable", "accountSecuritySettings_accountRecoveryScan_title", fallback: "Account Recovery Scan")
    }
    public enum Backups {
      /// Backups
      public static let title = L10n.tr("Localizable", "accountSecuritySettings_backups_title", fallback: "Backups")
    }
    public enum DepositGuarantees {
      /// Set your default guaranteed minimum for estimated deposits
      public static let subtitle = L10n.tr("Localizable", "accountSecuritySettings_depositGuarantees_subtitle", fallback: "Set your default guaranteed minimum for estimated deposits")
      /// Set the guaranteed minimum deposit to be applied whenever a deposit in a transaction can only be estimated.
      /// 
      /// You can always change the guarantee from this default in each transaction.
      public static let text = L10n.tr("Localizable", "accountSecuritySettings_depositGuarantees_text", fallback: "Set the guaranteed minimum deposit to be applied whenever a deposit in a transaction can only be estimated.\n\nYou can always change the guarantee from this default in each transaction.")
      /// Default Deposit Guarantees
      public static let title = L10n.tr("Localizable", "accountSecuritySettings_depositGuarantees_title", fallback: "Default Deposit Guarantees")
    }
    public enum ImportFromLegacyWallet {
      /// Import from a Legacy Wallet
      public static let title = L10n.tr("Localizable", "accountSecuritySettings_importFromLegacyWallet_title", fallback: "Import from a Legacy Wallet")
    }
    public enum LedgerHardwareWallets {
      /// Ledger Hardware Wallets
      public static let title = L10n.tr("Localizable", "accountSecuritySettings_ledgerHardwareWallets_title", fallback: "Ledger Hardware Wallets")
    }
    public enum SeedPhrases {
      /// Seed Phrases
      public static let title = L10n.tr("Localizable", "accountSecuritySettings_seedPhrases_title", fallback: "Seed Phrases")
    }
  }
  public enum AccountSettings {
    /// Account Color
    public static let accountColor = L10n.tr("Localizable", "accountSettings_accountColor", fallback: "Account Color")
    /// Select from a list of unique colors
    public static let accountColorSubtitle = L10n.tr("Localizable", "accountSettings_accountColorSubtitle", fallback: "Select from a list of unique colors")
    /// Account Hidden
    public static let accountHidden = L10n.tr("Localizable", "accountSettings_accountHidden", fallback: "Account Hidden")
    /// Account Label
    public static let accountLabel = L10n.tr("Localizable", "accountSettings_accountLabel", fallback: "Account Label")
    /// Set development preferences
    public static let developmentHeading = L10n.tr("Localizable", "accountSettings_developmentHeading", fallback: "Set development preferences")
    /// Dev Preferences
    public static let devPreferences = L10n.tr("Localizable", "accountSettings_devPreferences", fallback: "Dev Preferences")
    /// Get XRD Test Tokens
    public static let getXrdTestTokens = L10n.tr("Localizable", "accountSettings_getXrdTestTokens", fallback: "Get XRD Test Tokens")
    /// Hide Account
    public static let hideAccount = L10n.tr("Localizable", "accountSettings_hideAccount", fallback: "Hide Account")
    /// Are you sure you want to hide this account?
    public static let hideAccountConfirmation = L10n.tr("Localizable", "accountSettings_hideAccountConfirmation", fallback: "Are you sure you want to hide this account?")
    /// Hide This Account
    public static let hideThisAccount = L10n.tr("Localizable", "accountSettings_hideThisAccount", fallback: "Hide This Account")
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
    /// Allow/Deny Specific Assets
    public static let specificAssetsDeposits = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits", fallback: "Allow/Deny Specific Assets")
    /// Third-party Deposits
    public static let thirdPartyDeposits = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits", fallback: "Third-party Deposits")
    /// Account Settings
    public static let title = L10n.tr("Localizable", "accountSettings_title", fallback: "Account Settings")
    /// Updated
    public static let updatedAccountHUDMessage = L10n.tr("Localizable", "accountSettings_updatedAccountHUDMessage", fallback: "Updated")
    public enum AccountColor {
      /// Selected
      public static let selected = L10n.tr("Localizable", "accountSettings_accountColor_selected", fallback: "Selected")
      /// Select the color for this Account
      public static let text = L10n.tr("Localizable", "accountSettings_accountColor_text", fallback: "Select the color for this Account")
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
      /// Update
      public static let button = L10n.tr("Localizable", "accountSettings_renameAccount_button", fallback: "Update")
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
    public enum SpecificAssetsDeposits {
      /// Allow Deposits
      public static let addAnAssetAllow = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetAllow", fallback: "Allow Deposits")
      /// Add Asset
      public static let addAnAssetButton = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetButton", fallback: "Add Asset")
      /// Deny Deposits
      public static let addAnAssetDeny = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetDeny", fallback: "Deny Deposits")
      /// Resource Address
      public static let addAnAssetInputHint = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetInputHint", fallback: "Resource Address")
      /// Enter the asset’s resource address (starting with “reso”)
      public static let addAnAssetSubtitle = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetSubtitle", fallback: "Enter the asset’s resource address (starting with “reso”)")
      /// Add an Asset
      public static let addAnAssetTitle = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetTitle", fallback: "Add an Asset")
      /// Allow
      public static let allow = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allow", fallback: "Allow")
      /// The holder of the following badges may always deposit accounts to this account.
      public static let allowDepositors = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allowDepositors", fallback: "The holder of the following badges may always deposit accounts to this account.")
      /// Add a specific badge by its resource address to allow all deposits from its holder.
      public static let allowDepositorsNoResources = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allowDepositorsNoResources", fallback: "Add a specific badge by its resource address to allow all deposits from its holder.")
      /// The following resource addresses may always be deposited to this account by third parties.
      public static let allowInfo = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allowInfo", fallback: "The following resource addresses may always be deposited to this account by third parties.")
      /// Deny
      public static let deny = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_deny", fallback: "Deny")
      /// The following resource addresses may never be deposited to this account by third parties.
      public static let denyInfo = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_denyInfo", fallback: "The following resource addresses may never be deposited to this account by third parties.")
      /// Add a specific asset by its resource address to allow all third-party deposits
      public static let emptyAllowAll = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_emptyAllowAll", fallback: "Add a specific asset by its resource address to allow all third-party deposits")
      /// Add a specific asset by its resource address to deny all third-party deposits
      public static let emptyDenyAll = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_emptyDenyAll", fallback: "Add a specific asset by its resource address to deny all third-party deposits")
      /// Sorry, this Account's third-party exceptions and depositor lists are in an unknown state and cannot be viewed or edited because it was imported using only a seed phrase or Ledger. A forthcoming wallet update will enable viewing and editing of these lists.
      public static let modificationDisabledForRecoveredAccount = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_modificationDisabledForRecoveredAccount", fallback: "Sorry, this Account's third-party exceptions and depositor lists are in an unknown state and cannot be viewed or edited because it was imported using only a seed phrase or Ledger. A forthcoming wallet update will enable viewing and editing of these lists.")
      /// Remove Asset
      public static let removeAsset = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeAsset", fallback: "Remove Asset")
      /// The asset will be removed from the allow list
      public static let removeAssetMessageAllow = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeAssetMessageAllow", fallback: "The asset will be removed from the allow list")
      /// The asset will be removed from the deny list
      public static let removeAssetMessageDeny = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeAssetMessageDeny", fallback: "The asset will be removed from the deny list")
      /// The badge will be removed from the list
      public static let removeBadgeMessageDepositors = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeBadgeMessageDepositors", fallback: "The badge will be removed from the list")
      /// Remove Depositor
      public static let removeDepositor = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeDepositor", fallback: "Remove Depositor")
      /// The depositor will be removed from the allow list
      public static let removeDepositorMessage = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeDepositorMessage", fallback: "The depositor will be removed from the allow list")
      /// Select exception list
      public static let resourceListPicker = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_resourceListPicker", fallback: "Select exception list")
      /// Update
      public static let update = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_update", fallback: "Update")
    }
    public enum ThirdPartyDeposits {
      /// Accept all deposits
      public static let acceptAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAll", fallback: "Accept all deposits")
      /// Allow third-parties to deposit any asset
      public static let acceptAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAllSubtitle", fallback: "Allow third-parties to deposit any asset")
      /// Enter the badge’s resource address (starting with “reso”)
      public static let addDepositorSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_addDepositorSubtitle", fallback: "Enter the badge’s resource address (starting with “reso”)")
      /// Add a Depositor Badge
      public static let addDepositorTitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_addDepositorTitle", fallback: "Add a Depositor Badge")
      /// Allow/Deny specific assets
      public static let allowDenySpecific = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowDenySpecific", fallback: "Allow/Deny specific assets")
      /// Deny or allow third-party deposits of specific assets, ignoring the setting above
      public static let allowDenySpecificSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowDenySpecificSubtitle", fallback: "Deny or allow third-party deposits of specific assets, ignoring the setting above")
      /// Allow specific depositors
      public static let allowSpecificDepositors = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowSpecificDepositors", fallback: "Allow specific depositors")
      /// Add Depositor Badge
      public static let allowSpecificDepositorsButton = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowSpecificDepositorsButton", fallback: "Add Depositor Badge")
      /// Allow certain third party depositors to deposit assets freely
      public static let allowSpecificDepositorsSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowSpecificDepositorsSubtitle", fallback: "Allow certain third party depositors to deposit assets freely")
      /// Deny all
      public static let denyAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAll", fallback: "Deny all")
      /// Deny all third-party deposits
      public static let denyAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAllSubtitle", fallback: "Deny all third-party deposits")
      /// This account will not be able to receive "air drops" or be used by a trusted contact to assist with account recovery.
      public static let denyAllWarning = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAllWarning", fallback: "This account will not be able to receive \"air drops\" or be used by a trusted contact to assist with account recovery.")
      /// Discard Changes
      public static let discardChanges = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_discardChanges", fallback: "Discard Changes")
      /// Are you sure you want to discard changes?
      public static let discardMessage = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_discardMessage", fallback: "Are you sure you want to discard changes?")
      /// Keep Editing
      public static let keepEditing = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_keepEditing", fallback: "Keep Editing")
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
      /// This will be displayed when you’re prompted to sign with this Ledger device.
      public static let fieldHint = L10n.tr("Localizable", "addLedgerDevice_nameLedger_fieldHint", fallback: "This will be displayed when you’re prompted to sign with this Ledger device.")
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
    /// Verify Address with Ledger
    public static let verifyAddressLedger = L10n.tr("Localizable", "addressAction_verifyAddressLedger", fallback: "Verify Address with Ledger")
    /// View on Radix Dashboard
    public static let viewOnDashboard = L10n.tr("Localizable", "addressAction_viewOnDashboard", fallback: "View on Radix Dashboard")
    public enum QrCodeView {
      /// Could not create QR code
      public static let failureLabel = L10n.tr("Localizable", "addressAction_qrCodeView_failureLabel", fallback: "Could not create QR code")
      /// QR code for an account
      public static let qrCodeLabel = L10n.tr("Localizable", "addressAction_qrCodeView_qrCodeLabel", fallback: "QR code for an account")
    }
    public enum VerifyAddressLedger {
      /// Verify address request failed
      public static let error = L10n.tr("Localizable", "addressAction_verifyAddressLedger_error", fallback: "Verify address request failed")
      /// Address verified
      public static let success = L10n.tr("Localizable", "addressAction_verifyAddressLedger_success", fallback: "Address verified")
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
      /// Backup Wallet Data to Cloud
      public static let title = L10n.tr("Localizable", "androidProfileBackup_backupWalletData_title", fallback: "Backup Wallet Data to Cloud")
    }
    public enum DeleteWallet {
      /// Delete Wallet
      public static let confirmButton = L10n.tr("Localizable", "androidProfileBackup_deleteWallet_confirmButton", fallback: "Delete Wallet")
      /// You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any cloud backup.
      /// 
      /// **Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**
      public static let subtitle = L10n.tr("Localizable", "androidProfileBackup_deleteWallet_subtitle", fallback: "You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any cloud backup.\n\n**Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**")
    }
  }
  public enum AndroidRecoverProfileBackup {
    /// No wallet backups available
    public static let noBackupsAvailable = L10n.tr("Localizable", "androidRecoverProfileBackup_noBackupsAvailable", fallback: "No wallet backups available")
    public enum Choose {
      /// Choose a backup
      public static let title = L10n.tr("Localizable", "androidRecoverProfileBackup_choose_title", fallback: "Choose a backup")
    }
  }
  public enum AppSettings {
    /// Customize your Radix Wallet
    public static let subtitle = L10n.tr("Localizable", "appSettings_subtitle", fallback: "Customize your Radix Wallet")
    /// App Settings
    public static let title = L10n.tr("Localizable", "appSettings_title", fallback: "App Settings")
    public enum CrashReporting {
      /// I'm aware Radix Wallet will send crash reports together with device state from the moment of crash.
      public static let subtitle = L10n.tr("Localizable", "appSettings_crashReporting_subtitle", fallback: "I'm aware Radix Wallet will send crash reports together with device state from the moment of crash.")
      /// Crash Reporting
      public static let title = L10n.tr("Localizable", "appSettings_crashReporting_title", fallback: "Crash Reporting")
    }
    public enum DeveloperMode {
      /// Warning: Disables website validity checks
      public static let subtitle = L10n.tr("Localizable", "appSettings_developerMode_subtitle", fallback: "Warning: Disables website validity checks")
      /// Developer Mode
      public static let title = L10n.tr("Localizable", "appSettings_developerMode_title", fallback: "Developer Mode")
    }
    public enum EntityHiding {
      /// %d Account currently hidden
      public static func hiddenAccount(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenAccount", p1, fallback: "%d Account currently hidden")
      }
      /// %d Accounts currently hidden
      public static func hiddenAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenAccounts", p1, fallback: "%d Accounts currently hidden")
      }
      /// %d Persona currently hidden
      public static func hiddenPersona(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenPersona", p1, fallback: "%d Persona currently hidden")
      }
      /// %d Personas currently hidden
      public static func hiddenPersonas(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenPersonas", p1, fallback: "%d Personas currently hidden")
      }
      /// Manage hiding
      public static let subtitle = L10n.tr("Localizable", "appSettings_entityHiding_subtitle", fallback: "Manage hiding")
      /// Accounts and Personas you have created can be hidden in your Radix Wallet, acting as if “deleted”.
      public static let text = L10n.tr("Localizable", "appSettings_entityHiding_text", fallback: "Accounts and Personas you have created can be hidden in your Radix Wallet, acting as if “deleted”.")
      /// Account & Persona Hiding
      public static let title = L10n.tr("Localizable", "appSettings_entityHiding_title", fallback: "Account & Persona Hiding")
      /// Unhide All
      public static let unhideAllButton = L10n.tr("Localizable", "appSettings_entityHiding_unhideAllButton", fallback: "Unhide All")
      /// Are you sure you wish to unhide all Accounts and Personas? This cannot be undone.
      public static let unhideAllConfirmation = L10n.tr("Localizable", "appSettings_entityHiding_unhideAllConfirmation", fallback: "Are you sure you wish to unhide all Accounts and Personas? This cannot be undone.")
      /// Unhide Accounts & Personas
      public static let unhideAllSection = L10n.tr("Localizable", "appSettings_entityHiding_unhideAllSection", fallback: "Unhide Accounts & Personas")
    }
    public enum Gateways {
      /// Network Gateways
      public static let title = L10n.tr("Localizable", "appSettings_gateways_title", fallback: "Network Gateways")
    }
    public enum LinkedConnectors {
      /// Linked Connectors
      public static let title = L10n.tr("Localizable", "appSettings_linkedConnectors_title", fallback: "Linked Connectors")
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
    /// Validator
    public static let validator = L10n.tr("Localizable", "assetDetails_validator", fallback: "Validator")
    public enum NFTDetails {
      /// complex data
      public static let complexData = L10n.tr("Localizable", "assetDetails_NFTDetails_complexData", fallback: "complex data")
      /// Description
      public static let description = L10n.tr("Localizable", "assetDetails_NFTDetails_description", fallback: "Description")
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
      /// %d NFTs of total supply %d
      public static func ownedOfTotal(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_NFTDetails_ownedOfTotal", p1, p2, fallback: "%d NFTs of total supply %d")
      }
      /// Name
      public static let resourceName = L10n.tr("Localizable", "assetDetails_NFTDetails_resourceName", fallback: "Name")
      /// What are NFTs?
      public static let whatAreNfts = L10n.tr("Localizable", "assetDetails_NFTDetails_whatAreNfts", fallback: "What are NFTs?")
    }
    public enum BadgeDetails {
      /// You have no badges
      public static let noBadges = L10n.tr("Localizable", "assetDetails_badgeDetails_noBadges", fallback: "You have no badges")
      /// What are badges?
      public static let whatAreBadges = L10n.tr("Localizable", "assetDetails_badgeDetails_whatAreBadges", fallback: "What are badges?")
    }
    public enum Behaviors {
      /// Anyone can freeze this asset in place.
      public static let freezableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_freezableByAnyone", fallback: "Anyone can freeze this asset in place.")
      /// A third party can freeze this asset in place.
      public static let freezableByThirdParty = L10n.tr("Localizable", "assetDetails_behaviors_freezableByThirdParty", fallback: "A third party can freeze this asset in place.")
      /// Naming and information about this asset can be changed.
      public static let informationChangeable = L10n.tr("Localizable", "assetDetails_behaviors_informationChangeable", fallback: "Naming and information about this asset can be changed.")
      /// Anyone can change naming and information about this asset.
      public static let informationChangeableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_informationChangeableByAnyone", fallback: "Anyone can change naming and information about this asset.")
      /// Movement of this asset can be restricted in the future.
      public static let movementRestrictableInFuture = L10n.tr("Localizable", "assetDetails_behaviors_movementRestrictableInFuture", fallback: "Movement of this asset can be restricted in the future.")
      /// Anyone can restrict movement of this token in the future.
      public static let movementRestrictableInFutureByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_movementRestrictableInFutureByAnyone", fallback: "Anyone can restrict movement of this token in the future.")
      /// Movement of this asset is restricted.
      public static let movementRestricted = L10n.tr("Localizable", "assetDetails_behaviors_movementRestricted", fallback: "Movement of this asset is restricted.")
      /// Data that is set on these NFTs can be changed.
      public static let nftDataChangeable = L10n.tr("Localizable", "assetDetails_behaviors_nftDataChangeable", fallback: "Data that is set on these NFTs can be changed.")
      /// Anyone can change data that is set on these NFTs.
      public static let nftDataChangeableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_nftDataChangeableByAnyone", fallback: "Anyone can change data that is set on these NFTs.")
      /// Anyone can remove this asset from accounts and dApps.
      public static let removableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_removableByAnyone", fallback: "Anyone can remove this asset from accounts and dApps.")
      /// A third party can remove this asset from accounts and dApps.
      public static let removableByThirdParty = L10n.tr("Localizable", "assetDetails_behaviors_removableByThirdParty", fallback: "A third party can remove this asset from accounts and dApps.")
      /// This is a simple asset
      public static let simpleAsset = L10n.tr("Localizable", "assetDetails_behaviors_simpleAsset", fallback: "This is a simple asset")
      /// The supply of this asset can be decreased.
      public static let supplyDecreasable = L10n.tr("Localizable", "assetDetails_behaviors_supplyDecreasable", fallback: "The supply of this asset can be decreased.")
      /// Anyone can decrease the supply of this asset.
      public static let supplyDecreasableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_supplyDecreasableByAnyone", fallback: "Anyone can decrease the supply of this asset.")
      /// The supply of this asset can be increased or decreased.
      public static let supplyFlexible = L10n.tr("Localizable", "assetDetails_behaviors_supplyFlexible", fallback: "The supply of this asset can be increased or decreased.")
      /// Anyone can increase or decrease the supply of this asset.
      public static let supplyFlexibleByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_supplyFlexibleByAnyone", fallback: "Anyone can increase or decrease the supply of this asset.")
      /// Only the Radix Network may increase or decrease the supply of XRD.
      public static let supplyFlexibleXrd = L10n.tr("Localizable", "assetDetails_behaviors_supplyFlexibleXrd", fallback: "Only the Radix Network may increase or decrease the supply of XRD.")
      /// The supply of this asset can be increased.
      public static let supplyIncreasable = L10n.tr("Localizable", "assetDetails_behaviors_supplyIncreasable", fallback: "The supply of this asset can be increased.")
      /// Anyone can increase the supply of this asset.
      public static let supplyIncreasableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_supplyIncreasableByAnyone", fallback: "Anyone can increase the supply of this asset.")
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
    public enum Staking {
      /// Ready to claim in about %d minutes or less.
      public static func unstaking(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_staking_unstaking", p1, fallback: "Ready to claim in about %d minutes or less.")
      }
    }
    public enum StakingDetails {
      /// You have no Stakes
      public static let noStakes = L10n.tr("Localizable", "assetDetails_stakingDetails_noStakes", fallback: "You have no Stakes")
      /// What is Staking?
      public static let whatIsStaking = L10n.tr("Localizable", "assetDetails_stakingDetails_whatIsStaking", fallback: "What is Staking?")
    }
    public enum Tags {
      /// Official Radix
      public static let officialRadix = L10n.tr("Localizable", "assetDetails_tags_officialRadix", fallback: "Official Radix")
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
    /// Add a message
    public static let transactionMessagePlaceholder = L10n.tr("Localizable", "assetTransfer_transactionMessagePlaceholder", fallback: "Add a message")
    public enum AccountList {
      /// Add Transfer
      public static let addAccountButton = L10n.tr("Localizable", "assetTransfer_accountList_addAccountButton", fallback: "Add Transfer")
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
    public enum Error {
      /// Total amount exceeds your current balance
      public static let insufficientBalance = L10n.tr("Localizable", "assetTransfer_error_insufficientBalance", fallback: "Total amount exceeds your current balance")
      /// Resource already added
      public static let resourceAlreadyAdded = L10n.tr("Localizable", "assetTransfer_error_resourceAlreadyAdded", fallback: "Resource already added")
      /// Address is not valid on current network
      public static let wrongNetwork = L10n.tr("Localizable", "assetTransfer_error_wrongNetwork", fallback: "Address is not valid on current network")
    }
    public enum ExtraSignature {
      /// You will be asked for an extra signature
      public static let label = L10n.tr("Localizable", "assetTransfer_extraSignature_label", fallback: "You will be asked for an extra signature")
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
    public enum MaxAmountDialog {
      /// Sending the full amount of XRD in this account will require you to pay the transaction fee from a different account. Or, the wallet can reduce the amount transferred so the fee can be paid from this account. Choose the amount to transfer:
      public static let body = L10n.tr("Localizable", "assetTransfer_maxAmountDialog_body", fallback: "Sending the full amount of XRD in this account will require you to pay the transaction fee from a different account. Or, the wallet can reduce the amount transferred so the fee can be paid from this account. Choose the amount to transfer:")
      /// %@ (save 1 XRD for fee)
      public static func saveXrdForFeeButton(_ p1: Any) -> String {
        return L10n.tr("Localizable", "assetTransfer_maxAmountDialog_saveXrdForFeeButton", String(describing: p1), fallback: "%@ (save 1 XRD for fee)")
      }
      /// %@ (send all XRD)
      public static func sendAllButton(_ p1: Any) -> String {
        return L10n.tr("Localizable", "assetTransfer_maxAmountDialog_sendAllButton", String(describing: p1), fallback: "%@ (send all XRD)")
      }
      /// Sending All XRD
      public static let title = L10n.tr("Localizable", "assetTransfer_maxAmountDialog_title", fallback: "Sending All XRD")
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
      /// Edit Persona
      public static let editPersona = L10n.tr("Localizable", "authorizedDapps_personaDetails_editPersona", fallback: "Edit Persona")
      /// Email Address
      public static let emailAddress = L10n.tr("Localizable", "authorizedDapps_personaDetails_emailAddress", fallback: "Email Address")
      /// First Name
      public static let firstName = L10n.tr("Localizable", "authorizedDapps_personaDetails_firstName", fallback: "First Name")
      /// Full Name
      public static let fullName = L10n.tr("Localizable", "authorizedDapps_personaDetails_fullName", fallback: "Full Name")
      /// Given Name(s)
      public static let givenName = L10n.tr("Localizable", "authorizedDapps_personaDetails_givenName", fallback: "Given Name(s)")
      /// Are you sure you want to hide this persona?
      public static let hidePersonaConfirmation = L10n.tr("Localizable", "authorizedDapps_personaDetails_hidePersonaConfirmation", fallback: "Are you sure you want to hide this persona?")
      /// Hide This Persona
      public static let hideThisPersona = L10n.tr("Localizable", "authorizedDapps_personaDetails_hideThisPersona", fallback: "Hide This Persona")
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
      /// Persona Hidden
      public static let personaHidden = L10n.tr("Localizable", "authorizedDapps_personaDetails_personaHidden", fallback: "Persona Hidden")
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
      /// Your device currently has no device access security set, such as biometrics or a PIN. The Radix Wallet requires this to be set for your security.
      public static let message = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_message", fallback: "Your device currently has no device access security set, such as biometrics or a PIN. The Radix Wallet requires this to be set for your security.")
      /// Open Settings
      public static let openSettings = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_openSettings", fallback: "Open Settings")
      /// Quit
      public static let quit = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_quit", fallback: "Quit")
      /// Unsecured Device
      public static let title = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_title", fallback: "Unsecured Device")
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
    /// Bad HTTP response status code %d
    public static func badHttpResponseStatusCode(_ p1: Int) -> String {
      return L10n.tr("Localizable", "common_badHttpResponseStatusCode", p1, fallback: "Bad HTTP response status code %d")
    }
    /// Cancel
    public static let cancel = L10n.tr("Localizable", "common_cancel", fallback: "Cancel")
    /// Choose
    public static let choose = L10n.tr("Localizable", "common_choose", fallback: "Choose")
    /// Component
    public static let component = L10n.tr("Localizable", "common_component", fallback: "Component")
    /// Confirm
    public static let confirm = L10n.tr("Localizable", "common_confirm", fallback: "Confirm")
    /// Continue
    public static let `continue` = L10n.tr("Localizable", "common_continue", fallback: "Continue")
    /// Copy
    public static let copy = L10n.tr("Localizable", "common_copy", fallback: "Copy")
    /// Connected to a test network, not Radix main network.
    public static let developerDisclaimerText = L10n.tr("Localizable", "common_developerDisclaimerText", fallback: "Connected to a test network, not Radix main network.")
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
    /// Pool
    public static let pool = L10n.tr("Localizable", "common_pool", fallback: "Pool")
    /// Public
    public static let `public` = L10n.tr("Localizable", "common_public", fallback: "Public")
    /// Gateway access blocked due to exceeding rate limit. Please wait a few minutes to retry.
    public static let rateLimitReached = L10n.tr("Localizable", "common_rateLimitReached", fallback: "Gateway access blocked due to exceeding rate limit. Please wait a few minutes to retry.")
    /// Remove
    public static let remove = L10n.tr("Localizable", "common_remove", fallback: "Remove")
    /// Retry
    public static let retry = L10n.tr("Localizable", "common_retry", fallback: "Retry")
    /// Save
    public static let save = L10n.tr("Localizable", "common_save", fallback: "Save")
    /// Show Less
    public static let showLess = L10n.tr("Localizable", "common_showLess", fallback: "Show Less")
    /// Show More
    public static let showMore = L10n.tr("Localizable", "common_showMore", fallback: "Show More")
    /// Something Went Wrong
    public static let somethingWentWrong = L10n.tr("Localizable", "common_somethingWentWrong", fallback: "Something Went Wrong")
    /// Settings
    public static let systemSettings = L10n.tr("Localizable", "common_systemSettings", fallback: "Settings")
    /// Unauthorized
    public static let unauthorized = L10n.tr("Localizable", "common_unauthorized", fallback: "Unauthorized")
  }
  public enum ConfirmMnemonicBackedUp {
    /// Confirm you have written down the seed phrase by entering the missing words below.
    public static let subtitle = L10n.tr("Localizable", "confirmMnemonicBackedUp_subtitle", fallback: "Confirm you have written down the seed phrase by entering the missing words below.")
    /// Confirm Your Seed Phrase
    public static let title = L10n.tr("Localizable", "confirmMnemonicBackedUp_title", fallback: "Confirm Your Seed Phrase")
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
    public enum Introduction {
      /// Create an Account
      public static let title = L10n.tr("Localizable", "createAccount_introduction_title", fallback: "Create an Account")
    }
    public enum NameNewAccount {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "createAccount_nameNewAccount_continue", fallback: "Continue")
      /// This can be changed any time.
      public static let explanation = L10n.tr("Localizable", "createAccount_nameNewAccount_explanation", fallback: "This can be changed any time.")
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
      /// You will be asked to sign transactions with the Ledger device you select.
      public static let ledgerSubtitle = L10n.tr("Localizable", "createEntity_nameNewEntity_ledgerSubtitle", fallback: "You will be asked to sign transactions with the Ledger device you select.")
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
      /// Personas are used to login to dApps on Radix. dApps may request access to personal information associated with your Persona, like your name or email address.
      public static let subtitle2 = L10n.tr("Localizable", "createPersona_introduction_subtitle2", fallback: "Personas are used to login to dApps on Radix. dApps may request access to personal information associated with your Persona, like your name or email address.")
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
  public enum CustomizeNetworkFees {
    /// Change
    public static let changeButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_changeButtonTitle", fallback: "Change")
    /// Effective Tip
    public static let effectiveTip = L10n.tr("Localizable", "customizeNetworkFees_effectiveTip", fallback: "Effective Tip")
    /// Estimated Transaction Fees
    public static let feeBreakdownTitle = L10n.tr("Localizable", "customizeNetworkFees_feeBreakdownTitle", fallback: "Estimated Transaction Fees")
    /// Network Execution
    public static let networkExecution = L10n.tr("Localizable", "customizeNetworkFees_networkExecution", fallback: "Network Execution")
    /// Network Fee
    public static let networkFee = L10n.tr("Localizable", "customizeNetworkFees_networkFee", fallback: "Network Fee")
    /// Network Finalization
    public static let networkFinalization = L10n.tr("Localizable", "customizeNetworkFees_networkFinalization", fallback: "Network Finalization")
    /// Network Storage
    public static let networkStorage = L10n.tr("Localizable", "customizeNetworkFees_networkStorage", fallback: "Network Storage")
    /// No account selected
    public static let noAccountSelected = L10n.tr("Localizable", "customizeNetworkFees_noAccountSelected", fallback: "No account selected")
    /// None due
    public static let noneDue = L10n.tr("Localizable", "customizeNetworkFees_noneDue", fallback: "None due")
    /// None required
    public static let noneRequired = L10n.tr("Localizable", "customizeNetworkFees_noneRequired", fallback: "None required")
    /// Padding
    public static let padding = L10n.tr("Localizable", "customizeNetworkFees_padding", fallback: "Padding")
    /// Adjust Fee Padding Amount (XRD)
    public static let paddingFieldLabel = L10n.tr("Localizable", "customizeNetworkFees_paddingFieldLabel", fallback: "Adjust Fee Padding Amount (XRD)")
    /// Paid by dApps
    public static let paidByDApps = L10n.tr("Localizable", "customizeNetworkFees_paidByDApps", fallback: "Paid by dApps")
    /// Pay fee from
    public static let payFeeFrom = L10n.tr("Localizable", "customizeNetworkFees_payFeeFrom", fallback: "Pay fee from")
    /// Royalties
    public static let royalties = L10n.tr("Localizable", "customizeNetworkFees_royalties", fallback: "Royalties")
    /// Royalty fee
    public static let royaltyFee = L10n.tr("Localizable", "customizeNetworkFees_royaltyFee", fallback: "Royalty fee")
    /// (%% of Execution + Finalization Fees)
    public static let tipFieldInfo = L10n.tr("Localizable", "customizeNetworkFees_tipFieldInfo", fallback: "(%% of Execution + Finalization Fees)")
    /// Adjust Tip to Lock
    public static let tipFieldLabel = L10n.tr("Localizable", "customizeNetworkFees_tipFieldLabel", fallback: "Adjust Tip to Lock")
    /// Transaction Fee
    public static let totalFee = L10n.tr("Localizable", "customizeNetworkFees_totalFee", fallback: "Transaction Fee")
    /// View Advanced Mode
    public static let viewAdvancedModeButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_viewAdvancedModeButtonTitle", fallback: "View Advanced Mode")
    /// View Normal Mode
    public static let viewNormalModeButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_viewNormalModeButtonTitle", fallback: "View Normal Mode")
    public enum AdvancedMode {
      /// Fully customize fee payment for this transaction. Not recomended unless you are a developer or advanced user.
      public static let subtitle = L10n.tr("Localizable", "customizeNetworkFees_advancedMode_subtitle", fallback: "Fully customize fee payment for this transaction. Not recomended unless you are a developer or advanced user.")
      /// Advanced Customize Fees
      public static let title = L10n.tr("Localizable", "customizeNetworkFees_advancedMode_title", fallback: "Advanced Customize Fees")
    }
    public enum NormalMode {
      /// Choose what account to pay the transaction fee from, or add a "tip" to speed up your transaction if necessary.
      public static let subtitle = L10n.tr("Localizable", "customizeNetworkFees_normalMode_subtitle", fallback: "Choose what account to pay the transaction fee from, or add a \"tip\" to speed up your transaction if necessary.")
      /// Customize Fees
      public static let title = L10n.tr("Localizable", "customizeNetworkFees_normalMode_title", fallback: "Customize Fees")
    }
    public enum SelectFeePayer {
      /// Select Fee Payer
      public static let navigationTitle = L10n.tr("Localizable", "customizeNetworkFees_selectFeePayer_navigationTitle", fallback: "Select Fee Payer")
      /// Select Account
      public static let selectAccountButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_selectFeePayer_selectAccountButtonTitle", fallback: "Select Account")
      /// Select an account to pay %@ XRD transaction fee
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "customizeNetworkFees_selectFeePayer_subtitle", String(describing: p1), fallback: "Select an account to pay %@ XRD transaction fee")
      }
    }
    public enum TotalFee {
      /// (maximum to lock)
      public static let info = L10n.tr("Localizable", "customizeNetworkFees_totalFee_info", fallback: "(maximum to lock)")
    }
    public enum Warning {
      /// Insufficient balance to pay the transaction fee
      public static let insufficientBalance = L10n.tr("Localizable", "customizeNetworkFees_warning_insufficientBalance", fallback: "Insufficient balance to pay the transaction fee")
      /// Please select a fee payer for the transaction fee
      public static let selectFeePayer = L10n.tr("Localizable", "customizeNetworkFees_warning_selectFeePayer", fallback: "Please select a fee payer for the transaction fee")
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
      /// **%@** is requesting permission to *always* be able to view Account information when you login with this Persona.
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_subtitle", String(describing: p1), fallback: "**%@** is requesting permission to *always* be able to view Account information when you login with this Persona.")
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
      /// **%@** is making a one-time request for at least %d accounts.
      public static func subtitleAtLeast(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeast", String(describing: p1), p2, fallback: "**%@** is making a one-time request for at least %d accounts.")
      }
      /// **%@** is making a one-time request for at least 1 account.
      public static func subtitleAtLeastOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastOne", String(describing: p1), fallback: "**%@** is making a one-time request for at least 1 account.")
      }
      /// **%@** is making a one-time request for any number of accounts.
      public static func subtitleAtLeastZero(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastZero", String(describing: p1), fallback: "**%@** is making a one-time request for any number of accounts.")
      }
      /// *%@* is making a one-time request for at least %d accounts.
      public static func subtitleExactly(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactly", String(describing: p1), p2, fallback: "*%@* is making a one-time request for at least %d accounts.")
      }
      /// **%@** is making a one-time request for 1 account.
      public static func subtitleExactlyOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactlyOne", String(describing: p1), fallback: "**%@** is making a one-time request for 1 account.")
      }
      /// Account Request
      public static let title = L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_title", fallback: "Account Request")
    }
    public enum ChooseAccountsOngoing {
      /// Choose at least %d accounts you wish to use with **%@**.
      public static func subtitleAtLeast(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeast", p1, String(describing: p2), fallback: "Choose at least %d accounts you wish to use with **%@**.")
      }
      /// Choose at least 1 account you wish to use with **%@**.
      public static func subtitleAtLeastOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastOne", String(describing: p1), fallback: "Choose at least 1 account you wish to use with **%@**.")
      }
      /// Choose any accounts you wish to use with **%@**.
      public static func subtitleAtLeastZero(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastZero", String(describing: p1), fallback: "Choose any accounts you wish to use with **%@**.")
      }
      /// Choose %d accounts you wish to use with **%@**.
      public static func subtitleExactly(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactly", p1, String(describing: p2), fallback: "Choose %d accounts you wish to use with **%@**.")
      }
      /// Choose 1 account you wish to use with **%@**.
      public static func subtitleExactlyOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactlyOne", String(describing: p1), fallback: "Choose 1 account you wish to use with **%@**.")
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
      /// %@ is requesting that you login for the **first time** with a Persona.
      public static func subtitleNewDapp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_subtitleNewDapp", String(describing: p1), fallback: "%@ is requesting that you login for the **first time** with a Persona.")
      }
      /// Login Request
      public static let titleKnownDapp = L10n.tr("Localizable", "dAppRequest_login_titleKnownDapp", fallback: "Login Request")
      /// New Login Request
      public static let titleNewDapp = L10n.tr("Localizable", "dAppRequest_login_titleNewDapp", fallback: "New Login Request")
    }
    public enum Metadata {
      /// Unknown dApp
      public static let unknownName = L10n.tr("Localizable", "dAppRequest_metadata_unknownName", fallback: "Unknown dApp")
      /// Radix Wallet
      public static let wallet = L10n.tr("Localizable", "dAppRequest_metadata_wallet", fallback: "Radix Wallet")
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
      /// **%@** is requesting that you provide some pieces of personal data **just one time**
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataOneTime_subtitle", String(describing: p1), fallback: "**%@** is requesting that you provide some pieces of personal data **just one time**")
      }
      /// One-Time Data Request
      public static let title = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_title", fallback: "One-Time Data Request")
    }
    public enum PersonalDataPermission {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "dAppRequest_personalDataPermission_continue", fallback: "Continue")
      /// **%@** is requesting permission to **always** be able to view the following personal data when you login with this Persona.
      public static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataPermission_subtitle", String(describing: p1), fallback: "**%@** is requesting permission to **always** be able to view the following personal data when you login with this Persona.")
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
      /// dApp made a request intended for network %@, but you are currently connected to %@.
      public static func message(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_requestWrongNetworkAlert_message", String(describing: p1), String(describing: p2), fallback: "dApp made a request intended for network %@, but you are currently connected to %@.")
      }
    }
    public enum ResponseFailureAlert {
      /// Failed to send request response to dApp.
      public static let message = L10n.tr("Localizable", "dAppRequest_responseFailureAlert_message", fallback: "Failed to send request response to dApp.")
    }
    public enum ValidationOutcome {
      /// Invalid value of `numberOfAccountsInvalid`: must not be `exactly(0)` nor can `quantity` be negative
      public static let devExplanationBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationBadContent", fallback: "Invalid value of `numberOfAccountsInvalid`: must not be `exactly(0)` nor can `quantity` be negative")
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
      /// Could not validate the dApp.
      public static let invalidRequestMessage = L10n.tr("Localizable", "dAppRequest_validationOutcome_invalidRequestMessage", fallback: "Could not validate the dApp.")
      /// Invalid Request.
      public static let invalidRequestTitle = L10n.tr("Localizable", "dAppRequest_validationOutcome_invalidRequestTitle", fallback: "Invalid Request.")
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
  public enum DerivePublicKeys {
    /// Authenticate to your phone to sign.
    public static let subtitleDevice = L10n.tr("Localizable", "derivePublicKeys_subtitleDevice", fallback: "Authenticate to your phone to sign.")
    /// Make sure the following **Ledger hardware wallet device** is connected to a computer with a linked Radix Connector browser extension. Complete signing on the device.
    public static let subtitleLedger = L10n.tr("Localizable", "derivePublicKeys_subtitleLedger", fallback: "Make sure the following **Ledger hardware wallet device** is connected to a computer with a linked Radix Connector browser extension. Complete signing on the device.")
    /// Deriving Accounts
    public static let titleAccountRecoveryScan = L10n.tr("Localizable", "derivePublicKeys_titleAccountRecoveryScan", fallback: "Deriving Accounts")
    /// Creating Account
    public static let titleCreateAccount = L10n.tr("Localizable", "derivePublicKeys_titleCreateAccount", fallback: "Creating Account")
    /// Creating Key
    public static let titleCreateAuthSignKeyForAccount = L10n.tr("Localizable", "derivePublicKeys_titleCreateAuthSignKeyForAccount", fallback: "Creating Key")
    /// Creating Key
    public static let titleCreateAuthSignKeyForPersona = L10n.tr("Localizable", "derivePublicKeys_titleCreateAuthSignKeyForPersona", fallback: "Creating Key")
    /// Creating Persona
    public static let titleCreatePersona = L10n.tr("Localizable", "derivePublicKeys_titleCreatePersona", fallback: "Creating Persona")
    /// Deriving Accounts
    public static let titleImportLegacyAccount = L10n.tr("Localizable", "derivePublicKeys_titleImportLegacyAccount", fallback: "Deriving Accounts")
  }
  public enum DisplayMnemonics {
    /// Write Down this Seed Phrase
    public static let backUpWarning = L10n.tr("Localizable", "displayMnemonics_backUpWarning", fallback: "Write Down this Seed Phrase")
    /// Begin seed phrase entry
    public static let seedPhraseEntryWarning = L10n.tr("Localizable", "displayMnemonics_seedPhraseEntryWarning", fallback: "Begin seed phrase entry")
    /// Seed Phrases
    public static let seedPhrases = L10n.tr("Localizable", "displayMnemonics_seedPhrases", fallback: "Seed Phrases")
    /// You are responsible for the security of your Seed Phrase
    public static let seedPhraseSecurityInfo = L10n.tr("Localizable", "displayMnemonics_seedPhraseSecurityInfo", fallback: "You are responsible for the security of your Seed Phrase")
    public enum CautionAlert {
      /// A seed phrase provides full control of its Accounts. Do not view in a public area. Write down the seed phrase words securely. Screenshots are disabled.
      public static let message = L10n.tr("Localizable", "displayMnemonics_cautionAlert_message", fallback: "A seed phrase provides full control of its Accounts. Do not view in a public area. Write down the seed phrase words securely. Screenshots are disabled.")
      /// Reveal Seed Phrase
      public static let revealButtonLabel = L10n.tr("Localizable", "displayMnemonics_cautionAlert_revealButtonLabel", fallback: "Reveal Seed Phrase")
      /// Use Caution
      public static let title = L10n.tr("Localizable", "displayMnemonics_cautionAlert_title", fallback: "Use Caution")
    }
    public enum ConnectedAccountsLabel {
      /// Connected to %d Accounts
      public static func many(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsLabel_many", p1, fallback: "Connected to %d Accounts")
      }
      /// Connected to %d Account
      public static func one(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsLabel_one", p1, fallback: "Connected to %d Account")
      }
    }
    public enum ConnectedAccountsPersonasLabel {
      /// Connected to Personas and to %d Accounts
      public static func many(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsPersonasLabel_many", p1, fallback: "Connected to Personas and to %d Accounts")
      }
      /// Connected to Personas and %d Account
      public static func one(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsPersonasLabel_one", p1, fallback: "Connected to Personas and %d Account")
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
  public enum EncryptProfileBackup {
    public enum ConfirmPasswordField {
      /// Passwords do not match
      public static let error = L10n.tr("Localizable", "encryptProfileBackup_confirmPasswordField_error", fallback: "Passwords do not match")
      /// Confirm password
      public static let placeholder = L10n.tr("Localizable", "encryptProfileBackup_confirmPasswordField_placeholder", fallback: "Confirm password")
    }
    public enum EnterPasswordField {
      /// Enter password
      public static let placeholder = L10n.tr("Localizable", "encryptProfileBackup_enterPasswordField_placeholder", fallback: "Enter password")
    }
    public enum Header {
      /// Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.
      public static let subtitle = L10n.tr("Localizable", "encryptProfileBackup_header_subtitle", fallback: "Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.")
      /// Encrypt Wallet Backup File
      public static let title = L10n.tr("Localizable", "encryptProfileBackup_header_title", fallback: "Encrypt Wallet Backup File")
    }
  }
  public enum EnterSeedPhrase {
    /// Enter Babylon Seed Phrase
    public static let titleBabylon = L10n.tr("Localizable", "enterSeedPhrase_titleBabylon", fallback: "Enter Babylon Seed Phrase")
    /// Enter Main Seed Phrase
    public static let titleBabylonMain = L10n.tr("Localizable", "enterSeedPhrase_titleBabylonMain", fallback: "Enter Main Seed Phrase")
    /// Enter Olympia Seed Phrase
    public static let titleOlympia = L10n.tr("Localizable", "enterSeedPhrase_titleOlympia", fallback: "Enter Olympia Seed Phrase")
    /// For your safety, make sure no one is looking at your screen. Never give your seed phrase to anyone for any reason.
    public static let warning = L10n.tr("Localizable", "enterSeedPhrase_warning", fallback: "For your safety, make sure no one is looking at your screen. Never give your seed phrase to anyone for any reason.")
    public enum Header {
      /// Enter Seed Phrase
      public static let title = L10n.tr("Localizable", "enterSeedPhrase_header_title", fallback: "Enter Seed Phrase")
      /// Enter Main Seed Phrase
      public static let titleMain = L10n.tr("Localizable", "enterSeedPhrase_header_titleMain", fallback: "Enter Main Seed Phrase")
    }
  }
  public enum Error {
    public enum AccountLabel {
      /// Account label required
      public static let missing = L10n.tr("Localizable", "error_accountLabel_missing", fallback: "Account label required")
      /// Account label too long
      public static let tooLong = L10n.tr("Localizable", "error_accountLabel_tooLong", fallback: "Account label too long")
    }
    public enum DappRequest {
      /// Invalid Persona specified by dApp
      public static let invalidPersonaId = L10n.tr("Localizable", "error_dappRequest_invalidPersonaId", fallback: "Invalid Persona specified by dApp")
      /// Invalid request
      public static let invalidRequest = L10n.tr("Localizable", "error_dappRequest_invalidRequest", fallback: "Invalid request")
    }
    public enum PersonaLabel {
      /// Persona label too long
      public static let tooLong = L10n.tr("Localizable", "error_personaLabel_tooLong", fallback: "Persona label too long")
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
      /// Your current Ledger settings only allow signing of simple token transfers. Please either enable "verbose mode" (to see full transaction manifests) or "blind signing mode" (to enable signing of complex transaction manifest hashes) on your Ledger app device.
      public static let blindSigningNotEnabledButRequired = L10n.tr("Localizable", "error_transactionFailure_blindSigningNotEnabledButRequired", fallback: "Your current Ledger settings only allow signing of simple token transfers. Please either enable \"verbose mode\" (to see full transaction manifests) or \"blind signing mode\" (to enable signing of complex transaction manifest hashes) on your Ledger app device.")
      /// Failed to commit transaction
      public static let commit = L10n.tr("Localizable", "error_transactionFailure_commit", fallback: "Failed to commit transaction")
      /// One of the receiving accounts does not allow Third-Party deposits
      public static let doesNotAllowThirdPartyDeposits = L10n.tr("Localizable", "error_transactionFailure_doesNotAllowThirdPartyDeposits", fallback: "One of the receiving accounts does not allow Third-Party deposits")
      /// Failed to convert transaction manifest
      public static let duplicate = L10n.tr("Localizable", "error_transactionFailure_duplicate", fallback: "Failed to convert transaction manifest")
      /// Failed to get epoch
      public static let epoch = L10n.tr("Localizable", "error_transactionFailure_epoch", fallback: "Failed to get epoch")
      /// Failed to add Guarantee, try a different percentage, or try skip adding a guarantee.
      public static let failedToAddGuarantee = L10n.tr("Localizable", "error_transactionFailure_failedToAddGuarantee", fallback: "Failed to add Guarantee, try a different percentage, or try skip adding a guarantee.")
      /// Failed to add Transaction Fee, try a different amount of fee payer.
      public static let failedToAddLockFee = L10n.tr("Localizable", "error_transactionFailure_failedToAddLockFee", fallback: "Failed to add Transaction Fee, try a different amount of fee payer.")
      /// Failed to find ledger
      public static let failedToFindLedger = L10n.tr("Localizable", "error_transactionFailure_failedToFindLedger", fallback: "Failed to find ledger")
      /// Failed to build transaction header
      public static let header = L10n.tr("Localizable", "error_transactionFailure_header", fallback: "Failed to build transaction header")
      /// Failed to convert transaction manifest
      public static let manifest = L10n.tr("Localizable", "error_transactionFailure_manifest", fallback: "Failed to convert transaction manifest")
      /// You don't have access to some accounts or personas required to authorise this transaction
      public static let missingSigners = L10n.tr("Localizable", "error_transactionFailure_missingSigners", fallback: "You don't have access to some accounts or personas required to authorise this transaction")
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
      /// A proposed transaction could not be processed.
      public static let reviewFailure = L10n.tr("Localizable", "error_transactionFailure_reviewFailure", fallback: "A proposed transaction could not be processed.")
      /// Failed to submit transaction
      public static let submit = L10n.tr("Localizable", "error_transactionFailure_submit", fallback: "Failed to submit transaction")
      /// Unknown error
      public static let unknown = L10n.tr("Localizable", "error_transactionFailure_unknown", fallback: "Unknown error")
    }
  }
  public enum FactorSourceActions {
    public enum CreateAccount {
      /// Creating Account
      public static let title = L10n.tr("Localizable", "factorSourceActions_createAccount_title", fallback: "Creating Account")
    }
    public enum CreateKey {
      /// Creating Key
      public static let title = L10n.tr("Localizable", "factorSourceActions_createKey_title", fallback: "Creating Key")
    }
    public enum CreatePersona {
      /// Creating Persona
      public static let title = L10n.tr("Localizable", "factorSourceActions_createPersona_title", fallback: "Creating Persona")
    }
    public enum DeriveAccounts {
      /// Deriving Accounts
      public static let title = L10n.tr("Localizable", "factorSourceActions_deriveAccounts_title", fallback: "Deriving Accounts")
    }
    public enum Device {
      /// Authenticate to your phone to complete using your phone's signing key.
      public static let message = L10n.tr("Localizable", "factorSourceActions_device_message", fallback: "Authenticate to your phone to complete using your phone's signing key.")
      /// Authenticate to your phone to sign.
      public static let messageSignature = L10n.tr("Localizable", "factorSourceActions_device_messageSignature", fallback: "Authenticate to your phone to sign.")
    }
    public enum EncryptMessage {
      /// Encrypting Message
      public static let title = L10n.tr("Localizable", "factorSourceActions_encryptMessage_title", fallback: "Encrypting Message")
    }
    public enum Ledger {
      /// Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.
      public static let message = L10n.tr("Localizable", "factorSourceActions_ledger_message", fallback: "Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.")
      /// Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.
      /// **Derivation may take up to a minute.**
      public static let messageDeriveAccounts = L10n.tr("Localizable", "factorSourceActions_ledger_messageDeriveAccounts", fallback: "Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.\n**Derivation may take up to a minute.**")
      /// Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.
      /// **Complete signing on the device.**
      public static let messageSignature = L10n.tr("Localizable", "factorSourceActions_ledger_messageSignature", fallback: "Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.\n**Complete signing on the device.**")
    }
    public enum ProveOwnership {
      /// Proving Ownership
      public static let title = L10n.tr("Localizable", "factorSourceActions_proveOwnership_title", fallback: "Proving Ownership")
    }
    public enum Signature {
      /// Signature Request
      public static let title = L10n.tr("Localizable", "factorSourceActions_signature_title", fallback: "Signature Request")
    }
  }
  public enum FactorSources {
    public enum Kind {
      /// Phone
      public static let device = L10n.tr("Localizable", "factorSources_kind_device", fallback: "Phone")
      /// Ledger
      public static let ledgerHQHardwareWallet = L10n.tr("Localizable", "factorSources_kind_ledgerHQHardwareWallet", fallback: "Ledger")
      /// Seed phrase
      public static let offDeviceMnemonic = L10n.tr("Localizable", "factorSources_kind_offDeviceMnemonic", fallback: "Seed phrase")
      /// Security Questions
      public static let securityQuestions = L10n.tr("Localizable", "factorSources_kind_securityQuestions", fallback: "Security Questions")
      /// Third-party
      public static let trustedContact = L10n.tr("Localizable", "factorSources_kind_trustedContact", fallback: "Third-party")
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
    /// I have written down this seed phrase
    public static let backedUpMnemonicHeading = L10n.tr("Localizable", "homePage_backedUpMnemonicHeading", fallback: "I have written down this seed phrase")
    /// Create a New Account
    public static let createNewAccount = L10n.tr("Localizable", "homePage_createNewAccount", fallback: "Create a New Account")
    /// Legacy
    public static let legacyAccountHeading = L10n.tr("Localizable", "homePage_legacyAccountHeading", fallback: "Legacy")
    /// Please write down seed phrase to ensure Account control
    public static let securityPromptBackup = L10n.tr("Localizable", "homePage_securityPromptBackup", fallback: "Please write down seed phrase to ensure Account control")
    /// Seed phrase required - begin entry
    public static let securityPromptRecover = L10n.tr("Localizable", "homePage_securityPromptRecover", fallback: "Seed phrase required - begin entry")
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
    public enum ProfileOlympiaError {
      /// OK (%d)
      public static func okCountdown(_ p1: Int) -> String {
        return L10n.tr("Localizable", "homePage_profileOlympiaError_okCountdown", p1, fallback: "OK (%d)")
      }
      /// Your wallet is in a rare condition that must be resolved manually. Please email support at hello@radixdlt.com with subject line BDFS ERROR. Somebody will respond and help you resolve the issue safely.
      public static let subtitle = L10n.tr("Localizable", "homePage_profileOlympiaError_subtitle", fallback: "Your wallet is in a rare condition that must be resolved manually. Please email support at hello@radixdlt.com with subject line BDFS ERROR. Somebody will respond and help you resolve the issue safely.")
      /// SERIOUS ERROR - PLEASE READ
      public static let title = L10n.tr("Localizable", "homePage_profileOlympiaError_title", fallback: "SERIOUS ERROR - PLEASE READ")
    }
    public enum RadixBanner {
      /// Get Started Now
      public static let action = L10n.tr("Localizable", "homePage_radixBanner_action", fallback: "Get Started Now")
      /// Complete setting up your wallet and start staking, using dApps and more!
      public static let subtitle = L10n.tr("Localizable", "homePage_radixBanner_subtitle", fallback: "Complete setting up your wallet and start staking, using dApps and more!")
      /// Start Using Radix
      public static let title = L10n.tr("Localizable", "homePage_radixBanner_title", fallback: "Start Using Radix")
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
    /// Number of networks: %d
    public static func numberOfNetworksLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_numberOfNetworksLabel", p1, fallback: "Number of networks: %d")
    }
    /// Unable to find wallet backup in iCloud.
    public static let profileNotFoundInCloud = L10n.tr("Localizable", "iOSProfileBackup_profileNotFoundInCloud", fallback: "Unable to find wallet backup in iCloud.")
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
    public enum AutomaticBackups {
      /// Disable Backup to iCloud
      public static let disable = L10n.tr("Localizable", "iOSProfileBackup_automaticBackups_disable", fallback: "Disable Backup to iCloud")
      /// Enable Backup to iCloud
      public static let enable = L10n.tr("Localizable", "iOSProfileBackup_automaticBackups_enable", fallback: "Enable Backup to iCloud")
      /// Automatic continuous backups
      public static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_automaticBackups_subtitle", fallback: "Automatic continuous backups")
    }
    public enum ConfirmCloudSyncDisableAlert {
      /// Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?
      public static let title = L10n.tr("Localizable", "iOSProfileBackup_confirmCloudSyncDisableAlert_title", fallback: "Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?")
    }
    public enum DeleteWallet {
      /// Delete Wallet and iCloud Backup
      public static let confirmButton = L10n.tr("Localizable", "iOSProfileBackup_deleteWallet_confirmButton", fallback: "Delete Wallet and iCloud Backup")
      /// You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any iCloud backup.
      /// 
      /// **Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**
      public static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_deleteWallet_subtitle", fallback: "You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any iCloud backup.\n\n**Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**")
    }
    public enum ICloudSyncEnabledAlert {
      /// iCloud sync is now enabled, but it might take up to an hour before your wallet data is uploaded to iCloud.
      public static let message = L10n.tr("Localizable", "iOSProfileBackup_iCloudSyncEnabledAlert_message", fallback: "iCloud sync is now enabled, but it might take up to an hour before your wallet data is uploaded to iCloud.")
      /// Enabling iCloud sync
      public static let title = L10n.tr("Localizable", "iOSProfileBackup_iCloudSyncEnabledAlert_title", fallback: "Enabling iCloud sync")
    }
    public enum ProfileSync {
      /// Warning: If disabled you might lose access to your Accounts and Personas.
      public static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_profileSync_subtitle", fallback: "Warning: If disabled you might lose access to your Accounts and Personas.")
      /// Sync Wallet Data to iCloud
      public static let title = L10n.tr("Localizable", "iOSProfileBackup_profileSync_title", fallback: "Sync Wallet Data to iCloud")
    }
  }
  public enum IOSRecoverProfileBackup {
    /// No wallet backups available on current iCloud account
    public static let noBackupsAvailable = L10n.tr("Localizable", "iOSRecoverProfileBackup_noBackupsAvailable", fallback: "No wallet backups available on current iCloud account")
    public enum Choose {
      /// Choose a backup on iCloud
      public static let title = L10n.tr("Localizable", "iOSRecoverProfileBackup_choose_title", fallback: "Choose a backup on iCloud")
    }
  }
  public enum ImportMnemonic {
    /// Advanced Mode
    public static let advancedModeButton = L10n.tr("Localizable", "importMnemonic_advancedModeButton", fallback: "Advanced Mode")
    /// Incorrect seed phrase
    public static let checksumFailure = L10n.tr("Localizable", "importMnemonic_checksumFailure", fallback: "Incorrect seed phrase")
    /// Failed to validate all accounts against mnemonic
    public static let failedToValidateAllAccounts = L10n.tr("Localizable", "importMnemonic_failedToValidateAllAccounts", fallback: "Failed to validate all accounts against mnemonic")
    /// Import
    public static let importSeedPhrase = L10n.tr("Localizable", "importMnemonic_importSeedPhrase", fallback: "Import")
    /// Import Seed Phrase
    public static let navigationTitle = L10n.tr("Localizable", "importMnemonic_navigationTitle", fallback: "Import Seed Phrase")
    /// Backup Seed Phrase
    public static let navigationTitleBackup = L10n.tr("Localizable", "importMnemonic_navigationTitleBackup", fallback: "Backup Seed Phrase")
    /// Number of Seed Phrase Words
    public static let numberOfWordsPicker = L10n.tr("Localizable", "importMnemonic_numberOfWordsPicker", fallback: "Number of Seed Phrase Words")
    /// Passphrase
    public static let passphrase = L10n.tr("Localizable", "importMnemonic_passphrase", fallback: "Passphrase")
    /// Optional BIP39 Passphrase. This is not your wallet password, and the Radix Desktop Wallet did not use a BIP39 passphrase. This is only to support import from other wallets that may have used one.
    public static let passphraseHint = L10n.tr("Localizable", "importMnemonic_passphraseHint", fallback: "Optional BIP39 Passphrase. This is not your wallet password, and the Radix Desktop Wallet did not use a BIP39 passphrase. This is only to support import from other wallets that may have used one.")
    /// Passphrase
    public static let passphrasePlaceholder = L10n.tr("Localizable", "importMnemonic_passphrasePlaceholder", fallback: "Passphrase")
    /// Regular Mode
    public static let regularModeButton = L10n.tr("Localizable", "importMnemonic_regularModeButton", fallback: "Regular Mode")
    /// Imported Seed Phrase
    public static let seedPhraseImported = L10n.tr("Localizable", "importMnemonic_seedPhraseImported", fallback: "Imported Seed Phrase")
    /// Success
    public static let verificationSuccess = L10n.tr("Localizable", "importMnemonic_verificationSuccess", fallback: "Success")
    /// Word %d
    public static func wordHeading(_ p1: Int) -> String {
      return L10n.tr("Localizable", "importMnemonic_wordHeading", p1, fallback: "Word %d")
    }
    /// Wrong mnemmonic
    public static let wrongMnemonicHUD = L10n.tr("Localizable", "importMnemonic_wrongMnemonicHUD", fallback: "Wrong mnemmonic")
    public enum BackedUpAlert {
      /// Yes, I have written it down
      public static let confirmAction = L10n.tr("Localizable", "importMnemonic_backedUpAlert_confirmAction", fallback: "Yes, I have written it down")
      /// Are you sure you have securely written down this seed phrase? You will need it to recover access if you lose your phone.
      public static let message = L10n.tr("Localizable", "importMnemonic_backedUpAlert_message", fallback: "Are you sure you have securely written down this seed phrase? You will need it to recover access if you lose your phone.")
      /// No, not yet
      public static let noAction = L10n.tr("Localizable", "importMnemonic_backedUpAlert_noAction", fallback: "No, not yet")
      /// Confirm Seed Phrase Saved
      public static let title = L10n.tr("Localizable", "importMnemonic_backedUpAlert_title", fallback: "Confirm Seed Phrase Saved")
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
    public enum ShieldPrompt {
      /// Please write down seed phrase to ensure Account control
      public static let backupSeedPhrase = L10n.tr("Localizable", "importMnemonic_shieldPrompt_backupSeedPhrase", fallback: "Please write down seed phrase to ensure Account control")
      /// Enter this Account's seed phrase
      public static let enterSeedPhrase = L10n.tr("Localizable", "importMnemonic_shieldPrompt_enterSeedPhrase", fallback: "Enter this Account's seed phrase")
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
    /// No new accounts were found on this Ledger device
    public static let noNewAccounts = L10n.tr("Localizable", "importOlympiaAccounts_noNewAccounts", fallback: "No new accounts were found on this Ledger device")
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
      /// The following accounts will be imported into this Radix Wallet.
      public static let subtitle = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_subtitle", fallback: "The following accounts will be imported into this Radix Wallet.")
      /// Import Accounts
      public static let title = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_title", fallback: "Import Accounts")
      /// Unnamed
      public static let unnamed = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_unnamed", fallback: "Unnamed")
    }
    public enum Completion {
      /// Continue to Account List
      public static let accountListButtonTitle = L10n.tr("Localizable", "importOlympiaAccounts_completion_accountListButtonTitle", fallback: "Continue to Account List")
      /// Your Accounts live on the Radix Network and you can access them anytime in your Wallet.
      public static let explanation = L10n.tr("Localizable", "importOlympiaAccounts_completion_explanation", fallback: "Your Accounts live on the Radix Network and you can access them anytime in your Wallet.")
      /// You've now imported these Accounts:
      public static let subtitleMultiple = L10n.tr("Localizable", "importOlympiaAccounts_completion_subtitleMultiple", fallback: "You've now imported these Accounts:")
      /// You've now imported this Account:
      public static let subtitleSingle = L10n.tr("Localizable", "importOlympiaAccounts_completion_subtitleSingle", fallback: "You've now imported this Account:")
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
      /// Do not throw away this seed phrase! You will still need it if you need to recover access to your Olympia accounts in the future.
      public static let keepSeedPhrasePrompt = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_keepSeedPhrasePrompt", fallback: "Do not throw away this seed phrase! You will still need it if you need to recover access to your Olympia accounts in the future.")
      /// I Understand
      public static let keepSeedPhrasePromptConfirmation = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_keepSeedPhrasePromptConfirmation", fallback: "I Understand")
      /// Warning
      public static let keepSeedPhraseTitle = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_keepSeedPhraseTitle", fallback: "Warning")
      /// To complete importing your accounts, please view your seed phrase in the Radix Desktop Wallet and enter the words here.
      public static let subtitle = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_subtitle", fallback: "To complete importing your accounts, please view your seed phrase in the Radix Desktop Wallet and enter the words here.")
      /// Verify With Your Seed Phrase
      public static let title = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_title", fallback: "Verify With Your Seed Phrase")
      /// This will give this Radix Wallet control of your accounts. Never give your seed phrase to anyone for any reason.
      public static let warning = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_warning", fallback: "This will give this Radix Wallet control of your accounts. Never give your seed phrase to anyone for any reason.")
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
    public enum CouldNotSign {
      /// Transaction could not be signed. To sign complex transactions, please enable either "blind signing" or "verbose mode" in the Radix app on your Ledger device.
      public static let message = L10n.tr("Localizable", "ledgerHardwareDevices_couldNotSign_message", fallback: "Transaction could not be signed. To sign complex transactions, please enable either \"blind signing\" or \"verbose mode\" in the Radix app on your Ledger device.")
      /// Could Not Sign
      public static let title = L10n.tr("Localizable", "ledgerHardwareDevices_couldNotSign_title", fallback: "Could Not Sign")
    }
    public enum LinkConnectorAlert {
      /// Continue
      public static let `continue` = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_continue", fallback: "Continue")
      /// To use a Ledger hardware wallet device, it must be connected to a computer running the Radix Connector browser extension.
      public static let message = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_message", fallback: "To use a Ledger hardware wallet device, it must be connected to a computer running the Radix Connector browser extension.")
      /// Link a Connector
      public static let title = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_title", fallback: "Link a Connector")
    }
    public enum Verification {
      /// Address verified
      public static let addressVerified = L10n.tr("Localizable", "ledgerHardwareDevices_verification_addressVerified", fallback: "Address verified")
      /// Verify address: Returned bad response
      public static let badResponse = L10n.tr("Localizable", "ledgerHardwareDevices_verification_badResponse", fallback: "Verify address: Returned bad response")
      /// Verify address: Mismatched addresses
      public static let mismatch = L10n.tr("Localizable", "ledgerHardwareDevices_verification_mismatch", fallback: "Verify address: Mismatched addresses")
      /// Verify address: Request failed
      public static let requestFailed = L10n.tr("Localizable", "ledgerHardwareDevices_verification_requestFailed", fallback: "Verify address: Request failed")
    }
  }
  public enum LinkedConnectors {
    /// Please scan the QR code provided by your Radix Wallet Connector browser extension.
    public static let incorrectQrMessage = L10n.tr("Localizable", "linkedConnectors_incorrectQrMessage", fallback: "Please scan the QR code provided by your Radix Wallet Connector browser extension.")
    /// Incorrect QR code scanned.
    public static let incorrectQrTitle = L10n.tr("Localizable", "linkedConnectors_incorrectQrTitle", fallback: "Incorrect QR code scanned.")
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
      /// What would you like to call this Radix Connector installation?
      public static let subtitle = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_subtitle", fallback: "What would you like to call this Radix Connector installation?")
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
      /// Open your Radix Connector extension's menu by clicking its icon in your list of browser extensions, and scan the QR code shown.
      public static let subtitle = L10n.tr("Localizable", "linkedConnectors_newConnection_subtitle", fallback: "Open your Radix Connector extension's menu by clicking its icon in your list of browser extensions, and scan the QR code shown.")
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
    public enum Eula {
      /// Accept
      public static let accept = L10n.tr("Localizable", "onboarding_eula_accept", fallback: "Accept")
      /// To proceed, you must accept the user terms below.
      public static let headerSubtitle = L10n.tr("Localizable", "onboarding_eula_headerSubtitle", fallback: "To proceed, you must accept the user terms below.")
      /// User Terms
      public static let headerTitle = L10n.tr("Localizable", "onboarding_eula_headerTitle", fallback: "User Terms")
    }
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
    /// Write down main seed phrase
    public static let writeSeedPhrase = L10n.tr("Localizable", "personas_writeSeedPhrase", fallback: "Write down main seed phrase")
  }
  public enum ProfileBackup {
    /// Backing up your wallet ensures that you can restore access to your Accounts, Personas, and wallet settings on a new phone by re-entering your seed phrase(s).
    /// 
    /// **For security, backups do not contain any seed phrases or private keys. You must write them down separately.**
    public static let headerTitle = L10n.tr("Localizable", "profileBackup_headerTitle", fallback: "Backing up your wallet ensures that you can restore access to your Accounts, Personas, and wallet settings on a new phone by re-entering your seed phrase(s).\n\n**For security, backups do not contain any seed phrases or private keys. You must write them down separately.**")
    public enum AutomaticBackups {
      /// Automatic Backups (recommended)
      public static let title = L10n.tr("Localizable", "profileBackup_automaticBackups_title", fallback: "Automatic Backups (recommended)")
    }
    public enum DeleteWallet {
      /// Delete Wallet
      public static let buttonTitle = L10n.tr("Localizable", "profileBackup_deleteWallet_buttonTitle", fallback: "Delete Wallet")
    }
    public enum DeleteWalletDialog {
      /// Delete Wallet
      public static let confirm = L10n.tr("Localizable", "profileBackup_deleteWalletDialog_confirm", fallback: "Delete Wallet")
      /// WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.
      public static let message = L10n.tr("Localizable", "profileBackup_deleteWalletDialog_message", fallback: "WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.")
    }
    public enum IncorrectPasswordAlert {
      /// Failed to decrypt using provided password.
      public static let messageDecryption = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_messageDecryption", fallback: "Failed to decrypt using provided password.")
      /// Failed to encrypt using provided password.
      public static let messageEncryption = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_messageEncryption", fallback: "Failed to encrypt using provided password.")
      /// OK
      public static let okAction = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_okAction", fallback: "OK")
      /// Incorrect password
      public static let title = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_title", fallback: "Incorrect password")
    }
    public enum ManualBackups {
      /// Confirm password
      public static let confirmPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_confirmPasswordPlaceholder", fallback: "Confirm password")
      /// Enter the password you chose when you originally encrypted this Wallet Backup file.
      public static let decryptBackupSubtitle = L10n.tr("Localizable", "profileBackup_manualBackups_decryptBackupSubtitle", fallback: "Enter the password you chose when you originally encrypted this Wallet Backup file.")
      /// Decrypt Wallet Backup File
      public static let decryptBackupTitle = L10n.tr("Localizable", "profileBackup_manualBackups_decryptBackupTitle", fallback: "Decrypt Wallet Backup File")
      /// Yes
      public static let encryptBackupDialogConfirm = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupDialogConfirm", fallback: "Yes")
      /// No
      public static let encryptBackupDialogDeny = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupDialogDeny", fallback: "No")
      /// Encrypt this backup with a password?
      public static let encryptBackupDialogTitle = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupDialogTitle", fallback: "Encrypt this backup with a password?")
      /// Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.
      public static let encryptBackupSubtitle = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupSubtitle", fallback: "Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.")
      /// Encrypt Wallet Backup File
      public static let encryptBackupTitle = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupTitle", fallback: "Encrypt Wallet Backup File")
      /// Enter password
      public static let enterPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_enterPasswordPlaceholder", fallback: "Enter password")
      /// Export Wallet Backup File
      public static let exportButtonTitle = L10n.tr("Localizable", "profileBackup_manualBackups_exportButtonTitle", fallback: "Export Wallet Backup File")
      /// Decryption password
      public static let nonConformingDecryptionPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_nonConformingDecryptionPasswordPlaceholder", fallback: "Decryption password")
      /// Encryption password
      public static let nonConformingEncryptionPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_nonConformingEncryptionPasswordPlaceholder", fallback: "Encryption password")
      /// Passwords do not match
      public static let passwordsMissmatchError = L10n.tr("Localizable", "profileBackup_manualBackups_passwordsMissmatchError", fallback: "Passwords do not match")
      /// A manually exported wallet backup file may also be used for recovery, along with your seed phrase(s).
      /// 
      /// Only the **current configuration** of your wallet is backed up with each manual export.
      public static let subtitle = L10n.tr("Localizable", "profileBackup_manualBackups_subtitle", fallback: "A manually exported wallet backup file may also be used for recovery, along with your seed phrase(s).\n\nOnly the **current configuration** of your wallet is backed up with each manual export.")
      /// Exported wallet backup file
      public static let successMessage = L10n.tr("Localizable", "profileBackup_manualBackups_successMessage", fallback: "Exported wallet backup file")
      /// Manual Backups
      public static let title = L10n.tr("Localizable", "profileBackup_manualBackups_title", fallback: "Manual Backups")
    }
    public enum ResetWalletDialog {
      /// WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.
      public static let message = L10n.tr("Localizable", "profileBackup_resetWalletDialog_message", fallback: "WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.")
      /// Reset and Delete iCloud Backup
      public static let resetAndDeleteBackupButtonTitle = L10n.tr("Localizable", "profileBackup_resetWalletDialog_resetAndDeleteBackupButtonTitle", fallback: "Reset and Delete iCloud Backup")
      /// Reset Wallet
      public static let resetButtonTitle = L10n.tr("Localizable", "profileBackup_resetWalletDialog_resetButtonTitle", fallback: "Reset Wallet")
      /// Reset Wallet?
      public static let title = L10n.tr("Localizable", "profileBackup_resetWalletDialog_title", fallback: "Reset Wallet?")
    }
  }
  public enum RecoverProfileBackup {
    /// **Backup from:** %@
    public static func backupFrom(_ p1: Any) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_backupFrom", String(describing: p1), fallback: "**Backup from:** %@")
    }
    /// Backup not available?
    public static let backupNotAvailable = L10n.tr("Localizable", "recoverProfileBackup_backupNotAvailable", fallback: "Backup not available?")
    /// Incompatible Wallet data
    public static let incompatibleWalletDataLabel = L10n.tr("Localizable", "recoverProfileBackup_incompatibleWalletDataLabel", fallback: "Incompatible Wallet data")
    /// **Last modified:** %@
    public static func lastModified(_ p1: Any) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_lastModified", String(describing: p1), fallback: "**Last modified:** %@")
    }
    /// **Number of accounts:** %d
    public static func numberOfAccounts(_ p1: Int) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_numberOfAccounts", p1, fallback: "**Number of accounts:** %d")
    }
    /// **Number of personas:** %d
    public static func numberOfPersonas(_ p1: Int) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_numberOfPersonas", p1, fallback: "**Number of personas:** %d")
    }
    /// Other Restore Options
    public static let otherRestoreOptionsButton = L10n.tr("Localizable", "recoverProfileBackup_otherRestoreOptionsButton", fallback: "Other Restore Options")
    /// The password is wrong
    public static let passwordWrong = L10n.tr("Localizable", "recoverProfileBackup_passwordWrong", fallback: "The password is wrong")
    public enum Header {
      /// Select a backup to restore your Radix Wallet. You will be asked to enter your seed phrase(s) to recover control of your Accounts and Personas.
      public static let subtitle = L10n.tr("Localizable", "recoverProfileBackup_header_subtitle", fallback: "Select a backup to restore your Radix Wallet. You will be asked to enter your seed phrase(s) to recover control of your Accounts and Personas.")
      /// Restore Wallet From Backup
      public static let title = L10n.tr("Localizable", "recoverProfileBackup_header_title", fallback: "Restore Wallet From Backup")
    }
    public enum ImportFileButton {
      /// Import from Backup File Instead
      public static let title = L10n.tr("Localizable", "recoverProfileBackup_importFileButton_title", fallback: "Import from Backup File Instead")
    }
  }
  public enum RecoverSeedPhrase {
    /// Enter This Seed Phrase
    public static let enterButton = L10n.tr("Localizable", "recoverSeedPhrase_enterButton", fallback: "Enter This Seed Phrase")
    /// Hidden accounts only.
    public static let hiddenAccountsOnly = L10n.tr("Localizable", "recoverSeedPhrase_hiddenAccountsOnly", fallback: "Hidden accounts only.")
    /// I Don’t Have the Main Seed Phrase
    public static let noMainSeedPhraseButton = L10n.tr("Localizable", "recoverSeedPhrase_noMainSeedPhraseButton", fallback: "I Don’t Have the Main Seed Phrase")
    /// Skip This Seed Phrase For Now
    public static let skipButton = L10n.tr("Localizable", "recoverSeedPhrase_skipButton", fallback: "Skip This Seed Phrase For Now")
    /// Skip Main Seed Phrase Entry
    public static let skipMainSeedPhraseButton = L10n.tr("Localizable", "recoverSeedPhrase_skipMainSeedPhraseButton", fallback: "Skip Main Seed Phrase Entry")
    public enum Header {
      /// Your **Personas** and the following **Accounts** are controlled by your main seed phrase. To recover control, you must re-enter it.
      public static let subtitleMainSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_subtitleMainSeedPhrase", fallback: "Your **Personas** and the following **Accounts** are controlled by your main seed phrase. To recover control, you must re-enter it.")
      /// The Radix Wallet always uses a single main “Babylon” seed phrase to generate new Personas and new Accounts (when not using a Ledger device).
      /// 
      /// If you do not have access to your previous main seed phrase, you can skip entering it for now. **The Radix Wallet will create a new one, which will be used for new Personas and Accounts.**
      /// 
      /// Your old Accounts and Personas will still be listed, but you will have to enter their original seed phrase to use them. Alternatively, you can hide them if you no longer are interested in using them.
      public static let subtitleNoMainSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_subtitleNoMainSeedPhrase", fallback: "The Radix Wallet always uses a single main “Babylon” seed phrase to generate new Personas and new Accounts (when not using a Ledger device).\n\nIf you do not have access to your previous main seed phrase, you can skip entering it for now. **The Radix Wallet will create a new one, which will be used for new Personas and Accounts.**\n\nYour old Accounts and Personas will still be listed, but you will have to enter their original seed phrase to use them. Alternatively, you can hide them if you no longer are interested in using them.")
      /// The following **Accounts** are controlled by a seed phrase. To recover control, you must re-enter it.
      public static let subtitleOtherSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_subtitleOtherSeedPhrase", fallback: "The following **Accounts** are controlled by a seed phrase. To recover control, you must re-enter it.")
      /// Main Seed Phrase Required
      public static let titleMain = L10n.tr("Localizable", "recoverSeedPhrase_header_titleMain", fallback: "Main Seed Phrase Required")
      /// No Main Seed Phrase?
      public static let titleNoMainSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_titleNoMainSeedPhrase", fallback: "No Main Seed Phrase?")
      /// Seed Phrase Required
      public static let titleOther = L10n.tr("Localizable", "recoverSeedPhrase_header_titleOther", fallback: "Seed Phrase Required")
    }
  }
  public enum RecoverWalletWithoutProfile {
    public enum Complete {
      /// Continue
      public static let continueButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_complete_continueButton", fallback: "Continue")
      /// Accounts discovered in the scan have been added to your wallet.
      /// 
      /// If you have any “Legacy” Accounts (created on the Olympia network) to import - or any Accounts using a Ledger hardware wallet device - please continue and then use the **Account Recovery Scan** option in your Radix Wallet settings under **Account Security**.
      public static let headerSubtitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_complete_headerSubtitle", fallback: "Accounts discovered in the scan have been added to your wallet.\n\nIf you have any “Legacy” Accounts (created on the Olympia network) to import - or any Accounts using a Ledger hardware wallet device - please continue and then use the **Account Recovery Scan** option in your Radix Wallet settings under **Account Security**.")
      /// Recovery Complete
      public static let headerTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_complete_headerTitle", fallback: "Recovery Complete")
    }
    public enum Info {
      /// Continue
      public static let continueButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_info_continueButton", fallback: "Continue")
      /// **If you have no wallet backup in the cloud or as an exported backup file**, you can still restore Account access only using your main “Babylon” seed phrase. You cannot recover your Account names or other wallet settings this way.
      /// 
      /// You will be asked to enter your main seed phrase. This is a set of **24 words** that the Radix Wallet mobile app showed you to write down and save securely.
      public static let headerSubtitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_info_headerSubtitle", fallback: "**If you have no wallet backup in the cloud or as an exported backup file**, you can still restore Account access only using your main “Babylon” seed phrase. You cannot recover your Account names or other wallet settings this way.\n\nYou will be asked to enter your main seed phrase. This is a set of **24 words** that the Radix Wallet mobile app showed you to write down and save securely.")
      /// Recover Control Without Backup
      public static let headerTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_info_headerTitle", fallback: "Recover Control Without Backup")
    }
    public enum Start {
      /// Recover with Main Seed Phrase
      public static let babylonSectionButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_babylonSectionButton", fallback: "Recover with Main Seed Phrase")
      /// I have my main “Babylon” 24-word seed phrase.
      public static let babylonSectionTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_babylonSectionTitle", fallback: "I have my main “Babylon” 24-word seed phrase.")
      /// Ledger-only Restore
      public static let hardwareSectionButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_hardwareSectionButton", fallback: "Ledger-only Restore")
      /// I only want to restore Ledger hardware wallet Accounts.
      public static let hardwareSectionTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_hardwareSectionTitle", fallback: "I only want to restore Ledger hardware wallet Accounts.")
      /// If you have no wallet backup in the cloud, or as an exported backup file, you still have other restore options.
      public static let headerSubtitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_headerSubtitle", fallback: "If you have no wallet backup in the cloud, or as an exported backup file, you still have other restore options.")
      /// Recover Control Without Backup
      public static let headerTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_headerTitle", fallback: "Recover Control Without Backup")
      /// Olympia-only Restore
      public static let olympiaSectionButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_olympiaSectionButton", fallback: "Olympia-only Restore")
      /// I only have Accounts created on the Radix Olympia network.
      public static let olympiaSectionTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_olympiaSectionTitle", fallback: "I only have Accounts created on the Radix Olympia network.")
      /// Cancel
      public static let useNewWalletAlertCancel = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertCancel", fallback: "Cancel")
      /// Continue
      public static let useNewWalletAlertContinue = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertContinue", fallback: "Continue")
      /// Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Ledger device.
      public static let useNewWalletAlertMessageHardware = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertMessageHardware", fallback: "Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Ledger device.")
      /// Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Olympia seed phrase.
      public static let useNewWalletAlertMessageOlympia = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertMessageOlympia", fallback: "Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Olympia seed phrase.")
      /// No Main Seed Phrase?
      public static let useNewWalletAlertTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertTitle", fallback: "No Main Seed Phrase?")
    }
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
      /// I have written down this seed phrase
      public static let confirmButton = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_confirmButton", fallback: "I have written down this seed phrase")
      /// Are you sure you have written down your seed phrase?
      public static let subtitle = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_subtitle", fallback: "Are you sure you have written down your seed phrase?")
      /// Use Caution
      public static let title = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_title", fallback: "Use Caution")
    }
  }
  public enum SeedPhrases {
    /// Please write down your Seed Phrase
    public static let backupWarning = L10n.tr("Localizable", "seedPhrases_backupWarning", fallback: "Please write down your Seed Phrase")
    /// Hidden Accounts only
    public static let hiddenAccountsOnly = L10n.tr("Localizable", "seedPhrases_hiddenAccountsOnly", fallback: "Hidden Accounts only")
    /// A Seed Phrase provides full access to your accounts and funds. When viewing, ensure you’re in a safe environment and no one is looking at your screen.
    public static let message = L10n.tr("Localizable", "seedPhrases_message", fallback: "A Seed Phrase provides full access to your accounts and funds. When viewing, ensure you’re in a safe environment and no one is looking at your screen.")
    /// Seed Phrases
    public static let title = L10n.tr("Localizable", "seedPhrases_title", fallback: "Seed Phrases")
    /// You are responsible for the security of your Seed Phrase
    public static let warning = L10n.tr("Localizable", "seedPhrases_warning", fallback: "You are responsible for the security of your Seed Phrase")
    public enum SeedPhrase {
      /// Seed Phrase Entry Required
      public static let headingNeedsImport = L10n.tr("Localizable", "seedPhrases_seedPhrase_headingNeedsImport", fallback: "Seed Phrase Entry Required")
      /// Reveal Seed Phrase
      public static let headingReveal = L10n.tr("Localizable", "seedPhrases_seedPhrase_headingReveal", fallback: "Reveal Seed Phrase")
      /// Seed Phrase
      public static let headingScan = L10n.tr("Localizable", "seedPhrases_seedPhrase_headingScan", fallback: "Seed Phrase")
      /// Connected to %d Accounts
      public static func multipleConnectedAccountsReveal(_ p1: Int) -> String {
        return L10n.tr("Localizable", "seedPhrases_seedPhrase_multipleConnectedAccountsReveal", p1, fallback: "Connected to %d Accounts")
      }
      /// Currently connected to %d Accounts
      public static func multipleConnectedAccountsScan(_ p1: Int) -> String {
        return L10n.tr("Localizable", "seedPhrases_seedPhrase_multipleConnectedAccountsScan", p1, fallback: "Currently connected to %d Accounts")
      }
      /// Not connected to any Accounts
      public static let noConnectedAccountsReveal = L10n.tr("Localizable", "seedPhrases_seedPhrase_noConnectedAccountsReveal", fallback: "Not connected to any Accounts")
      /// Not yet connected to any Accounts
      public static let noConnectedAccountsScan = L10n.tr("Localizable", "seedPhrases_seedPhrase_noConnectedAccountsScan", fallback: "Not yet connected to any Accounts")
      /// Connected to 1 Account
      public static let oneConnectedAccountReveal = L10n.tr("Localizable", "seedPhrases_seedPhrase_oneConnectedAccountReveal", fallback: "Connected to 1 Account")
      /// Currently connected to 1 Account
      public static let oneConnectedAccountScan = L10n.tr("Localizable", "seedPhrases_seedPhrase_oneConnectedAccountScan", fallback: "Currently connected to 1 Account")
    }
  }
  public enum Settings {
    /// Account Security & Settings
    public static let accountSecurityAndSettings = L10n.tr("Localizable", "settings_accountSecurityAndSettings", fallback: "Account Security & Settings")
    /// App Settings
    public static let appSettings = L10n.tr("Localizable", "settings_appSettings", fallback: "App Settings")
    /// Version: %@ build #%@
    public static func appVersion(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "settings_appVersion", String(describing: p1), String(describing: p2), fallback: "Version: %@ build #%@")
    }
    /// Authorized dApps
    public static let authorizedDapps = L10n.tr("Localizable", "settings_authorizedDapps", fallback: "Authorized dApps")
    /// Personas
    public static let personas = L10n.tr("Localizable", "settings_personas", fallback: "Personas")
    /// Please write down the seed phrase for your Personas
    public static let personasSeedPhrasePrompt = L10n.tr("Localizable", "settings_personasSeedPhrasePrompt", fallback: "Please write down the seed phrase for your Personas")
    /// Settings
    public static let title = L10n.tr("Localizable", "settings_title", fallback: "Settings")
    public enum ImportFromLegacyWalletHeader {
      /// Import Legacy Accounts
      public static let importLegacyAccounts = L10n.tr("Localizable", "settings_importFromLegacyWalletHeader_importLegacyAccounts", fallback: "Import Legacy Accounts")
      /// Get started importing your Olympia accounts into your new Radix Wallet
      public static let subtitle = L10n.tr("Localizable", "settings_importFromLegacyWalletHeader_subtitle", fallback: "Get started importing your Olympia accounts into your new Radix Wallet")
      /// Radix Olympia Desktop Wallet user?
      public static let title = L10n.tr("Localizable", "settings_importFromLegacyWalletHeader_title", fallback: "Radix Olympia Desktop Wallet user?")
    }
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
    /// Tap to unlock
    public static let tapAnywhereToUnlock = L10n.tr("Localizable", "splash_tapAnywhereToUnlock", fallback: "Tap to unlock")
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
    public enum ProfileOnAnotherDeviceAlert {
      /// Ask Later (no changes)
      public static let askLater = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_askLater", fallback: "Ask Later (no changes)")
      /// Claim Existing Wallet
      public static let claimExisting = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_claimExisting", fallback: "Claim Existing Wallet")
      /// Clear Wallet on This Phone
      public static let claimHere = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_claimHere", fallback: "Clear Wallet on This Phone")
      /// This wallet is currently configured with a set of Accounts and Personas in use by a different phone.
      /// 
      /// To make changes to this wallet, you must claim it for use on this phone instead, removing access by the other phone.
      /// 
      /// Or you can clear this wallet from this phone and start fresh.
      public static let message = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_message", fallback: "This wallet is currently configured with a set of Accounts and Personas in use by a different phone.\n\nTo make changes to this wallet, you must claim it for use on this phone instead, removing access by the other phone.\n\nOr you can clear this wallet from this phone and start fresh.")
      /// Claim This Wallet?
      public static let title = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_title", fallback: "Claim This Wallet?")
    }
    public enum RootDetection {
      /// I Understand the Risk
      public static let acknowledgeButton = L10n.tr("Localizable", "splash_rootDetection_acknowledgeButton", fallback: "I Understand the Risk")
      /// It appears that your device might be rooted. To ensure the security of your Accounts and assets, using the Radix Wallet on rooted devices is not recommended. Please confirm if you wish to continue anyway at your own risk.
      public static let messageAndroid = L10n.tr("Localizable", "splash_rootDetection_messageAndroid", fallback: "It appears that your device might be rooted. To ensure the security of your Accounts and assets, using the Radix Wallet on rooted devices is not recommended. Please confirm if you wish to continue anyway at your own risk.")
      /// It appears that your device might be jailbroken. To ensure the security of your Accounts and assets, using the Radix Wallet on jailbroken devices is not recommended. Please confirm if you wish to continue anyway at your own risk.
      public static let messageIOS = L10n.tr("Localizable", "splash_rootDetection_messageIOS", fallback: "It appears that your device might be jailbroken. To ensure the security of your Accounts and assets, using the Radix Wallet on jailbroken devices is not recommended. Please confirm if you wish to continue anyway at your own risk.")
      /// Possible jailbreak detected
      public static let titleIOS = L10n.tr("Localizable", "splash_rootDetection_titleIOS", fallback: "Possible jailbreak detected")
    }
  }
  public enum Survey {
    /// 10 - Very likely
    public static let highestScoreLabel = L10n.tr("Localizable", "survey_highestScoreLabel", fallback: "10 - Very likely")
    /// 0 - Not likely
    public static let lowestScoreLabel = L10n.tr("Localizable", "survey_lowestScoreLabel", fallback: "0 - Not likely")
    /// Submit Feedback - Thanks!
    public static let submitButton = L10n.tr("Localizable", "survey_submitButton", fallback: "Submit Feedback - Thanks!")
    /// How likely are you to recommend Radix and the Radix Wallet to your friends or colleagues?
    public static let subtitle = L10n.tr("Localizable", "survey_subtitle", fallback: "How likely are you to recommend Radix and the Radix Wallet to your friends or colleagues?")
    /// How's it Going?
    public static let title = L10n.tr("Localizable", "survey_title", fallback: "How's it Going?")
    public enum Reason {
      /// Let us know...
      public static let fieldHint = L10n.tr("Localizable", "survey_reason_fieldHint", fallback: "Let us know...")
      /// What’s the main reason for your score?
      public static let heading = L10n.tr("Localizable", "survey_reason_heading", fallback: "What’s the main reason for your score?")
    }
  }
  public enum TransactionHistory {
    /// This transaction cannot be summarized. Only the raw transaction manifest may be viewed.
    public static let complexTransaction = L10n.tr("Localizable", "transactionHistory_complexTransaction", fallback: "This transaction cannot be summarized. Only the raw transaction manifest may be viewed.")
    /// Deposited
    public static let depositedSection = L10n.tr("Localizable", "transactionHistory_depositedSection", fallback: "Deposited")
    /// Failed Transaction
    public static let failedTransaction = L10n.tr("Localizable", "transactionHistory_failedTransaction", fallback: "Failed Transaction")
    /// No deposits or withdrawals from this account in this transaction.
    public static let noBalanceChanges = L10n.tr("Localizable", "transactionHistory_noBalanceChanges", fallback: "No deposits or withdrawals from this account in this transaction.")
    /// You have no Transactions.
    public static let noTransactions = L10n.tr("Localizable", "transactionHistory_noTransactions", fallback: "You have no Transactions.")
    /// Settings
    public static let settingsSection = L10n.tr("Localizable", "transactionHistory_settingsSection", fallback: "Settings")
    /// History
    public static let title = L10n.tr("Localizable", "transactionHistory_title", fallback: "History")
    /// Updated Account Deposit Settings
    public static let updatedDepositSettings = L10n.tr("Localizable", "transactionHistory_updatedDepositSettings", fallback: "Updated Account Deposit Settings")
    /// Withdrawn
    public static let withdrawnSection = L10n.tr("Localizable", "transactionHistory_withdrawnSection", fallback: "Withdrawn")
    public enum DatePrefix {
      /// Today
      public static let today = L10n.tr("Localizable", "transactionHistory_datePrefix_today", fallback: "Today")
      /// Yesterday
      public static let yesterday = L10n.tr("Localizable", "transactionHistory_datePrefix_yesterday", fallback: "Yesterday")
    }
    public enum Filters {
      /// Type of Asset
      public static let assetTypeLabel = L10n.tr("Localizable", "transactionHistory_filters_assetTypeLabel", fallback: "Type of Asset")
      /// NFTs
      public static let assetTypeNFTsLabel = L10n.tr("Localizable", "transactionHistory_filters_assetTypeNFTsLabel", fallback: "NFTs")
      /// Clear All
      public static let clearAll = L10n.tr("Localizable", "transactionHistory_filters_clearAll", fallback: "Clear All")
      /// Deposits
      public static let depositsType = L10n.tr("Localizable", "transactionHistory_filters_depositsType", fallback: "Deposits")
      /// Show All NFTs
      public static let nftShowAll = L10n.tr("Localizable", "transactionHistory_filters_nftShowAll", fallback: "Show All NFTs")
      /// Show Less NFTs
      public static let nftShowLess = L10n.tr("Localizable", "transactionHistory_filters_nftShowLess", fallback: "Show Less NFTs")
      /// Show Results
      public static let showResultsButton = L10n.tr("Localizable", "transactionHistory_filters_showResultsButton", fallback: "Show Results")
      /// Filter
      public static let title = L10n.tr("Localizable", "transactionHistory_filters_title", fallback: "Filter")
      /// Show All Tokens
      public static let tokenShowAll = L10n.tr("Localizable", "transactionHistory_filters_tokenShowAll", fallback: "Show All Tokens")
      /// Show Less Tokens
      public static let tokenShowLess = L10n.tr("Localizable", "transactionHistory_filters_tokenShowLess", fallback: "Show Less Tokens")
      /// Tokens
      public static let tokensLabel = L10n.tr("Localizable", "transactionHistory_filters_tokensLabel", fallback: "Tokens")
      /// Type of Transaction
      public static let transactionTypeLabel = L10n.tr("Localizable", "transactionHistory_filters_transactionTypeLabel", fallback: "Type of Transaction")
      /// Withdrawals
      public static let withdrawalsType = L10n.tr("Localizable", "transactionHistory_filters_withdrawalsType", fallback: "Withdrawals")
    }
    public enum ManifestClass {
      /// Deposit Settings
      public static let accountSettings = L10n.tr("Localizable", "transactionHistory_manifestClass_AccountSettings", fallback: "Deposit Settings")
      /// Claim Stake
      public static let claim = L10n.tr("Localizable", "transactionHistory_manifestClass_Claim", fallback: "Claim Stake")
      /// Contribute
      public static let contribute = L10n.tr("Localizable", "transactionHistory_manifestClass_Contribute", fallback: "Contribute")
      /// General
      public static let general = L10n.tr("Localizable", "transactionHistory_manifestClass_General", fallback: "General")
      /// Other
      public static let other = L10n.tr("Localizable", "transactionHistory_manifestClass_Other", fallback: "Other")
      /// Redeem
      public static let redeem = L10n.tr("Localizable", "transactionHistory_manifestClass_Redeem", fallback: "Redeem")
      /// Stake
      public static let staking = L10n.tr("Localizable", "transactionHistory_manifestClass_Staking", fallback: "Stake")
      /// Transfer
      public static let transfer = L10n.tr("Localizable", "transactionHistory_manifestClass_Transfer", fallback: "Transfer")
      /// Request Unstake
      public static let unstaking = L10n.tr("Localizable", "transactionHistory_manifestClass_Unstaking", fallback: "Request Unstake")
    }
  }
  public enum TransactionReview {
    /// Approve
    public static let approveButtonTitle = L10n.tr("Localizable", "transactionReview_approveButtonTitle", fallback: "Approve")
    /// Claim from validators
    public static let claimFromValidatorsHeading = L10n.tr("Localizable", "transactionReview_claimFromValidatorsHeading", fallback: "Claim from validators")
    /// Customize Guarantees
    public static let customizeGuaranteesButtonTitle = L10n.tr("Localizable", "transactionReview_customizeGuaranteesButtonTitle", fallback: "Customize Guarantees")
    /// Depositing To
    public static let depositsHeading = L10n.tr("Localizable", "transactionReview_depositsHeading", fallback: "Depositing To")
    /// Estimated
    public static let estimated = L10n.tr("Localizable", "transactionReview_estimated", fallback: "Estimated")
    /// Account
    public static let externalAccountName = L10n.tr("Localizable", "transactionReview_externalAccountName", fallback: "Account")
    /// Fee Payer account required
    public static let feePayerRequiredMessage = L10n.tr("Localizable", "transactionReview_feePayerRequiredMessage", fallback: "Fee Payer account required")
    /// Guaranteed
    public static let guaranteed = L10n.tr("Localizable", "transactionReview_guaranteed", fallback: "Guaranteed")
    /// Insufficient Balance
    public static let insufficientBalance = L10n.tr("Localizable", "transactionReview_insufficientBalance", fallback: "Insufficient Balance")
    /// Message
    public static let messageHeading = L10n.tr("Localizable", "transactionReview_messageHeading", fallback: "Message")
    /// Contributing to pools
    public static let poolContributionHeading = L10n.tr("Localizable", "transactionReview_poolContributionHeading", fallback: "Contributing to pools")
    /// Unknown pool
    public static let poolNameUnknown = L10n.tr("Localizable", "transactionReview_poolNameUnknown", fallback: "Unknown pool")
    /// Redeeming from pools
    public static let poolRedemptionHeading = L10n.tr("Localizable", "transactionReview_poolRedemptionHeading", fallback: "Redeeming from pools")
    /// Pool Units
    public static let poolUnits = L10n.tr("Localizable", "transactionReview_poolUnits", fallback: "Pool Units")
    /// Presenting
    public static let presentingHeading = L10n.tr("Localizable", "transactionReview_presentingHeading", fallback: "Presenting")
    /// Proposed by %@
    public static func proposingDappSubtitle(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transactionReview_proposingDappSubtitle", String(describing: p1), fallback: "Proposed by %@")
    }
    /// Raw Transaction
    public static let rawTransactionTitle = L10n.tr("Localizable", "transactionReview_rawTransactionTitle", fallback: "Raw Transaction")
    /// Sending to
    public static let sendingToHeading = L10n.tr("Localizable", "transactionReview_sendingToHeading", fallback: "Sending to")
    /// Slide to Sign
    public static let slideToSign = L10n.tr("Localizable", "transactionReview_slideToSign", fallback: "Slide to Sign")
    /// Staking to Validators
    public static let stakingToValidatorsHeading = L10n.tr("Localizable", "transactionReview_stakingToValidatorsHeading", fallback: "Staking to Validators")
    /// Third-party deposit exceptions
    public static let thirdPartyDepositExceptionsHeading = L10n.tr("Localizable", "transactionReview_thirdPartyDepositExceptionsHeading", fallback: "Third-party deposit exceptions")
    /// Third-party deposit setting
    public static let thirdPartyDepositSettingHeading = L10n.tr("Localizable", "transactionReview_thirdPartyDepositSettingHeading", fallback: "Third-party deposit setting")
    /// Review Your Transaction
    public static let title = L10n.tr("Localizable", "transactionReview_title", fallback: "Review Your Transaction")
    /// To be claimed
    public static let toBeClaimed = L10n.tr("Localizable", "transactionReview_toBeClaimed", fallback: "To be claimed")
    /// Review Your Transfer
    public static let transferTitle = L10n.tr("Localizable", "transactionReview_transferTitle", fallback: "Review Your Transfer")
    /// Unknown
    public static let unknown = L10n.tr("Localizable", "transactionReview_unknown", fallback: "Unknown")
    /// %d Unknown Components
    public static func unknownComponents(_ p1: Int) -> String {
      return L10n.tr("Localizable", "transactionReview_unknownComponents", p1, fallback: "%d Unknown Components")
    }
    /// %d Pool Components
    public static func unknownPools(_ p1: Int) -> String {
      return L10n.tr("Localizable", "transactionReview_unknownPools", p1, fallback: "%d Pool Components")
    }
    /// Unnamed dApp
    public static let unnamedDapp = L10n.tr("Localizable", "transactionReview_unnamedDapp", fallback: "Unnamed dApp")
    /// Requesting unstake from validators
    public static let unstakingFromValidatorsHeading = L10n.tr("Localizable", "transactionReview_unstakingFromValidatorsHeading", fallback: "Requesting unstake from validators")
    /// Using dApps
    public static let usingDappsHeading = L10n.tr("Localizable", "transactionReview_usingDappsHeading", fallback: "Using dApps")
    /// Withdrawing From
    public static let withdrawalsHeading = L10n.tr("Localizable", "transactionReview_withdrawalsHeading", fallback: "Withdrawing From")
    /// Worth
    public static let worth = L10n.tr("Localizable", "transactionReview_worth", fallback: "Worth")
    /// %@ XRD
    public static func xrdAmount(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transactionReview_xrdAmount", String(describing: p1), fallback: "%@ XRD")
    }
    public enum AccountDepositSettings {
      /// Allow third parties to deposit **any asset** to this account.
      public static let acceptAllRule = L10n.tr("Localizable", "transactionReview_accountDepositSettings_acceptAllRule", fallback: "Allow third parties to deposit **any asset** to this account.")
      /// Allow third parties to deposit **only assets this account has already held**.
      public static let acceptKnownRule = L10n.tr("Localizable", "transactionReview_accountDepositSettings_acceptKnownRule", fallback: "Allow third parties to deposit **only assets this account has already held**.")
      /// Allow
      public static let assetChangeAllow = L10n.tr("Localizable", "transactionReview_accountDepositSettings_assetChangeAllow", fallback: "Allow")
      /// Remove Exception
      public static let assetChangeClear = L10n.tr("Localizable", "transactionReview_accountDepositSettings_assetChangeClear", fallback: "Remove Exception")
      /// Disallow
      public static let assetChangeDisallow = L10n.tr("Localizable", "transactionReview_accountDepositSettings_assetChangeDisallow", fallback: "Disallow")
      /// **Disallow** all deposits from third parties without your consent.
      public static let denyAllRule = L10n.tr("Localizable", "transactionReview_accountDepositSettings_denyAllRule", fallback: "**Disallow** all deposits from third parties without your consent.")
      /// Add Depositor
      public static let depositorChangeAdd = L10n.tr("Localizable", "transactionReview_accountDepositSettings_depositorChangeAdd", fallback: "Add Depositor")
      /// Remove Depositor
      public static let depositorChangeRemove = L10n.tr("Localizable", "transactionReview_accountDepositSettings_depositorChangeRemove", fallback: "Remove Depositor")
      /// Third-party deposit setting
      public static let subtitle = L10n.tr("Localizable", "transactionReview_accountDepositSettings_subtitle", fallback: "Third-party deposit setting")
      /// Review New Deposit Settings
      public static let title = L10n.tr("Localizable", "transactionReview_accountDepositSettings_title", fallback: "Review New Deposit Settings")
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
    public enum NoMnemonicError {
      /// The required seed phrase is missing. Please return to the account and begin the recovery process.
      public static let text = L10n.tr("Localizable", "transactionReview_noMnemonicError_text", fallback: "The required seed phrase is missing. Please return to the account and begin the recovery process.")
      /// Could Not Complete
      public static let title = L10n.tr("Localizable", "transactionReview_noMnemonicError_title", fallback: "Could Not Complete")
    }
    public enum NonConformingManifestWarning {
      /// This is a complex transaction that cannot be summarized - the raw transaction manifest will be shown. Do not submit unless you understand the contents.
      public static let message = L10n.tr("Localizable", "transactionReview_nonConformingManifestWarning_message", fallback: "This is a complex transaction that cannot be summarized - the raw transaction manifest will be shown. Do not submit unless you understand the contents.")
      /// Warning
      public static let title = L10n.tr("Localizable", "transactionReview_nonConformingManifestWarning_title", fallback: "Warning")
    }
    public enum PrepareForSigning {
      /// Preparing transaction for signing
      public static let body = L10n.tr("Localizable", "transactionReview_prepareForSigning_body", fallback: "Preparing transaction for signing")
      /// Preparing Transaction
      public static let navigationTitle = L10n.tr("Localizable", "transactionReview_prepareForSigning_navigationTitle", fallback: "Preparing Transaction")
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
    public enum UnacceptableManifest {
      /// A proposed transaction was rejected because it contains one or more reserved instructions.
      public static let rejected = L10n.tr("Localizable", "transactionReview_unacceptableManifest_rejected", fallback: "A proposed transaction was rejected because it contains one or more reserved instructions.")
    }
  }
  public enum TransactionSigning {
    /// Incoming Transaction
    public static let preparingTransaction = L10n.tr("Localizable", "transactionSigning_preparingTransaction", fallback: "Incoming Transaction")
    /// Submitting transaction…
    public static let signingAndSubmittingTransaction = L10n.tr("Localizable", "transactionSigning_signingAndSubmittingTransaction", fallback: "Submitting transaction…")
    /// Approve Transaction
    public static let signTransactionButtonTitle = L10n.tr("Localizable", "transactionSigning_signTransactionButtonTitle", fallback: "Approve Transaction")
    /// Approve Transaction
    public static let title = L10n.tr("Localizable", "transactionSigning_title", fallback: "Approve Transaction")
  }
  public enum TransactionStatus {
    public enum AssertionFailure {
      /// A guarantee on transaction results was not met. Consider reducing your preferred guarantee %%
      public static let text = L10n.tr("Localizable", "transactionStatus_assertionFailure_text", fallback: "A guarantee on transaction results was not met. Consider reducing your preferred guarantee %%")
    }
    public enum Completing {
      /// Completing Transaction…
      public static let text = L10n.tr("Localizable", "transactionStatus_completing_text", fallback: "Completing Transaction…")
    }
    public enum DismissDialog {
      /// Stop waiting for transaction result? The transaction will not be canceled.
      public static let message = L10n.tr("Localizable", "transactionStatus_dismissDialog_message", fallback: "Stop waiting for transaction result? The transaction will not be canceled.")
    }
    public enum DismissalDisabledDialog {
      /// This transaction requires to be completed
      public static let text = L10n.tr("Localizable", "transactionStatus_dismissalDisabledDialog_text", fallback: "This transaction requires to be completed")
      /// Dismiss
      public static let title = L10n.tr("Localizable", "transactionStatus_dismissalDisabledDialog_title", fallback: "Dismiss")
    }
    public enum Error {
      /// This transaction was rejected and is unlikely to be processed, but could potentially be processed within the next %@ minutes. It is likely that the dApp you are using proposed a transaction that includes an action that is not currently valid.
      public static func text(_ p1: Any) -> String {
        return L10n.tr("Localizable", "transactionStatus_error_text", String(describing: p1), fallback: "This transaction was rejected and is unlikely to be processed, but could potentially be processed within the next %@ minutes. It is likely that the dApp you are using proposed a transaction that includes an action that is not currently valid.")
      }
      /// Transaction Error
      public static let title = L10n.tr("Localizable", "transactionStatus_error_title", fallback: "Transaction Error")
    }
    public enum Failed {
      /// Your transaction was processed, but had a problem that caused it to fail permanently
      public static let text = L10n.tr("Localizable", "transactionStatus_failed_text", fallback: "Your transaction was processed, but had a problem that caused it to fail permanently")
      /// Transaction Failed
      public static let title = L10n.tr("Localizable", "transactionStatus_failed_title", fallback: "Transaction Failed")
    }
    public enum Failure {
      /// Transaction was rejected as invalid by the Radix Network.
      public static let text = L10n.tr("Localizable", "transactionStatus_failure_text", fallback: "Transaction was rejected as invalid by the Radix Network.")
      /// Something Went Wrong
      public static let title = L10n.tr("Localizable", "transactionStatus_failure_title", fallback: "Something Went Wrong")
    }
    public enum Rejected {
      /// Your transaction was improperly constructed and cannot be processed
      public static let text = L10n.tr("Localizable", "transactionStatus_rejected_text", fallback: "Your transaction was improperly constructed and cannot be processed")
      /// Transaction Rejected
      public static let title = L10n.tr("Localizable", "transactionStatus_rejected_title", fallback: "Transaction Rejected")
    }
    public enum Success {
      /// Your transaction was successful
      public static let text = L10n.tr("Localizable", "transactionStatus_success_text", fallback: "Your transaction was successful")
      /// Transaction Success
      public static let title = L10n.tr("Localizable", "transactionStatus_success_title", fallback: "Transaction Success")
    }
    public enum TransactionID {
      /// Transaction ID: 
      public static let text = L10n.tr("Localizable", "transactionStatus_transactionID_text", fallback: "Transaction ID: ")
    }
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
