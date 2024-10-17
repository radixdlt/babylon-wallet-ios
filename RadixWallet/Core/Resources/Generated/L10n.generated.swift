// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
enum L10n {
  enum Account {
    /// Badges
    static let badges = L10n.tr("Localizable", "account_badges", fallback: "Badges")
    /// NFTs
    static let nfts = L10n.tr("Localizable", "account_nfts", fallback: "NFTs")
    /// Pool Units
    static let poolUnits = L10n.tr("Localizable", "account_poolUnits", fallback: "Pool Units")
    /// Staking
    static let staking = L10n.tr("Localizable", "account_staking", fallback: "Staking")
    /// Tokens
    static let tokens = L10n.tr("Localizable", "account_tokens", fallback: "Tokens")
    /// Transfer
    static let transfer = L10n.tr("Localizable", "account_transfer", fallback: "Transfer")
    enum Nfts {
      /// %d in this collection
      static func itemsCount(_ p1: Int) -> String {
        return L10n.tr("Localizable", "account_nfts_itemsCount", p1, fallback: "%d in this collection")
      }
    }
    enum PoolUnits {
      /// Missing Total supply - could not calculate redemption value
      static let noTotalSupply = L10n.tr("Localizable", "account_poolUnits_noTotalSupply", fallback: "Missing Total supply - could not calculate redemption value")
      /// Unknown
      static let unknownPoolUnitName = L10n.tr("Localizable", "account_poolUnits_unknownPoolUnitName", fallback: "Unknown")
      /// Unknown
      static let unknownSymbolName = L10n.tr("Localizable", "account_poolUnits_unknownSymbolName", fallback: "Unknown")
      /// Unknown
      static let unknownValidatorName = L10n.tr("Localizable", "account_poolUnits_unknownValidatorName", fallback: "Unknown")
      enum Details {
        /// Current Redeemable Value
        static let currentRedeemableValue = L10n.tr("Localizable", "account_poolUnits_details_currentRedeemableValue", fallback: "Current Redeemable Value")
      }
    }
    enum Staking {
      /// Claim
      static let claim = L10n.tr("Localizable", "account_staking_claim", fallback: "Claim")
      /// Current Stake: %@
      static func currentStake(_ p1: Any) -> String {
        return L10n.tr("Localizable", "account_staking_currentStake", String(describing: p1), fallback: "Current Stake: %@")
      }
      /// Liquid Stake Units
      static let liquidStakeUnits = L10n.tr("Localizable", "account_staking_liquidStakeUnits", fallback: "Liquid Stake Units")
      /// Radix Network XRD Stake Summary
      static let lsuResourceHeader = L10n.tr("Localizable", "account_staking_lsuResourceHeader", fallback: "Radix Network XRD Stake Summary")
      /// Ready to be claimed
      static let readyToBeClaimed = L10n.tr("Localizable", "account_staking_readyToBeClaimed", fallback: "Ready to be claimed")
      /// Ready to Claim
      static let readyToClaim = L10n.tr("Localizable", "account_staking_readyToClaim", fallback: "Ready to Claim")
      /// Stake Claim NFTs
      static let stakeClaimNFTs = L10n.tr("Localizable", "account_staking_stakeClaimNFTs", fallback: "Stake Claim NFTs")
      /// Staked
      static let staked = L10n.tr("Localizable", "account_staking_staked", fallback: "Staked")
      /// STAKED VALIDATORS (%d)
      static func stakedValidators(_ p1: Int) -> String {
        return L10n.tr("Localizable", "account_staking_stakedValidators", p1, fallback: "STAKED VALIDATORS (%d)")
      }
      /// Unstaking
      static let unstaking = L10n.tr("Localizable", "account_staking_unstaking", fallback: "Unstaking")
      /// WORTH
      static let worth = L10n.tr("Localizable", "account_staking_worth", fallback: "WORTH")
    }
  }
  enum AccountRecoveryScan {
    /// Use Ledger Hardware Wallet
    static let ledgerButtonTitle = L10n.tr("Localizable", "accountRecoveryScan_ledgerButtonTitle", fallback: "Use Ledger Hardware Wallet")
    /// Note: You must still use the new *Radix Babylon* app on your Ledger device, not the old Radix Ledger app.
    static let olympiaLedgerNote = L10n.tr("Localizable", "accountRecoveryScan_olympiaLedgerNote", fallback: "Note: You must still use the new *Radix Babylon* app on your Ledger device, not the old Radix Ledger app.")
    /// Use Seed Phrase
    static let seedPhraseButtonTitle = L10n.tr("Localizable", "accountRecoveryScan_seedPhraseButtonTitle", fallback: "Use Seed Phrase")
    /// The Radix Wallet can scan for previously used accounts using a bare seed phrase or Ledger hardware wallet device
    static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_subtitle", fallback: "The Radix Wallet can scan for previously used accounts using a bare seed phrase or Ledger hardware wallet device")
    /// Account Recovery Scan
    static let title = L10n.tr("Localizable", "accountRecoveryScan_title", fallback: "Account Recovery Scan")
    enum BabylonSection {
      /// Scan for Accounts originally created on the **Babylon** network.
      static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_babylonSection_subtitle", fallback: "Scan for Accounts originally created on the **Babylon** network.")
      /// Babylon Accounts
      static let title = L10n.tr("Localizable", "accountRecoveryScan_babylonSection_title", fallback: "Babylon Accounts")
    }
    enum ChooseSeedPhrase {
      /// Add Babylon Seed Phrase
      static let addButtonBabylon = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_addButtonBabylon", fallback: "Add Babylon Seed Phrase")
      /// Add Olympia Seed Phrase
      static let addButtonOlympia = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_addButtonOlympia", fallback: "Add Olympia Seed Phrase")
      /// Continue
      static let continueButton = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_continueButton", fallback: "Continue")
      /// Enter Seed Phrase
      static let importMnemonicTitleBabylon = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_importMnemonicTitleBabylon", fallback: "Enter Seed Phrase")
      /// Enter Legacy Seed Phrase
      static let importMnemonicTitleOlympia = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_importMnemonicTitleOlympia", fallback: "Enter Legacy Seed Phrase")
      /// Choose the Babylon seed phrase for use for derivation:
      static let subtitleBabylon = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_subtitleBabylon", fallback: "Choose the Babylon seed phrase for use for derivation:")
      /// Choose the "Legacy" Olympia seed phrase for use for derivation:
      static let subtitleOlympia = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_subtitleOlympia", fallback: "Choose the \"Legacy\" Olympia seed phrase for use for derivation:")
      /// Choose Seed Phrase
      static let title = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_title", fallback: "Choose Seed Phrase")
    }
    enum InProgress {
      /// **Babylon Seed Phrase**
      static let factorSourceBabylonSeedPhrase = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceBabylonSeedPhrase", fallback: "**Babylon Seed Phrase**")
      /// Signing Factor
      static let factorSourceFallback = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceFallback", fallback: "Signing Factor")
      /// **Ledger hardware wallet device**
      static let factorSourceLedgerHardwareDevice = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceLedgerHardwareDevice", fallback: "**Ledger hardware wallet device**")
      /// **Olympia Seed Phrase**
      static let factorSourceOlympiaSeedPhrase = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceOlympiaSeedPhrase", fallback: "**Olympia Seed Phrase**")
      /// Scanning for Accounts that have been included in at least one transaction, using:
      static let headerSubtitle = L10n.tr("Localizable", "accountRecoveryScan_inProgress_headerSubtitle", fallback: "Scanning for Accounts that have been included in at least one transaction, using:")
      /// Scanning in progress
      static let headerTitle = L10n.tr("Localizable", "accountRecoveryScan_inProgress_headerTitle", fallback: "Scanning in progress")
      /// Unnamed
      static let nameOfRecoveredAccount = L10n.tr("Localizable", "accountRecoveryScan_inProgress_nameOfRecoveredAccount", fallback: "Unnamed")
      /// Scanning network
      static let scanningNetwork = L10n.tr("Localizable", "accountRecoveryScan_inProgress_scanningNetwork", fallback: "Scanning network")
    }
    enum OlympiaSection {
      /// Note: You will still use the new **Radix Babylon** app on your Ledger device, not the old Radix Ledger app.
      static let footnote = L10n.tr("Localizable", "accountRecoveryScan_olympiaSection_footnote", fallback: "Note: You will still use the new **Radix Babylon** app on your Ledger device, not the old Radix Ledger app.")
      /// Scan for Accounts originally created on the **Olympia** network.
      /// 
      /// (If you have Olympia Accounts in the Radix Olympia Desktop Wallet, consider using **Import from a Legacy Wallet** instead.
      static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_olympiaSection_subtitle", fallback: "Scan for Accounts originally created on the **Olympia** network.\n\n(If you have Olympia Accounts in the Radix Olympia Desktop Wallet, consider using **Import from a Legacy Wallet** instead.")
      /// Olympia Accounts
      static let title = L10n.tr("Localizable", "accountRecoveryScan_olympiaSection_title", fallback: "Olympia Accounts")
    }
    enum ScanComplete {
      /// Continue
      static let continueButton = L10n.tr("Localizable", "accountRecoveryScan_scanComplete_continueButton", fallback: "Continue")
      /// The first **%d** potential Accounts from this signing factor were scanned. The following Accounts had at least one transaction:
      static func headerSubtitle(_ p1: Int) -> String {
        return L10n.tr("Localizable", "accountRecoveryScan_scanComplete_headerSubtitle", p1, fallback: "The first **%d** potential Accounts from this signing factor were scanned. The following Accounts had at least one transaction:")
      }
      /// Scan Complete
      static let headerTitle = L10n.tr("Localizable", "accountRecoveryScan_scanComplete_headerTitle", fallback: "Scan Complete")
      /// No new accounts found
      static let noAccounts = L10n.tr("Localizable", "accountRecoveryScan_scanComplete_noAccounts", fallback: "No new accounts found")
      /// Tap here to scan the next %d
      static func scanNextBatchButton(_ p1: Int) -> String {
        return L10n.tr("Localizable", "accountRecoveryScan_scanComplete_scanNextBatchButton", p1, fallback: "Tap here to scan the next %d")
      }
    }
    enum SelectInactiveAccounts {
      /// Continue
      static let continueButton = L10n.tr("Localizable", "accountRecoveryScan_selectInactiveAccounts_continueButton", fallback: "Continue")
      enum Header {
        /// These Accounts were never used, but you **may** have created them. Select any addresses that you wish to keep:
        static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_selectInactiveAccounts_header_subtitle", fallback: "These Accounts were never used, but you **may** have created them. Select any addresses that you wish to keep:")
        /// Add Inactive Accounts?
        static let title = L10n.tr("Localizable", "accountRecoveryScan_selectInactiveAccounts_header_title", fallback: "Add Inactive Accounts?")
      }
    }
  }
  enum AccountSecuritySettings {
    enum AccountRecoveryScan {
      /// Using seed phrase or Ledger device
      static let subtitle = L10n.tr("Localizable", "accountSecuritySettings_accountRecoveryScan_subtitle", fallback: "Using seed phrase or Ledger device")
      /// Account Recovery Scan
      static let title = L10n.tr("Localizable", "accountSecuritySettings_accountRecoveryScan_title", fallback: "Account Recovery Scan")
    }
    enum Backups {
      /// Backups
      static let title = L10n.tr("Localizable", "accountSecuritySettings_backups_title", fallback: "Backups")
    }
    enum DepositGuarantees {
      /// Set your default guaranteed minimum for estimated deposits
      static let subtitle = L10n.tr("Localizable", "accountSecuritySettings_depositGuarantees_subtitle", fallback: "Set your default guaranteed minimum for estimated deposits")
      /// Set the guaranteed minimum deposit to be applied whenever a deposit in a transaction can only be estimated.
      /// 
      /// You can always change the guarantee from this default in each transaction.
      static let text = L10n.tr("Localizable", "accountSecuritySettings_depositGuarantees_text", fallback: "Set the guaranteed minimum deposit to be applied whenever a deposit in a transaction can only be estimated.\n\nYou can always change the guarantee from this default in each transaction.")
      /// Default Deposit Guarantees
      static let title = L10n.tr("Localizable", "accountSecuritySettings_depositGuarantees_title", fallback: "Default Deposit Guarantees")
    }
    enum ImportFromLegacyWallet {
      /// Import from a Legacy Wallet
      static let title = L10n.tr("Localizable", "accountSecuritySettings_importFromLegacyWallet_title", fallback: "Import from a Legacy Wallet")
    }
    enum LedgerHardwareWallets {
      /// Ledger Hardware Wallets
      static let title = L10n.tr("Localizable", "accountSecuritySettings_ledgerHardwareWallets_title", fallback: "Ledger Hardware Wallets")
    }
    enum SeedPhrases {
      /// Seed Phrases
      static let title = L10n.tr("Localizable", "accountSecuritySettings_seedPhrases_title", fallback: "Seed Phrases")
    }
  }
  enum AccountSettings {
    /// Account Color
    static let accountColor = L10n.tr("Localizable", "accountSettings_accountColor", fallback: "Account Color")
    /// Select from a list of unique colors
    static let accountColorSubtitle = L10n.tr("Localizable", "accountSettings_accountColorSubtitle", fallback: "Select from a list of unique colors")
    /// Account Hidden
    static let accountHidden = L10n.tr("Localizable", "accountSettings_accountHidden", fallback: "Account Hidden")
    /// Account Name
    static let accountLabel = L10n.tr("Localizable", "accountSettings_accountLabel", fallback: "Account Name")
    /// Name your account
    static let accountLabelSubtitle = L10n.tr("Localizable", "accountSettings_accountLabelSubtitle", fallback: "Name your account")
    /// Set development preferences
    static let developmentHeading = L10n.tr("Localizable", "accountSettings_developmentHeading", fallback: "Set development preferences")
    /// Dev Preferences
    static let devPreferences = L10n.tr("Localizable", "accountSettings_devPreferences", fallback: "Dev Preferences")
    /// Get XRD Test Tokens
    static let getXrdTestTokens = L10n.tr("Localizable", "accountSettings_getXrdTestTokens", fallback: "Get XRD Test Tokens")
    /// Hide Account
    static let hideAccount = L10n.tr("Localizable", "accountSettings_hideAccount", fallback: "Hide Account")
    /// Are you sure you want to hide this account?
    static let hideAccountConfirmation = L10n.tr("Localizable", "accountSettings_hideAccountConfirmation", fallback: "Are you sure you want to hide this account?")
    /// Hide This Account
    static let hideThisAccount = L10n.tr("Localizable", "accountSettings_hideThisAccount", fallback: "Hide This Account")
    /// This may take several seconds, please wait for completion
    static let loadingPrompt = L10n.tr("Localizable", "accountSettings_loadingPrompt", fallback: "This may take several seconds, please wait for completion")
    /// Personalize this Account
    static let personalizeHeading = L10n.tr("Localizable", "accountSettings_personalizeHeading", fallback: "Personalize this Account")
    /// Set how you want this Account to work
    static let setBehaviorHeading = L10n.tr("Localizable", "accountSettings_setBehaviorHeading", fallback: "Set how you want this Account to work")
    /// Show Assets with Tags
    static let showAssets = L10n.tr("Localizable", "accountSettings_showAssets", fallback: "Show Assets with Tags")
    /// Select which tags to show for assets in this Account
    static let showAssetsSubtitle = L10n.tr("Localizable", "accountSettings_showAssetsSubtitle", fallback: "Select which tags to show for assets in this Account")
    /// Show Account QR Code
    static let showQR = L10n.tr("Localizable", "accountSettings_showQR", fallback: "Show Account QR Code")
    /// Allow/Deny Specific Assets
    static let specificAssetsDeposits = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits", fallback: "Allow/Deny Specific Assets")
    /// Third-party Deposits
    static let thirdPartyDeposits = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits", fallback: "Third-party Deposits")
    /// Choose who can deposit into your Account
    static let thirdPartyDepositsSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDepositsSubtitle", fallback: "Choose who can deposit into your Account")
    /// Account Settings
    static let title = L10n.tr("Localizable", "accountSettings_title", fallback: "Account Settings")
    /// Updated
    static let updatedAccountHUDMessage = L10n.tr("Localizable", "accountSettings_updatedAccountHUDMessage", fallback: "Updated")
    enum AccountColor {
      /// Selected
      static let selected = L10n.tr("Localizable", "accountSettings_accountColor_selected", fallback: "Selected")
      /// Select the color for this Account
      static let text = L10n.tr("Localizable", "accountSettings_accountColor_text", fallback: "Select the color for this Account")
    }
    enum HideAccount {
      /// Hide Account
      static let button = L10n.tr("Localizable", "accountSettings_hideAccount_button", fallback: "Hide Account")
      /// Hide this Account in your wallet? You can always unhide it from the main application settings.
      static let message = L10n.tr("Localizable", "accountSettings_hideAccount_message", fallback: "Hide this Account in your wallet? You can always unhide it from the main application settings.")
      /// Hide This Account
      static let title = L10n.tr("Localizable", "accountSettings_hideAccount_title", fallback: "Hide This Account")
    }
    enum RenameAccount {
      /// Update
      static let button = L10n.tr("Localizable", "accountSettings_renameAccount_button", fallback: "Update")
      /// Enter a new label for this Account
      static let subtitle = L10n.tr("Localizable", "accountSettings_renameAccount_subtitle", fallback: "Enter a new label for this Account")
      /// Rename Account
      static let title = L10n.tr("Localizable", "accountSettings_renameAccount_title", fallback: "Rename Account")
    }
    enum ShowAssets {
      /// Recommended
      static let recommended = L10n.tr("Localizable", "accountSettings_showAssets_recommended", fallback: "Recommended")
      /// Select the ones you’d like shown on all your assets.
      static let selectShown = L10n.tr("Localizable", "accountSettings_showAssets_selectShown", fallback: "Select the ones you’d like shown on all your assets.")
      /// Asset creators can add tags to them. You can choose which tags you want to see in this Account.
      static let text = L10n.tr("Localizable", "accountSettings_showAssets_text", fallback: "Asset creators can add tags to them. You can choose which tags you want to see in this Account.")
    }
    enum SpecificAssetsDeposits {
      /// Allow Deposits
      static let addAnAssetAllow = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetAllow", fallback: "Allow Deposits")
      /// Add Asset
      static let addAnAssetButton = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetButton", fallback: "Add Asset")
      /// Deny Deposits
      static let addAnAssetDeny = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetDeny", fallback: "Deny Deposits")
      /// Resource Address
      static let addAnAssetInputHint = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetInputHint", fallback: "Resource Address")
      /// Enter the asset’s resource address (starting with “reso”)
      static let addAnAssetSubtitle = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetSubtitle", fallback: "Enter the asset’s resource address (starting with “reso”)")
      /// Add an Asset
      static let addAnAssetTitle = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetTitle", fallback: "Add an Asset")
      /// Allow
      static let allow = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allow", fallback: "Allow")
      /// The holder of the following badges may always deposit accounts to this account.
      static let allowDepositors = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allowDepositors", fallback: "The holder of the following badges may always deposit accounts to this account.")
      /// Add a specific badge by its resource address to allow all deposits from its holder.
      static let allowDepositorsNoResources = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allowDepositorsNoResources", fallback: "Add a specific badge by its resource address to allow all deposits from its holder.")
      /// The following resource addresses may always be deposited to this account by third parties.
      static let allowInfo = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allowInfo", fallback: "The following resource addresses may always be deposited to this account by third parties.")
      /// Deny
      static let deny = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_deny", fallback: "Deny")
      /// The following resource addresses may never be deposited to this account by third parties.
      static let denyInfo = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_denyInfo", fallback: "The following resource addresses may never be deposited to this account by third parties.")
      /// Add a specific asset by its resource address to allow all third-party deposits
      static let emptyAllowAll = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_emptyAllowAll", fallback: "Add a specific asset by its resource address to allow all third-party deposits")
      /// Add a specific asset by its resource address to deny all third-party deposits
      static let emptyDenyAll = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_emptyDenyAll", fallback: "Add a specific asset by its resource address to deny all third-party deposits")
      /// Sorry, this Account's third-party exceptions and depositor lists are in an unknown state and cannot be viewed or edited because it was imported using only a seed phrase or Ledger. A forthcoming wallet update will enable viewing and editing of these lists.
      static let modificationDisabledForRecoveredAccount = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_modificationDisabledForRecoveredAccount", fallback: "Sorry, this Account's third-party exceptions and depositor lists are in an unknown state and cannot be viewed or edited because it was imported using only a seed phrase or Ledger. A forthcoming wallet update will enable viewing and editing of these lists.")
      /// Remove Asset
      static let removeAsset = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeAsset", fallback: "Remove Asset")
      /// The asset will be removed from the allow list
      static let removeAssetMessageAllow = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeAssetMessageAllow", fallback: "The asset will be removed from the allow list")
      /// The asset will be removed from the deny list
      static let removeAssetMessageDeny = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeAssetMessageDeny", fallback: "The asset will be removed from the deny list")
      /// The badge will be removed from the list
      static let removeBadgeMessageDepositors = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeBadgeMessageDepositors", fallback: "The badge will be removed from the list")
      /// Remove Depositor
      static let removeDepositor = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeDepositor", fallback: "Remove Depositor")
      /// The depositor will be removed from the allow list
      static let removeDepositorMessage = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeDepositorMessage", fallback: "The depositor will be removed from the allow list")
      /// Select exception list
      static let resourceListPicker = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_resourceListPicker", fallback: "Select exception list")
      /// Update
      static let update = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_update", fallback: "Update")
    }
    enum ThirdPartyDeposits {
      /// Accept all deposits
      static let acceptAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAll", fallback: "Accept all deposits")
      /// Allow third-parties to deposit any asset
      static let acceptAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAllSubtitle", fallback: "Allow third-parties to deposit any asset")
      /// Enter the badge’s resource address (starting with “reso”)
      static let addDepositorSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_addDepositorSubtitle", fallback: "Enter the badge’s resource address (starting with “reso”)")
      /// Add a Depositor Badge
      static let addDepositorTitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_addDepositorTitle", fallback: "Add a Depositor Badge")
      /// Allow/Deny specific assets
      static let allowDenySpecific = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowDenySpecific", fallback: "Allow/Deny specific assets")
      /// Deny or allow third-party deposits of specific assets, ignoring the setting above
      static let allowDenySpecificSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowDenySpecificSubtitle", fallback: "Deny or allow third-party deposits of specific assets, ignoring the setting above")
      /// Allow specific depositors
      static let allowSpecificDepositors = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowSpecificDepositors", fallback: "Allow specific depositors")
      /// Add Depositor Badge
      static let allowSpecificDepositorsButton = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowSpecificDepositorsButton", fallback: "Add Depositor Badge")
      /// Allow certain third party depositors to deposit assets freely
      static let allowSpecificDepositorsSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowSpecificDepositorsSubtitle", fallback: "Allow certain third party depositors to deposit assets freely")
      /// Deny all
      static let denyAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAll", fallback: "Deny all")
      /// Deny all third-party deposits
      static let denyAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAllSubtitle", fallback: "Deny all third-party deposits")
      /// This account will not be able to receive "air drops" or be used by a trusted contact to assist with account recovery.
      static let denyAllWarning = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAllWarning", fallback: "This account will not be able to receive \"air drops\" or be used by a trusted contact to assist with account recovery.")
      /// Discard Changes
      static let discardChanges = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_discardChanges", fallback: "Discard Changes")
      /// Are you sure you want to discard changes?
      static let discardMessage = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_discardMessage", fallback: "Are you sure you want to discard changes?")
      /// Keep Editing
      static let keepEditing = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_keepEditing", fallback: "Keep Editing")
      /// Only accept known
      static let onlyKnown = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_onlyKnown", fallback: "Only accept known")
      /// Allow third-parties to deposit only assets this Account already holds
      static let onlyKnownSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_onlyKnownSubtitle", fallback: "Allow third-parties to deposit only assets this Account already holds")
      /// Choose if you want to allow third parties to directly deposit assets into your Account. Deposits that you approve yourself in your Radix Wallet are always accepted.
      static let text = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_text", fallback: "Choose if you want to allow third parties to directly deposit assets into your Account. Deposits that you approve yourself in your Radix Wallet are always accepted.")
    }
  }
  enum AddLedgerDevice {
    enum AddDevice {
      /// Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.
      static let body1 = L10n.tr("Localizable", "addLedgerDevice_addDevice_body1", fallback: "Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.")
      /// Connect your Ledger to a computer running a linked Radix Connector browser extension, and make sure the Radix Babylon app is running on the Ledger device.
      static let body2 = L10n.tr("Localizable", "addLedgerDevice_addDevice_body2", fallback: "Connect your Ledger to a computer running a linked Radix Connector browser extension, and make sure the Radix Babylon app is running on the Ledger device.")
      /// Continue
      static let `continue` = L10n.tr("Localizable", "addLedgerDevice_addDevice_continue", fallback: "Continue")
      /// Add Ledger Device
      static let title = L10n.tr("Localizable", "addLedgerDevice_addDevice_title", fallback: "Add Ledger Device")
    }
    enum AlreadyAddedAlert {
      /// You have already added this Ledger as: %@
      static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "addLedgerDevice_alreadyAddedAlert_message", String(describing: p1), fallback: "You have already added this Ledger as: %@")
      }
      /// Ledger Already Added
      static let title = L10n.tr("Localizable", "addLedgerDevice_alreadyAddedAlert_title", fallback: "Ledger Already Added")
    }
    enum NameLedger {
      /// Save and Continue
      static let continueButtonTitle = L10n.tr("Localizable", "addLedgerDevice_nameLedger_continueButtonTitle", fallback: "Save and Continue")
      /// Detected type: %@
      static func detectedType(_ p1: Any) -> String {
        return L10n.tr("Localizable", "addLedgerDevice_nameLedger_detectedType", String(describing: p1), fallback: "Detected type: %@")
      }
      /// This will be displayed when you’re prompted to sign with this Ledger device.
      static let fieldHint = L10n.tr("Localizable", "addLedgerDevice_nameLedger_fieldHint", fallback: "This will be displayed when you’re prompted to sign with this Ledger device.")
      /// Green Ledger Nano S+
      static let namePlaceholder = L10n.tr("Localizable", "addLedgerDevice_nameLedger_namePlaceholder", fallback: "Green Ledger Nano S+")
      /// What would you like to call this Ledger device?
      static let subtitle = L10n.tr("Localizable", "addLedgerDevice_nameLedger_subtitle", fallback: "What would you like to call this Ledger device?")
      /// Name Your Ledger
      static let title = L10n.tr("Localizable", "addLedgerDevice_nameLedger_title", fallback: "Name Your Ledger")
    }
  }
  enum AddressAction {
    /// Copied to Clipboard
    static let copiedToClipboard = L10n.tr("Localizable", "addressAction_copiedToClipboard", fallback: "Copied to Clipboard")
    /// Copy Address
    static let copyAddress = L10n.tr("Localizable", "addressAction_copyAddress", fallback: "Copy Address")
    /// Copy NFT ID
    static let copyNftId = L10n.tr("Localizable", "addressAction_copyNftId", fallback: "Copy NFT ID")
    /// Copy Transaction ID
    static let copyTransactionId = L10n.tr("Localizable", "addressAction_copyTransactionId", fallback: "Copy Transaction ID")
    /// There is no web browser installed in this device
    static let noWebBrowserInstalled = L10n.tr("Localizable", "addressAction_noWebBrowserInstalled", fallback: "There is no web browser installed in this device")
    /// Show Address QR Code
    static let showAccountQR = L10n.tr("Localizable", "addressAction_showAccountQR", fallback: "Show Address QR Code")
    /// Verify Address with Ledger
    static let verifyAddressLedger = L10n.tr("Localizable", "addressAction_verifyAddressLedger", fallback: "Verify Address with Ledger")
    /// View on Radix Dashboard
    static let viewOnDashboard = L10n.tr("Localizable", "addressAction_viewOnDashboard", fallback: "View on Radix Dashboard")
    enum QrCodeView {
      /// Could not create QR code
      static let failureLabel = L10n.tr("Localizable", "addressAction_qrCodeView_failureLabel", fallback: "Could not create QR code")
      /// QR code for an account
      static let qrCodeLabel = L10n.tr("Localizable", "addressAction_qrCodeView_qrCodeLabel", fallback: "QR code for an account")
    }
    enum VerifyAddressLedger {
      /// Verify address request failed
      static let error = L10n.tr("Localizable", "addressAction_verifyAddressLedger_error", fallback: "Verify address request failed")
      /// Address verified
      static let success = L10n.tr("Localizable", "addressAction_verifyAddressLedger_success", fallback: "Address verified")
    }
  }
  enum AddressDetails {
    /// Copy
    static let copy = L10n.tr("Localizable", "addressDetails_copy", fallback: "Copy")
    /// Enlarge
    static let enlarge = L10n.tr("Localizable", "addressDetails_enlarge", fallback: "Enlarge")
    /// Full address
    static let fullAddress = L10n.tr("Localizable", "addressDetails_fullAddress", fallback: "Full address")
    /// Address QR Code
    static let qrCode = L10n.tr("Localizable", "addressDetails_qrCode", fallback: "Address QR Code")
    /// Could not create QR code
    static let qrCodeFailure = L10n.tr("Localizable", "addressDetails_qrCodeFailure", fallback: "Could not create QR code")
    /// Share
    static let share = L10n.tr("Localizable", "addressDetails_share", fallback: "Share")
    /// Verify Address on Ledger Device
    static let verifyOnLedger = L10n.tr("Localizable", "addressDetails_verifyOnLedger", fallback: "Verify Address on Ledger Device")
    /// View on Radix Dashboard
    static let viewOnDashboard = L10n.tr("Localizable", "addressDetails_viewOnDashboard", fallback: "View on Radix Dashboard")
  }
  enum AndroidProfileBackup {
    /// Back up is turned off
    static let disabledText = L10n.tr("Localizable", "androidProfileBackup_disabledText", fallback: "Back up is turned off")
    /// Last Backed up: %@
    static func lastBackedUp(_ p1: Any) -> String {
      return L10n.tr("Localizable", "androidProfileBackup_lastBackedUp", String(describing: p1), fallback: "Last Backed up: %@")
    }
    /// Not backed up yet
    static let noLastBackUp = L10n.tr("Localizable", "androidProfileBackup_noLastBackUp", fallback: "Not backed up yet")
    /// Open System Backup Settings
    static let openSystemBackupSettings = L10n.tr("Localizable", "androidProfileBackup_openSystemBackupSettings", fallback: "Open System Backup Settings")
    enum BackupWalletData {
      /// Warning: If disabled you might lose access to your Accounts and Personas.
      static let message = L10n.tr("Localizable", "androidProfileBackup_backupWalletData_message", fallback: "Warning: If disabled you might lose access to your Accounts and Personas.")
      /// Backup Wallet Data to Cloud
      static let title = L10n.tr("Localizable", "androidProfileBackup_backupWalletData_title", fallback: "Backup Wallet Data to Cloud")
    }
    enum DeleteWallet {
      /// Delete Wallet
      static let confirmButton = L10n.tr("Localizable", "androidProfileBackup_deleteWallet_confirmButton", fallback: "Delete Wallet")
      /// You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any cloud backup.
      /// 
      /// **Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**
      static let subtitle = L10n.tr("Localizable", "androidProfileBackup_deleteWallet_subtitle", fallback: "You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any cloud backup.\n\n**Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**")
    }
  }
  enum AndroidRecoverProfileBackup {
    /// No wallet backups available
    static let noBackupsAvailable = L10n.tr("Localizable", "androidRecoverProfileBackup_noBackupsAvailable", fallback: "No wallet backups available")
    enum Choose {
      /// Choose a backup from Google Drive
      static let title = L10n.tr("Localizable", "androidRecoverProfileBackup_choose_title", fallback: "Choose a backup from Google Drive")
    }
  }
  enum AppSettings {
    /// Customize your Radix Wallet
    static let subtitle = L10n.tr("Localizable", "appSettings_subtitle", fallback: "Customize your Radix Wallet")
    /// App Settings
    static let title = L10n.tr("Localizable", "appSettings_title", fallback: "App Settings")
    enum CrashReporting {
      /// I'm aware Radix Wallet will send crash reports together with device state from the moment of crash.
      static let subtitle = L10n.tr("Localizable", "appSettings_crashReporting_subtitle", fallback: "I'm aware Radix Wallet will send crash reports together with device state from the moment of crash.")
      /// Crash Reporting
      static let title = L10n.tr("Localizable", "appSettings_crashReporting_title", fallback: "Crash Reporting")
    }
    enum DeveloperMode {
      /// Warning: Disables website validity checks
      static let subtitle = L10n.tr("Localizable", "appSettings_developerMode_subtitle", fallback: "Warning: Disables website validity checks")
      /// Developer Mode
      static let title = L10n.tr("Localizable", "appSettings_developerMode_title", fallback: "Developer Mode")
    }
    enum EntityHiding {
      /// %d Account currently hidden
      static func hiddenAccount(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenAccount", p1, fallback: "%d Account currently hidden")
      }
      /// %d Accounts currently hidden
      static func hiddenAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenAccounts", p1, fallback: "%d Accounts currently hidden")
      }
      /// %d Persona currently hidden
      static func hiddenPersona(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenPersona", p1, fallback: "%d Persona currently hidden")
      }
      /// %d Personas currently hidden
      static func hiddenPersonas(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenPersonas", p1, fallback: "%d Personas currently hidden")
      }
      /// Manage hiding
      static let subtitle = L10n.tr("Localizable", "appSettings_entityHiding_subtitle", fallback: "Manage hiding")
      /// Accounts and Personas you have created can be hidden in your Radix Wallet, acting as if “deleted”.
      static let text = L10n.tr("Localizable", "appSettings_entityHiding_text", fallback: "Accounts and Personas you have created can be hidden in your Radix Wallet, acting as if “deleted”.")
      /// Account & Persona Hiding
      static let title = L10n.tr("Localizable", "appSettings_entityHiding_title", fallback: "Account & Persona Hiding")
      /// Unhide All
      static let unhideAllButton = L10n.tr("Localizable", "appSettings_entityHiding_unhideAllButton", fallback: "Unhide All")
      /// Are you sure you wish to unhide all Accounts and Personas? This cannot be undone.
      static let unhideAllConfirmation = L10n.tr("Localizable", "appSettings_entityHiding_unhideAllConfirmation", fallback: "Are you sure you wish to unhide all Accounts and Personas? This cannot be undone.")
      /// Unhide Accounts & Personas
      static let unhideAllSection = L10n.tr("Localizable", "appSettings_entityHiding_unhideAllSection", fallback: "Unhide Accounts & Personas")
    }
    enum Gateways {
      /// Network Gateways
      static let title = L10n.tr("Localizable", "appSettings_gateways_title", fallback: "Network Gateways")
    }
    enum LinkedConnectors {
      /// Linked Connectors
      static let title = L10n.tr("Localizable", "appSettings_linkedConnectors_title", fallback: "Linked Connectors")
    }
  }
  enum AssetDetails {
    /// Associated dApps
    static let associatedDapps = L10n.tr("Localizable", "assetDetails_associatedDapps", fallback: "Associated dApps")
    /// Behavior
    static let behavior = L10n.tr("Localizable", "assetDetails_behavior", fallback: "Behavior")
    /// Current Supply
    static let currentSupply = L10n.tr("Localizable", "assetDetails_currentSupply", fallback: "Current Supply")
    /// Divisibility
    static let divisibility = L10n.tr("Localizable", "assetDetails_divisibility", fallback: "Divisibility")
    /// Hide Asset
    static let hideAsset = L10n.tr("Localizable", "assetDetails_hideAsset", fallback: "Hide Asset")
    /// Hide Collection
    static let hideCollection = L10n.tr("Localizable", "assetDetails_hideCollection", fallback: "Hide Collection")
    /// For more info
    static let moreInfo = L10n.tr("Localizable", "assetDetails_moreInfo", fallback: "For more info")
    /// Name
    static let name = L10n.tr("Localizable", "assetDetails_name", fallback: "Name")
    /// Address
    static let resourceAddress = L10n.tr("Localizable", "assetDetails_resourceAddress", fallback: "Address")
    /// Unknown
    static let supplyUnkown = L10n.tr("Localizable", "assetDetails_supplyUnkown", fallback: "Unknown")
    /// Tags
    static let tags = L10n.tr("Localizable", "assetDetails_tags", fallback: "Tags")
    /// Validator
    static let validator = L10n.tr("Localizable", "assetDetails_validator", fallback: "Validator")
    enum NFTDetails {
      /// complex data
      static let complexData = L10n.tr("Localizable", "assetDetails_NFTDetails_complexData", fallback: "complex data")
      /// Description
      static let description = L10n.tr("Localizable", "assetDetails_NFTDetails_description", fallback: "Description")
      /// ID
      static let id = L10n.tr("Localizable", "assetDetails_NFTDetails_id", fallback: "ID")
      /// Name
      static let name = L10n.tr("Localizable", "assetDetails_NFTDetails_name", fallback: "Name")
      /// %d NFTs
      static func nftPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_NFTDetails_nftPlural", p1, fallback: "%d NFTs")
      }
      /// You have no NFTs
      static let noNfts = L10n.tr("Localizable", "assetDetails_NFTDetails_noNfts", fallback: "You have no NFTs")
      /// %d NFTs of total supply %d
      static func ownedOfTotal(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_NFTDetails_ownedOfTotal", p1, p2, fallback: "%d NFTs of total supply %d")
      }
      /// Name
      static let resourceName = L10n.tr("Localizable", "assetDetails_NFTDetails_resourceName", fallback: "Name")
    }
    enum BadgeDetails {
      /// You have no badges
      static let noBadges = L10n.tr("Localizable", "assetDetails_badgeDetails_noBadges", fallback: "You have no badges")
    }
    enum Behaviors {
      /// Anyone can freeze this asset in place.
      static let freezableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_freezableByAnyone", fallback: "Anyone can freeze this asset in place.")
      /// A third party can freeze this asset in place.
      static let freezableByThirdParty = L10n.tr("Localizable", "assetDetails_behaviors_freezableByThirdParty", fallback: "A third party can freeze this asset in place.")
      /// Naming and information about this asset can be changed.
      static let informationChangeable = L10n.tr("Localizable", "assetDetails_behaviors_informationChangeable", fallback: "Naming and information about this asset can be changed.")
      /// Anyone can change naming and information about this asset.
      static let informationChangeableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_informationChangeableByAnyone", fallback: "Anyone can change naming and information about this asset.")
      /// Movement of this asset can be restricted in the future.
      static let movementRestrictableInFuture = L10n.tr("Localizable", "assetDetails_behaviors_movementRestrictableInFuture", fallback: "Movement of this asset can be restricted in the future.")
      /// Anyone can restrict movement of this token in the future.
      static let movementRestrictableInFutureByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_movementRestrictableInFutureByAnyone", fallback: "Anyone can restrict movement of this token in the future.")
      /// Movement of this asset is restricted.
      static let movementRestricted = L10n.tr("Localizable", "assetDetails_behaviors_movementRestricted", fallback: "Movement of this asset is restricted.")
      /// Data that is set on these NFTs can be changed.
      static let nftDataChangeable = L10n.tr("Localizable", "assetDetails_behaviors_nftDataChangeable", fallback: "Data that is set on these NFTs can be changed.")
      /// Anyone can change data that is set on these NFTs.
      static let nftDataChangeableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_nftDataChangeableByAnyone", fallback: "Anyone can change data that is set on these NFTs.")
      /// Anyone can remove this asset from accounts and dApps.
      static let removableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_removableByAnyone", fallback: "Anyone can remove this asset from accounts and dApps.")
      /// A third party can remove this asset from accounts and dApps.
      static let removableByThirdParty = L10n.tr("Localizable", "assetDetails_behaviors_removableByThirdParty", fallback: "A third party can remove this asset from accounts and dApps.")
      /// This is a simple asset
      static let simpleAsset = L10n.tr("Localizable", "assetDetails_behaviors_simpleAsset", fallback: "This is a simple asset")
      /// The supply of this asset can be decreased.
      static let supplyDecreasable = L10n.tr("Localizable", "assetDetails_behaviors_supplyDecreasable", fallback: "The supply of this asset can be decreased.")
      /// Anyone can decrease the supply of this asset.
      static let supplyDecreasableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_supplyDecreasableByAnyone", fallback: "Anyone can decrease the supply of this asset.")
      /// The supply of this asset can be increased or decreased.
      static let supplyFlexible = L10n.tr("Localizable", "assetDetails_behaviors_supplyFlexible", fallback: "The supply of this asset can be increased or decreased.")
      /// Anyone can increase or decrease the supply of this asset.
      static let supplyFlexibleByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_supplyFlexibleByAnyone", fallback: "Anyone can increase or decrease the supply of this asset.")
      /// Only the Radix Network may increase or decrease the supply of XRD.
      static let supplyFlexibleXrd = L10n.tr("Localizable", "assetDetails_behaviors_supplyFlexibleXrd", fallback: "Only the Radix Network may increase or decrease the supply of XRD.")
      /// The supply of this asset can be increased.
      static let supplyIncreasable = L10n.tr("Localizable", "assetDetails_behaviors_supplyIncreasable", fallback: "The supply of this asset can be increased.")
      /// Anyone can increase the supply of this asset.
      static let supplyIncreasableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_supplyIncreasableByAnyone", fallback: "Anyone can increase the supply of this asset.")
    }
    enum PoolUnitDetails {
      /// You have no Pool units
      static let noPoolUnits = L10n.tr("Localizable", "assetDetails_poolUnitDetails_noPoolUnits", fallback: "You have no Pool units")
    }
    enum Staking {
      /// Current Redeemable Value
      static let currentRedeemableValue = L10n.tr("Localizable", "assetDetails_staking_currentRedeemableValue", fallback: "Current Redeemable Value")
      /// Ready to Claim
      static let readyToClaim = L10n.tr("Localizable", "assetDetails_staking_readyToClaim", fallback: "Ready to Claim")
      /// Ready to Claim in
      static let readyToClaimIn = L10n.tr("Localizable", "assetDetails_staking_readyToClaimIn", fallback: "Ready to Claim in")
      /// 1 day or less
      static let readyToClaimInDay = L10n.tr("Localizable", "assetDetails_staking_readyToClaimInDay", fallback: "1 day or less")
      /// %d days or less
      static func readyToClaimInDays(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_staking_readyToClaimInDays", p1, fallback: "%d days or less")
      }
      /// 1 hour or less
      static let readyToClaimInHour = L10n.tr("Localizable", "assetDetails_staking_readyToClaimInHour", fallback: "1 hour or less")
      /// %d hours or less
      static func readyToClaimInHours(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_staking_readyToClaimInHours", p1, fallback: "%d hours or less")
      }
      /// 1 minute or less
      static let readyToClaimInMinute = L10n.tr("Localizable", "assetDetails_staking_readyToClaimInMinute", fallback: "1 minute or less")
      /// %d minutes or less
      static func readyToClaimInMinutes(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_staking_readyToClaimInMinutes", p1, fallback: "%d minutes or less")
      }
    }
    enum StakingDetails {
      /// You have no Stakes
      static let noStakes = L10n.tr("Localizable", "assetDetails_stakingDetails_noStakes", fallback: "You have no Stakes")
    }
    enum Tags {
      /// Official Radix
      static let officialRadix = L10n.tr("Localizable", "assetDetails_tags_officialRadix", fallback: "Official Radix")
    }
    enum TokenDetails {
      /// You have no Tokens
      static let noTokens = L10n.tr("Localizable", "assetDetails_tokenDetails_noTokens", fallback: "You have no Tokens")
    }
  }
  enum AssetTransfer {
    /// Scan a QR code of a Radix Account address from another wallet or an exchange.
    static let qrScanInstructions = L10n.tr("Localizable", "assetTransfer_qrScanInstructions", fallback: "Scan a QR code of a Radix Account address from another wallet or an exchange.")
    /// Continue
    static let sendTransferButton = L10n.tr("Localizable", "assetTransfer_sendTransferButton", fallback: "Continue")
    /// Message
    static let transactionMessage = L10n.tr("Localizable", "assetTransfer_transactionMessage", fallback: "Message")
    /// Add a message
    static let transactionMessagePlaceholder = L10n.tr("Localizable", "assetTransfer_transactionMessagePlaceholder", fallback: "Add a message")
    enum AccountList {
      /// Add Transfer
      static let addAccountButton = L10n.tr("Localizable", "assetTransfer_accountList_addAccountButton", fallback: "Add Transfer")
      /// Account
      static let externalAccountName = L10n.tr("Localizable", "assetTransfer_accountList_externalAccountName", fallback: "Account")
      /// From
      static let fromLabel = L10n.tr("Localizable", "assetTransfer_accountList_fromLabel", fallback: "From")
      /// To
      static let toLabel = L10n.tr("Localizable", "assetTransfer_accountList_toLabel", fallback: "To")
    }
    enum AddAssets {
      /// Choose %d Assets
      static func buttonAssets(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetTransfer_addAssets_buttonAssets", p1, fallback: "Choose %d Assets")
      }
      /// Select Assets
      static let buttonAssetsNone = L10n.tr("Localizable", "assetTransfer_addAssets_buttonAssetsNone", fallback: "Select Assets")
      /// Choose 1 Asset
      static let buttonAssetsOne = L10n.tr("Localizable", "assetTransfer_addAssets_buttonAssetsOne", fallback: "Choose 1 Asset")
      /// Choose Asset(s) to Send
      static let navigationTitle = L10n.tr("Localizable", "assetTransfer_addAssets_navigationTitle", fallback: "Choose Asset(s) to Send")
    }
    enum ChooseReceivingAccount {
      /// Enter Radix Account address
      static let addressFieldPlaceholder = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_addressFieldPlaceholder", fallback: "Enter Radix Account address")
      /// Account already added
      static let alreadyAddedError = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_alreadyAddedError", fallback: "Account already added")
      /// Or: Choose one of your own Accounts
      static let chooseOwnAccount = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_chooseOwnAccount", fallback: "Or: Choose one of your own Accounts")
      /// Enter or scan an Account address
      static let enterManually = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_enterManually", fallback: "Enter or scan an Account address")
      /// Invalid address
      static let invalidAddressError = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_invalidAddressError", fallback: "Invalid address")
      /// Choose Receiving Account
      static let navigationTitle = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_navigationTitle", fallback: "Choose Receiving Account")
      /// Scan Account QR Code
      static let scanQRNavigationTitle = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_scanQRNavigationTitle", fallback: "Scan Account QR Code")
    }
    enum DepositStatus {
      /// Recipient does not accept these tokens
      static let denied = L10n.tr("Localizable", "assetTransfer_depositStatus_denied", fallback: "Recipient does not accept these tokens")
      /// Additional signature required to deposit
      static let signatureRequired = L10n.tr("Localizable", "assetTransfer_depositStatus_signatureRequired", fallback: "Additional signature required to deposit")
    }
    enum Error {
      /// Total amount exceeds your current balance
      static let insufficientBalance = L10n.tr("Localizable", "assetTransfer_error_insufficientBalance", fallback: "Total amount exceeds your current balance")
      /// Resource already added
      static let resourceAlreadyAdded = L10n.tr("Localizable", "assetTransfer_error_resourceAlreadyAdded", fallback: "Resource already added")
      /// Address is not valid on current network
      static let wrongNetwork = L10n.tr("Localizable", "assetTransfer_error_wrongNetwork", fallback: "Address is not valid on current network")
    }
    enum ExtraSignature {
      /// You will be asked for an extra signature
      static let label = L10n.tr("Localizable", "assetTransfer_extraSignature_label", fallback: "You will be asked for an extra signature")
    }
    enum FungibleResource {
      /// Balance: %@
      static func balance(_ p1: Any) -> String {
        return L10n.tr("Localizable", "assetTransfer_fungibleResource_balance", String(describing: p1), fallback: "Balance: %@")
      }
      /// Total exceeds your current balance
      static let totalExceedsBalance = L10n.tr("Localizable", "assetTransfer_fungibleResource_totalExceedsBalance", fallback: "Total exceeds your current balance")
    }
    enum Header {
      /// Add Message
      static let addMessageButton = L10n.tr("Localizable", "assetTransfer_header_addMessageButton", fallback: "Add Message")
      /// Transfer
      static let transfer = L10n.tr("Localizable", "assetTransfer_header_transfer", fallback: "Transfer")
    }
    enum MaxAmountDialog {
      /// Sending the full amount of XRD in this account will require you to pay the transaction fee from a different account. Or, the wallet can reduce the amount transferred so the fee can be paid from this account. Choose the amount to transfer:
      static let body = L10n.tr("Localizable", "assetTransfer_maxAmountDialog_body", fallback: "Sending the full amount of XRD in this account will require you to pay the transaction fee from a different account. Or, the wallet can reduce the amount transferred so the fee can be paid from this account. Choose the amount to transfer:")
      /// %@ (save 1 XRD for fee)
      static func saveXrdForFeeButton(_ p1: Any) -> String {
        return L10n.tr("Localizable", "assetTransfer_maxAmountDialog_saveXrdForFeeButton", String(describing: p1), fallback: "%@ (save 1 XRD for fee)")
      }
      /// %@ (send all XRD)
      static func sendAllButton(_ p1: Any) -> String {
        return L10n.tr("Localizable", "assetTransfer_maxAmountDialog_sendAllButton", String(describing: p1), fallback: "%@ (send all XRD)")
      }
      /// Sending All XRD
      static let title = L10n.tr("Localizable", "assetTransfer_maxAmountDialog_title", fallback: "Sending All XRD")
    }
    enum ReceivingAccount {
      /// Add Assets
      static let addAssetsButton = L10n.tr("Localizable", "assetTransfer_receivingAccount_addAssetsButton", fallback: "Add Assets")
      /// Choose Account
      static let chooseAccountButton = L10n.tr("Localizable", "assetTransfer_receivingAccount_chooseAccountButton", fallback: "Choose Account")
    }
  }
  enum AuthorizedDapps {
    /// A deposit from this dApp is available. Go to your Accounts to view and claim.
    static let pendingDeposit = L10n.tr("Localizable", "authorizedDapps_pendingDeposit", fallback: "A deposit from this dApp is available. Go to your Accounts to view and claim.")
    /// These are the dApps that you have logged into using the Radix Wallet.
    static let subtitle = L10n.tr("Localizable", "authorizedDapps_subtitle", fallback: "These are the dApps that you have logged into using the Radix Wallet.")
    /// Approved dApps
    static let title = L10n.tr("Localizable", "authorizedDapps_title", fallback: "Approved dApps")
    enum DAppDetails {
      /// dApp Definition
      static let dAppDefinition = L10n.tr("Localizable", "authorizedDapps_dAppDetails_dAppDefinition", fallback: "dApp Definition")
      /// Available deposits from this dApp will not be shown
      static let depositsHidden = L10n.tr("Localizable", "authorizedDapps_dAppDetails_depositsHidden", fallback: "Available deposits from this dApp will not be shown")
      /// Show direct deposits to claim
      static let depositsTitle = L10n.tr("Localizable", "authorizedDapps_dAppDetails_depositsTitle", fallback: "Show direct deposits to claim")
      /// Available deposits from this dApp will be shown on the recipient Accounts
      static let depositsVisible = L10n.tr("Localizable", "authorizedDapps_dAppDetails_depositsVisible", fallback: "Available deposits from this dApp will be shown on the recipient Accounts")
      /// Forget this dApp
      static let forgetDapp = L10n.tr("Localizable", "authorizedDapps_dAppDetails_forgetDapp", fallback: "Forget this dApp")
      /// Missing description
      static let missingDescription = L10n.tr("Localizable", "authorizedDapps_dAppDetails_missingDescription", fallback: "Missing description")
      /// Associated NFTs
      static let nfts = L10n.tr("Localizable", "authorizedDapps_dAppDetails_nfts", fallback: "Associated NFTs")
      /// No Personas have been used to login to this dApp.
      static let noPersonasHeading = L10n.tr("Localizable", "authorizedDapps_dAppDetails_noPersonasHeading", fallback: "No Personas have been used to login to this dApp.")
      /// Here are the Personas that you have used to login to this dApp.
      static let personasHeading = L10n.tr("Localizable", "authorizedDapps_dAppDetails_personasHeading", fallback: "Here are the Personas that you have used to login to this dApp.")
      /// Associated Tokens
      static let tokens = L10n.tr("Localizable", "authorizedDapps_dAppDetails_tokens", fallback: "Associated Tokens")
      /// Unknown name
      static let unknownTokenName = L10n.tr("Localizable", "authorizedDapps_dAppDetails_unknownTokenName", fallback: "Unknown name")
      /// Website
      static let website = L10n.tr("Localizable", "authorizedDapps_dAppDetails_website", fallback: "Website")
    }
    enum ForgetDappAlert {
      /// Forget dApp?
      static let forget = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_forget", fallback: "Forget dApp?")
      /// Do you really want to forget this dApp and remove its permissions for all Personas?
      static let message = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_message", fallback: "Do you really want to forget this dApp and remove its permissions for all Personas?")
      /// Forget This dApp
      static let title = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_title", fallback: "Forget This dApp")
    }
    enum PersonaDetails {
      /// Here are the Account names and addresses that you are currently sharing with %@.
      static func accountSharingDescription(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_accountSharingDescription", String(describing: p1), fallback: "Here are the Account names and addresses that you are currently sharing with %@.")
      }
      /// Here are the dApps you have logged into with this Persona.
      static let authorizedDappsHeading = L10n.tr("Localizable", "authorizedDapps_personaDetails_authorizedDappsHeading", fallback: "Here are the dApps you have logged into with this Persona.")
      /// Edit
      static let edit = L10n.tr("Localizable", "authorizedDapps_personaDetails_edit", fallback: "Edit")
      /// Edit Account Sharing
      static let editAccountSharing = L10n.tr("Localizable", "authorizedDapps_personaDetails_editAccountSharing", fallback: "Edit Account Sharing")
      /// Edit Avatar
      static let editAvatarButtonTitle = L10n.tr("Localizable", "authorizedDapps_personaDetails_editAvatarButtonTitle", fallback: "Edit Avatar")
      /// Edit Persona
      static let editPersona = L10n.tr("Localizable", "authorizedDapps_personaDetails_editPersona", fallback: "Edit Persona")
      /// Email Address
      static let emailAddress = L10n.tr("Localizable", "authorizedDapps_personaDetails_emailAddress", fallback: "Email Address")
      /// First Name
      static let firstName = L10n.tr("Localizable", "authorizedDapps_personaDetails_firstName", fallback: "First Name")
      /// Full Name
      static let fullName = L10n.tr("Localizable", "authorizedDapps_personaDetails_fullName", fallback: "Full Name")
      /// Given Name(s)
      static let givenName = L10n.tr("Localizable", "authorizedDapps_personaDetails_givenName", fallback: "Given Name(s)")
      /// Are you sure you want to hide this persona?
      static let hidePersonaConfirmation = L10n.tr("Localizable", "authorizedDapps_personaDetails_hidePersonaConfirmation", fallback: "Are you sure you want to hide this persona?")
      /// Hide This Persona
      static let hideThisPersona = L10n.tr("Localizable", "authorizedDapps_personaDetails_hideThisPersona", fallback: "Hide This Persona")
      /// Last Name
      static let lastName = L10n.tr("Localizable", "authorizedDapps_personaDetails_lastName", fallback: "Last Name")
      /// Family Name
      static let nameFamily = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameFamily", fallback: "Family Name")
      /// Name Order
      static let nameVariant = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameVariant", fallback: "Name Order")
      /// Eastern style (family name first)
      static let nameVariantEastern = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameVariantEastern", fallback: "Eastern style (family name first)")
      /// Western style (given name(s) first)
      static let nameVariantWestern = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameVariantWestern", fallback: "Western style (given name(s) first)")
      /// Nickname
      static let nickname = L10n.tr("Localizable", "authorizedDapps_personaDetails_nickname", fallback: "Nickname")
      /// You are not sharing any personal data with %@.
      static func notSharingAnything(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_notSharingAnything", String(describing: p1), fallback: "You are not sharing any personal data with %@.")
      }
      /// Persona Hidden
      static let personaHidden = L10n.tr("Localizable", "authorizedDapps_personaDetails_personaHidden", fallback: "Persona Hidden")
      /// Persona Label
      static let personaLabelHeading = L10n.tr("Localizable", "authorizedDapps_personaDetails_personaLabelHeading", fallback: "Persona Label")
      /// Here is the personal data that you are sharing with %@.
      static func personalDataSharingDescription(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_personalDataSharingDescription", String(describing: p1), fallback: "Here is the personal data that you are sharing with %@.")
      }
      /// Phone Number
      static let phoneNumber = L10n.tr("Localizable", "authorizedDapps_personaDetails_phoneNumber", fallback: "Phone Number")
      /// Disconnect Persona from this dApp
      static let removeAuthorization = L10n.tr("Localizable", "authorizedDapps_personaDetails_removeAuthorization", fallback: "Disconnect Persona from this dApp")
    }
    enum RemoveAuthorizationAlert {
      /// Continue
      static let confirm = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_confirm", fallback: "Continue")
      /// This dApp will no longer have authorization to see data associated with this Persona, unless you choose to login with it again in the future.
      static let message = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_message", fallback: "This dApp will no longer have authorization to see data associated with this Persona, unless you choose to login with it again in the future.")
      /// Remove Authorization
      static let title = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_title", fallback: "Remove Authorization")
    }
  }
  enum Biometrics {
    enum AppLockAvailableAlert {
      /// Your phone was updated and now supports Apple's built-in App Lock feature.
      static let message = L10n.tr("Localizable", "biometrics_appLockAvailableAlert_message", fallback: "Your phone was updated and now supports Apple's built-in App Lock feature.")
      /// Advanced Lock Disabled
      static let title = L10n.tr("Localizable", "biometrics_appLockAvailableAlert_title", fallback: "Advanced Lock Disabled")
    }
    enum DeviceNotSecureAlert {
      /// Your device currently has no device access security set, such as biometrics or a PIN. The Radix Wallet requires this to be set for your security.
      static let message = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_message", fallback: "Your device currently has no device access security set, such as biometrics or a PIN. The Radix Wallet requires this to be set for your security.")
      /// Open Settings
      static let openSettings = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_openSettings", fallback: "Open Settings")
      /// Quit
      static let quit = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_quit", fallback: "Quit")
      /// Unsecured Device
      static let title = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_title", fallback: "Unsecured Device")
    }
    enum Prompt {
      /// Checking accounts.
      static let checkingAccounts = L10n.tr("Localizable", "biometrics_prompt_checkingAccounts", fallback: "Checking accounts.")
      /// Create Auth signing key.
      static let createSignAuthKey = L10n.tr("Localizable", "biometrics_prompt_createSignAuthKey", fallback: "Create Auth signing key.")
      /// Authenticate to create new %@ with this phone.
      static func creationOfEntity(_ p1: Any) -> String {
        return L10n.tr("Localizable", "biometrics_prompt_creationOfEntity", String(describing: p1), fallback: "Authenticate to create new %@ with this phone.")
      }
      /// Display seed phrase.
      static let displaySeedPhrase = L10n.tr("Localizable", "biometrics_prompt_displaySeedPhrase", fallback: "Display seed phrase.")
      /// Check if seed phrase already exists.
      static let importOlympiaAccounts = L10n.tr("Localizable", "biometrics_prompt_importOlympiaAccounts", fallback: "Check if seed phrase already exists.")
      /// Authenticate to sign proof with this phone.
      static let signAuthChallenge = L10n.tr("Localizable", "biometrics_prompt_signAuthChallenge", fallback: "Authenticate to sign proof with this phone.")
      /// Authenticate to sign transaction with this phone.
      static let signTransaction = L10n.tr("Localizable", "biometrics_prompt_signTransaction", fallback: "Authenticate to sign transaction with this phone.")
      /// Authenticate to continue
      static let title = L10n.tr("Localizable", "biometrics_prompt_title", fallback: "Authenticate to continue")
      /// Update account metadata.
      static let updateAccountMetadata = L10n.tr("Localizable", "biometrics_prompt_updateAccountMetadata", fallback: "Update account metadata.")
    }
  }
  enum Common {
    /// Account
    static let account = L10n.tr("Localizable", "common_account", fallback: "Account")
    /// Bad HTTP response status code %d
    static func badHttpResponseStatusCode(_ p1: Int) -> String {
      return L10n.tr("Localizable", "common_badHttpResponseStatusCode", p1, fallback: "Bad HTTP response status code %d")
    }
    /// Cancel
    static let cancel = L10n.tr("Localizable", "common_cancel", fallback: "Cancel")
    /// Choose
    static let choose = L10n.tr("Localizable", "common_choose", fallback: "Choose")
    /// Component
    static let component = L10n.tr("Localizable", "common_component", fallback: "Component")
    /// Confirm
    static let confirm = L10n.tr("Localizable", "common_confirm", fallback: "Confirm")
    /// Continue
    static let `continue` = L10n.tr("Localizable", "common_continue", fallback: "Continue")
    /// Copy
    static let copy = L10n.tr("Localizable", "common_copy", fallback: "Copy")
    /// Connected to a test network, not Radix main network.
    static let developerDisclaimerText = L10n.tr("Localizable", "common_developerDisclaimerText", fallback: "Connected to a test network, not Radix main network.")
    /// Dismiss
    static let dismiss = L10n.tr("Localizable", "common_dismiss", fallback: "Dismiss")
    /// Done
    static let done = L10n.tr("Localizable", "common_done", fallback: "Done")
    /// An Error Occurred
    static let errorAlertTitle = L10n.tr("Localizable", "common_errorAlertTitle", fallback: "An Error Occurred")
    /// History
    static let history = L10n.tr("Localizable", "common_history", fallback: "History")
    /// Invalid
    static let invalid = L10n.tr("Localizable", "common_invalid", fallback: "Invalid")
    /// Max
    static let max = L10n.tr("Localizable", "common_max", fallback: "Max")
    /// None
    static let `none` = L10n.tr("Localizable", "common_none", fallback: "None")
    /// OK
    static let ok = L10n.tr("Localizable", "common_ok", fallback: "OK")
    /// Optional
    static let `optional` = L10n.tr("Localizable", "common_optional", fallback: "Optional")
    /// Persona
    static let persona = L10n.tr("Localizable", "common_persona", fallback: "Persona")
    /// Pool
    static let pool = L10n.tr("Localizable", "common_pool", fallback: "Pool")
    /// Public
    static let `public` = L10n.tr("Localizable", "common_public", fallback: "Public")
    /// Gateway access blocked due to exceeding rate limit. Please wait a few minutes to retry.
    static let rateLimitReached = L10n.tr("Localizable", "common_rateLimitReached", fallback: "Gateway access blocked due to exceeding rate limit. Please wait a few minutes to retry.")
    /// Remove
    static let remove = L10n.tr("Localizable", "common_remove", fallback: "Remove")
    /// Retry
    static let retry = L10n.tr("Localizable", "common_retry", fallback: "Retry")
    /// Save
    static let save = L10n.tr("Localizable", "common_save", fallback: "Save")
    /// Show Less
    static let showLess = L10n.tr("Localizable", "common_showLess", fallback: "Show Less")
    /// Show More
    static let showMore = L10n.tr("Localizable", "common_showMore", fallback: "Show More")
    /// Something Went Wrong
    static let somethingWentWrong = L10n.tr("Localizable", "common_somethingWentWrong", fallback: "Something Went Wrong")
    /// Settings
    static let systemSettings = L10n.tr("Localizable", "common_systemSettings", fallback: "Settings")
    /// Unauthorized
    static let unauthorized = L10n.tr("Localizable", "common_unauthorized", fallback: "Unauthorized")
  }
  enum ConfigurationBackup {
    /// You need an up-to-date Configuration Backup to recover your Accounts and Personas if you lose access to them.
    /// 
    /// Your Backup does not contain your keys or seed phrase.
    static let heading = L10n.tr("Localizable", "configurationBackup_heading", fallback: "You need an up-to-date Configuration Backup to recover your Accounts and Personas if you lose access to them.\n\nYour Backup does not contain your keys or seed phrase.")
    /// Configuration Backup
    static let title = L10n.tr("Localizable", "configurationBackup_title", fallback: "Configuration Backup")
    enum Automated {
      /// Your list of Accounts and the Factors required to recover them
      static let accountsItemSubtitle = L10n.tr("Localizable", "configurationBackup_automated_accountsItemSubtitle", fallback: "Your list of Accounts and the Factors required to recover them")
      /// Accounts
      static let accountsItemTitle = L10n.tr("Localizable", "configurationBackup_automated_accountsItemTitle", fallback: "Accounts")
      /// Login to Google Drive for Backups
      static let cloudUpdatedLoginButtonAndroid = L10n.tr("Localizable", "configurationBackup_automated_cloudUpdatedLoginButtonAndroid", fallback: "Login to Google Drive for Backups")
      /// Skip for Now
      static let cloudUpdatedSkipButtonAndroid = L10n.tr("Localizable", "configurationBackup_automated_cloudUpdatedSkipButtonAndroid", fallback: "Skip for Now")
      /// The Radix Wallet has an all new and improved backup system.
      /// 
      /// To continue, log in with the Google Drive account you want to use for backups.
      static let cloudUpdatedSubtitleAndroid = L10n.tr("Localizable", "configurationBackup_automated_cloudUpdatedSubtitleAndroid", fallback: "The Radix Wallet has an all new and improved backup system.\n\nTo continue, log in with the Google Drive account you want to use for backups.")
      /// Backups on Google Drive Have Updated
      static let cloudUpdatedTitleAndroid = L10n.tr("Localizable", "configurationBackup_automated_cloudUpdatedTitleAndroid", fallback: "Backups on Google Drive Have Updated")
      /// Delete
      static let deleteOutdatedBackupIOS = L10n.tr("Localizable", "configurationBackup_automated_deleteOutdatedBackupIOS", fallback: "Delete")
      /// Disconnect
      static let disconnectAndroid = L10n.tr("Localizable", "configurationBackup_automated_disconnectAndroid", fallback: "Disconnect")
      /// Last backup: %@
      static func lastBackup(_ p1: Any) -> String {
        return L10n.tr("Localizable", "configurationBackup_automated_lastBackup", String(describing: p1), fallback: "Last backup: %@")
      }
      /// Logged in as:
      static let loggedInAsAndroid = L10n.tr("Localizable", "configurationBackup_automated_loggedInAsAndroid", fallback: "Logged in as:")
      /// Log in to Google Drive
      static let logInAndroid = L10n.tr("Localizable", "configurationBackup_automated_logInAndroid", fallback: "Log in to Google Drive")
      /// Out-of-date backup still present on iCloud
      static let outdatedBackupIOS = L10n.tr("Localizable", "configurationBackup_automated_outdatedBackupIOS", fallback: "Out-of-date backup still present on iCloud")
      /// Your list of Personas and the Factors required to recover them. Also your Persona data.
      static let personasItemSubtitle = L10n.tr("Localizable", "configurationBackup_automated_personasItemSubtitle", fallback: "Your list of Personas and the Factors required to recover them. Also your Persona data.")
      /// Personas
      static let personasItemTitle = L10n.tr("Localizable", "configurationBackup_automated_personasItemTitle", fallback: "Personas")
      /// The list of Security Factors you need to recover your Accounts and Personas.
      static let securityFactorsItemSubtitle = L10n.tr("Localizable", "configurationBackup_automated_securityFactorsItemSubtitle", fallback: "The list of Security Factors you need to recover your Accounts and Personas.")
      /// Security Factors
      static let securityFactorsItemTitle = L10n.tr("Localizable", "configurationBackup_automated_securityFactorsItemTitle", fallback: "Security Factors")
      /// Configuration Backup status
      static let text = L10n.tr("Localizable", "configurationBackup_automated_text", fallback: "Configuration Backup status")
      /// Automated Google Drive Backups
      static let toggleAndroid = L10n.tr("Localizable", "configurationBackup_automated_toggleAndroid", fallback: "Automated Google Drive Backups")
      /// Automated iCloud Backups
      static let toggleIOS = L10n.tr("Localizable", "configurationBackup_automated_toggleIOS", fallback: "Automated iCloud Backups")
      /// Your general settings, such as trusted dApps, linked Connectors and wallet display settings.
      static let walletSettingsItemSubtitle = L10n.tr("Localizable", "configurationBackup_automated_walletSettingsItemSubtitle", fallback: "Your general settings, such as trusted dApps, linked Connectors and wallet display settings.")
      /// Wallet settings
      static let walletSettingsItemTitle = L10n.tr("Localizable", "configurationBackup_automated_walletSettingsItemTitle", fallback: "Wallet settings")
      /// Clear Wallet on This Phone
      static let walletTransferredClearButton = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredClearButton", fallback: "Clear Wallet on This Phone")
      /// If this was done in error, you can reclaim control to this phone. You won’t be able to access it from your old phone after the transfer.
      static let walletTransferredExplanation1 = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredExplanation1", fallback: "If this was done in error, you can reclaim control to this phone. You won’t be able to access it from your old phone after the transfer.")
      /// Or, you can clear the wallet configuration from this phone and start fresh.
      static let walletTransferredExplanation2 = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredExplanation2", fallback: "Or, you can clear the wallet configuration from this phone and start fresh.")
      /// The current wallet configuration is now controlled by another phone.
      static let walletTransferredSubtitle = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredSubtitle", fallback: "The current wallet configuration is now controlled by another phone.")
      /// Wallet Control Has Been Transferred
      static let walletTransferredTitle = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredTitle", fallback: "Wallet Control Has Been Transferred")
      /// Transfer Control Back to This Phone
      static let walletTransferredTransferBackButton = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredTransferBackButton", fallback: "Transfer Control Back to This Phone")
      /// Without an updated Configuration Backup, you cannot recover your Accounts and Personas.
      static let warning = L10n.tr("Localizable", "configurationBackup_automated_warning", fallback: "Without an updated Configuration Backup, you cannot recover your Accounts and Personas.")
    }
    enum Manual {
      /// Export Backup File
      static let exportButton = L10n.tr("Localizable", "configurationBackup_manual_exportButton", fallback: "Export Backup File")
      /// Manual backup
      static let heading = L10n.tr("Localizable", "configurationBackup_manual_heading", fallback: "Manual backup")
      /// Last backup: %@
      static func lastBackup(_ p1: Any) -> String {
        return L10n.tr("Localizable", "configurationBackup_manual_lastBackup", String(describing: p1), fallback: "Last backup: %@")
      }
      /// You can export your own Configuration Backup file and save it locally
      static let text = L10n.tr("Localizable", "configurationBackup_manual_text", fallback: "You can export your own Configuration Backup file and save it locally")
      /// You’ll need to export a new Backup file each time you make a change in your wallet.
      static let warning = L10n.tr("Localizable", "configurationBackup_manual_warning", fallback: "You’ll need to export a new Backup file each time you make a change in your wallet.")
    }
  }
  enum ConfirmMnemonicBackedUp {
    /// Confirm you have written down the seed phrase by entering the missing words below.
    static let subtitle = L10n.tr("Localizable", "confirmMnemonicBackedUp_subtitle", fallback: "Confirm you have written down the seed phrase by entering the missing words below.")
    /// Confirm Your Seed Phrase
    static let title = L10n.tr("Localizable", "confirmMnemonicBackedUp_title", fallback: "Confirm Your Seed Phrase")
  }
  enum Confirmation {
    enum HideAccount {
      /// Hide Account
      static let button = L10n.tr("Localizable", "confirmation_hideAccount_button", fallback: "Hide Account")
      /// Hide this Account in your wallet? You can always unhide it from the main application settings.
      static let message = L10n.tr("Localizable", "confirmation_hideAccount_message", fallback: "Hide this Account in your wallet? You can always unhide it from the main application settings.")
      /// Hide This Account
      static let title = L10n.tr("Localizable", "confirmation_hideAccount_title", fallback: "Hide This Account")
    }
    enum HideAsset {
      /// Hide Asset
      static let button = L10n.tr("Localizable", "confirmation_hideAsset_button", fallback: "Hide Asset")
      /// Hide this asset in your Radix Wallet? You can always unhide it in your account settings.
      static let message = L10n.tr("Localizable", "confirmation_hideAsset_message", fallback: "Hide this asset in your Radix Wallet? You can always unhide it in your account settings.")
      /// Hide Asset
      static let title = L10n.tr("Localizable", "confirmation_hideAsset_title", fallback: "Hide Asset")
    }
    enum HideCollection {
      /// Hide
      static let button = L10n.tr("Localizable", "confirmation_hideCollection_button", fallback: "Hide")
      /// Hide **%@** NFT Collection in your Radix Wallet? You can always unhide it in your account settings.
      static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "confirmation_hideCollection_message", String(describing: p1), fallback: "Hide **%@** NFT Collection in your Radix Wallet? You can always unhide it in your account settings.")
      }
      /// Hide Collection
      static let title = L10n.tr("Localizable", "confirmation_hideCollection_title", fallback: "Hide Collection")
    }
  }
  enum CreateAccount {
    /// Create First Account
    static let titleFirst = L10n.tr("Localizable", "createAccount_titleFirst", fallback: "Create First Account")
    /// Create New Account
    static let titleNotFirst = L10n.tr("Localizable", "createAccount_titleNotFirst", fallback: "Create New Account")
    enum Completion {
      /// Your Account lives on the Radix Network and you can access it any time in your Radix Wallet.
      static let explanation = L10n.tr("Localizable", "createAccount_completion_explanation", fallback: "Your Account lives on the Radix Network and you can access it any time in your Radix Wallet.")
      /// You’ve created your first Account!
      static let subtitleFirst = L10n.tr("Localizable", "createAccount_completion_subtitleFirst", fallback: "You’ve created your first Account!")
      /// Your Account has been created.
      static let subtitleNotFirst = L10n.tr("Localizable", "createAccount_completion_subtitleNotFirst", fallback: "Your Account has been created.")
    }
    enum Introduction {
      /// Create an Account
      static let title = L10n.tr("Localizable", "createAccount_introduction_title", fallback: "Create an Account")
    }
    enum NameNewAccount {
      /// Continue
      static let `continue` = L10n.tr("Localizable", "createAccount_nameNewAccount_continue", fallback: "Continue")
      /// This can be changed any time.
      static let explanation = L10n.tr("Localizable", "createAccount_nameNewAccount_explanation", fallback: "This can be changed any time.")
      /// e.g. My Main Account
      static let placeholder = L10n.tr("Localizable", "createAccount_nameNewAccount_placeholder", fallback: "e.g. My Main Account")
      /// What would you like to call your Account?
      static let subtitle = L10n.tr("Localizable", "createAccount_nameNewAccount_subtitle", fallback: "What would you like to call your Account?")
    }
  }
  enum CreateEntity {
    enum Completion {
      /// Choose Accounts
      static let destinationChooseAccounts = L10n.tr("Localizable", "createEntity_completion_destinationChooseAccounts", fallback: "Choose Accounts")
      /// Persona Selection
      static let destinationChoosePersonas = L10n.tr("Localizable", "createEntity_completion_destinationChoosePersonas", fallback: "Persona Selection")
      /// Gateways
      static let destinationGateways = L10n.tr("Localizable", "createEntity_completion_destinationGateways", fallback: "Gateways")
      /// Account List
      static let destinationHome = L10n.tr("Localizable", "createEntity_completion_destinationHome", fallback: "Account List")
      /// Persona List
      static let destinationPersonaList = L10n.tr("Localizable", "createEntity_completion_destinationPersonaList", fallback: "Persona List")
      /// Continue to %@
      static func goToDestination(_ p1: Any) -> String {
        return L10n.tr("Localizable", "createEntity_completion_goToDestination", String(describing: p1), fallback: "Continue to %@")
      }
      /// Congratulations
      static let title = L10n.tr("Localizable", "createEntity_completion_title", fallback: "Congratulations")
    }
    enum Ledger {
      /// Create Ledger Account
      static let createAccount = L10n.tr("Localizable", "createEntity_ledger_createAccount", fallback: "Create Ledger Account")
      /// Create Ledger Persona
      static let createPersona = L10n.tr("Localizable", "createEntity_ledger_createPersona", fallback: "Create Ledger Persona")
    }
    enum NameNewEntity {
      /// Your Account lives on the Radix Network and you can access it any time in your Wallet.
      static let explanation = L10n.tr("Localizable", "createEntity_nameNewEntity_explanation", fallback: "Your Account lives on the Radix Network and you can access it any time in your Wallet.")
      /// You will be asked to sign transactions with the Ledger device you select.
      static let ledgerSubtitle = L10n.tr("Localizable", "createEntity_nameNewEntity_ledgerSubtitle", fallback: "You will be asked to sign transactions with the Ledger device you select.")
      /// Create with Ledger Hardware Wallet
      static let ledgerTitle = L10n.tr("Localizable", "createEntity_nameNewEntity_ledgerTitle", fallback: "Create with Ledger Hardware Wallet")
    }
  }
  enum CreatePersona {
    /// Empty display name
    static let emptyDisplayName = L10n.tr("Localizable", "createPersona_emptyDisplayName", fallback: "Empty display name")
    /// Required field
    static let requiredField = L10n.tr("Localizable", "createPersona_requiredField", fallback: "Required field")
    /// Save and Continue
    static let saveAndContinueButtonTitle = L10n.tr("Localizable", "createPersona_saveAndContinueButtonTitle", fallback: "Save and Continue")
    enum Completion {
      /// Personal data that you add to your Persona will only be shared with dApps with your permission.
      static let explanation = L10n.tr("Localizable", "createPersona_completion_explanation", fallback: "Personal data that you add to your Persona will only be shared with dApps with your permission.")
      /// You’ve created your first Persona!
      static let subtitleFirst = L10n.tr("Localizable", "createPersona_completion_subtitleFirst", fallback: "You’ve created your first Persona!")
      /// Your Persona has been created.
      static let subtitleNotFirst = L10n.tr("Localizable", "createPersona_completion_subtitleNotFirst", fallback: "Your Persona has been created.")
    }
    enum Explanation {
      /// Some dApps may request personal information, like name or email address, that can be added to your Persona. Add some data now if you like.
      static let someDappsMayRequest = L10n.tr("Localizable", "createPersona_explanation_someDappsMayRequest", fallback: "Some dApps may request personal information, like name or email address, that can be added to your Persona. Add some data now if you like.")
      /// This will be shared with dApps you login to
      static let thisWillBeShared = L10n.tr("Localizable", "createPersona_explanation_thisWillBeShared", fallback: "This will be shared with dApps you login to")
    }
    enum Introduction {
      /// Continue
      static let `continue` = L10n.tr("Localizable", "createPersona_introduction_continue", fallback: "Continue")
      /// A Persona is an identity that you own and control. You can have as many as you like.
      static let subtitle1 = L10n.tr("Localizable", "createPersona_introduction_subtitle1", fallback: "A Persona is an identity that you own and control. You can have as many as you like.")
      /// Personas are used to login to dApps on Radix. dApps may request access to personal information associated with your Persona, like your name or email address.
      static let subtitle2 = L10n.tr("Localizable", "createPersona_introduction_subtitle2", fallback: "Personas are used to login to dApps on Radix. dApps may request access to personal information associated with your Persona, like your name or email address.")
      /// Create a Persona
      static let title = L10n.tr("Localizable", "createPersona_introduction_title", fallback: "Create a Persona")
    }
    enum NameNewPersona {
      /// Continue
      static let `continue` = L10n.tr("Localizable", "createPersona_nameNewPersona_continue", fallback: "Continue")
      /// e.g. My Main Persona
      static let placeholder = L10n.tr("Localizable", "createPersona_nameNewPersona_placeholder", fallback: "e.g. My Main Persona")
      /// What would you like to call your Persona?
      static let subtitle = L10n.tr("Localizable", "createPersona_nameNewPersona_subtitle", fallback: "What would you like to call your Persona?")
    }
  }
  enum CustomizeNetworkFees {
    /// Change
    static let changeButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_changeButtonTitle", fallback: "Change")
    /// Effective Tip
    static let effectiveTip = L10n.tr("Localizable", "customizeNetworkFees_effectiveTip", fallback: "Effective Tip")
    /// Estimated Transaction Fees
    static let feeBreakdownTitle = L10n.tr("Localizable", "customizeNetworkFees_feeBreakdownTitle", fallback: "Estimated Transaction Fees")
    /// Network Execution
    static let networkExecution = L10n.tr("Localizable", "customizeNetworkFees_networkExecution", fallback: "Network Execution")
    /// Network Fee
    static let networkFee = L10n.tr("Localizable", "customizeNetworkFees_networkFee", fallback: "Network Fee")
    /// Network Finalization
    static let networkFinalization = L10n.tr("Localizable", "customizeNetworkFees_networkFinalization", fallback: "Network Finalization")
    /// Network Storage
    static let networkStorage = L10n.tr("Localizable", "customizeNetworkFees_networkStorage", fallback: "Network Storage")
    /// No account selected
    static let noAccountSelected = L10n.tr("Localizable", "customizeNetworkFees_noAccountSelected", fallback: "No account selected")
    /// None due
    static let noneDue = L10n.tr("Localizable", "customizeNetworkFees_noneDue", fallback: "None due")
    /// None required
    static let noneRequired = L10n.tr("Localizable", "customizeNetworkFees_noneRequired", fallback: "None required")
    /// Padding
    static let padding = L10n.tr("Localizable", "customizeNetworkFees_padding", fallback: "Padding")
    /// Adjust Fee Padding Amount (XRD)
    static let paddingFieldLabel = L10n.tr("Localizable", "customizeNetworkFees_paddingFieldLabel", fallback: "Adjust Fee Padding Amount (XRD)")
    /// Paid by dApps
    static let paidByDApps = L10n.tr("Localizable", "customizeNetworkFees_paidByDApps", fallback: "Paid by dApps")
    /// Pay fee from
    static let payFeeFrom = L10n.tr("Localizable", "customizeNetworkFees_payFeeFrom", fallback: "Pay fee from")
    /// Royalties
    static let royalties = L10n.tr("Localizable", "customizeNetworkFees_royalties", fallback: "Royalties")
    /// Royalty fee
    static let royaltyFee = L10n.tr("Localizable", "customizeNetworkFees_royaltyFee", fallback: "Royalty fee")
    /// (%% of Execution + Finalization Fees)
    static let tipFieldInfo = L10n.tr("Localizable", "customizeNetworkFees_tipFieldInfo", fallback: "(%% of Execution + Finalization Fees)")
    /// Adjust Tip to Lock
    static let tipFieldLabel = L10n.tr("Localizable", "customizeNetworkFees_tipFieldLabel", fallback: "Adjust Tip to Lock")
    /// Transaction Fee
    static let totalFee = L10n.tr("Localizable", "customizeNetworkFees_totalFee", fallback: "Transaction Fee")
    /// View Advanced Mode
    static let viewAdvancedModeButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_viewAdvancedModeButtonTitle", fallback: "View Advanced Mode")
    /// View Normal Mode
    static let viewNormalModeButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_viewNormalModeButtonTitle", fallback: "View Normal Mode")
    enum AdvancedMode {
      /// Fully customize fee payment for this transaction. Not recomended unless you are a developer or advanced user.
      static let subtitle = L10n.tr("Localizable", "customizeNetworkFees_advancedMode_subtitle", fallback: "Fully customize fee payment for this transaction. Not recomended unless you are a developer or advanced user.")
      /// Advanced Customize Fees
      static let title = L10n.tr("Localizable", "customizeNetworkFees_advancedMode_title", fallback: "Advanced Customize Fees")
    }
    enum NormalMode {
      /// Choose what account to pay the transaction fee from, or add a "tip" to speed up your transaction if necessary.
      static let subtitle = L10n.tr("Localizable", "customizeNetworkFees_normalMode_subtitle", fallback: "Choose what account to pay the transaction fee from, or add a \"tip\" to speed up your transaction if necessary.")
      /// Customize Fees
      static let title = L10n.tr("Localizable", "customizeNetworkFees_normalMode_title", fallback: "Customize Fees")
    }
    enum SelectFeePayer {
      /// Select Fee Payer
      static let navigationTitle = L10n.tr("Localizable", "customizeNetworkFees_selectFeePayer_navigationTitle", fallback: "Select Fee Payer")
      /// Select Account
      static let selectAccountButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_selectFeePayer_selectAccountButtonTitle", fallback: "Select Account")
      /// Select an account to pay %@ XRD transaction fee
      static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "customizeNetworkFees_selectFeePayer_subtitle", String(describing: p1), fallback: "Select an account to pay %@ XRD transaction fee")
      }
    }
    enum TotalFee {
      /// (maximum to lock)
      static let info = L10n.tr("Localizable", "customizeNetworkFees_totalFee_info", fallback: "(maximum to lock)")
    }
    enum Warning {
      /// Not enough XRD for transaction fee
      static let insufficientBalance = L10n.tr("Localizable", "customizeNetworkFees_warning_insufficientBalance", fallback: "Not enough XRD for transaction fee")
      /// Please select a fee payer for the transaction fee
      static let selectFeePayer = L10n.tr("Localizable", "customizeNetworkFees_warning_selectFeePayer", fallback: "Please select a fee payer for the transaction fee")
    }
  }
  enum DAppRequest {
    /// Loading…
    static let metadataLoadingPrompt = L10n.tr("Localizable", "dAppRequest_metadataLoadingPrompt", fallback: "Loading…")
    enum AccountPermission {
      /// Continue
      static let `continue` = L10n.tr("Localizable", "dAppRequest_accountPermission_continue", fallback: "Continue")
      /// %d or more accounts
      static func numberOfAccountsAtLeast(_ p1: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsAtLeast", p1, fallback: "%d or more accounts")
      }
      /// Any number of accounts
      static let numberOfAccountsAtLeastZero = L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsAtLeastZero", fallback: "Any number of accounts")
      /// %d accounts
      static func numberOfAccountsExactly(_ p1: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsExactly", p1, fallback: "%d accounts")
      }
      /// 1 account
      static let numberOfAccountsExactlyOne = L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsExactlyOne", fallback: "1 account")
      /// **%@** is requesting permission to *always* be able to view Account information when you login with this Persona.
      static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_subtitle", String(describing: p1), fallback: "**%@** is requesting permission to *always* be able to view Account information when you login with this Persona.")
      }
      /// Account Permission
      static let title = L10n.tr("Localizable", "dAppRequest_accountPermission_title", fallback: "Account Permission")
      /// You can update this permission in wallet settings for this dApp at any time.
      static let updateInSettingsExplanation = L10n.tr("Localizable", "dAppRequest_accountPermission_updateInSettingsExplanation", fallback: "You can update this permission in wallet settings for this dApp at any time.")
    }
    enum AccountsProofOfOwnership {
      /// **%@** is requesting verification that you own the following Account(s).
      static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountsProofOfOwnership_subtitle", String(describing: p1), fallback: "**%@** is requesting verification that you own the following Account(s).")
      }
      /// Verify Account Ownership
      static let title = L10n.tr("Localizable", "dAppRequest_accountsProofOfOwnership_title", fallback: "Verify Account Ownership")
    }
    enum ChooseAccounts {
      /// Continue
      static let `continue` = L10n.tr("Localizable", "dAppRequest_chooseAccounts_continue", fallback: "Continue")
      /// Create a New Account
      static let createNewAccount = L10n.tr("Localizable", "dAppRequest_chooseAccounts_createNewAccount", fallback: "Create a New Account")
      /// You are now connected to %@. You can change your preferences for this dApp in wallet settings at any time.
      static func successMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccounts_successMessage", String(describing: p1), fallback: "You are now connected to %@. You can change your preferences for this dApp in wallet settings at any time.")
      }
      /// dApp Connection Successful
      static let successTitle = L10n.tr("Localizable", "dAppRequest_chooseAccounts_successTitle", fallback: "dApp Connection Successful")
      /// DApp error
      static let verificationErrorTitle = L10n.tr("Localizable", "dAppRequest_chooseAccounts_verificationErrorTitle", fallback: "DApp error")
    }
    enum ChooseAccountsOneTime {
      /// **%@** is making a one-time request for at least %d accounts.
      static func subtitleAtLeast(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeast", String(describing: p1), p2, fallback: "**%@** is making a one-time request for at least %d accounts.")
      }
      /// **%@** is making a one-time request for at least 1 account.
      static func subtitleAtLeastOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastOne", String(describing: p1), fallback: "**%@** is making a one-time request for at least 1 account.")
      }
      /// **%@** is making a one-time request for any number of accounts.
      static func subtitleAtLeastZero(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastZero", String(describing: p1), fallback: "**%@** is making a one-time request for any number of accounts.")
      }
      /// **%@** is making a one-time request for %d accounts.
      static func subtitleExactly(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactly", String(describing: p1), p2, fallback: "**%@** is making a one-time request for %d accounts.")
      }
      /// **%@** is making a one-time request for 1 account.
      static func subtitleExactlyOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactlyOne", String(describing: p1), fallback: "**%@** is making a one-time request for 1 account.")
      }
      /// Account Request
      static let title = L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_title", fallback: "Account Request")
    }
    enum ChooseAccountsOngoing {
      /// Choose at least %d accounts you wish to use with **%@**.
      static func subtitleAtLeast(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeast", p1, String(describing: p2), fallback: "Choose at least %d accounts you wish to use with **%@**.")
      }
      /// Choose at least 1 account you wish to use with **%@**.
      static func subtitleAtLeastOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastOne", String(describing: p1), fallback: "Choose at least 1 account you wish to use with **%@**.")
      }
      /// Choose any accounts you wish to use with **%@**.
      static func subtitleAtLeastZero(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastZero", String(describing: p1), fallback: "Choose any accounts you wish to use with **%@**.")
      }
      /// Choose %d accounts you wish to use with **%@**.
      static func subtitleExactly(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactly", p1, String(describing: p2), fallback: "Choose %d accounts you wish to use with **%@**.")
      }
      /// Choose 1 account you wish to use with **%@**.
      static func subtitleExactlyOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactlyOne", String(describing: p1), fallback: "Choose 1 account you wish to use with **%@**.")
      }
      /// Account Permission
      static let title = L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_title", fallback: "Account Permission")
    }
    enum Completion {
      /// Request from %@ complete
      static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_completion_subtitle", String(describing: p1), fallback: "Request from %@ complete")
      }
      /// Success
      static let title = L10n.tr("Localizable", "dAppRequest_completion_title", fallback: "Success")
    }
    enum Login {
      /// Choose a Persona
      static let choosePersona = L10n.tr("Localizable", "dAppRequest_login_choosePersona", fallback: "Choose a Persona")
      /// Continue
      static let `continue` = L10n.tr("Localizable", "dAppRequest_login_continue", fallback: "Continue")
      /// Your last login was on %@
      static func lastLoginWasOn(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_lastLoginWasOn", String(describing: p1), fallback: "Your last login was on %@")
      }
      /// **%@** is requesting that you login with a Persona.
      static func subtitleKnownDapp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_subtitleKnownDapp", String(describing: p1), fallback: "**%@** is requesting that you login with a Persona.")
      }
      /// **%@** is requesting that you login for the first time with a Persona.
      static func subtitleNewDapp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_subtitleNewDapp", String(describing: p1), fallback: "**%@** is requesting that you login for the first time with a Persona.")
      }
      /// Login Request
      static let titleKnownDapp = L10n.tr("Localizable", "dAppRequest_login_titleKnownDapp", fallback: "Login Request")
      /// New Login Request
      static let titleNewDapp = L10n.tr("Localizable", "dAppRequest_login_titleNewDapp", fallback: "New Login Request")
    }
    enum Metadata {
      /// Unknown dApp
      static let unknownName = L10n.tr("Localizable", "dAppRequest_metadata_unknownName", fallback: "Unknown dApp")
      /// Radix Wallet
      static let wallet = L10n.tr("Localizable", "dAppRequest_metadata_wallet", fallback: "Radix Wallet")
    }
    enum MetadataLoadingAlert {
      /// Danger! Bad dApp configuration, or you're being spoofed!
      static let message = L10n.tr("Localizable", "dAppRequest_metadataLoadingAlert_message", fallback: "Danger! Bad dApp configuration, or you're being spoofed!")
    }
    enum PersonaProofOfOwnership {
      /// **%@** is requesting verification of your login with the following Persona.
      static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personaProofOfOwnership_subtitle", String(describing: p1), fallback: "**%@** is requesting verification of your login with the following Persona.")
      }
      /// Verify Persona Login
      static let title = L10n.tr("Localizable", "dAppRequest_personaProofOfOwnership_title", fallback: "Verify Persona Login")
    }
    enum PersonalDataBox {
      /// Edit
      static let edit = L10n.tr("Localizable", "dAppRequest_personalDataBox_edit", fallback: "Edit")
      /// Required information:
      static let requiredInformation = L10n.tr("Localizable", "dAppRequest_personalDataBox_requiredInformation", fallback: "Required information:")
    }
    enum PersonalDataOneTime {
      /// Choose the data to provide
      static let chooseDataToProvide = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_chooseDataToProvide", fallback: "Choose the data to provide")
      /// Continue
      static let `continue` = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_continue", fallback: "Continue")
      /// **%@** is requesting that you provide some pieces of personal data **just one time**
      static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataOneTime_subtitle", String(describing: p1), fallback: "**%@** is requesting that you provide some pieces of personal data **just one time**")
      }
      /// One-Time Data Request
      static let title = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_title", fallback: "One-Time Data Request")
    }
    enum PersonalDataPermission {
      /// Continue
      static let `continue` = L10n.tr("Localizable", "dAppRequest_personalDataPermission_continue", fallback: "Continue")
      /// **%@** is requesting permission to **always** be able to view the following personal data when you login with this Persona.
      static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataPermission_subtitle", String(describing: p1), fallback: "**%@** is requesting permission to **always** be able to view the following personal data when you login with this Persona.")
      }
      /// Personal Data Permission
      static let title = L10n.tr("Localizable", "dAppRequest_personalDataPermission_title", fallback: "Personal Data Permission")
      /// You can update this permission in your Settings at any time.
      static let updateInSettingsExplanation = L10n.tr("Localizable", "dAppRequest_personalDataPermission_updateInSettingsExplanation", fallback: "You can update this permission in your Settings at any time.")
    }
    enum RequestMalformedAlert {
      /// Request received from dApp is invalid.
      static let message = L10n.tr("Localizable", "dAppRequest_requestMalformedAlert_message", fallback: "Request received from dApp is invalid.")
    }
    enum RequestPersonaNotFoundAlert {
      /// dApp specified an invalid Persona.
      static let message = L10n.tr("Localizable", "dAppRequest_requestPersonaNotFoundAlert_message", fallback: "dApp specified an invalid Persona.")
    }
    enum RequestWrongNetworkAlert {
      /// dApp made a request intended for network %@, but you are currently connected to %@.
      static func message(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_requestWrongNetworkAlert_message", String(describing: p1), String(describing: p2), fallback: "dApp made a request intended for network %@, but you are currently connected to %@.")
      }
    }
    enum ResponseFailureAlert {
      /// Failed to send request response to dApp.
      static let message = L10n.tr("Localizable", "dAppRequest_responseFailureAlert_message", fallback: "Failed to send request response to dApp.")
    }
    enum ValidationOutcome {
      /// Invalid value of `numberOfAccountsInvalid`: must not be `exactly(0)` nor can `quantity` be negative
      static let devExplanationBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationBadContent", fallback: "Invalid value of `numberOfAccountsInvalid`: must not be `exactly(0)` nor can `quantity` be negative")
      /// %@ (CE: %@, wallet: %@)
      static func devExplanationIncompatibleVersion(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationIncompatibleVersion", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "%@ (CE: %@, wallet: %@)")
      }
      /// '%@' is not valid account address.
      static func devExplanationInvalidDappDefinitionAddress(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationInvalidDappDefinitionAddress", String(describing: p1), fallback: "'%@' is not valid account address.")
      }
      /// '%@' is not valid origin.
      static func devExplanationInvalidOrigin(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationInvalidOrigin", String(describing: p1), fallback: "'%@' is not valid origin.")
      }
      /// dApp specified an invalid Persona or Account
      static let invalidPersonaOrAccoubts = L10n.tr("Localizable", "dAppRequest_validationOutcome_invalidPersonaOrAccoubts", fallback: "dApp specified an invalid Persona or Account")
      /// Could not validate the dApp.
      static let invalidRequestMessage = L10n.tr("Localizable", "dAppRequest_validationOutcome_invalidRequestMessage", fallback: "Could not validate the dApp.")
      /// Invalid Request.
      static let invalidRequestTitle = L10n.tr("Localizable", "dAppRequest_validationOutcome_invalidRequestTitle", fallback: "Invalid Request.")
      /// Invalid data in request
      static let shortExplanationBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationBadContent", fallback: "Invalid data in request")
      /// Please update Radix Wallet
      static let shortExplanationIncompatibleVersionCEGreater = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationIncompatibleVersionCEGreater", fallback: "Please update Radix Wallet")
      /// Please update Radix Connector browser extension
      static let shortExplanationIncompatibleVersionCENotGreater = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationIncompatibleVersionCENotGreater", fallback: "Please update Radix Connector browser extension")
      /// Invalid dApp Definition Address
      static let shortExplanationInvalidDappDefinitionAddress = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationInvalidDappDefinitionAddress", fallback: "Invalid dApp Definition Address")
      /// Invalid origin
      static let shortExplanationInvalidOrigin = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationInvalidOrigin", fallback: "Invalid origin")
      /// Radix Connect connection error
      static let shortExplanationP2PError = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationP2PError", fallback: "Radix Connect connection error")
      /// Invalid content
      static let subtitleBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_subtitleBadContent", fallback: "Invalid content")
      /// Incompatible connector extension
      static let subtitleIncompatibleVersion = L10n.tr("Localizable", "dAppRequest_validationOutcome_subtitleIncompatibleVersion", fallback: "Incompatible connector extension")
      /// Network mismatch
      static let subtitleWrongNetworkID = L10n.tr("Localizable", "dAppRequest_validationOutcome_subtitleWrongNetworkID", fallback: "Network mismatch")
    }
  }
  enum DisplayMnemonics {
    /// Write Down this Seed Phrase
    static let backUpWarning = L10n.tr("Localizable", "displayMnemonics_backUpWarning", fallback: "Write Down this Seed Phrase")
    /// Begin seed phrase entry
    static let seedPhraseEntryWarning = L10n.tr("Localizable", "displayMnemonics_seedPhraseEntryWarning", fallback: "Begin seed phrase entry")
    /// Seed Phrases
    static let seedPhrases = L10n.tr("Localizable", "displayMnemonics_seedPhrases", fallback: "Seed Phrases")
    /// You are responsible for the security of your Seed Phrase
    static let seedPhraseSecurityInfo = L10n.tr("Localizable", "displayMnemonics_seedPhraseSecurityInfo", fallback: "You are responsible for the security of your Seed Phrase")
    enum CautionAlert {
      /// A seed phrase provides full control of its Accounts. Do not view in a area. Write down the seed phrase words securely. Screenshots are disabled.
      static let message = L10n.tr("Localizable", "displayMnemonics_cautionAlert_message", fallback: "A seed phrase provides full control of its Accounts. Do not view in a area. Write down the seed phrase words securely. Screenshots are disabled.")
      /// Reveal Seed Phrase
      static let revealButtonLabel = L10n.tr("Localizable", "displayMnemonics_cautionAlert_revealButtonLabel", fallback: "Reveal Seed Phrase")
      /// Use Caution
      static let title = L10n.tr("Localizable", "displayMnemonics_cautionAlert_title", fallback: "Use Caution")
    }
    enum ConnectedAccountsLabel {
      /// Connected to %d Accounts
      static func many(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsLabel_many", p1, fallback: "Connected to %d Accounts")
      }
      /// Connected to %d Account
      static func one(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsLabel_one", p1, fallback: "Connected to %d Account")
      }
    }
    enum ConnectedAccountsPersonasLabel {
      /// Connected to Personas and to %d Accounts
      static func many(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsPersonasLabel_many", p1, fallback: "Connected to Personas and to %d Accounts")
      }
      /// Connected to Personas and %d Account
      static func one(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsPersonasLabel_one", p1, fallback: "Connected to Personas and %d Account")
      }
    }
  }
  enum EditPersona {
    /// Add a Field
    static let addAField = L10n.tr("Localizable", "editPersona_addAField", fallback: "Add a Field")
    /// Required by dApp
    static let requiredByDapp = L10n.tr("Localizable", "editPersona_requiredByDapp", fallback: "Required by dApp")
    /// The following information can be seen if requested by the dApp
    static let sharedInformationHeading = L10n.tr("Localizable", "editPersona_sharedInformationHeading", fallback: "The following information can be seen if requested by the dApp")
    enum AddAField {
      /// Add Data Fields
      static let add = L10n.tr("Localizable", "editPersona_addAField_add", fallback: "Add Data Fields")
      /// Choose one or more data fields to add to this Persona.
      static let subtitle = L10n.tr("Localizable", "editPersona_addAField_subtitle", fallback: "Choose one or more data fields to add to this Persona.")
      /// Add a Field
      static let title = L10n.tr("Localizable", "editPersona_addAField_title", fallback: "Add a Field")
    }
    enum CloseConfirmationDialog {
      /// Discard Changes
      static let discardChanges = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_discardChanges", fallback: "Discard Changes")
      /// Keep Editing
      static let keepEditing = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_keepEditing", fallback: "Keep Editing")
      /// Are you sure you want to discard changes to this Persona?
      static let message = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_message", fallback: "Are you sure you want to discard changes to this Persona?")
    }
    enum Error {
      /// Label cannot be blank
      static let blank = L10n.tr("Localizable", "editPersona_error_blank", fallback: "Label cannot be blank")
      /// Invalid email address
      static let invalidEmailAddress = L10n.tr("Localizable", "editPersona_error_invalidEmailAddress", fallback: "Invalid email address")
      /// Required field for this dApp
      static let requiredByDapp = L10n.tr("Localizable", "editPersona_error_requiredByDapp", fallback: "Required field for this dApp")
    }
  }
  enum EncryptProfileBackup {
    enum ConfirmPasswordField {
      /// Passwords do not match
      static let error = L10n.tr("Localizable", "encryptProfileBackup_confirmPasswordField_error", fallback: "Passwords do not match")
      /// Confirm password
      static let placeholder = L10n.tr("Localizable", "encryptProfileBackup_confirmPasswordField_placeholder", fallback: "Confirm password")
    }
    enum EnterPasswordField {
      /// Enter password
      static let placeholder = L10n.tr("Localizable", "encryptProfileBackup_enterPasswordField_placeholder", fallback: "Enter password")
    }
    enum Header {
      /// Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.
      static let subtitle = L10n.tr("Localizable", "encryptProfileBackup_header_subtitle", fallback: "Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.")
      /// Encrypt Wallet Backup File
      static let title = L10n.tr("Localizable", "encryptProfileBackup_header_title", fallback: "Encrypt Wallet Backup File")
    }
  }
  enum EnterSeedPhrase {
    /// Enter Babylon Seed Phrase
    static let titleBabylon = L10n.tr("Localizable", "enterSeedPhrase_titleBabylon", fallback: "Enter Babylon Seed Phrase")
    /// Enter Main Seed Phrase
    static let titleBabylonMain = L10n.tr("Localizable", "enterSeedPhrase_titleBabylonMain", fallback: "Enter Main Seed Phrase")
    /// Enter Olympia Seed Phrase
    static let titleOlympia = L10n.tr("Localizable", "enterSeedPhrase_titleOlympia", fallback: "Enter Olympia Seed Phrase")
    /// For your safety, make sure no one is looking at your screen. Never give your seed phrase to anyone for any reason.
    static let warning = L10n.tr("Localizable", "enterSeedPhrase_warning", fallback: "For your safety, make sure no one is looking at your screen. Never give your seed phrase to anyone for any reason.")
    enum Header {
      /// Enter Seed Phrase
      static let title = L10n.tr("Localizable", "enterSeedPhrase_header_title", fallback: "Enter Seed Phrase")
      /// Enter Main Seed Phrase
      static let titleMain = L10n.tr("Localizable", "enterSeedPhrase_header_titleMain", fallback: "Enter Main Seed Phrase")
    }
  }
  enum Error {
    /// Email Support
    static let emailSupportButtonTitle = L10n.tr("Localizable", "error_emailSupportButtonTitle", fallback: "Email Support")
    /// Please email support to automatically provide debugging info, and get assistance.
    /// Code: %@
    static func emailSupportMessage(_ p1: Any) -> String {
      return L10n.tr("Localizable", "error_emailSupportMessage", String(describing: p1), fallback: "Please email support to automatically provide debugging info, and get assistance.\nCode: %@")
    }
    enum AccountLabel {
      /// Account label required
      static let missing = L10n.tr("Localizable", "error_accountLabel_missing", fallback: "Account label required")
      /// Account label too long
      static let tooLong = L10n.tr("Localizable", "error_accountLabel_tooLong", fallback: "Account label too long")
    }
    enum DappRequest {
      /// Invalid Persona specified by dApp
      static let invalidPersonaId = L10n.tr("Localizable", "error_dappRequest_invalidPersonaId", fallback: "Invalid Persona specified by dApp")
      /// Invalid request
      static let invalidRequest = L10n.tr("Localizable", "error_dappRequest_invalidRequest", fallback: "Invalid request")
    }
    enum PersonaLabel {
      /// Persona label too long
      static let tooLong = L10n.tr("Localizable", "error_personaLabel_tooLong", fallback: "Persona label too long")
    }
    enum ProfileLoad {
      /// Failed to import Radix Wallet backup: %@
      static func decodingError(_ p1: Any) -> String {
        return L10n.tr("Localizable", "error_profileLoad_decodingError", String(describing: p1), fallback: "Failed to import Radix Wallet backup: %@")
      }
      /// Failed to import Radix Wallet backup, error: %@, version: %@
      static func failedToCreateProfileFromSnapshot(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "error_profileLoad_failedToCreateProfileFromSnapshot", String(describing: p1), String(describing: p2), fallback: "Failed to import Radix Wallet backup, error: %@, version: %@")
      }
    }
    enum TransactionFailure {
      /// Your current Ledger settings only allow signing of simple token transfers. Please either enable "verbose mode" (to see full transaction manifests) or "blind signing mode" (to enable signing of complex transaction manifest hashes) on your Ledger app device.
      static let blindSigningNotEnabledButRequired = L10n.tr("Localizable", "error_transactionFailure_blindSigningNotEnabledButRequired", fallback: "Your current Ledger settings only allow signing of simple token transfers. Please either enable \"verbose mode\" (to see full transaction manifests) or \"blind signing mode\" (to enable signing of complex transaction manifest hashes) on your Ledger app device.")
      /// Failed to commit transaction
      static let commit = L10n.tr("Localizable", "error_transactionFailure_commit", fallback: "Failed to commit transaction")
      /// One of the receiving accounts does not allow Third-Party deposits
      static let doesNotAllowThirdPartyDeposits = L10n.tr("Localizable", "error_transactionFailure_doesNotAllowThirdPartyDeposits", fallback: "One of the receiving accounts does not allow Third-Party deposits")
      /// Failed to convert transaction manifest
      static let duplicate = L10n.tr("Localizable", "error_transactionFailure_duplicate", fallback: "Failed to convert transaction manifest")
      /// Failed to get epoch
      static let epoch = L10n.tr("Localizable", "error_transactionFailure_epoch", fallback: "Failed to get epoch")
      /// Failed to add Guarantee, try a different percentage, or try skip adding a guarantee.
      static let failedToAddGuarantee = L10n.tr("Localizable", "error_transactionFailure_failedToAddGuarantee", fallback: "Failed to add Guarantee, try a different percentage, or try skip adding a guarantee.")
      /// Failed to add Transaction Fee, try a different amount of fee payer.
      static let failedToAddLockFee = L10n.tr("Localizable", "error_transactionFailure_failedToAddLockFee", fallback: "Failed to add Transaction Fee, try a different amount of fee payer.")
      /// Failed to find ledger
      static let failedToFindLedger = L10n.tr("Localizable", "error_transactionFailure_failedToFindLedger", fallback: "Failed to find ledger")
      /// Failed to build transaction header
      static let header = L10n.tr("Localizable", "error_transactionFailure_header", fallback: "Failed to build transaction header")
      /// Failed to convert transaction manifest
      static let manifest = L10n.tr("Localizable", "error_transactionFailure_manifest", fallback: "Failed to convert transaction manifest")
      /// You don't have access to some accounts or personas required to authorise this transaction
      static let missingSigners = L10n.tr("Localizable", "error_transactionFailure_missingSigners", fallback: "You don't have access to some accounts or personas required to authorise this transaction")
      /// Wrong network
      static let network = L10n.tr("Localizable", "error_transactionFailure_network", fallback: "Wrong network")
      /// No funds to approve transaction
      static let noFundsToApproveTransaction = L10n.tr("Localizable", "error_transactionFailure_noFundsToApproveTransaction", fallback: "No funds to approve transaction")
      /// Failed to poll transaction status
      static let pollStatus = L10n.tr("Localizable", "error_transactionFailure_pollStatus", fallback: "Failed to poll transaction status")
      /// Failed to prepare transaction
      static let prepare = L10n.tr("Localizable", "error_transactionFailure_prepare", fallback: "Failed to prepare transaction")
      /// Transaction rejected
      static let rejected = L10n.tr("Localizable", "error_transactionFailure_rejected", fallback: "Transaction rejected")
      /// Failed to convert transaction manifest
      static let rejectedByUser = L10n.tr("Localizable", "error_transactionFailure_rejectedByUser", fallback: "Failed to convert transaction manifest")
      /// A proposed transaction could not be processed.
      static let reviewFailure = L10n.tr("Localizable", "error_transactionFailure_reviewFailure", fallback: "A proposed transaction could not be processed.")
      /// Failed to submit transaction
      static let submit = L10n.tr("Localizable", "error_transactionFailure_submit", fallback: "Failed to submit transaction")
      /// Unknown error
      static let unknown = L10n.tr("Localizable", "error_transactionFailure_unknown", fallback: "Unknown error")
    }
  }
  enum FactorSourceActions {
    enum CreateAccount {
      /// Creating Account
      static let title = L10n.tr("Localizable", "factorSourceActions_createAccount_title", fallback: "Creating Account")
    }
    enum CreateKey {
      /// Creating Key
      static let title = L10n.tr("Localizable", "factorSourceActions_createKey_title", fallback: "Creating Key")
    }
    enum CreatePersona {
      /// Creating Persona
      static let title = L10n.tr("Localizable", "factorSourceActions_createPersona_title", fallback: "Creating Persona")
    }
    enum DeriveAccounts {
      /// Deriving Accounts
      static let title = L10n.tr("Localizable", "factorSourceActions_deriveAccounts_title", fallback: "Deriving Accounts")
    }
    enum Device {
      /// Authenticate to your phone to complete using your phone's signing key.
      static let message = L10n.tr("Localizable", "factorSourceActions_device_message", fallback: "Authenticate to your phone to complete using your phone's signing key.")
      /// Authenticate to your phone to sign.
      static let messageSignature = L10n.tr("Localizable", "factorSourceActions_device_messageSignature", fallback: "Authenticate to your phone to sign.")
    }
    enum EncryptMessage {
      /// Encrypting Message
      static let title = L10n.tr("Localizable", "factorSourceActions_encryptMessage_title", fallback: "Encrypting Message")
    }
    enum Ledger {
      /// Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.
      static let message = L10n.tr("Localizable", "factorSourceActions_ledger_message", fallback: "Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.")
      /// Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.
      /// **Derivation may take up to a minute.**
      static let messageDeriveAccounts = L10n.tr("Localizable", "factorSourceActions_ledger_messageDeriveAccounts", fallback: "Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.\n**Derivation may take up to a minute.**")
      /// Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.
      /// **Complete signing on the device.**
      static let messageSignature = L10n.tr("Localizable", "factorSourceActions_ledger_messageSignature", fallback: "Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.\n**Complete signing on the device.**")
    }
    enum ProveOwnership {
      /// Proving Ownership
      static let title = L10n.tr("Localizable", "factorSourceActions_proveOwnership_title", fallback: "Proving Ownership")
    }
    enum Signature {
      /// Signature Request
      static let title = L10n.tr("Localizable", "factorSourceActions_signature_title", fallback: "Signature Request")
    }
  }
  enum FactorSources {
    enum Kind {
      /// Phone
      static let device = L10n.tr("Localizable", "factorSources_kind_device", fallback: "Phone")
      /// Ledger
      static let ledgerHQHardwareWallet = L10n.tr("Localizable", "factorSources_kind_ledgerHQHardwareWallet", fallback: "Ledger")
      /// Seed phrase
      static let offDeviceMnemonic = L10n.tr("Localizable", "factorSources_kind_offDeviceMnemonic", fallback: "Seed phrase")
      /// Security Questions
      static let securityQuestions = L10n.tr("Localizable", "factorSources_kind_securityQuestions", fallback: "Security Questions")
      /// Third-party
      static let trustedContact = L10n.tr("Localizable", "factorSources_kind_trustedContact", fallback: "Third-party")
    }
  }
  enum FactoryReset {
    /// Once you’ve completed a factory reset, you will not be able to access your Accounts and Personas unless you do a full recovery.
    static let disclosure = L10n.tr("Localizable", "factoryReset_disclosure", fallback: "Once you’ve completed a factory reset, you will not be able to access your Accounts and Personas unless you do a full recovery.")
    /// A factory reset will restore your Radix wallet to its original settings. All of your data and preferences will be erased.
    static let message = L10n.tr("Localizable", "factoryReset_message", fallback: "A factory reset will restore your Radix wallet to its original settings. All of your data and preferences will be erased.")
    /// Your wallet is recoverable
    static let recoverable = L10n.tr("Localizable", "factoryReset_recoverable", fallback: "Your wallet is recoverable")
    /// Reset Wallet
    static let resetWallet = L10n.tr("Localizable", "factoryReset_resetWallet", fallback: "Reset Wallet")
    /// Security Center status
    static let status = L10n.tr("Localizable", "factoryReset_status", fallback: "Security Center status")
    /// Factory Reset
    static let title = L10n.tr("Localizable", "factoryReset_title", fallback: "Factory Reset")
    enum Dialog {
      /// Return wallet to factory settings? You cannot undo this.
      static let message = L10n.tr("Localizable", "factoryReset_dialog_message", fallback: "Return wallet to factory settings? You cannot undo this.")
      /// Confirm factory reset
      static let title = L10n.tr("Localizable", "factoryReset_dialog_title", fallback: "Confirm factory reset")
    }
    enum Unrecoverable {
      /// Your wallet is currently unrecoverable. If you do a factory reset now, you will never be able to access your Accounts and Personas again.
      static let message = L10n.tr("Localizable", "factoryReset_unrecoverable_message", fallback: "Your wallet is currently unrecoverable. If you do a factory reset now, you will never be able to access your Accounts and Personas again.")
      /// Your wallet is not recoverable
      static let title = L10n.tr("Localizable", "factoryReset_unrecoverable_title", fallback: "Your wallet is not recoverable")
    }
  }
  enum Gateways {
    /// Add New Gateway
    static let addNewGatewayButtonTitle = L10n.tr("Localizable", "gateways_addNewGatewayButtonTitle", fallback: "Add New Gateway")
    /// RCnet Gateway
    static let rcNetGateway = L10n.tr("Localizable", "gateways_rcNetGateway", fallback: "RCnet Gateway")
    /// Choose the gateway your wallet will use to connect to the Radix Network or test networks. Only change this if you know what you’re doing.
    static let subtitle = L10n.tr("Localizable", "gateways_subtitle", fallback: "Choose the gateway your wallet will use to connect to the Radix Network or test networks. Only change this if you know what you’re doing.")
    /// Gateways
    static let title = L10n.tr("Localizable", "gateways_title", fallback: "Gateways")
    enum AddNewGateway {
      /// Add Gateway
      static let addGatewayButtonTitle = L10n.tr("Localizable", "gateways_addNewGateway_addGatewayButtonTitle", fallback: "Add Gateway")
      /// This gateway is already added
      static let errorDuplicateURL = L10n.tr("Localizable", "gateways_addNewGateway_errorDuplicateURL", fallback: "This gateway is already added")
      /// No gateway found at specified URL
      static let errorNoGatewayFound = L10n.tr("Localizable", "gateways_addNewGateway_errorNoGatewayFound", fallback: "No gateway found at specified URL")
      /// There was an error establishing a connection
      static let establishingConnectionErrorMessage = L10n.tr("Localizable", "gateways_addNewGateway_establishingConnectionErrorMessage", fallback: "There was an error establishing a connection")
      /// Enter a gateway URL
      static let subtitle = L10n.tr("Localizable", "gateways_addNewGateway_subtitle", fallback: "Enter a gateway URL")
      /// Enter full URL
      static let textFieldPlaceholder = L10n.tr("Localizable", "gateways_addNewGateway_textFieldPlaceholder", fallback: "Enter full URL")
      /// Add New Gateway
      static let title = L10n.tr("Localizable", "gateways_addNewGateway_title", fallback: "Add New Gateway")
    }
    enum RemoveGatewayAlert {
      /// You will no longer be able to connect to this gateway.
      static let message = L10n.tr("Localizable", "gateways_removeGatewayAlert_message", fallback: "You will no longer be able to connect to this gateway.")
      /// Remove Gateway
      static let title = L10n.tr("Localizable", "gateways_removeGatewayAlert_title", fallback: "Remove Gateway")
    }
  }
  enum HiddenAssets {
    /// Tokens
    static let fungibles = L10n.tr("Localizable", "hiddenAssets_fungibles", fallback: "Tokens")
    /// NFTs
    static let nonFungibles = L10n.tr("Localizable", "hiddenAssets_nonFungibles", fallback: "NFTs")
    /// Pool Units
    static let poolUnits = L10n.tr("Localizable", "hiddenAssets_poolUnits", fallback: "Pool Units")
    /// You have hidden the following assets. While hidden, you will not see these in any of your Accounts.
    static let text = L10n.tr("Localizable", "hiddenAssets_text", fallback: "You have hidden the following assets. While hidden, you will not see these in any of your Accounts.")
    /// Hidden Assets
    static let title = L10n.tr("Localizable", "hiddenAssets_title", fallback: "Hidden Assets")
    /// Unhide
    static let unhide = L10n.tr("Localizable", "hiddenAssets_unhide", fallback: "Unhide")
    enum NonFungibles {
      /// %d in this collection
      static func count(_ p1: Int) -> String {
        return L10n.tr("Localizable", "hiddenAssets_nonFungibles_count", p1, fallback: "%d in this collection")
      }
    }
    enum UnhideConfirmation {
      /// Make this asset visible in your Accounts again?
      static let asset = L10n.tr("Localizable", "hiddenAssets_unhideConfirmation_asset", fallback: "Make this asset visible in your Accounts again?")
      /// Make this collection visible in your Accounts again?
      static let collection = L10n.tr("Localizable", "hiddenAssets_unhideConfirmation_collection", fallback: "Make this collection visible in your Accounts again?")
    }
  }
  enum HiddenEntities {
    /// Accounts
    static let accounts = L10n.tr("Localizable", "hiddenEntities_accounts", fallback: "Accounts")
    /// Personas
    static let personas = L10n.tr("Localizable", "hiddenEntities_personas", fallback: "Personas")
    /// You have hidden the following Personas and Accounts. They remain on the Radix Network, but while hidden, your wallet will treat them as if they don’t exist.
    static let text = L10n.tr("Localizable", "hiddenEntities_text", fallback: "You have hidden the following Personas and Accounts. They remain on the Radix Network, but while hidden, your wallet will treat them as if they don’t exist.")
    /// Hidden Personas & Accounts
    static let title = L10n.tr("Localizable", "hiddenEntities_title", fallback: "Hidden Personas & Accounts")
    /// Unhide
    static let unhide = L10n.tr("Localizable", "hiddenEntities_unhide", fallback: "Unhide")
    /// Make this Account visible in your wallet again?
    static let unhideAccountsConfirmation = L10n.tr("Localizable", "hiddenEntities_unhideAccountsConfirmation", fallback: "Make this Account visible in your wallet again?")
    /// Make this Persona visible in your wallet again?
    static let unhidePersonasConfirmation = L10n.tr("Localizable", "hiddenEntities_unhidePersonasConfirmation", fallback: "Make this Persona visible in your wallet again?")
  }
  enum HomePage {
    /// %@ has a deposit for you to claim
    static func accountLockerClaim(_ p1: Any) -> String {
      return L10n.tr("Localizable", "homePage_accountLockerClaim", String(describing: p1), fallback: "%@ has a deposit for you to claim")
    }
    /// I have written down this seed phrase
    static let backedUpMnemonicHeading = L10n.tr("Localizable", "homePage_backedUpMnemonicHeading", fallback: "I have written down this seed phrase")
    /// Create a New Account
    static let createNewAccount = L10n.tr("Localizable", "homePage_createNewAccount", fallback: "Create a New Account")
    /// Legacy
    static let legacyAccountHeading = L10n.tr("Localizable", "homePage_legacyAccountHeading", fallback: "Legacy")
    /// Please write down seed phrase to ensure Account control
    static let securityPromptBackup = L10n.tr("Localizable", "homePage_securityPromptBackup", fallback: "Please write down seed phrase to ensure Account control")
    /// Seed phrase required - begin entry
    static let securityPromptRecover = L10n.tr("Localizable", "homePage_securityPromptRecover", fallback: "Seed phrase required - begin entry")
    /// Welcome. Here are all your Accounts on the Radix Network.
    static let subtitle = L10n.tr("Localizable", "homePage_subtitle", fallback: "Welcome. Here are all your Accounts on the Radix Network.")
    /// Radix Wallet
    static let title = L10n.tr("Localizable", "homePage_title", fallback: "Radix Wallet")
    /// Total value
    static let totalValue = L10n.tr("Localizable", "homePage_totalValue", fallback: "Total value")
    enum AccountsTag {
      /// dApp Definition
      static let dAppDefinition = L10n.tr("Localizable", "homePage_accountsTag_dAppDefinition", fallback: "dApp Definition")
      /// Ledger
      static let ledgerBabylon = L10n.tr("Localizable", "homePage_accountsTag_ledgerBabylon", fallback: "Ledger")
      /// Legacy (Ledger)
      static let ledgerLegacy = L10n.tr("Localizable", "homePage_accountsTag_ledgerLegacy", fallback: "Legacy (Ledger)")
      /// Legacy
      static let legacySoftware = L10n.tr("Localizable", "homePage_accountsTag_legacySoftware", fallback: "Legacy")
    }
    enum ProfileOlympiaError {
      /// Affected Accounts
      static let affectedAccounts = L10n.tr("Localizable", "homePage_profileOlympiaError_affectedAccounts", fallback: "Affected Accounts")
      /// Affected Personas
      static let affectedPersonas = L10n.tr("Localizable", "homePage_profileOlympiaError_affectedPersonas", fallback: "Affected Personas")
      /// OK (%d)
      static func okCountdown(_ p1: Int) -> String {
        return L10n.tr("Localizable", "homePage_profileOlympiaError_okCountdown", p1, fallback: "OK (%d)")
      }
      /// Your wallet is in a rare condition that must be resolved manually. Please email support at hello@radixdlt.com with subject line BDFS ERROR. Somebody will respond and help you resolve the issue safely.
      static let subtitle = L10n.tr("Localizable", "homePage_profileOlympiaError_subtitle", fallback: "Your wallet is in a rare condition that must be resolved manually. Please email support at hello@radixdlt.com with subject line BDFS ERROR. Somebody will respond and help you resolve the issue safely.")
      /// SERIOUS ERROR - PLEASE READ
      static let title = L10n.tr("Localizable", "homePage_profileOlympiaError_title", fallback: "SERIOUS ERROR - PLEASE READ")
    }
    enum RadixBanner {
      /// Get Started Now
      static let action = L10n.tr("Localizable", "homePage_radixBanner_action", fallback: "Get Started Now")
      /// Complete setting up your wallet and start staking, using dApps and more!
      static let subtitle = L10n.tr("Localizable", "homePage_radixBanner_subtitle", fallback: "Complete setting up your wallet and start staking, using dApps and more!")
      /// Start Using Radix
      static let title = L10n.tr("Localizable", "homePage_radixBanner_title", fallback: "Start Using Radix")
    }
    enum SecureFolder {
      /// Your wallet has encountered a problem that should be resolved before you continue use. If you have a Samsung phone, this may be caused by putting the Radix Wallet in the "Secure Folder". Please contact support at hello@radixdlt.com for assistance.
      static let warning = L10n.tr("Localizable", "homePage_secureFolder_warning", fallback: "Your wallet has encountered a problem that should be resolved before you continue use. If you have a Samsung phone, this may be caused by putting the Radix Wallet in the \"Secure Folder\". Please contact support at hello@radixdlt.com for assistance.")
    }
    enum VisitDashboard {
      /// Ready to get started using the Radix Network and your Wallet?
      static let subtitle = L10n.tr("Localizable", "homePage_visitDashboard_subtitle", fallback: "Ready to get started using the Radix Network and your Wallet?")
      /// Visit the Radix Dashboard
      static let title = L10n.tr("Localizable", "homePage_visitDashboard_title", fallback: "Visit the Radix Dashboard")
    }
  }
  enum HomePageCarousel {
    enum ContinueOnDapp {
      /// You can now connect with your Radix Wallet. Tap to dismiss.
      static let text = L10n.tr("Localizable", "homePageCarousel_continueOnDapp_text", fallback: "You can now connect with your Radix Wallet. Tap to dismiss.")
      /// Continue on dApp in browser
      static let title = L10n.tr("Localizable", "homePageCarousel_continueOnDapp_title", fallback: "Continue on dApp in browser")
    }
    enum DiscoverRadix {
      /// Start RadQuest, learn about Radix, earn XRD and collectibles.
      static let text = L10n.tr("Localizable", "homePageCarousel_discoverRadix_text", fallback: "Start RadQuest, learn about Radix, earn XRD and collectibles.")
      /// Discover Radix. Get XRD
      static let title = L10n.tr("Localizable", "homePageCarousel_discoverRadix_title", fallback: "Discover Radix. Get XRD")
    }
    enum RejoinRadquest {
      /// Continue your Radix journey in your browser. Tap to dismiss.
      static let text = L10n.tr("Localizable", "homePageCarousel_rejoinRadquest_text", fallback: "Continue your Radix journey in your browser. Tap to dismiss.")
      /// Rejoin RadQuest
      static let title = L10n.tr("Localizable", "homePageCarousel_rejoinRadquest_title", fallback: "Rejoin RadQuest")
    }
    enum UseDappsOnDesktop {
      /// Connect to dApps on the big screen with Radix Connector.
      static let text = L10n.tr("Localizable", "homePageCarousel_useDappsOnDesktop_text", fallback: "Connect to dApps on the big screen with Radix Connector.")
      /// Use dApps on Desktop
      static let title = L10n.tr("Localizable", "homePageCarousel_useDappsOnDesktop_title", fallback: "Use dApps on Desktop")
    }
  }
  enum IOSProfileBackup {
    /// Available backups:
    static let cloudBackupWallet = L10n.tr("Localizable", "iOSProfileBackup_cloudBackupWallet", fallback: "Available backups:")
    /// Backup created by: %@
    static func creatingDevice(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_creatingDevice", String(describing: p1), fallback: "Backup created by: %@")
    }
    /// Creation date: %@
    static func creationDateLabel(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_creationDateLabel", String(describing: p1), fallback: "Creation date: %@")
    }
    /// Import From Backup
    static let importBackupWallet = L10n.tr("Localizable", "iOSProfileBackup_importBackupWallet", fallback: "Import From Backup")
    /// Incompatible Wallet data
    static let incompatibleWalletDataLabel = L10n.tr("Localizable", "iOSProfileBackup_incompatibleWalletDataLabel", fallback: "Incompatible Wallet data")
    /// Last modified date: %@
    static func lastModifedDateLabel(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_lastModifedDateLabel", String(describing: p1), fallback: "Last modified date: %@")
    }
    /// Last used on device: %@
    static func lastUsedOnDeviceLabel(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_lastUsedOnDeviceLabel", String(describing: p1), fallback: "Last used on device: %@")
    }
    /// Wallet Data Backup
    static let navigationTitle = L10n.tr("Localizable", "iOSProfileBackup_navigationTitle", fallback: "Wallet Data Backup")
    /// Number of networks: %d
    static func numberOfNetworksLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_numberOfNetworksLabel", p1, fallback: "Number of networks: %d")
    }
    /// Unable to find wallet backup in iCloud.
    static let profileNotFoundInCloud = L10n.tr("Localizable", "iOSProfileBackup_profileNotFoundInCloud", fallback: "Unable to find wallet backup in iCloud.")
    /// Number of Accounts: %d
    static func totalAccountsNumberLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_totalAccountsNumberLabel", p1, fallback: "Number of Accounts: %d")
    }
    /// Number of Personas: %d
    static func totalPersonasNumberLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_totalPersonasNumberLabel", p1, fallback: "Number of Personas: %d")
    }
    /// Use iCloud Backup Data
    static let useICloudBackup = L10n.tr("Localizable", "iOSProfileBackup_useICloudBackup", fallback: "Use iCloud Backup Data")
    enum AutomaticBackups {
      /// Disable Backup to iCloud
      static let disable = L10n.tr("Localizable", "iOSProfileBackup_automaticBackups_disable", fallback: "Disable Backup to iCloud")
      /// Enable Backup to iCloud
      static let enable = L10n.tr("Localizable", "iOSProfileBackup_automaticBackups_enable", fallback: "Enable Backup to iCloud")
      /// Automatic continuous backups
      static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_automaticBackups_subtitle", fallback: "Automatic continuous backups")
    }
    enum ConfirmCloudSyncDisableAlert {
      /// Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?
      static let title = L10n.tr("Localizable", "iOSProfileBackup_confirmCloudSyncDisableAlert_title", fallback: "Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?")
    }
    enum DeleteWallet {
      /// Delete Wallet and iCloud Backup
      static let confirmButton = L10n.tr("Localizable", "iOSProfileBackup_deleteWallet_confirmButton", fallback: "Delete Wallet and iCloud Backup")
      /// You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any iCloud backup.
      /// 
      /// **Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**
      static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_deleteWallet_subtitle", fallback: "You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any iCloud backup.\n\n**Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**")
    }
    enum ICloudSyncEnabledAlert {
      /// iCloud sync is now enabled, but it might take up to an hour before your wallet data is uploaded to iCloud.
      static let message = L10n.tr("Localizable", "iOSProfileBackup_iCloudSyncEnabledAlert_message", fallback: "iCloud sync is now enabled, but it might take up to an hour before your wallet data is uploaded to iCloud.")
      /// Enabling iCloud sync
      static let title = L10n.tr("Localizable", "iOSProfileBackup_iCloudSyncEnabledAlert_title", fallback: "Enabling iCloud sync")
    }
    enum ProfileSync {
      /// Warning: If disabled you might lose access to your Accounts and Personas.
      static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_profileSync_subtitle", fallback: "Warning: If disabled you might lose access to your Accounts and Personas.")
      /// Sync Wallet Data to iCloud
      static let title = L10n.tr("Localizable", "iOSProfileBackup_profileSync_title", fallback: "Sync Wallet Data to iCloud")
    }
  }
  enum ImportMnemonic {
    /// Advanced Mode
    static let advancedModeButton = L10n.tr("Localizable", "importMnemonic_advancedModeButton", fallback: "Advanced Mode")
    /// Incorrect seed phrase
    static let checksumFailure = L10n.tr("Localizable", "importMnemonic_checksumFailure", fallback: "Incorrect seed phrase")
    /// Failed to validate all accounts against mnemonic
    static let failedToValidateAllAccounts = L10n.tr("Localizable", "importMnemonic_failedToValidateAllAccounts", fallback: "Failed to validate all accounts against mnemonic")
    /// Import
    static let importSeedPhrase = L10n.tr("Localizable", "importMnemonic_importSeedPhrase", fallback: "Import")
    /// Import Seed Phrase
    static let navigationTitle = L10n.tr("Localizable", "importMnemonic_navigationTitle", fallback: "Import Seed Phrase")
    /// Backup Seed Phrase
    static let navigationTitleBackup = L10n.tr("Localizable", "importMnemonic_navigationTitleBackup", fallback: "Backup Seed Phrase")
    /// Number of Seed Phrase Words
    static let numberOfWordsPicker = L10n.tr("Localizable", "importMnemonic_numberOfWordsPicker", fallback: "Number of Seed Phrase Words")
    /// Passphrase
    static let passphrase = L10n.tr("Localizable", "importMnemonic_passphrase", fallback: "Passphrase")
    /// Optional BIP39 Passphrase. This is not your wallet password, and the Radix Desktop Wallet did not use a BIP39 passphrase. This is only to support import from other wallets that may have used one.
    static let passphraseHint = L10n.tr("Localizable", "importMnemonic_passphraseHint", fallback: "Optional BIP39 Passphrase. This is not your wallet password, and the Radix Desktop Wallet did not use a BIP39 passphrase. This is only to support import from other wallets that may have used one.")
    /// Passphrase
    static let passphrasePlaceholder = L10n.tr("Localizable", "importMnemonic_passphrasePlaceholder", fallback: "Passphrase")
    /// Regular Mode
    static let regularModeButton = L10n.tr("Localizable", "importMnemonic_regularModeButton", fallback: "Regular Mode")
    /// Imported Seed Phrase
    static let seedPhraseImported = L10n.tr("Localizable", "importMnemonic_seedPhraseImported", fallback: "Imported Seed Phrase")
    /// Success
    static let verificationSuccess = L10n.tr("Localizable", "importMnemonic_verificationSuccess", fallback: "Success")
    /// Word %d
    static func wordHeading(_ p1: Int) -> String {
      return L10n.tr("Localizable", "importMnemonic_wordHeading", p1, fallback: "Word %d")
    }
    /// Wrong mnemmonic
    static let wrongMnemonicHUD = L10n.tr("Localizable", "importMnemonic_wrongMnemonicHUD", fallback: "Wrong mnemmonic")
    enum BackedUpAlert {
      /// Yes, I have written it down
      static let confirmAction = L10n.tr("Localizable", "importMnemonic_backedUpAlert_confirmAction", fallback: "Yes, I have written it down")
      /// Are you sure you have securely written down this seed phrase? You will need it to recover access if you lose your phone.
      static let message = L10n.tr("Localizable", "importMnemonic_backedUpAlert_message", fallback: "Are you sure you have securely written down this seed phrase? You will need it to recover access if you lose your phone.")
      /// No, not yet
      static let noAction = L10n.tr("Localizable", "importMnemonic_backedUpAlert_noAction", fallback: "No, not yet")
      /// Confirm Seed Phrase Saved
      static let title = L10n.tr("Localizable", "importMnemonic_backedUpAlert_title", fallback: "Confirm Seed Phrase Saved")
    }
    enum OffDevice {
      /// Without revealing location, vague hint on where this mnemonic is backed up, if anywhere.
      static let locationHint = L10n.tr("Localizable", "importMnemonic_offDevice_locationHint", fallback: "Without revealing location, vague hint on where this mnemonic is backed up, if anywhere.")
      /// In that book my mother used to read to me at my best childhoods summer vacation place
      static let locationPlaceholder = L10n.tr("Localizable", "importMnemonic_offDevice_locationPlaceholder", fallback: "In that book my mother used to read to me at my best childhoods summer vacation place")
      /// Backup location?
      static let locationPrimaryHeading = L10n.tr("Localizable", "importMnemonic_offDevice_locationPrimaryHeading", fallback: "Backup location?")
      /// Save with description
      static let saveWithDescription = L10n.tr("Localizable", "importMnemonic_offDevice_saveWithDescription", fallback: "Save with description")
      /// Save without description
      static let saveWithoutDescription = L10n.tr("Localizable", "importMnemonic_offDevice_saveWithoutDescription", fallback: "Save without description")
      /// Without revealing the words, what comes to mind when reading this seed phrase?
      static let storyHint = L10n.tr("Localizable", "importMnemonic_offDevice_storyHint", fallback: "Without revealing the words, what comes to mind when reading this seed phrase?")
      /// Hitchcock's The Birds mixed with Office space
      static let storyPlaceholder = L10n.tr("Localizable", "importMnemonic_offDevice_storyPlaceholder", fallback: "Hitchcock's The Birds mixed with Office space")
      /// Tell a story
      static let storyPrimaryHeading = L10n.tr("Localizable", "importMnemonic_offDevice_storyPrimaryHeading", fallback: "Tell a story")
    }
    enum ShieldPrompt {
      /// Please write down seed phrase to ensure Account control
      static let backupSeedPhrase = L10n.tr("Localizable", "importMnemonic_shieldPrompt_backupSeedPhrase", fallback: "Please write down seed phrase to ensure Account control")
      /// Enter this Account's seed phrase
      static let enterSeedPhrase = L10n.tr("Localizable", "importMnemonic_shieldPrompt_enterSeedPhrase", fallback: "Enter this Account's seed phrase")
    }
    enum TempAndroid {
      /// Change seed phrase length
      static let changeSeedPhrase = L10n.tr("Localizable", "importMnemonic_tempAndroid_changeSeedPhrase", fallback: "Change seed phrase length")
      /// Recover Mnemonic
      static let heading = L10n.tr("Localizable", "importMnemonic_tempAndroid_heading", fallback: "Recover Mnemonic")
      /// %d word seed phrase
      static func seedLength(_ p1: Int) -> String {
        return L10n.tr("Localizable", "importMnemonic_tempAndroid_seedLength", p1, fallback: "%d word seed phrase")
      }
    }
  }
  enum ImportOlympiaAccounts {
    /// Already imported
    static let alreadyImported = L10n.tr("Localizable", "importOlympiaAccounts_alreadyImported", fallback: "Already imported")
    /// BIP39 passphrase
    static let bip39passphrase = L10n.tr("Localizable", "importOlympiaAccounts_bip39passphrase", fallback: "BIP39 passphrase")
    /// Import
    static let importLabel = L10n.tr("Localizable", "importOlympiaAccounts_importLabel", fallback: "Import")
    /// Invalid Mnemonic
    static let invalidMnemonic = L10n.tr("Localizable", "importOlympiaAccounts_invalidMnemonic", fallback: "Invalid Mnemonic")
    /// Invalid QR code
    static let invalidPayload = L10n.tr("Localizable", "importOlympiaAccounts_invalidPayload", fallback: "Invalid QR code")
    /// No mnemonic found for accounts
    static let noMnemonicFound = L10n.tr("Localizable", "importOlympiaAccounts_noMnemonicFound", fallback: "No mnemonic found for accounts")
    /// No new accounts were found on this Ledger device
    static let noNewAccounts = L10n.tr("Localizable", "importOlympiaAccounts_noNewAccounts", fallback: "No new accounts were found on this Ledger device")
    /// Passphrase
    static let passphrase = L10n.tr("Localizable", "importOlympiaAccounts_passphrase", fallback: "Passphrase")
    /// Seed phrase
    static let seedPhrase = L10n.tr("Localizable", "importOlympiaAccounts_seedPhrase", fallback: "Seed phrase")
    enum AccountsToImport {
      /// Import %d accounts
      static func buttonManyAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_buttonManyAccounts", p1, fallback: "Import %d accounts")
      }
      /// Import 1 account
      static let buttonOneAcccount = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_buttonOneAcccount", fallback: "Import 1 account")
      /// Ledger (Legacy)
      static let ledgerAccount = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_ledgerAccount", fallback: "Ledger (Legacy)")
      /// Legacy Account
      static let legacyAccount = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_legacyAccount", fallback: "Legacy Account")
      /// New Address
      static let newAddressLabel = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_newAddressLabel", fallback: "New Address")
      /// Olympia Address (Obsolete)
      static let olympiaAddressLabel = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_olympiaAddressLabel", fallback: "Olympia Address (Obsolete)")
      /// The following accounts will be imported into this Radix Wallet.
      static let subtitle = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_subtitle", fallback: "The following accounts will be imported into this Radix Wallet.")
      /// Import Accounts
      static let title = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_title", fallback: "Import Accounts")
      /// Unnamed
      static let unnamed = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_unnamed", fallback: "Unnamed")
    }
    enum Completion {
      /// Continue to Account List
      static let accountListButtonTitle = L10n.tr("Localizable", "importOlympiaAccounts_completion_accountListButtonTitle", fallback: "Continue to Account List")
      /// Your Accounts live on the Radix Network and you can access them anytime in your Wallet.
      static let explanation = L10n.tr("Localizable", "importOlympiaAccounts_completion_explanation", fallback: "Your Accounts live on the Radix Network and you can access them anytime in your Wallet.")
      /// You've now imported these Accounts:
      static let subtitleMultiple = L10n.tr("Localizable", "importOlympiaAccounts_completion_subtitleMultiple", fallback: "You've now imported these Accounts:")
      /// You've now imported this Account:
      static let subtitleSingle = L10n.tr("Localizable", "importOlympiaAccounts_completion_subtitleSingle", fallback: "You've now imported this Account:")
      /// Congratulations
      static let title = L10n.tr("Localizable", "importOlympiaAccounts_completion_title", fallback: "Congratulations")
    }
    enum ScanQR {
      /// Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.
      static let instructions = L10n.tr("Localizable", "importOlympiaAccounts_scanQR_instructions", fallback: "Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.")
      /// Scanned: %d/%d
      static func scannedLabel(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "importOlympiaAccounts_scanQR_scannedLabel", p1, p2, fallback: "Scanned: %d/%d")
      }
      /// Import Legacy Olympia Accounts
      static let title = L10n.tr("Localizable", "importOlympiaAccounts_scanQR_title", fallback: "Import Legacy Olympia Accounts")
    }
    enum VerifySeedPhrase {
      /// Do not throw away this seed phrase! You will still need it if you need to recover access to your Olympia accounts in the future.
      static let keepSeedPhrasePrompt = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_keepSeedPhrasePrompt", fallback: "Do not throw away this seed phrase! You will still need it if you need to recover access to your Olympia accounts in the future.")
      /// I Understand
      static let keepSeedPhrasePromptConfirmation = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_keepSeedPhrasePromptConfirmation", fallback: "I Understand")
      /// Warning
      static let keepSeedPhraseTitle = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_keepSeedPhraseTitle", fallback: "Warning")
      /// To complete importing your accounts, please view your seed phrase in the Radix Desktop Wallet and enter the words here.
      static let subtitle = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_subtitle", fallback: "To complete importing your accounts, please view your seed phrase in the Radix Desktop Wallet and enter the words here.")
      /// Verify With Your Seed Phrase
      static let title = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_title", fallback: "Verify With Your Seed Phrase")
      /// This will give this Radix Wallet control of your accounts. Never give your seed phrase to anyone for any reason.
      static let warning = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_warning", fallback: "This will give this Radix Wallet control of your accounts. Never give your seed phrase to anyone for any reason.")
    }
  }
  enum ImportOlympiaLedgerAccounts {
    /// Accounts remaining to verify: %d
    static func accountCount(_ p1: Int) -> String {
      return L10n.tr("Localizable", "importOlympiaLedgerAccounts_accountCount", p1, fallback: "Accounts remaining to verify: %d")
    }
    /// Continue
    static let continueButtonTitle = L10n.tr("Localizable", "importOlympiaLedgerAccounts_continueButtonTitle", fallback: "Continue")
    /// Connect your next Ledger device, launch the Radix Babylon app on it, and tap Continue here.
    static let instruction = L10n.tr("Localizable", "importOlympiaLedgerAccounts_instruction", fallback: "Connect your next Ledger device, launch the Radix Babylon app on it, and tap Continue here.")
    /// Already verified Ledger devices:
    static let listHeading = L10n.tr("Localizable", "importOlympiaLedgerAccounts_listHeading", fallback: "Already verified Ledger devices:")
    /// You are attempting to import one or more Olympia accounts that must be verified with a Ledger hardware wallet device.
    static let subtitle = L10n.tr("Localizable", "importOlympiaLedgerAccounts_subtitle", fallback: "You are attempting to import one or more Olympia accounts that must be verified with a Ledger hardware wallet device.")
    /// Verify With Ledger Device
    static let title = L10n.tr("Localizable", "importOlympiaLedgerAccounts_title", fallback: "Verify With Ledger Device")
  }
  enum InfoLink {
    enum Glossary {
      /// ## Radix Accounts
      /// 
      /// Accounts are secure containers for any kind of digital asset on the [Radix Network](?glossaryAnchor=radixnetwork).
      /// 
      /// ---
      /// 
      /// Unlike an account on a bank or other service, there is no company that controls your Radix Accounts for you. Your [Radix Wallet](?glossaryAnchor=radixwallet) app on your phone gives you direct access to your Accounts on the network, and can help you regain access to your Accounts if you lose your phone.
      /// 
      /// Compared to accounts on other crypto networks, Radix Accounts are so much more clever, they’re sometimes called “Smart Accounts”.
      /// 
      /// [Learn more about Smart Accounts](https://learn.radixdlt.com/article/what-are-smart-accounts) ↗
      /// 
      /// [Read about Smart Account multi-factor and other features](https://www.radixdlt.com/blog/how-radix-multi-factor-smart-accounts-work-and-what-they-can-do) ↗
      static let accounts = L10n.tr("Localizable", "infoLink_glossary_accounts", fallback: "## Radix Accounts\n\nAccounts are secure containers for any kind of digital asset on the [Radix Network](?glossaryAnchor=radixnetwork).\n\n---\n\nUnlike an account on a bank or other service, there is no company that controls your Radix Accounts for you. Your [Radix Wallet](?glossaryAnchor=radixwallet) app on your phone gives you direct access to your Accounts on the network, and can help you regain access to your Accounts if you lose your phone.\n\nCompared to accounts on other crypto networks, Radix Accounts are so much more clever, they’re sometimes called “Smart Accounts”.\n\n[Learn more about Smart Accounts](https://learn.radixdlt.com/article/what-are-smart-accounts) ↗\n\n[Read about Smart Account multi-factor and other features](https://www.radixdlt.com/blog/how-radix-multi-factor-smart-accounts-work-and-what-they-can-do) ↗")
      /// ## Badges
      /// 
      /// Radix Badges are tokens or NFTs that are used to prove their holder is authorized to claim something, access something or perform a certain action within the Radix Network. Any token on Radix can be used as a badge, but dApps may often create special tokens specifically for use as a badge.
      /// 
      /// ---
      /// 
      /// [Tokens](?glossaryAnchor=tokens) and [NFTs](?glossaryAnchor=nfts) can represent almost anything. The [Radix Network](?glossaryAnchor=radixnetwork) makes it possible to use ownership of a token or NFT to authorize the holder to access to certain [dApp](?glossaryAnchor=dapps) functionality. Tokens or NFTs used in this way are referred to as “badges”, indicating that only the holder of the badge can use it for authorization.
      /// 
      /// When a badge is used to authorize access in a [transaction](?glossaryAnchor=transactions), you will see it listed in the [Radix Wallet’s](?glossaryAnchor=radixwallet) summary of the transaction under “presenting”. The badge isn’t being sent anywhere; all that’s happening is that you are providing proof that you own the badge.
      /// 
      /// [Learn more about Radix badges](https://learn.radixdlt.com/article/whats-a-badge) ↗
      static let badges = L10n.tr("Localizable", "infoLink_glossary_badges", fallback: "## Badges\n\nRadix Badges are tokens or NFTs that are used to prove their holder is authorized to claim something, access something or perform a certain action within the Radix Network. Any token on Radix can be used as a badge, but dApps may often create special tokens specifically for use as a badge.\n\n---\n\n[Tokens](?glossaryAnchor=tokens) and [NFTs](?glossaryAnchor=nfts) can represent almost anything. The [Radix Network](?glossaryAnchor=radixnetwork) makes it possible to use ownership of a token or NFT to authorize the holder to access to certain [dApp](?glossaryAnchor=dapps) functionality. Tokens or NFTs used in this way are referred to as “badges”, indicating that only the holder of the badge can use it for authorization.\n\nWhen a badge is used to authorize access in a [transaction](?glossaryAnchor=transactions), you will see it listed in the [Radix Wallet’s](?glossaryAnchor=radixwallet) summary of the transaction under “presenting”. The badge isn’t being sent anywhere; all that’s happening is that you are providing proof that you own the badge.\n\n[Learn more about Radix badges](https://learn.radixdlt.com/article/whats-a-badge) ↗")
      /// ## Asset Behaviors
      /// 
      /// Asset behaviors define the rules that were placed on a [token](?glossaryAnchor=tokens) or [NFT](?glossaryAnchor=nfts) when it was created. They ensure all users know exactly what actions can be performed on any asset. And they’re labeled in everyday language so everyone can read them, understand them and know the nature of the asset they’re holding.
      /// 
      /// ---
      /// 
      /// The [Radix Network](?glossaryAnchor=radixnetwork) is built differently to all other blockchains. One of the great benefits of this is that assets – tokens and NFTs – are native to the ecosystem. So unlike on networks such as Ethereum, where tokens are not really tokens but just balances on a smart contract, assets on Radix act like real-life assets. With real-life assets of different kinds, you know who can create it, destory it, take it away from you or freeze it within your bank account. Similarly with Radix, you’ll always know how assets will behave and what someone can do to them.
      /// 
      /// When anyone creates a token or NFT on Radix, there is a list of behaviors they can apply to them. Things like being able to increase the token’s supply, being able to change an NFT’s image and description, or being able to remove a token from someone’s account. There are plenty of valid reasons for why someone might want to do these things, but it’s always good to know if they can. 
      /// 
      /// Just tap into any token in the Radix Wallet to get a full list of its behaviors.
      static let behaviors = L10n.tr("Localizable", "infoLink_glossary_behaviors", fallback: "## Asset Behaviors\n\nAsset behaviors define the rules that were placed on a [token](?glossaryAnchor=tokens) or [NFT](?glossaryAnchor=nfts) when it was created. They ensure all users know exactly what actions can be performed on any asset. And they’re labeled in everyday language so everyone can read them, understand them and know the nature of the asset they’re holding.\n\n---\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) is built differently to all other blockchains. One of the great benefits of this is that assets – tokens and NFTs – are native to the ecosystem. So unlike on networks such as Ethereum, where tokens are not really tokens but just balances on a smart contract, assets on Radix act like real-life assets. With real-life assets of different kinds, you know who can create it, destory it, take it away from you or freeze it within your bank account. Similarly with Radix, you’ll always know how assets will behave and what someone can do to them.\n\nWhen anyone creates a token or NFT on Radix, there is a list of behaviors they can apply to them. Things like being able to increase the token’s supply, being able to change an NFT’s image and description, or being able to remove a token from someone’s account. There are plenty of valid reasons for why someone might want to do these things, but it’s always good to know if they can. \n\nJust tap into any token in the Radix Wallet to get a full list of its behaviors.")
      /// ## Bridging
      /// 
      /// Bridging is the process of getting assets into and out of the [Radix Network](?glossaryAnchor=radixnetwork). Assets on Radix can be held by your [Radix Wallet](?glossaryAnchor=radixnetwork), and used with [dApps](?glossaryAnchor=dapps) on Radix. There are a variety of dApps that provide bridging in different ways, for different assets.
      /// 
      /// Sometimes bridging involves converting an asset into a different form that can live on Radix. For example, dollars (USD) in your bank account might be bridged into Radix and become xUSDC tokens in your Radix Wallet. Or your Bitcoin (BTC) might be bridged into xwBTC tokens.
      /// 
      /// Sometimes bridging works as a swap, similar to a [DEX](?glossaryAnchor=dex). In this case you might swap one asset outside Radix for a different asset within Radix. Maybe you swap ETH (on the Ethereum network) for XRD tokens (on the Radix Network) at a current market price.
      static let bridging = L10n.tr("Localizable", "infoLink_glossary_bridging", fallback: "## Bridging\n\nBridging is the process of getting assets into and out of the [Radix Network](?glossaryAnchor=radixnetwork). Assets on Radix can be held by your [Radix Wallet](?glossaryAnchor=radixnetwork), and used with [dApps](?glossaryAnchor=dapps) on Radix. There are a variety of dApps that provide bridging in different ways, for different assets.\n\nSometimes bridging involves converting an asset into a different form that can live on Radix. For example, dollars (USD) in your bank account might be bridged into Radix and become xUSDC tokens in your Radix Wallet. Or your Bitcoin (BTC) might be bridged into xwBTC tokens.\n\nSometimes bridging works as a swap, similar to a [DEX](?glossaryAnchor=dex). In this case you might swap one asset outside Radix for a different asset within Radix. Maybe you swap ETH (on the Ethereum network) for XRD tokens (on the Radix Network) at a current market price.")
      /// ## Stake Claim NFTs
      /// 
      /// Stake claim [NFTs](?glossaryAnchor=NFTs) are tokens that represent a quantity of unstaked XRD that the user can claim from a [validator](?glossaryAnchor=validators) to receive back [XRD](?glossaryAnchor=xrd).
      /// 
      /// ---
      /// 
      /// After a user requests an unstake using a quantity of [liquid stake units](?glossaryAnchor=liquidstakeunits), they receive a stake claim NFT that represents the quantity and validator of that particular unstake request. Like LSUs, stake claim NFTs are freely transferable.
      /// 
      /// After the require unstaking delay is over, the user can do a special claim transaction to return the stake claim NFT to the validator and receive the amount of XRD due.
      /// 
      /// [Learn how to Stake and Unstake XRD](https://learn.radixdlt.com/article/how-to-stake-and-unstake-xrd) ↗
      static let claimnfts = L10n.tr("Localizable", "infoLink_glossary_claimnfts", fallback: "## Stake Claim NFTs\n\nStake claim [NFTs](?glossaryAnchor=NFTs) are tokens that represent a quantity of unstaked XRD that the user can claim from a [validator](?glossaryAnchor=validators) to receive back [XRD](?glossaryAnchor=xrd).\n\n---\n\nAfter a user requests an unstake using a quantity of [liquid stake units](?glossaryAnchor=liquidstakeunits), they receive a stake claim NFT that represents the quantity and validator of that particular unstake request. Like LSUs, stake claim NFTs are freely transferable.\n\nAfter the require unstaking delay is over, the user can do a special claim transaction to return the stake claim NFT to the validator and receive the amount of XRD due.\n\n[Learn how to Stake and Unstake XRD](https://learn.radixdlt.com/article/how-to-stake-and-unstake-xrd) ↗")
      /// ## √ Connect Button
      /// 
      /// [dApps](?glossaryAnchor=dapps) built on Radix should always include a button marked **√ Connect**. Start here to connect your [Radix Wallet](?glossaryAnchor=radixwallet) to the dApp.
      /// 
      /// In most cases, the √ Connect button will include a menu where you can Connect Now, often asking your Radix Wallet to log in with a Persona. After logging in, that menu should provide a variety of features and information to help you manage your login and sharing with that dApp.
      static let connectbutton = L10n.tr("Localizable", "infoLink_glossary_connectbutton", fallback: "## √ Connect Button\n\n[dApps](?glossaryAnchor=dapps) built on Radix should always include a button marked **√ Connect**. Start here to connect your [Radix Wallet](?glossaryAnchor=radixwallet) to the dApp.\n\nIn most cases, the √ Connect button will include a menu where you can Connect Now, often asking your Radix Wallet to log in with a Persona. After logging in, that menu should provide a variety of features and information to help you manage your login and sharing with that dApp.")
      /// ## dApps
      /// 
      /// Decentralized applications, or dApps, are basically any application that makes use of web3 features.
      /// 
      /// ---
      /// 
      /// In web3, users control their own digital assets and identity. That’s much different from typical webpages and other apps today. For example, to access your money, you have to do it through a banking or payments app. Your login to every website is owned by that website, or else you use something like your Google login, which is owned by Google.
      /// 
      /// But in web3, you can hold your money in an [account](?glossaryAnchor=accounts) that you control directly with a [wallet](?glossaryAnchor=radixwallet) app, and you can create your own [login](?glossaryAnchor=personas) in your wallet app and use that in many places.
      /// 
      /// Doing things that way is “decentralized” – and it means that websites and applications need to be built specially to interact with wallet apps, self-owned accounts, and self-owned logins. That’s what makes them dApps.
      /// 
      /// In the end, web3 dApps can do many things that were never possible before. For example, a [decentralized exchange](?glossaryAnchor=dex) dApp can let you instantly swap between two different kinds of assets right from your wallet in just a tap.
      /// 
      /// [Visit the Radix dApp Ecosystem Page](https://www.radixdlt.com/ecosystem) ↗
      static let dapps = L10n.tr("Localizable", "infoLink_glossary_dapps", fallback: "## dApps\n\nDecentralized applications, or dApps, are basically any application that makes use of web3 features.\n\n---\n\nIn web3, users control their own digital assets and identity. That’s much different from typical webpages and other apps today. For example, to access your money, you have to do it through a banking or payments app. Your login to every website is owned by that website, or else you use something like your Google login, which is owned by Google.\n\nBut in web3, you can hold your money in an [account](?glossaryAnchor=accounts) that you control directly with a [wallet](?glossaryAnchor=radixwallet) app, and you can create your own [login](?glossaryAnchor=personas) in your wallet app and use that in many places.\n\nDoing things that way is “decentralized” – and it means that websites and applications need to be built specially to interact with wallet apps, self-owned accounts, and self-owned logins. That’s what makes them dApps.\n\nIn the end, web3 dApps can do many things that were never possible before. For example, a [decentralized exchange](?glossaryAnchor=dex) dApp can let you instantly swap between two different kinds of assets right from your wallet in just a tap.\n\n[Visit the Radix dApp Ecosystem Page](https://www.radixdlt.com/ecosystem) ↗")
      /// ## Radix Dashboard
      /// 
      /// The Radix Dashboard is a [dApp](?glossaryAnchor=dapps) created by the same team as the [Radix Wallet](?glossaryAnchor=radixwallet) to help users interact with the [Radix Network](?glossaryAnchor=radixnetwork) directly.
      /// 
      /// You can look up information about things on the Radix Network by entering its address, such as: Accounts, tokens, NFTs, components (smart contracts), and more.
      /// 
      /// You can also use the Radix Dashboard’s [network staking](?glossaryAnchor=networkstaking) feature to view the list of current Radix Network validators, stake XRD, and manage your existing network staking.
      /// 
      /// [Visit the Radix Dashboard](https://dashboard.radixdlt.com) ↗
      static let dashboard = L10n.tr("Localizable", "infoLink_glossary_dashboard", fallback: "## Radix Dashboard\n\nThe Radix Dashboard is a [dApp](?glossaryAnchor=dapps) created by the same team as the [Radix Wallet](?glossaryAnchor=radixwallet) to help users interact with the [Radix Network](?glossaryAnchor=radixnetwork) directly.\n\nYou can look up information about things on the Radix Network by entering its address, such as: Accounts, tokens, NFTs, components (smart contracts), and more.\n\nYou can also use the Radix Dashboard’s [network staking](?glossaryAnchor=networkstaking) feature to view the list of current Radix Network validators, stake XRD, and manage your existing network staking.\n\n[Visit the Radix Dashboard](https://dashboard.radixdlt.com) ↗")
      /// ## Decentralized Exchange (DEX)
      /// 
      /// A decentralized exchange, or “DEX” for short, is a [dApp](?glossaryAnchor=dapps) that offers something a bit like a much more powerful web3 version of a foreign currency exchange counter at the airport.
      /// 
      /// ---
      /// 
      /// A DEX dApp lets users do instant and fully automated swaps between a huge variety of tokens or other digital assets. The exchange logic runs right on the [Radix Network](?glossaryAnchor=radixnetwork) itself. This means that a DEX swap is done with a [transaction](?glossaryAnchor=transactions) and the [Radix Wallet](?glossaryAnchor=radixwallet) can show you exactly what’s going to happen, and let you apply [deposit guarantees](?glossaryAnchor=guarantees) to the results.
      /// 
      /// [Learn more about DEX dApps](https://learn.radixdlt.com/article/whats-a-dex) ↗
      static let dex = L10n.tr("Localizable", "infoLink_glossary_dex", fallback: "## Decentralized Exchange (DEX)\n\nA decentralized exchange, or “DEX” for short, is a [dApp](?glossaryAnchor=dapps) that offers something a bit like a much more powerful web3 version of a foreign currency exchange counter at the airport.\n\n---\n\nA DEX dApp lets users do instant and fully automated swaps between a huge variety of tokens or other digital assets. The exchange logic runs right on the [Radix Network](?glossaryAnchor=radixnetwork) itself. This means that a DEX swap is done with a [transaction](?glossaryAnchor=transactions) and the [Radix Wallet](?glossaryAnchor=radixwallet) can show you exactly what’s going to happen, and let you apply [deposit guarantees](?glossaryAnchor=guarantees) to the results.\n\n[Learn more about DEX dApps](https://learn.radixdlt.com/article/whats-a-dex) ↗")
      /// ## Gateways
      /// 
      /// A gateway is your pathway to connect to the [Radix Network](?glossaryAnchor=radixnetwork) – it enables users to communicate with the Radix Network and transfer data to and from it. 
      /// 
      /// ---
      /// 
      /// You can add additional gateways in your Radix Wallet and switch between them. Each gateway will connect your wallet to a particular network. The Radix Network (known as “mainnet”) is the primary network where all real assets, including the real XRD of value, are located. However a gateway might target a test network (like “Stokenet”) where developers can experiment with updates and new features before they go live on Bablyon. None of the assets on these test networks, including XRD, have any value.
      /// 
      /// The [Radix Wallet](?glossaryAnchor=radixwallet) comes automatically connected to a Radix Network mainnet gateway operated by the creators of the Radix Wallet, but there are community-run gateways that users can choose to use as well. Because anyone can create a new gateway, third-party gateways should always be accessed with caution.
      static let gateways = L10n.tr("Localizable", "infoLink_glossary_gateways", fallback: "## Gateways\n\nA gateway is your pathway to connect to the [Radix Network](?glossaryAnchor=radixnetwork) – it enables users to communicate with the Radix Network and transfer data to and from it. \n\n---\n\nYou can add additional gateways in your Radix Wallet and switch between them. Each gateway will connect your wallet to a particular network. The Radix Network (known as “mainnet”) is the primary network where all real assets, including the real XRD of value, are located. However a gateway might target a test network (like “Stokenet”) where developers can experiment with updates and new features before they go live on Bablyon. None of the assets on these test networks, including XRD, have any value.\n\nThe [Radix Wallet](?glossaryAnchor=radixwallet) comes automatically connected to a Radix Network mainnet gateway operated by the creators of the Radix Wallet, but there are community-run gateways that users can choose to use as well. Because anyone can create a new gateway, third-party gateways should always be accessed with caution.")
      /// ## Deposit Guarantees
      /// 
      /// Some Radix [transactions](?glossaryAnchor=transactions) may have unpredictable results. In these cases, deposit guarantees make sure you never get less than you expect when you do a transaction.
      /// 
      /// ---
      /// 
      /// For example, the result of a swap between assets using a [DEX](?glossaryAnchor=dex) depends on a current market price of the assets involved. You may see one price when considering the swap, but it typically changes by the time the network processes it. Deposit guarantees protect you by letting you specify a minimum amount that must be deposited to your account at the end of the swap transaction.
      /// 
      /// To make this possible, the [Radix Network](?glossaryAnchor=radixnetwork) app and [Radix Wallet](?glossaryAnchor=radixwallet) work together. The wallet will show you whenever a deposit to your account is “estimated” rather than of a known quantity. And whenever that's true, you can set your own “guarantees” in the wallet on those estimated deposits – putting a limit on how much you expect to get for you to be willing to go through with the transaction. If that guarantee isn't met at the time the transaction is processed, the deal is off! The transaction is rejected by the Radix Network and no assets change hands.
      /// 
      /// [Learn more about deposit guarantees](https://learn.radixdlt.com/article/what-are-customizable-transaction-guarantees-on-radix) ↗
      static let guarantees = L10n.tr("Localizable", "infoLink_glossary_guarantees", fallback: "## Deposit Guarantees\n\nSome Radix [transactions](?glossaryAnchor=transactions) may have unpredictable results. In these cases, deposit guarantees make sure you never get less than you expect when you do a transaction.\n\n---\n\nFor example, the result of a swap between assets using a [DEX](?glossaryAnchor=dex) depends on a current market price of the assets involved. You may see one price when considering the swap, but it typically changes by the time the network processes it. Deposit guarantees protect you by letting you specify a minimum amount that must be deposited to your account at the end of the swap transaction.\n\nTo make this possible, the [Radix Network](?glossaryAnchor=radixnetwork) app and [Radix Wallet](?glossaryAnchor=radixwallet) work together. The wallet will show you whenever a deposit to your account is “estimated” rather than of a known quantity. And whenever that's true, you can set your own “guarantees” in the wallet on those estimated deposits – putting a limit on how much you expect to get for you to be willing to go through with the transaction. If that guarantee isn't met at the time the transaction is processed, the deal is off! The transaction is rejected by the Radix Network and no assets change hands.\n\n[Learn more about deposit guarantees](https://learn.radixdlt.com/article/what-are-customizable-transaction-guarantees-on-radix) ↗")
      /// ## Liquid Stake Unit
      /// 
      /// A liquid stake unit (LSU) is a type of token within the [Radix Network](?glossaryAnchor=radixnetwork) that represents the amount of [XRD](?glossaryAnchor=xrd) a user has staked to a certain validator. LSUs are freely transferable in Radix’s DeFi ecosystem and can be traded as assets.
      /// 
      /// ---
      /// 
      /// Whenever a user stakes XRD to a validator, they receive an LSU in return that is specific to that validator. The amount of LSU represents the quantity of XRD stake to that validator, which will increase as new emissions are provided.
      /// 
      /// Because they're liquid, LSUs can be traded within the Radix Network like any other asset. The holder of the LSU can also redeem the XRD that they represent.
      /// 
      /// To request an unstake of XRD tokens, the user does a special transaction to send some LSU back to the validator component, which returns a [stake claim NFT](?glossaryAnchor=claimnfts) that can later be redeemed for the XRD after an unstaking delay.
      /// 
      /// [Learn how to Stake and Unstake XRD](https://learn.radixdlt.com/article/how-to-stake-and-unstake-xrd) ↗
      static let liquidstakeunits = L10n.tr("Localizable", "infoLink_glossary_liquidstakeunits", fallback: "## Liquid Stake Unit\n\nA liquid stake unit (LSU) is a type of token within the [Radix Network](?glossaryAnchor=radixnetwork) that represents the amount of [XRD](?glossaryAnchor=xrd) a user has staked to a certain validator. LSUs are freely transferable in Radix’s DeFi ecosystem and can be traded as assets.\n\n---\n\nWhenever a user stakes XRD to a validator, they receive an LSU in return that is specific to that validator. The amount of LSU represents the quantity of XRD stake to that validator, which will increase as new emissions are provided.\n\nBecause they're liquid, LSUs can be traded within the Radix Network like any other asset. The holder of the LSU can also redeem the XRD that they represent.\n\nTo request an unstake of XRD tokens, the user does a special transaction to send some LSU back to the validator component, which returns a [stake claim NFT](?glossaryAnchor=claimnfts) that can later be redeemed for the XRD after an unstaking delay.\n\n[Learn how to Stake and Unstake XRD](https://learn.radixdlt.com/article/how-to-stake-and-unstake-xrd) ↗")
      /// ## Radix Network Staking
      /// 
      /// An important feature of the [Radix Network](?glossaryAnchor=radixnetwork) is that users can “stake” [XRD tokens](?glossaryAnchor=xrd) to increase the security of the network, and be rewarded for doing so.
      /// 
      /// ---
      /// 
      /// The process involves choosing one or more [validators](?glossaryAnchor=validators) to stake to, and then doing a [transaction](?glossaryAnchor=transactions) to send some XRD to the network to support those validators. You can unstake the XRD later to get them back – and you’ll find that you accumulated extra XRD in the meantime.
      /// 
      /// The extra XRD you earn is proportional to how much XRD you stake, and is often called an “APY” (annual percentage yield).
      /// 
      /// You can stake, unstake, and check on your validators and APY returns using the [Radix Dashboard](?glossaryAnchor=dashboard) dApp.
      /// 
      /// Staking is a great way to put your XRD to work and earn a return, but it’s **not simply free money**. Choosing validators is like voting for who will run the Radix Network. If you choose a bad validator, you might help slow down the network or even help attack it. And you might not get the APY you expect.
      /// 
      /// Get started with the links below before you stake a meaningful amount of XRD.
      /// 
      /// [Introduction to Radix staking](https://learn.radixdlt.com/article/start-here-radix-staking-introduction) ↗
      /// 
      /// [Learn how to choose validators](https://learn.radixdlt.com/article/how-should-i-choose-validators-to-stake-to) ↗
      static let networkstaking = L10n.tr("Localizable", "infoLink_glossary_networkstaking", fallback: "## Radix Network Staking\n\nAn important feature of the [Radix Network](?glossaryAnchor=radixnetwork) is that users can “stake” [XRD tokens](?glossaryAnchor=xrd) to increase the security of the network, and be rewarded for doing so.\n\n---\n\nThe process involves choosing one or more [validators](?glossaryAnchor=validators) to stake to, and then doing a [transaction](?glossaryAnchor=transactions) to send some XRD to the network to support those validators. You can unstake the XRD later to get them back – and you’ll find that you accumulated extra XRD in the meantime.\n\nThe extra XRD you earn is proportional to how much XRD you stake, and is often called an “APY” (annual percentage yield).\n\nYou can stake, unstake, and check on your validators and APY returns using the [Radix Dashboard](?glossaryAnchor=dashboard) dApp.\n\nStaking is a great way to put your XRD to work and earn a return, but it’s **not simply free money**. Choosing validators is like voting for who will run the Radix Network. If you choose a bad validator, you might help slow down the network or even help attack it. And you might not get the APY you expect.\n\nGet started with the links below before you stake a meaningful amount of XRD.\n\n[Introduction to Radix staking](https://learn.radixdlt.com/article/start-here-radix-staking-introduction) ↗\n\n[Learn how to choose validators](https://learn.radixdlt.com/article/how-should-i-choose-validators-to-stake-to) ↗")
      /// ## Non-fungible Token (NFT)
      /// 
      /// Non-fungible tokens are a special class of web3 [token](?glossaryAnchor=tokens) where each token has a unique identity.
      /// 
      /// Like other tokens, they can represent many things. But NFTs are used to represent things where each is different from another, like pieces of art, loan positions, treasury bonds, tickets to assigned-seating events, collectible cards, or equipment in games.
      /// 
      /// ---
      /// 
      /// The [Radix Network](?glossaryAnchor=radixnetwork) has special features specifically to make the creation and use of non-fungible tokens on Radix safe and predictable, and the [Radix Wallet](?glossaryAnchor=radixwallet) can automatically provide useful information about the NFTs you hold in your [Accounts](?glossaryAnchor=accounts).
      /// 
      /// [Learn more about NFTs](https://learn.radixdlt.com/article/what-is-an-nft) ↗
      /// 
      /// [Find out why tokens on Radix are better than other crypto networks](https://www.radixdlt.com/blog/its-10pm-do-you-know-where-your-tokens-are) ↗
      static let nfts = L10n.tr("Localizable", "infoLink_glossary_nfts", fallback: "## Non-fungible Token (NFT)\n\nNon-fungible tokens are a special class of web3 [token](?glossaryAnchor=tokens) where each token has a unique identity.\n\nLike other tokens, they can represent many things. But NFTs are used to represent things where each is different from another, like pieces of art, loan positions, treasury bonds, tickets to assigned-seating events, collectible cards, or equipment in games.\n\n---\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) has special features specifically to make the creation and use of non-fungible tokens on Radix safe and predictable, and the [Radix Wallet](?glossaryAnchor=radixwallet) can automatically provide useful information about the NFTs you hold in your [Accounts](?glossaryAnchor=accounts).\n\n[Learn more about NFTs](https://learn.radixdlt.com/article/what-is-an-nft) ↗\n\n[Find out why tokens on Radix are better than other crypto networks](https://www.radixdlt.com/blog/its-10pm-do-you-know-where-your-tokens-are) ↗")
      /// ## Why your Accounts will be linked
      /// 
      /// Paying your transaction fee from this Account will make you identifiable on ledger as both the owner of the fee-paying Account and all other Accounts you use in this transaction.
      /// 
      /// This is because you’ll sign the transactions from each Account at the same time, so your Accounts will be linked together in the transaction record.
      static let payingaccount = L10n.tr("Localizable", "infoLink_glossary_payingaccount", fallback: "## Why your Accounts will be linked\n\nPaying your transaction fee from this Account will make you identifiable on ledger as both the owner of the fee-paying Account and all other Accounts you use in this transaction.\n\nThis is because you’ll sign the transactions from each Account at the same time, so your Accounts will be linked together in the transaction record.")
      /// ## Radix Personas
      /// 
      /// Personas are the web3 replacement for the old email address and password login. Using a Persona of your choice, you can securely log in to [dApps](?glossaryAnchor=dapps) built on Radix without having to remember a password at all.
      /// 
      /// ---
      /// 
      /// Using your [Radix Wallet](?glossaryAnchor=radixwallet) app, you can create as many Personas as you like. Personas can also hold pieces of your personal information - like name and email address - that dApps can request access to, if you want to give permission.
      /// 
      /// [Learn more about Personas](https://learn.radixdlt.com/article/what-are-personas-and-identities) ↗
      /// 
      /// [Find out how Personas are logins for the web3 era](https://www.radixdlt.com/blog/personas-logins-for-the-web3-era) ↗
      static let personas = L10n.tr("Localizable", "infoLink_glossary_personas", fallback: "## Radix Personas\n\nPersonas are the web3 replacement for the old email address and password login. Using a Persona of your choice, you can securely log in to [dApps](?glossaryAnchor=dapps) built on Radix without having to remember a password at all.\n\n---\n\nUsing your [Radix Wallet](?glossaryAnchor=radixwallet) app, you can create as many Personas as you like. Personas can also hold pieces of your personal information - like name and email address - that dApps can request access to, if you want to give permission.\n\n[Learn more about Personas](https://learn.radixdlt.com/article/what-are-personas-and-identities) ↗\n\n[Find out how Personas are logins for the web3 era](https://www.radixdlt.com/blog/personas-logins-for-the-web3-era) ↗")
      /// ## Pool Units
      /// 
      /// Pool units are fungible [tokens](?glossaryAnchor=tokens) that represent the proportional size of a user's contribution to a liquidity pool
      /// 
      /// Pool units are redeemable for the user's portion of the pool but can also be traded, sold and used in DeFi applications.
      /// 
      /// ---
      /// 
      /// Liquidity pools play an integral role in lending and swapping on DeFi platforms. They work by liquidity providers (LPs) contributing tokens to a pool, thus creating a market for people to lend, borrow and swap. In return, these LPs receive tokens to show they've made a contribution to the pool. LPs usually get rewarded for their contributions in the form of fees paid by the people using the DeFi platform to swap and borrow crypto, but there are other ways for them to earn revenue.
      /// 
      /// With other wallets on other blockchains, this process raises risks. Other wallets can’t tell an LP what the tokens they received for providing liquidity are worth. Other wallets can’t even be sure they are actually tokens that represent a portion of a pool or that the tokens are redeemable. They don’t provide any confidence.
      /// 
      /// The [Radix Network](?glossaryAnchor=radixnetwork) solves this with a native package called a “pool”. This package automatically implements the logic of minting and burning pool units in the proportion to other LPs’ contributions. It also means your [Radix Wallet](?glossaryAnchor=radixwallet) can always read what your pool units are worth and ensures they’re always redeemable for tokens from the liquidity pool.
      /// 
      /// [Learn more about pool units](https://learn.radixdlt.com/article/what-are-pool-units-or-native-lp-tokens) ↗
      static let poolunits = L10n.tr("Localizable", "infoLink_glossary_poolunits", fallback: "## Pool Units\n\nPool units are fungible [tokens](?glossaryAnchor=tokens) that represent the proportional size of a user's contribution to a liquidity pool\n\nPool units are redeemable for the user's portion of the pool but can also be traded, sold and used in DeFi applications.\n\n---\n\nLiquidity pools play an integral role in lending and swapping on DeFi platforms. They work by liquidity providers (LPs) contributing tokens to a pool, thus creating a market for people to lend, borrow and swap. In return, these LPs receive tokens to show they've made a contribution to the pool. LPs usually get rewarded for their contributions in the form of fees paid by the people using the DeFi platform to swap and borrow crypto, but there are other ways for them to earn revenue.\n\nWith other wallets on other blockchains, this process raises risks. Other wallets can’t tell an LP what the tokens they received for providing liquidity are worth. Other wallets can’t even be sure they are actually tokens that represent a portion of a pool or that the tokens are redeemable. They don’t provide any confidence.\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) solves this with a native package called a “pool”. This package automatically implements the logic of minting and burning pool units in the proportion to other LPs’ contributions. It also means your [Radix Wallet](?glossaryAnchor=radixwallet) can always read what your pool units are worth and ensures they’re always redeemable for tokens from the liquidity pool.\n\n[Learn more about pool units](https://learn.radixdlt.com/article/what-are-pool-units-or-native-lp-tokens) ↗")
      /// ## Radix Connect
      /// 
      /// Radix Connect is the technology that lets users connect their [Radix Wallet](?glossaryAnchor=radixwallet) to [dApps](?glossaryAnchor=dapps) in mobile or desktop web browsers – and even more places in the future.
      /// 
      /// ---
      /// 
      /// To use Radix Connect with desktop browsers, there is a simple one-time setup flow that links the Radix Wallet on mobile to a desktop browser using the [Radix Connector browser extension](?glossaryAnchor=radixconnector). This extension provides a QR code to scan with your Radix Wallet, which setting up a connection between your Radix Wallet and your desktop browser.
      /// 
      /// The connection is fully end-to-end encrypted and is also peer-to-peer, meaning there will be no centralized server holding your data or sending your messages back and forth.
      /// 
      /// On mobile, the process is even easier. dApps in your mobile browser can directly connect to your Radix Wallet app running on the same phone.
      /// 
      /// [Learn more about Radix Connect](https://learn.radixdlt.com/article/what-is-radix-connect) ↗
      static let radixconnect = L10n.tr("Localizable", "infoLink_glossary_radixconnect", fallback: "## Radix Connect\n\nRadix Connect is the technology that lets users connect their [Radix Wallet](?glossaryAnchor=radixwallet) to [dApps](?glossaryAnchor=dapps) in mobile or desktop web browsers – and even more places in the future.\n\n---\n\nTo use Radix Connect with desktop browsers, there is a simple one-time setup flow that links the Radix Wallet on mobile to a desktop browser using the [Radix Connector browser extension](?glossaryAnchor=radixconnector). This extension provides a QR code to scan with your Radix Wallet, which setting up a connection between your Radix Wallet and your desktop browser.\n\nThe connection is fully end-to-end encrypted and is also peer-to-peer, meaning there will be no centralized server holding your data or sending your messages back and forth.\n\nOn mobile, the process is even easier. dApps in your mobile browser can directly connect to your Radix Wallet app running on the same phone.\n\n[Learn more about Radix Connect](https://learn.radixdlt.com/article/what-is-radix-connect) ↗")
      /// ## Radix Connector Browser Extension
      /// 
      /// When you want to use [dApp websites](?glossaryAnchor=dapps) on your desktop web browser, the Radix Connect browser extension helps make the connection to your [Radix Wallet](?glossaryAnchor=radixwallet) mobile app, quickly and securely.
      /// 
      /// ---
      /// 
      /// All you need to do is install it in your preferred desktop browser, link it to your Radix Wallet app via QR code, and it sits quietly in the background making the magic happen. It will also give you your list of [Accounts](?glossaryAnchor=accounts) for easy copying of addresses on desktop.
      /// 
      /// To download and set up the Radix Connector browser extension, visit **wallet.radixdlt.com** in your preferred desktop browser.
      /// 
      /// [Learn more about the Radix Connector browser extension](https://learn.radixdlt.com/article/what-is-the-radix-connector-browser-extension) ↗
      static let radixconnector = L10n.tr("Localizable", "infoLink_glossary_radixconnector", fallback: "## Radix Connector Browser Extension\n\nWhen you want to use [dApp websites](?glossaryAnchor=dapps) on your desktop web browser, the Radix Connect browser extension helps make the connection to your [Radix Wallet](?glossaryAnchor=radixwallet) mobile app, quickly and securely.\n\n---\n\nAll you need to do is install it in your preferred desktop browser, link it to your Radix Wallet app via QR code, and it sits quietly in the background making the magic happen. It will also give you your list of [Accounts](?glossaryAnchor=accounts) for easy copying of addresses on desktop.\n\nTo download and set up the Radix Connector browser extension, visit **wallet.radixdlt.com** in your preferred desktop browser.\n\n[Learn more about the Radix Connector browser extension](https://learn.radixdlt.com/article/what-is-the-radix-connector-browser-extension) ↗")
      /// ## The Radix Network
      /// 
      /// Radix is an open network that makes [web3](?glossaryAnchor=web3) possible. Think of the Radix Network as a place on the internet where users can directly control their own digital assets, and where those assets can move effortlessly between users and applications – without relying on any company.
      /// 
      /// ---
      /// 
      /// You can view and freely [transfer](?glossaryAnchor=transfers) your assets on the Radix Network using the [Radix Wallet](?glossaryAnchor=radixwallet) app. Applications built using the Radix Network’s capabilities (called [dApps](?glossaryAnchor=dapps) have the ability to interact with these assets and identities, letting you do things that weren't possible before on the web.
      /// 
      /// [Visit the official Radix homepage](https://radixdlt.com) ↗
      /// 
      /// [Learn more about the Radix Network](https://learn.radixdlt.com/article/what-are-the-radix-public-network-and-radix-ledger) ↗
      static let radixnetwork = L10n.tr("Localizable", "infoLink_glossary_radixnetwork", fallback: "## The Radix Network\n\nRadix is an open network that makes [web3](?glossaryAnchor=web3) possible. Think of the Radix Network as a place on the internet where users can directly control their own digital assets, and where those assets can move effortlessly between users and applications – without relying on any company.\n\n---\n\nYou can view and freely [transfer](?glossaryAnchor=transfers) your assets on the Radix Network using the [Radix Wallet](?glossaryAnchor=radixwallet) app. Applications built using the Radix Network’s capabilities (called [dApps](?glossaryAnchor=dapps) have the ability to interact with these assets and identities, letting you do things that weren't possible before on the web.\n\n[Visit the official Radix homepage](https://radixdlt.com) ↗\n\n[Learn more about the Radix Network](https://learn.radixdlt.com/article/what-are-the-radix-public-network-and-radix-ledger) ↗")
      /// ## Radix Wallet
      /// 
      /// The Radix Wallet is an iOS and Android mobile app that is your gateway to the capabilities of the Radix Network.
      /// 
      /// ---
      /// 
      /// It helps you create and use [Accounts](?glossaryAnchor=accounts) that can hold all of your digital assets on Radix, and [Personas](?glossaryAnchor=personas) that you can use to securely log in to [dApps](?glossaryAnchor=dapps) built on Radix without a password.
      /// 
      /// The Radix Wallet also makes sure that you are always in control of [transactions](?glossaryAnchor=transactions) that interact with your Accounts and assets.
      /// 
      /// Think of the Radix Wallet as your companion as you move between dApps on Radix – keeping your assets safe, and letting you choose who you are and what you bring with you on each dApp.
      /// 
      /// The Radix Wallet was created by the team who created the Radix Network’s technology, and is offered for free (and open-source) to let anyone use Radix and dApps built on Radix.
      /// 
      /// [Get the Radix Wallet](https://wallet.radixdlt.com/) ↗
      /// 
      /// [Learn more about the Radix Wallet](https://learn.radixdlt.com/article/what-is-the-radix-wallet) ↗
      static let radixwallet = L10n.tr("Localizable", "infoLink_glossary_radixwallet", fallback: "## Radix Wallet\n\nThe Radix Wallet is an iOS and Android mobile app that is your gateway to the capabilities of the Radix Network.\n\n---\n\nIt helps you create and use [Accounts](?glossaryAnchor=accounts) that can hold all of your digital assets on Radix, and [Personas](?glossaryAnchor=personas) that you can use to securely log in to [dApps](?glossaryAnchor=dapps) built on Radix without a password.\n\nThe Radix Wallet also makes sure that you are always in control of [transactions](?glossaryAnchor=transactions) that interact with your Accounts and assets.\n\nThink of the Radix Wallet as your companion as you move between dApps on Radix – keeping your assets safe, and letting you choose who you are and what you bring with you on each dApp.\n\nThe Radix Wallet was created by the team who created the Radix Network’s technology, and is offered for free (and open-source) to let anyone use Radix and dApps built on Radix.\n\n[Get the Radix Wallet](https://wallet.radixdlt.com/) ↗\n\n[Learn more about the Radix Wallet](https://learn.radixdlt.com/article/what-is-the-radix-wallet) ↗")
      /// ## Token
      /// 
      /// Token is the general term for any kind of web3 asset that you can hold in a crypto wallet.
      /// 
      /// Tokens can represent many things, like dollars and euros, shares of companies, cryptocurrencies, or imaginary currencies in games. One special kind of token on Radix is [XRD](?glossaryAnchor=xrd).
      /// 
      /// ---
      /// 
      /// The [Radix Network](?glossaryAnchor=radixnetwork) has special features specifically to make the creation and use of tokens on Radix safe and predictable, and the [Radix Wallet](?glossaryAnchor=radixwallet) can automatically provide useful information about the tokens you hold in your [Accounts](?glossaryAnchor=accounts).
      /// 
      /// Usually “token” is used specifically to refer to assets that are all alike. For example, one XRD token is exactly the same as any other XRD token. Assets where each token has a unique identity have a special term: [a non-fungible token or NFT](?glossaryAnchor=nfts).
      /// 
      /// [Learn more about tokens](https://learn.radixdlt.com/article/what-is-a-token) ↗
      /// 
      /// [Find out why tokens on Radix are better than other crypto networks](https://www.radixdlt.com/blog/its-10pm-do-you-know-where-your-tokens-are) ↗
      static let tokens = L10n.tr("Localizable", "infoLink_glossary_tokens", fallback: "## Token\n\nToken is the general term for any kind of web3 asset that you can hold in a crypto wallet.\n\nTokens can represent many things, like dollars and euros, shares of companies, cryptocurrencies, or imaginary currencies in games. One special kind of token on Radix is [XRD](?glossaryAnchor=xrd).\n\n---\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) has special features specifically to make the creation and use of tokens on Radix safe and predictable, and the [Radix Wallet](?glossaryAnchor=radixwallet) can automatically provide useful information about the tokens you hold in your [Accounts](?glossaryAnchor=accounts).\n\nUsually “token” is used specifically to refer to assets that are all alike. For example, one XRD token is exactly the same as any other XRD token. Assets where each token has a unique identity have a special term: [a non-fungible token or NFT](?glossaryAnchor=nfts).\n\n[Learn more about tokens](https://learn.radixdlt.com/article/what-is-a-token) ↗\n\n[Find out why tokens on Radix are better than other crypto networks](https://www.radixdlt.com/blog/its-10pm-do-you-know-where-your-tokens-are) ↗")
      /// ## Transaction Fee
      /// 
      /// Each time a [transaction](?glossaryAnchor=transactions) is submitted to the [Radix Network](?glossaryAnchor=radixnetwork), a _very_ small fee (usually only a few cents) has to be paid to the network itself.
      /// 
      /// This fee must be paid in [XRD tokens](?glossaryAnchor=xrd) and is paid as a part of each transaction.
      /// 
      /// ---
      /// 
      /// For transactions you submit to the network in your [Radix Wallet](?glossaryAnchor=radixwallet), you will see how much it will cost before you submit, and you can choose which [Account](?glossaryAnchor=accounts) you want to pay the fee from.
      /// 
      /// Transactions fees on Radix are split into 3 parts.
      /// 
      /// **Network fees**: These support Radix [node operators](?glossaryAnchor=validators) who validate transactions and secure the Radix Network. The size of network fees reflect the burden each transaction puts on the network.
      /// 
      /// **Royalties**: These are set by developers who deploy code or run applications on the network. Royalties allow developers to collect a “use fee” every time their work is used as part of a transaction.
      /// 
      /// **Tips**: These are optional payments users can make directly to validators to prioritize their own transactions during periods of high network demand. 
      /// 
      /// [Learn more about transaction fees](https://learn.radixdlt.com/article/how-do-transaction-fees-work-on-radix) ↗
      static let transactionfee = L10n.tr("Localizable", "infoLink_glossary_transactionfee", fallback: "## Transaction Fee\n\nEach time a [transaction](?glossaryAnchor=transactions) is submitted to the [Radix Network](?glossaryAnchor=radixnetwork), a _very_ small fee (usually only a few cents) has to be paid to the network itself.\n\nThis fee must be paid in [XRD tokens](?glossaryAnchor=xrd) and is paid as a part of each transaction.\n\n---\n\nFor transactions you submit to the network in your [Radix Wallet](?glossaryAnchor=radixwallet), you will see how much it will cost before you submit, and you can choose which [Account](?glossaryAnchor=accounts) you want to pay the fee from.\n\nTransactions fees on Radix are split into 3 parts.\n\n**Network fees**: These support Radix [node operators](?glossaryAnchor=validators) who validate transactions and secure the Radix Network. The size of network fees reflect the burden each transaction puts on the network.\n\n**Royalties**: These are set by developers who deploy code or run applications on the network. Royalties allow developers to collect a “use fee” every time their work is used as part of a transaction.\n\n**Tips**: These are optional payments users can make directly to validators to prioritize their own transactions during periods of high network demand. \n\n[Learn more about transaction fees](https://learn.radixdlt.com/article/how-do-transaction-fees-work-on-radix) ↗")
      /// ## Transactions
      /// 
      /// Any time a user or application wants to move assets around on the [Radix Network](?glossaryAnchor=radixnetwork), they must sign and submit a transaction to the network to do it.
      /// 
      /// ---
      /// 
      /// A transaction on Radix is basically a set of instructions to the network that might include things like “withdraw 10 XRD from my account” or “pass 2 RadGem NFTs to RadQuest”.
      /// 
      /// Transactions can be very simple – like sending tokens to somebody – or can be complex, with lots of steps and interactions with dApps. But no matter what, any time a transaction touches your own assets, you will see and approve it in your [Radix Wallet](?glossaryAnchor=radixwallet) app first.
      /// 
      /// [Learn more about transactions](https://learn.radixdlt.com/article/what-is-a-transaction-in-crypto) ↗
      /// 
      /// [Find out how transactions on Radix are better than other crypto networks](https://www.radixdlt.com/blog/radixs-asset-oriented-transactions) ↗
      static let transactions = L10n.tr("Localizable", "infoLink_glossary_transactions", fallback: "## Transactions\n\nAny time a user or application wants to move assets around on the [Radix Network](?glossaryAnchor=radixnetwork), they must sign and submit a transaction to the network to do it.\n\n---\n\nA transaction on Radix is basically a set of instructions to the network that might include things like “withdraw 10 XRD from my account” or “pass 2 RadGem NFTs to RadQuest”.\n\nTransactions can be very simple – like sending tokens to somebody – or can be complex, with lots of steps and interactions with dApps. But no matter what, any time a transaction touches your own assets, you will see and approve it in your [Radix Wallet](?glossaryAnchor=radixwallet) app first.\n\n[Learn more about transactions](https://learn.radixdlt.com/article/what-is-a-transaction-in-crypto) ↗\n\n[Find out how transactions on Radix are better than other crypto networks](https://www.radixdlt.com/blog/radixs-asset-oriented-transactions) ↗")
      /// ## Asset Transfers
      /// 
      /// The simplest kind of [transaction](?glossaryAnchor=transactions) on Radix is an asset transfer. It is simply a transaction to move a [token](?glossaryAnchor=tokens) or [NFT](?glossaryAnchor=nfts) from one [Account](?glossaryAnchor=accounts) to another.
      /// 
      /// The [Radix Wallet](?glossaryAnchor=radixwallet) lets you do asset transfers from your own Accounts without using any other [dApp](?glossaryAnchor=dapps). Simply go into the Account, tap the “Transfer” button, and fill in the recipient and the assets you want to transfer there. You can even choose multiple recipients and assets in a single asset transfer transaction.
      static let transfers = L10n.tr("Localizable", "infoLink_glossary_transfers", fallback: "## Asset Transfers\n\nThe simplest kind of [transaction](?glossaryAnchor=transactions) on Radix is an asset transfer. It is simply a transaction to move a [token](?glossaryAnchor=tokens) or [NFT](?glossaryAnchor=nfts) from one [Account](?glossaryAnchor=accounts) to another.\n\nThe [Radix Wallet](?glossaryAnchor=radixwallet) lets you do asset transfers from your own Accounts without using any other [dApp](?glossaryAnchor=dapps). Simply go into the Account, tap the “Transfer” button, and fill in the recipient and the assets you want to transfer there. You can even choose multiple recipients and assets in a single asset transfer transaction.")
      /// ## Radix Network Validators
      /// 
      /// The [Radix Network](?glossaryAnchor=radixnetwork) is an open network that anybody can freely use. To make that possible, the network isn’t run by a company, but by an open community of “validators”.
      /// 
      /// ---
      /// 
      /// Each validator is a server run by somebody that helps “validate” [transactions](?glossaryAnchor=transactions). Working together, validators make sure that transactions are correctly processed and committed on the Radix Network.
      /// 
      /// When you [stake XRD tokens to the network](?glossaryAnchor=networkstaking), you select validators that you trust to correctly and reliably keep running the Radix Network - it's a big responsibility, kind of like voting in an open election to pick good leaders.
      /// 
      /// Start with the link below to consider how you choose the validators that you stake to.
      /// 
      /// [Learn how to choose validators](https://learn.radixdlt.com/article/how-should-i-choose-validators-to-stake-to) ↗
      static let validators = L10n.tr("Localizable", "infoLink_glossary_validators", fallback: "## Radix Network Validators\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) is an open network that anybody can freely use. To make that possible, the network isn’t run by a company, but by an open community of “validators”.\n\n---\n\nEach validator is a server run by somebody that helps “validate” [transactions](?glossaryAnchor=transactions). Working together, validators make sure that transactions are correctly processed and committed on the Radix Network.\n\nWhen you [stake XRD tokens to the network](?glossaryAnchor=networkstaking), you select validators that you trust to correctly and reliably keep running the Radix Network - it's a big responsibility, kind of like voting in an open election to pick good leaders.\n\nStart with the link below to consider how you choose the validators that you stake to.\n\n[Learn how to choose validators](https://learn.radixdlt.com/article/how-should-i-choose-validators-to-stake-to) ↗")
      /// ## Web3
      /// 
      /// Web3 is the name given to the latest stage in the evolution of the internet. It is underpinned by blockchain technology and is intended to give users more control over their online assets, identity, and data.
      /// 
      /// ---
      /// 
      /// In the beginning, the web was all about just viewing content produced by other people. Here’s a webpage, look at it, click it. That was Web1.
      /// 
      /// **Web2** made it possible for users to create their own content online. Social media, social news, photo sharing, and more became possible – communicating on the web became a 2-way street
      /// 
      /// However, parts of the web are still a 1-way street. While we have control of what we create and share, we don’t have control over _what we own_ and _who we are_. Your money and everything you can do with it is still locked inside separate bank or payment apps, and your logins are specific to every website (if not controlled by Google or Apple or Meta).
      /// 
      /// **Web3** now adds the ability for users to own their own digital assets and digital identities online, and allows websites and other applications to interact with these truly digital-native assets and identities in powerful new ways.
      /// 
      /// Cryptocurrencies like Bitcoin were the very beginning of web3, but it goes so much further. In web3, “Decentralized Finance” becomes possible, making finance cheaper, better, and more accessible to anyone – financial services compete to put your money to work, rather than charging you for the privilege of holding it. And new things become possible; imagine logging out of your favorite game, but taking your equipment with you to trade with others directly, outside the game?
      /// 
      /// This new capability is generally enabled by blockchain technology, but it is in its early days. [Radix](?glossaryAnchor=radixnetwork) is pushing the cutting edge of making web3 ready for average users and real applications that matter.
      static let web3 = L10n.tr("Localizable", "infoLink_glossary_web3", fallback: "## Web3\n\nWeb3 is the name given to the latest stage in the evolution of the internet. It is underpinned by blockchain technology and is intended to give users more control over their online assets, identity, and data.\n\n---\n\nIn the beginning, the web was all about just viewing content produced by other people. Here’s a webpage, look at it, click it. That was Web1.\n\n**Web2** made it possible for users to create their own content online. Social media, social news, photo sharing, and more became possible – communicating on the web became a 2-way street\n\nHowever, parts of the web are still a 1-way street. While we have control of what we create and share, we don’t have control over _what we own_ and _who we are_. Your money and everything you can do with it is still locked inside separate bank or payment apps, and your logins are specific to every website (if not controlled by Google or Apple or Meta).\n\n**Web3** now adds the ability for users to own their own digital assets and digital identities online, and allows websites and other applications to interact with these truly digital-native assets and identities in powerful new ways.\n\nCryptocurrencies like Bitcoin were the very beginning of web3, but it goes so much further. In web3, “Decentralized Finance” becomes possible, making finance cheaper, better, and more accessible to anyone – financial services compete to put your money to work, rather than charging you for the privilege of holding it. And new things become possible; imagine logging out of your favorite game, but taking your equipment with you to trade with others directly, outside the game?\n\nThis new capability is generally enabled by blockchain technology, but it is in its early days. [Radix](?glossaryAnchor=radixnetwork) is pushing the cutting edge of making web3 ready for average users and real applications that matter.")
      /// ## XRD Token
      /// 
      /// XRD is the official Radix Network token.
      /// 
      /// ---
      /// 
      ///  It is created by the [Radix Network](?glossaryAnchor=radixnetwork) itself and users and applications can use it to use features of the network. For example, [transaction fees](?glossaryAnchor=transactionfee) are always paid in XRD, and XRD is the only token that can be used to participate in [Radix Network staking](?glossaryAnchor=networkstaking).
      /// 
      /// Because XRD has a special role on Radix, XRD is also frequently used by [dApps](?glossaryAnchor=dapps) on Radix as a convenient form of money to pay for things and to enable exchanges with other tokens.
      /// 
      /// [Buy XRD tokens](https://www.radixdlt.com/token) ↗
      /// 
      /// [Learn more about the XRD token](https://learn.radixdlt.com/article/what-is-the-xrd-token) ↗
      static let xrd = L10n.tr("Localizable", "infoLink_glossary_xrd", fallback: "## XRD Token\n\nXRD is the official Radix Network token.\n\n---\n\n It is created by the [Radix Network](?glossaryAnchor=radixnetwork) itself and users and applications can use it to use features of the network. For example, [transaction fees](?glossaryAnchor=transactionfee) are always paid in XRD, and XRD is the only token that can be used to participate in [Radix Network staking](?glossaryAnchor=networkstaking).\n\nBecause XRD has a special role on Radix, XRD is also frequently used by [dApps](?glossaryAnchor=dapps) on Radix as a convenient form of money to pay for things and to enable exchanges with other tokens.\n\n[Buy XRD tokens](https://www.radixdlt.com/token) ↗\n\n[Learn more about the XRD token](https://learn.radixdlt.com/article/what-is-the-xrd-token) ↗")
    }
    enum Title {
      /// What are behaviors?
      static let behaviors = L10n.tr("Localizable", "infoLink_title_behaviors", fallback: "What are behaviors?")
      /// What is a dApp?
      static let dapps = L10n.tr("Localizable", "infoLink_title_dapps", fallback: "What is a dApp?")
      /// What is a Gateway?
      static let gateways = L10n.tr("Localizable", "infoLink_title_gateways", fallback: "What is a Gateway?")
      /// How do guarantees work?
      static let guarantees = L10n.tr("Localizable", "infoLink_title_guarantees", fallback: "How do guarantees work?")
      /// What is Staking?
      static let networkstaking = L10n.tr("Localizable", "infoLink_title_networkstaking", fallback: "What is Staking?")
      /// What are NFTs?
      static let nfts = L10n.tr("Localizable", "infoLink_title_nfts", fallback: "What are NFTs?")
      /// What is a Persona?
      static let personas = L10n.tr("Localizable", "infoLink_title_personas", fallback: "What is a Persona?")
      /// Learn about Personas
      static let personasLearnAbout = L10n.tr("Localizable", "infoLink_title_personasLearnAbout", fallback: "Learn about Personas")
      /// What are Pool units?
      static let poolunits = L10n.tr("Localizable", "infoLink_title_poolunits", fallback: "What are Pool units?")
      /// Learn more about Radix Connect
      static let radixconnect = L10n.tr("Localizable", "infoLink_title_radixconnect", fallback: "Learn more about Radix Connect")
      /// What are Tokens?
      static let tokens = L10n.tr("Localizable", "infoLink_title_tokens", fallback: "What are Tokens?")
      /// How do fees work?
      static let transactionfee = L10n.tr("Localizable", "infoLink_title_transactionfee", fallback: "How do fees work?")
    }
  }
  enum LedgerHardwareDevices {
    /// Added
    static let addedHeading = L10n.tr("Localizable", "ledgerHardwareDevices_addedHeading", fallback: "Added")
    /// Add Ledger Device
    static let addNewLedger = L10n.tr("Localizable", "ledgerHardwareDevices_addNewLedger", fallback: "Add Ledger Device")
    /// Continue
    static let continueWithLedger = L10n.tr("Localizable", "ledgerHardwareDevices_continueWithLedger", fallback: "Continue")
    /// What is a Ledger Factor Source
    static let ledgerFactorSourceInfoCaption = L10n.tr("Localizable", "ledgerHardwareDevices_ledgerFactorSourceInfoCaption", fallback: "What is a Ledger Factor Source")
    /// Choose Ledger
    static let navigationTitleAllowSelection = L10n.tr("Localizable", "ledgerHardwareDevices_navigationTitleAllowSelection", fallback: "Choose Ledger")
    /// Ledger Devices
    static let navigationTitleGeneral = L10n.tr("Localizable", "ledgerHardwareDevices_navigationTitleGeneral", fallback: "Ledger Devices")
    /// Choose Ledger Device
    static let navigationTitleNoSelection = L10n.tr("Localizable", "ledgerHardwareDevices_navigationTitleNoSelection", fallback: "Choose Ledger Device")
    /// Here are all the Ledger devices you have added.
    static let subtitleAllLedgers = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleAllLedgers", fallback: "Here are all the Ledger devices you have added.")
    /// Could not find Ledger devices
    static let subtitleFailure = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleFailure", fallback: "Could not find Ledger devices")
    /// No Ledger devices currently added to your Radix Wallet
    static let subtitleNoLedgers = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleNoLedgers", fallback: "No Ledger devices currently added to your Radix Wallet")
    /// Choose a Ledger device to use
    static let subtitleSelectLedger = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleSelectLedger", fallback: "Choose a Ledger device to use")
    /// Choose an existing Ledger or add a new one
    static let subtitleSelectLedgerExisting = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleSelectLedgerExisting", fallback: "Choose an existing Ledger or add a new one")
    /// Last Used
    static let usedHeading = L10n.tr("Localizable", "ledgerHardwareDevices_usedHeading", fallback: "Last Used")
    enum CouldNotSign {
      /// Transaction could not be signed. To sign complex transactions, please enable either "blind signing" or "verbose mode" in the Radix app on your Ledger device.
      static let message = L10n.tr("Localizable", "ledgerHardwareDevices_couldNotSign_message", fallback: "Transaction could not be signed. To sign complex transactions, please enable either \"blind signing\" or \"verbose mode\" in the Radix app on your Ledger device.")
      /// Could Not Sign
      static let title = L10n.tr("Localizable", "ledgerHardwareDevices_couldNotSign_title", fallback: "Could Not Sign")
    }
    enum LinkConnectorAlert {
      /// Continue
      static let `continue` = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_continue", fallback: "Continue")
      /// To use a Ledger hardware wallet device, it must be connected to a computer running the Radix Connector browser extension.
      static let message = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_message", fallback: "To use a Ledger hardware wallet device, it must be connected to a computer running the Radix Connector browser extension.")
      /// Link a Connector
      static let title = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_title", fallback: "Link a Connector")
    }
    enum Verification {
      /// Address verified
      static let addressVerified = L10n.tr("Localizable", "ledgerHardwareDevices_verification_addressVerified", fallback: "Address verified")
      /// Verify address: Returned bad response
      static let badResponse = L10n.tr("Localizable", "ledgerHardwareDevices_verification_badResponse", fallback: "Verify address: Returned bad response")
      /// Verify address: Mismatched addresses
      static let mismatch = L10n.tr("Localizable", "ledgerHardwareDevices_verification_mismatch", fallback: "Verify address: Mismatched addresses")
      /// Verify address: Request failed
      static let requestFailed = L10n.tr("Localizable", "ledgerHardwareDevices_verification_requestFailed", fallback: "Verify address: Request failed")
    }
  }
  enum LinkedConnectors {
    /// Changing a Connector’s type is not supported.
    static let changingPurposeNotSupportedErrorMessage = L10n.tr("Localizable", "linkedConnectors_changingPurposeNotSupportedErrorMessage", fallback: "Changing a Connector’s type is not supported.")
    /// Please scan the QR code provided by your Radix Wallet Connector browser extension.
    static let incorrectQrMessage = L10n.tr("Localizable", "linkedConnectors_incorrectQrMessage", fallback: "Please scan the QR code provided by your Radix Wallet Connector browser extension.")
    /// Incorrect QR code scanned.
    static let incorrectQrTitle = L10n.tr("Localizable", "linkedConnectors_incorrectQrTitle", fallback: "Incorrect QR code scanned.")
    /// Last connected %@
    static func lastConnected(_ p1: Any) -> String {
      return L10n.tr("Localizable", "linkedConnectors_lastConnected", String(describing: p1), fallback: "Last connected %@")
    }
    /// Link Failed
    static let linkFailedErrorTitle = L10n.tr("Localizable", "linkedConnectors_linkFailedErrorTitle", fallback: "Link Failed")
    /// Link New Connector
    static let linkNewConnector = L10n.tr("Localizable", "linkedConnectors_linkNewConnector", fallback: "Link New Connector")
    /// This is an old version of the Radix Connector browser extension. Please update to the latest Connector and try linking again.
    static let oldQRErrorMessage = L10n.tr("Localizable", "linkedConnectors_oldQRErrorMessage", fallback: "This is an old version of the Radix Connector browser extension. Please update to the latest Connector and try linking again.")
    /// Your Radix Wallet is linked to the following desktop browsers using the Connector browser extension.
    static let subtitle = L10n.tr("Localizable", "linkedConnectors_subtitle", fallback: "Your Radix Wallet is linked to the following desktop browsers using the Connector browser extension.")
    /// Linked Connectors
    static let title = L10n.tr("Localizable", "linkedConnectors_title", fallback: "Linked Connectors")
    /// This type of Connector link is not supported.
    static let unknownPurposeErrorMessage = L10n.tr("Localizable", "linkedConnectors_unknownPurposeErrorMessage", fallback: "This type of Connector link is not supported.")
    enum ApproveExistingConnector {
      /// This appears to be a Radix Connector you previously linked to. Link will be updated.
      static let message = L10n.tr("Localizable", "linkedConnectors_approveExistingConnector_message", fallback: "This appears to be a Radix Connector you previously linked to. Link will be updated.")
      /// Update Link
      static let title = L10n.tr("Localizable", "linkedConnectors_approveExistingConnector_title", fallback: "Update Link")
    }
    enum ApproveNewConnector {
      /// This Connector will be trusted to verify the dApp origin of requests to this wallet.
      /// 
      /// Only continue if you are linking to the **official Radix Connector browser extension** - or a Connector you control and trust.
      static let message = L10n.tr("Localizable", "linkedConnectors_approveNewConnector_message", fallback: "This Connector will be trusted to verify the dApp origin of requests to this wallet.\n\nOnly continue if you are linking to the **official Radix Connector browser extension** - or a Connector you control and trust.")
      /// Link Connector
      static let title = L10n.tr("Localizable", "linkedConnectors_approveNewConnector_title", fallback: "Link Connector")
    }
    enum CameraPermissionDeniedAlert {
      /// Camera access is required to link to a Connector.
      static let message = L10n.tr("Localizable", "linkedConnectors_cameraPermissionDeniedAlert_message", fallback: "Camera access is required to link to a Connector.")
      /// Access Required
      static let title = L10n.tr("Localizable", "linkedConnectors_cameraPermissionDeniedAlert_title", fallback: "Access Required")
    }
    enum LocalNetworkPermissionDeniedAlert {
      /// Local network access is required to link to a Connector.
      static let message = L10n.tr("Localizable", "linkedConnectors_localNetworkPermissionDeniedAlert_message", fallback: "Local network access is required to link to a Connector.")
      /// Access Required
      static let title = L10n.tr("Localizable", "linkedConnectors_localNetworkPermissionDeniedAlert_title", fallback: "Access Required")
    }
    enum NameNewConnector {
      /// Continue
      static let saveLinkButtonTitle = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_saveLinkButtonTitle", fallback: "Continue")
      /// What would you like to call this Radix Connector installation?
      static let subtitle = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_subtitle", fallback: "What would you like to call this Radix Connector installation?")
      /// Name this connector e.g. ‘Chrome on MacBook Pro’
      static let textFieldHint = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_textFieldHint", fallback: "Name this connector e.g. ‘Chrome on MacBook Pro’")
      /// e.g. Chrome on Personal Laptop
      static let textFieldPlaceholder = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_textFieldPlaceholder", fallback: "e.g. Chrome on Personal Laptop")
      /// Name New Connector
      static let title = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_title", fallback: "Name New Connector")
    }
    enum NewConnection {
      /// Linking…
      static let linking = L10n.tr("Localizable", "linkedConnectors_newConnection_linking", fallback: "Linking…")
      /// Open your Radix Connector extension's menu by clicking its icon in your list of browser extensions, and scan the QR code shown.
      static let subtitle = L10n.tr("Localizable", "linkedConnectors_newConnection_subtitle", fallback: "Open your Radix Connector extension's menu by clicking its icon in your list of browser extensions, and scan the QR code shown.")
      /// Link Connector
      static let title = L10n.tr("Localizable", "linkedConnectors_newConnection_title", fallback: "Link Connector")
    }
    enum RelinkConnectors {
      /// Any Connectors you had linked to this wallet using a different phone have been disconnected
      /// 
      /// **Please re-link your Connector(s) to use with this phone.**
      static let afterProfileRestoreMessage = L10n.tr("Localizable", "linkedConnectors_relinkConnectors_afterProfileRestoreMessage", fallback: "Any Connectors you had linked to this wallet using a different phone have been disconnected\n\n**Please re-link your Connector(s) to use with this phone.**")
      /// Radix Connector now supports linking multiple phones with one browser.
      /// 
      /// To support this feature, we've had to disconnect your existing links – **please re-link your Connector(s).**
      static let afterUpdateMessage = L10n.tr("Localizable", "linkedConnectors_relinkConnectors_afterUpdateMessage", fallback: "Radix Connector now supports linking multiple phones with one browser.\n\nTo support this feature, we've had to disconnect your existing links – **please re-link your Connector(s).**")
      /// Later
      static let laterButton = L10n.tr("Localizable", "linkedConnectors_relinkConnectors_laterButton", fallback: "Later")
      /// Re-link Connector
      static let title = L10n.tr("Localizable", "linkedConnectors_relinkConnectors_title", fallback: "Re-link Connector")
    }
    enum RemoveConnectionAlert {
      /// You will no longer be able to connect your wallet to this device and browser combination.
      static let message = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_message", fallback: "You will no longer be able to connect your wallet to this device and browser combination.")
      /// Remove
      static let removeButtonTitle = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_removeButtonTitle", fallback: "Remove")
      /// Remove Connection
      static let title = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_title", fallback: "Remove Connection")
    }
    enum RenameConnector {
      /// Linked Connector name required
      static let errorEmpty = L10n.tr("Localizable", "linkedConnectors_renameConnector_errorEmpty", fallback: "Linked Connector name required")
      /// Enter a new name for this Linked Connector
      static let subtitle = L10n.tr("Localizable", "linkedConnectors_renameConnector_subtitle", fallback: "Enter a new name for this Linked Connector")
      /// Updated
      static let successHud = L10n.tr("Localizable", "linkedConnectors_renameConnector_successHud", fallback: "Updated")
      /// Rename Connector
      static let title = L10n.tr("Localizable", "linkedConnectors_renameConnector_title", fallback: "Rename Connector")
      /// Update
      static let update = L10n.tr("Localizable", "linkedConnectors_renameConnector_update", fallback: "Update")
    }
  }
  enum Misc {
    enum RemoteThumbnails {
      /// Can't load image
      static let loadingFailure = L10n.tr("Localizable", "misc_remoteThumbnails_loadingFailure", fallback: "Can't load image")
      /// Can't displays image of vector type
      static let vectorImageFailure = L10n.tr("Localizable", "misc_remoteThumbnails_vectorImageFailure", fallback: "Can't displays image of vector type")
    }
  }
  enum MobileConnect {
    /// Switch back to your browser to continue
    static let interactionSuccess = L10n.tr("Localizable", "mobileConnect_interactionSuccess", fallback: "Switch back to your browser to continue")
    /// Does the website address match what you’re expecting?
    static let linkBody1 = L10n.tr("Localizable", "mobileConnect_linkBody1", fallback: "Does the website address match what you’re expecting?")
    /// If you came from a social media ad, is the website legitimate?
    static let linkBody2 = L10n.tr("Localizable", "mobileConnect_linkBody2", fallback: "If you came from a social media ad, is the website legitimate?")
    /// Before you connect to **%@**, you might want to check:
    static func linkSubtitle(_ p1: Any) -> String {
      return L10n.tr("Localizable", "mobileConnect_linkSubtitle", String(describing: p1), fallback: "Before you connect to **%@**, you might want to check:")
    }
    /// Have you come from a genuine website?
    static let linkTitle = L10n.tr("Localizable", "mobileConnect_linkTitle", fallback: "Have you come from a genuine website?")
    enum NoProfileDialog {
      /// You can proceed with this request after you create or restore your Radix Wallet.
      static let subtitle = L10n.tr("Localizable", "mobileConnect_noProfileDialog_subtitle", fallback: "You can proceed with this request after you create or restore your Radix Wallet.")
      /// dApp Request
      static let title = L10n.tr("Localizable", "mobileConnect_noProfileDialog_title", fallback: "dApp Request")
    }
  }
  enum Onboarding {
    /// I'm a New Radix Wallet User
    static let newUser = L10n.tr("Localizable", "onboarding_newUser", fallback: "I'm a New Radix Wallet User")
    /// Restore Wallet from Backup
    static let restoreFromBackup = L10n.tr("Localizable", "onboarding_restoreFromBackup", fallback: "Restore Wallet from Backup")
    enum CloudAndroid {
      /// Back up to Google Drive
      static let backupButton = L10n.tr("Localizable", "onboarding_cloudAndroid_backupButton", fallback: "Back up to Google Drive")
      /// Connect to Google Drive to automatically backup your Radix wallet settings.
      static let backupSubtitle = L10n.tr("Localizable", "onboarding_cloudAndroid_backupSubtitle", fallback: "Connect to Google Drive to automatically backup your Radix wallet settings.")
      /// Back up your Wallet Settings
      static let backupTitle = L10n.tr("Localizable", "onboarding_cloudAndroid_backupTitle", fallback: "Back up your Wallet Settings")
      /// Skip
      static let skip = L10n.tr("Localizable", "onboarding_cloudAndroid_skip", fallback: "Skip")
    }
    enum CloudRestoreAndroid {
      /// Log in to Google Drive to restore your Radix wallet from Backup.
      static let backupSubtitle = L10n.tr("Localizable", "onboarding_cloudRestoreAndroid_backupSubtitle", fallback: "Log in to Google Drive to restore your Radix wallet from Backup.")
      /// Restore Wallet from Backup
      static let backupTitle = L10n.tr("Localizable", "onboarding_cloudRestoreAndroid_backupTitle", fallback: "Restore Wallet from Backup")
      /// Log in to Google Drive
      static let loginButton = L10n.tr("Localizable", "onboarding_cloudRestoreAndroid_loginButton", fallback: "Log in to Google Drive")
      /// Skip
      static let skip = L10n.tr("Localizable", "onboarding_cloudRestoreAndroid_skip", fallback: "Skip")
    }
    enum Eula {
      /// Accept
      static let accept = L10n.tr("Localizable", "onboarding_eula_accept", fallback: "Accept")
      /// To proceed, you must accept the user terms below.
      static let headerSubtitle = L10n.tr("Localizable", "onboarding_eula_headerSubtitle", fallback: "To proceed, you must accept the user terms below.")
      /// User Terms
      static let headerTitle = L10n.tr("Localizable", "onboarding_eula_headerTitle", fallback: "User Terms")
    }
    enum Step1 {
      /// Your direct connection to the Radix Network
      static let subtitle = L10n.tr("Localizable", "onboarding_step1_subtitle", fallback: "Your direct connection to the Radix Network")
      /// Welcome to the Radix Wallet
      static let title = L10n.tr("Localizable", "onboarding_step1_title", fallback: "Welcome to the Radix Wallet")
    }
    enum Step2 {
      /// Let's get started
      static let subtitle = L10n.tr("Localizable", "onboarding_step2_subtitle", fallback: "Let's get started")
      /// A World of Possibilities
      static let title = L10n.tr("Localizable", "onboarding_step2_title", fallback: "A World of Possibilities")
    }
    enum Step3 {
      /// Connect and transact securely with a world of web3 dApps, tokens, NFTs, and much more
      static let subtitle = L10n.tr("Localizable", "onboarding_step3_subtitle", fallback: "Connect and transact securely with a world of web3 dApps, tokens, NFTs, and much more")
      /// Your phone is your login
      static let title = L10n.tr("Localizable", "onboarding_step3_title", fallback: "Your phone is your login")
    }
  }
  enum Personas {
    /// Create a New Persona
    static let createNewPersona = L10n.tr("Localizable", "personas_createNewPersona", fallback: "Create a New Persona")
    /// Here are all of your current Personas in your Radix Wallet.
    static let subtitle = L10n.tr("Localizable", "personas_subtitle", fallback: "Here are all of your current Personas in your Radix Wallet.")
    /// Personas
    static let title = L10n.tr("Localizable", "personas_title", fallback: "Personas")
    /// Write down main seed phrase
    static let writeSeedPhrase = L10n.tr("Localizable", "personas_writeSeedPhrase", fallback: "Write down main seed phrase")
  }
  enum Preferences {
    /// Advanced Preferences
    static let advancedPreferences = L10n.tr("Localizable", "preferences_advancedPreferences", fallback: "Advanced Preferences")
    /// Display
    static let displayPreferences = L10n.tr("Localizable", "preferences_displayPreferences", fallback: "Display")
    /// Network Gateways
    static let gateways = L10n.tr("Localizable", "preferences_gateways", fallback: "Network Gateways")
    /// Preferences
    static let title = L10n.tr("Localizable", "preferences_title", fallback: "Preferences")
    enum AdvancedLock {
      /// Re-authenticate when switching between apps
      static let subtitle = L10n.tr("Localizable", "preferences_advancedLock_subtitle", fallback: "Re-authenticate when switching between apps")
      /// Advanced Lock
      static let title = L10n.tr("Localizable", "preferences_advancedLock_title", fallback: "Advanced Lock")
    }
    enum AdvancedLockAndroid {
      /// Re-authenticate when switching, prevent screen recording
      static let subtitle = L10n.tr("Localizable", "preferences_advancedLockAndroid_subtitle", fallback: "Re-authenticate when switching, prevent screen recording")
    }
    enum DepositGuarantees {
      /// Set your guaranteed minimum for estimated deposits
      static let subtitle = L10n.tr("Localizable", "preferences_depositGuarantees_subtitle", fallback: "Set your guaranteed minimum for estimated deposits")
      /// Default Deposit Guarantees
      static let title = L10n.tr("Localizable", "preferences_depositGuarantees_title", fallback: "Default Deposit Guarantees")
    }
    enum DeveloperMode {
      /// Warning: disables website validity checks
      static let subtitle = L10n.tr("Localizable", "preferences_developerMode_subtitle", fallback: "Warning: disables website validity checks")
      /// Developer Mode
      static let title = L10n.tr("Localizable", "preferences_developerMode_title", fallback: "Developer Mode")
    }
    enum HiddenAssets {
      /// Manage hidden Tokens, NFTs, and other asset types
      static let subtitle = L10n.tr("Localizable", "preferences_hiddenAssets_subtitle", fallback: "Manage hidden Tokens, NFTs, and other asset types")
      /// Hidden Assets
      static let title = L10n.tr("Localizable", "preferences_hiddenAssets_title", fallback: "Hidden Assets")
    }
    enum HiddenEntities {
      /// Manage hidden Personas and Accounts
      static let subtitle = L10n.tr("Localizable", "preferences_hiddenEntities_subtitle", fallback: "Manage hidden Personas and Accounts")
      /// Hidden Personas & Accounts
      static let title = L10n.tr("Localizable", "preferences_hiddenEntities_title", fallback: "Hidden Personas & Accounts")
    }
  }
  enum ProfileBackup {
    /// Backing up your wallet ensures that you can restore access to your Accounts, Personas, and wallet settings on a new phone by re-entering your seed phrase(s).
    /// 
    /// **For security, backups do not contain any seed phrases or private keys. You must write them down separately.**
    static let headerTitle = L10n.tr("Localizable", "profileBackup_headerTitle", fallback: "Backing up your wallet ensures that you can restore access to your Accounts, Personas, and wallet settings on a new phone by re-entering your seed phrase(s).\n\n**For security, backups do not contain any seed phrases or private keys. You must write them down separately.**")
    enum AutomaticBackups {
      /// Automatic Backups (recommended)
      static let title = L10n.tr("Localizable", "profileBackup_automaticBackups_title", fallback: "Automatic Backups (recommended)")
    }
    enum DeleteWallet {
      /// Delete Wallet
      static let buttonTitle = L10n.tr("Localizable", "profileBackup_deleteWallet_buttonTitle", fallback: "Delete Wallet")
    }
    enum DeleteWalletDialog {
      /// Delete Wallet
      static let confirm = L10n.tr("Localizable", "profileBackup_deleteWalletDialog_confirm", fallback: "Delete Wallet")
      /// WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.
      static let message = L10n.tr("Localizable", "profileBackup_deleteWalletDialog_message", fallback: "WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.")
    }
    enum IncorrectPasswordAlert {
      /// Failed to decrypt using provided password.
      static let messageDecryption = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_messageDecryption", fallback: "Failed to decrypt using provided password.")
      /// Failed to encrypt using provided password.
      static let messageEncryption = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_messageEncryption", fallback: "Failed to encrypt using provided password.")
      /// OK
      static let okAction = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_okAction", fallback: "OK")
      /// Incorrect password
      static let title = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_title", fallback: "Incorrect password")
    }
    enum ManualBackups {
      /// Confirm password
      static let confirmPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_confirmPasswordPlaceholder", fallback: "Confirm password")
      /// Enter the password you chose when you originally encrypted this Wallet Backup file.
      static let decryptBackupSubtitle = L10n.tr("Localizable", "profileBackup_manualBackups_decryptBackupSubtitle", fallback: "Enter the password you chose when you originally encrypted this Wallet Backup file.")
      /// Decrypt Wallet Backup File
      static let decryptBackupTitle = L10n.tr("Localizable", "profileBackup_manualBackups_decryptBackupTitle", fallback: "Decrypt Wallet Backup File")
      /// Yes
      static let encryptBackupDialogConfirm = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupDialogConfirm", fallback: "Yes")
      /// No
      static let encryptBackupDialogDeny = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupDialogDeny", fallback: "No")
      /// Encrypt this backup with a password?
      static let encryptBackupDialogTitle = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupDialogTitle", fallback: "Encrypt this backup with a password?")
      /// Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.
      static let encryptBackupSubtitle = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupSubtitle", fallback: "Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.")
      /// Encrypt Wallet Backup File
      static let encryptBackupTitle = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupTitle", fallback: "Encrypt Wallet Backup File")
      /// Enter password
      static let enterPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_enterPasswordPlaceholder", fallback: "Enter password")
      /// Export Wallet Backup File
      static let exportButtonTitle = L10n.tr("Localizable", "profileBackup_manualBackups_exportButtonTitle", fallback: "Export Wallet Backup File")
      /// Decryption password
      static let nonConformingDecryptionPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_nonConformingDecryptionPasswordPlaceholder", fallback: "Decryption password")
      /// Encryption password
      static let nonConformingEncryptionPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_nonConformingEncryptionPasswordPlaceholder", fallback: "Encryption password")
      /// Passwords do not match
      static let passwordsMissmatchError = L10n.tr("Localizable", "profileBackup_manualBackups_passwordsMissmatchError", fallback: "Passwords do not match")
      /// A manually exported wallet backup file may also be used for recovery, along with your seed phrase(s).
      /// 
      /// Only the **current configuration** of your wallet is backed up with each manual export.
      static let subtitle = L10n.tr("Localizable", "profileBackup_manualBackups_subtitle", fallback: "A manually exported wallet backup file may also be used for recovery, along with your seed phrase(s).\n\nOnly the **current configuration** of your wallet is backed up with each manual export.")
      /// Exported wallet backup file
      static let successMessage = L10n.tr("Localizable", "profileBackup_manualBackups_successMessage", fallback: "Exported wallet backup file")
      /// Manual Backups
      static let title = L10n.tr("Localizable", "profileBackup_manualBackups_title", fallback: "Manual Backups")
    }
    enum ResetWalletDialog {
      /// WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.
      static let message = L10n.tr("Localizable", "profileBackup_resetWalletDialog_message", fallback: "WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.")
      /// Reset and Delete iCloud Backup
      static let resetAndDeleteBackupButtonTitle = L10n.tr("Localizable", "profileBackup_resetWalletDialog_resetAndDeleteBackupButtonTitle", fallback: "Reset and Delete iCloud Backup")
      /// Reset Wallet
      static let resetButtonTitle = L10n.tr("Localizable", "profileBackup_resetWalletDialog_resetButtonTitle", fallback: "Reset Wallet")
      /// Reset Wallet?
      static let title = L10n.tr("Localizable", "profileBackup_resetWalletDialog_title", fallback: "Reset Wallet?")
    }
  }
  enum RecoverProfileBackup {
    /// **Backup from:** %@
    static func backupFrom(_ p1: Any) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_backupFrom", String(describing: p1), fallback: "**Backup from:** %@")
    }
    /// Backup not available?
    static let backupNotAvailable = L10n.tr("Localizable", "recoverProfileBackup_backupNotAvailable", fallback: "Backup not available?")
    /// Could not load backups
    static let couldNotLoadBackups = L10n.tr("Localizable", "recoverProfileBackup_couldNotLoadBackups", fallback: "Could not load backups")
    /// Incompatible Wallet data
    static let incompatibleWalletDataLabel = L10n.tr("Localizable", "recoverProfileBackup_incompatibleWalletDataLabel", fallback: "Incompatible Wallet data")
    /// **Last modified:** %@
    static func lastModified(_ p1: Any) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_lastModified", String(describing: p1), fallback: "**Last modified:** %@")
    }
    /// Network unavailable
    static let networkUnavailable = L10n.tr("Localizable", "recoverProfileBackup_networkUnavailable", fallback: "Network unavailable")
    /// **Number of accounts:** %d
    static func numberOfAccounts(_ p1: Int) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_numberOfAccounts", p1, fallback: "**Number of accounts:** %d")
    }
    /// **Number of personas:** %d
    static func numberOfPersonas(_ p1: Int) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_numberOfPersonas", p1, fallback: "**Number of personas:** %d")
    }
    /// Other Restore Options
    static let otherRestoreOptionsButton = L10n.tr("Localizable", "recoverProfileBackup_otherRestoreOptionsButton", fallback: "Other Restore Options")
    /// The password is wrong
    static let passwordWrong = L10n.tr("Localizable", "recoverProfileBackup_passwordWrong", fallback: "The password is wrong")
    /// This Device
    static let thisDevice = L10n.tr("Localizable", "recoverProfileBackup_thisDevice", fallback: "This Device")
    enum Choose {
      /// Choose a backup on iCloud
      static let ios = L10n.tr("Localizable", "recoverProfileBackup_choose_iOS", fallback: "Choose a backup on iCloud")
    }
    enum Header {
      /// Select a backup to restore your Radix Wallet. You will be asked to enter your seed phrase(s) to recover control of your Accounts and Personas.
      static let subtitle = L10n.tr("Localizable", "recoverProfileBackup_header_subtitle", fallback: "Select a backup to restore your Radix Wallet. You will be asked to enter your seed phrase(s) to recover control of your Accounts and Personas.")
      /// Restore Wallet From Backup
      static let title = L10n.tr("Localizable", "recoverProfileBackup_header_title", fallback: "Restore Wallet From Backup")
    }
    enum ImportFileButton {
      /// Import from Backup File Instead
      static let title = L10n.tr("Localizable", "recoverProfileBackup_importFileButton_title", fallback: "Import from Backup File Instead")
    }
    enum NoBackupsAvailable {
      /// No wallet backups available on current iCloud account
      static let ios = L10n.tr("Localizable", "recoverProfileBackup_noBackupsAvailable_iOS", fallback: "No wallet backups available on current iCloud account")
    }
    enum NotLoggedIn {
      /// Not logged in to iCloud
      static let ios = L10n.tr("Localizable", "recoverProfileBackup_notLoggedIn_iOS", fallback: "Not logged in to iCloud")
    }
  }
  enum RecoverSeedPhrase {
    /// Enter This Seed Phrase
    static let enterButton = L10n.tr("Localizable", "recoverSeedPhrase_enterButton", fallback: "Enter This Seed Phrase")
    /// Hidden accounts only.
    static let hiddenAccountsOnly = L10n.tr("Localizable", "recoverSeedPhrase_hiddenAccountsOnly", fallback: "Hidden accounts only.")
    /// I Don’t Have the Main Seed Phrase
    static let noMainSeedPhraseButton = L10n.tr("Localizable", "recoverSeedPhrase_noMainSeedPhraseButton", fallback: "I Don’t Have the Main Seed Phrase")
    /// Skip This Seed Phrase For Now
    static let skipButton = L10n.tr("Localizable", "recoverSeedPhrase_skipButton", fallback: "Skip This Seed Phrase For Now")
    /// Skip Main Seed Phrase Entry
    static let skipMainSeedPhraseButton = L10n.tr("Localizable", "recoverSeedPhrase_skipMainSeedPhraseButton", fallback: "Skip Main Seed Phrase Entry")
    enum Header {
      /// Your **Personas** and the following **Accounts** are controlled by your main seed phrase. To recover control, you must re-enter it.
      static let subtitleMainSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_subtitleMainSeedPhrase", fallback: "Your **Personas** and the following **Accounts** are controlled by your main seed phrase. To recover control, you must re-enter it.")
      /// The Radix Wallet always uses a single main “Babylon” seed phrase to generate new Personas and new Accounts (when not using a Ledger device).
      /// 
      /// If you do not have access to your previous main seed phrase, you can skip entering it for now. **The Radix Wallet will create a new one, which will be used for new Personas and Accounts.**
      /// 
      /// Your old Accounts and Personas will still be listed, but you will have to enter their original seed phrase to use them. Alternatively, you can hide them if you no longer are interested in using them.
      static let subtitleNoMainSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_subtitleNoMainSeedPhrase", fallback: "The Radix Wallet always uses a single main “Babylon” seed phrase to generate new Personas and new Accounts (when not using a Ledger device).\n\nIf you do not have access to your previous main seed phrase, you can skip entering it for now. **The Radix Wallet will create a new one, which will be used for new Personas and Accounts.**\n\nYour old Accounts and Personas will still be listed, but you will have to enter their original seed phrase to use them. Alternatively, you can hide them if you no longer are interested in using them.")
      /// The following **Accounts** are controlled by a seed phrase. To recover control, you must re-enter it.
      static let subtitleOtherSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_subtitleOtherSeedPhrase", fallback: "The following **Accounts** are controlled by a seed phrase. To recover control, you must re-enter it.")
      /// Main Seed Phrase Required
      static let titleMain = L10n.tr("Localizable", "recoverSeedPhrase_header_titleMain", fallback: "Main Seed Phrase Required")
      /// No Main Seed Phrase?
      static let titleNoMainSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_titleNoMainSeedPhrase", fallback: "No Main Seed Phrase?")
      /// Seed Phrase Required
      static let titleOther = L10n.tr("Localizable", "recoverSeedPhrase_header_titleOther", fallback: "Seed Phrase Required")
    }
  }
  enum RecoverWalletWithoutProfile {
    enum Complete {
      /// Continue
      static let continueButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_complete_continueButton", fallback: "Continue")
      /// Accounts discovered in the scan have been added to your wallet.
      /// 
      /// If you have any “Legacy” Accounts (created on the Olympia network) to import - or any Accounts using a Ledger hardware wallet device - please continue and then use the **Account Recovery Scan** option in your Radix Wallet settings under **Account Security**.
      static let headerSubtitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_complete_headerSubtitle", fallback: "Accounts discovered in the scan have been added to your wallet.\n\nIf you have any “Legacy” Accounts (created on the Olympia network) to import - or any Accounts using a Ledger hardware wallet device - please continue and then use the **Account Recovery Scan** option in your Radix Wallet settings under **Account Security**.")
      /// Recovery Complete
      static let headerTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_complete_headerTitle", fallback: "Recovery Complete")
    }
    enum Info {
      /// Continue
      static let continueButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_info_continueButton", fallback: "Continue")
      /// **If you have no wallet backup in the cloud or as an exported backup file**, you can still restore Account access only using your main “Babylon” seed phrase. You cannot recover your Account names or other wallet settings this way.
      /// 
      /// You will be asked to enter your main seed phrase. This is a set of **24 words** that the Radix Wallet mobile app showed you to write down and save securely.
      static let headerSubtitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_info_headerSubtitle", fallback: "**If you have no wallet backup in the cloud or as an exported backup file**, you can still restore Account access only using your main “Babylon” seed phrase. You cannot recover your Account names or other wallet settings this way.\n\nYou will be asked to enter your main seed phrase. This is a set of **24 words** that the Radix Wallet mobile app showed you to write down and save securely.")
      /// Recover Control Without Backup
      static let headerTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_info_headerTitle", fallback: "Recover Control Without Backup")
    }
    enum Start {
      /// Recover with Main Seed Phrase
      static let babylonSectionButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_babylonSectionButton", fallback: "Recover with Main Seed Phrase")
      /// I have my main “Babylon” 24-word seed phrase.
      static let babylonSectionTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_babylonSectionTitle", fallback: "I have my main “Babylon” 24-word seed phrase.")
      /// Ledger-only Restore
      static let hardwareSectionButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_hardwareSectionButton", fallback: "Ledger-only Restore")
      /// I only want to restore Ledger hardware wallet Accounts.
      static let hardwareSectionTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_hardwareSectionTitle", fallback: "I only want to restore Ledger hardware wallet Accounts.")
      /// If you have no wallet backup in the cloud, or as an exported backup file, you still have other restore options.
      static let headerSubtitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_headerSubtitle", fallback: "If you have no wallet backup in the cloud, or as an exported backup file, you still have other restore options.")
      /// Recover Control Without Backup
      static let headerTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_headerTitle", fallback: "Recover Control Without Backup")
      /// Olympia-only Restore
      static let olympiaSectionButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_olympiaSectionButton", fallback: "Olympia-only Restore")
      /// I only have Accounts created on the Radix Olympia network.
      static let olympiaSectionTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_olympiaSectionTitle", fallback: "I only have Accounts created on the Radix Olympia network.")
      /// Cancel
      static let useNewWalletAlertCancel = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertCancel", fallback: "Cancel")
      /// Continue
      static let useNewWalletAlertContinue = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertContinue", fallback: "Continue")
      /// Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Ledger device.
      static let useNewWalletAlertMessageHardware = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertMessageHardware", fallback: "Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Ledger device.")
      /// Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Olympia seed phrase.
      static let useNewWalletAlertMessageOlympia = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertMessageOlympia", fallback: "Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Olympia seed phrase.")
      /// No Main Seed Phrase?
      static let useNewWalletAlertTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertTitle", fallback: "No Main Seed Phrase?")
    }
  }
  enum RevealSeedPhrase {
    /// Passphrase
    static let passphrase = L10n.tr("Localizable", "revealSeedPhrase_passphrase", fallback: "Passphrase")
    /// Reveal Seed Phrase
    static let title = L10n.tr("Localizable", "revealSeedPhrase_title", fallback: "Reveal Seed Phrase")
    /// For your safety, make sure no one is looking at your screen. Taking a screen shot has been disabled.
    static let warning = L10n.tr("Localizable", "revealSeedPhrase_warning", fallback: "For your safety, make sure no one is looking at your screen. Taking a screen shot has been disabled.")
    /// Word %d
    static func wordLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "revealSeedPhrase_wordLabel", p1, fallback: "Word %d")
    }
    enum WarningDialog {
      /// I have written down this seed phrase
      static let confirmButton = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_confirmButton", fallback: "I have written down this seed phrase")
      /// Are you sure you have written down your seed phrase?
      static let subtitle = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_subtitle", fallback: "Are you sure you have written down your seed phrase?")
      /// Use Caution
      static let title = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_title", fallback: "Use Caution")
    }
  }
  enum ScanQR {
    enum Account {
      /// Scan a QR code of a Radix Account address from another wallet or an exchange.
      static let instructions = L10n.tr("Localizable", "scanQR_account_instructions", fallback: "Scan a QR code of a Radix Account address from another wallet or an exchange.")
    }
    enum ConnectorExtension {
      /// Go to **wallet.radixdlt.com** in your desktop browser.
      static let disclosureItem1 = L10n.tr("Localizable", "scanQR_connectorExtension_disclosureItem1", fallback: "Go to **wallet.radixdlt.com** in your desktop browser.")
      /// Follow the instructions there to install the Radix Connector.
      static let disclosureItem2 = L10n.tr("Localizable", "scanQR_connectorExtension_disclosureItem2", fallback: "Follow the instructions there to install the Radix Connector.")
      /// Don't have the Radix Connector browser extension?
      static let disclosureTitle = L10n.tr("Localizable", "scanQR_connectorExtension_disclosureTitle", fallback: "Don't have the Radix Connector browser extension?")
      /// Scan the QR code in the Radix Connector browser extension.
      static let instructions = L10n.tr("Localizable", "scanQR_connectorExtension_instructions", fallback: "Scan the QR code in the Radix Connector browser extension.")
    }
    enum ImportOlympia {
      /// Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.
      static let instructions = L10n.tr("Localizable", "scanQR_importOlympia_instructions", fallback: "Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.")
    }
  }
  enum SecurityCenter {
    /// Decentralized security settings that give you total control over your wallet’s protection.
    static let subtitle = L10n.tr("Localizable", "securityCenter_subtitle", fallback: "Decentralized security settings that give you total control over your wallet’s protection.")
    /// Security Center
    static let title = L10n.tr("Localizable", "securityCenter_title", fallback: "Security Center")
    enum AnyItem {
      /// Action required
      static let actionRequiredStatus = L10n.tr("Localizable", "securityCenter_anyItem_actionRequiredStatus", fallback: "Action required")
    }
    enum ConfigurationBackupItem {
      /// Backed up
      static let backedUpStatus = L10n.tr("Localizable", "securityCenter_configurationBackupItem_backedUpStatus", fallback: "Backed up")
      /// A backup of your Account, Personas and wallet settings
      static let subtitle = L10n.tr("Localizable", "securityCenter_configurationBackupItem_subtitle", fallback: "A backup of your Account, Personas and wallet settings")
      /// Configuration Backup
      static let title = L10n.tr("Localizable", "securityCenter_configurationBackupItem_title", fallback: "Configuration Backup")
    }
    enum EncryptWalletBackup {
      /// Confirm Password
      static let confirmPassword = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_confirmPassword", fallback: "Confirm Password")
      /// Continue
      static let `continue` = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_continue", fallback: "Continue")
      /// Enter Password
      static let enterPassword = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_enterPassword", fallback: "Enter Password")
      /// Passwords do not match
      static let passwordMismatchError = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_passwordMismatchError", fallback: "Passwords do not match")
      /// Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.
      static let subtitle = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_subtitle", fallback: "Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.")
      /// Encrypt Wallet Backup File
      static let title = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_title", fallback: "Encrypt Wallet Backup File")
    }
    enum GoodState {
      /// Your wallet is recoverable
      static let heading = L10n.tr("Localizable", "securityCenter_goodState_heading", fallback: "Your wallet is recoverable")
    }
    enum SecurityFactorsItem {
      /// Active
      static let activeStatus = L10n.tr("Localizable", "securityCenter_securityFactorsItem_activeStatus", fallback: "Active")
      /// The keys you use to control your Accounts and Personas
      static let subtitle = L10n.tr("Localizable", "securityCenter_securityFactorsItem_subtitle", fallback: "The keys you use to control your Accounts and Personas")
      /// Security Factors
      static let title = L10n.tr("Localizable", "securityCenter_securityFactorsItem_title", fallback: "Security Factors")
    }
  }
  enum SecurityFactors {
    /// View and manage your security factors
    static let subtitle = L10n.tr("Localizable", "securityFactors_subtitle", fallback: "View and manage your security factors")
    /// Security Factors
    static let title = L10n.tr("Localizable", "securityFactors_title", fallback: "Security Factors")
    enum LedgerWallet {
      /// %d set
      static func counterPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "securityFactors_ledgerWallet_counterPlural", p1, fallback: "%d set")
      }
      /// 1 set
      static let counterSingular = L10n.tr("Localizable", "securityFactors_ledgerWallet_counterSingular", fallback: "1 set")
      /// Hardware wallet designed for holding crypto
      static let subtitle = L10n.tr("Localizable", "securityFactors_ledgerWallet_subtitle", fallback: "Hardware wallet designed for holding crypto")
      /// Ledger Hardware Wallets
      static let title = L10n.tr("Localizable", "securityFactors_ledgerWallet_title", fallback: "Ledger Hardware Wallets")
    }
    enum SeedPhrases {
      /// %d Seed phrases
      static func counterPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "securityFactors_seedPhrases_counterPlural", p1, fallback: "%d Seed phrases")
      }
      /// 1 Seed phrase
      static let counterSingular = L10n.tr("Localizable", "securityFactors_seedPhrases_counterSingular", fallback: "1 Seed phrase")
      /// Enter your seed phrase to recover Accounts
      static let enterSeedPhrase = L10n.tr("Localizable", "securityFactors_seedPhrases_enterSeedPhrase", fallback: "Enter your seed phrase to recover Accounts")
      /// Your seedphrases connected to your account
      static let subtitle = L10n.tr("Localizable", "securityFactors_seedPhrases_subtitle", fallback: "Your seedphrases connected to your account")
      /// Seed Phrases
      static let title = L10n.tr("Localizable", "securityFactors_seedPhrases_title", fallback: "Seed Phrases")
    }
  }
  enum SecurityProblems {
    enum Common {
      /// %d accounts
      static func accountPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "securityProblems_common_accountPlural", p1, fallback: "%d accounts")
      }
      /// 1 account
      static let accountSingular = L10n.tr("Localizable", "securityProblems_common_accountSingular", fallback: "1 account")
      /// %d personas
      static func personaPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "securityProblems_common_personaPlural", p1, fallback: "%d personas")
      }
      /// 1 persona
      static let personaSingular = L10n.tr("Localizable", "securityProblems_common_personaSingular", fallback: "1 persona")
    }
    enum No3 {
      /// You need to write down a seed phrase
      static let accountCard = L10n.tr("Localizable", "securityProblems_no3_accountCard", fallback: "You need to write down a seed phrase")
      /// You need to write down a seed phrase
      static let personas = L10n.tr("Localizable", "securityProblems_no3_personas", fallback: "You need to write down a seed phrase")
      /// View and write down your seed phrase so Accounts and Personas are recoverable.
      static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no3_securityCenterBody", fallback: "View and write down your seed phrase so Accounts and Personas are recoverable.")
      /// %@ and %@ are not recoverable.
      static func securityCenterTitle(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "securityProblems_no3_securityCenterTitle", String(describing: p1), String(describing: p2), fallback: "%@ and %@ are not recoverable.")
      }
      /// %@ and %@ (plus some hidden) are not recoverable.
      static func securityCenterTitleHidden(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "securityProblems_no3_securityCenterTitleHidden", String(describing: p1), String(describing: p2), fallback: "%@ and %@ (plus some hidden) are not recoverable.")
      }
      /// View and write down seed phrase
      static let securityFactors = L10n.tr("Localizable", "securityProblems_no3_securityFactors", fallback: "View and write down seed phrase")
      /// View and write down seed phrase
      static let seedPhrases = L10n.tr("Localizable", "securityProblems_no3_seedPhrases", fallback: "View and write down seed phrase")
      /// Personas are not recoverable
      static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no3_walletSettingsPersonas", fallback: "Personas are not recoverable")
    }
    enum No5 {
      /// Problem with Configuration Backup
      static let accountCard = L10n.tr("Localizable", "securityProblems_no5_accountCard", fallback: "Problem with Configuration Backup")
      /// Automated Configuration Backup not working. Check internet connection and cloud settings.
      static let configurationBackup = L10n.tr("Localizable", "securityProblems_no5_configurationBackup", fallback: "Automated Configuration Backup not working. Check internet connection and cloud settings.")
      /// Problem with Configuration Backup
      static let personas = L10n.tr("Localizable", "securityProblems_no5_personas", fallback: "Problem with Configuration Backup")
      /// Automated Configuration Backup has stopped working. Check internet and cloud settings.
      static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no5_securityCenterBody", fallback: "Automated Configuration Backup has stopped working. Check internet and cloud settings.")
      /// Your wallet is not recoverable
      static let securityCenterTitle = L10n.tr("Localizable", "securityProblems_no5_securityCenterTitle", fallback: "Your wallet is not recoverable")
      /// Personas are not recoverable
      static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no5_walletSettingsPersonas", fallback: "Personas are not recoverable")
    }
    enum No6 {
      /// Your wallet is not recoverable
      static let accountCard = L10n.tr("Localizable", "securityProblems_no6_accountCard", fallback: "Your wallet is not recoverable")
      /// To secure your wallet, turn on automated backups or manually export backup file.
      static let configurationBackup = L10n.tr("Localizable", "securityProblems_no6_configurationBackup", fallback: "To secure your wallet, turn on automated backups or manually export backup file.")
      /// Your wallet is not recoverable
      static let personas = L10n.tr("Localizable", "securityProblems_no6_personas", fallback: "Your wallet is not recoverable")
      /// Configuration Backup is not up to date. Create backup now.
      static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no6_securityCenterBody", fallback: "Configuration Backup is not up to date. Create backup now.")
      /// Your wallet is not recoverable
      static let securityCenterTitle = L10n.tr("Localizable", "securityProblems_no6_securityCenterTitle", fallback: "Your wallet is not recoverable")
      /// Personas are not recoverable
      static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no6_walletSettingsPersonas", fallback: "Personas are not recoverable")
    }
    enum No7 {
      /// Configuration Backup not up to date
      static let accountCard = L10n.tr("Localizable", "securityProblems_no7_accountCard", fallback: "Configuration Backup not up to date")
      /// Configuration Backup not up to date. Turn on automated backups or manually export backup file.
      static let configurationBackup = L10n.tr("Localizable", "securityProblems_no7_configurationBackup", fallback: "Configuration Backup not up to date. Turn on automated backups or manually export backup file.")
      /// Configuration Backup not up to date
      static let personas = L10n.tr("Localizable", "securityProblems_no7_personas", fallback: "Configuration Backup not up to date")
      /// Accounts and Personas not recoverable. Create Configuration Backup now.
      static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no7_securityCenterBody", fallback: "Accounts and Personas not recoverable. Create Configuration Backup now.")
      /// Your wallet is not recoverable
      static let securityCenterTitle = L10n.tr("Localizable", "securityProblems_no7_securityCenterTitle", fallback: "Your wallet is not recoverable")
      /// Personas are not recoverable
      static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no7_walletSettingsPersonas", fallback: "Personas are not recoverable")
    }
    enum No9 {
      /// Recovery required
      static let accountCard = L10n.tr("Localizable", "securityProblems_no9_accountCard", fallback: "Recovery required")
      /// Recovery required
      static let personas = L10n.tr("Localizable", "securityProblems_no9_personas", fallback: "Recovery required")
      /// Enter seed phrase to recover control.
      static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no9_securityCenterBody", fallback: "Enter seed phrase to recover control.")
      /// Recovery required
      static let securityCenterTitle = L10n.tr("Localizable", "securityProblems_no9_securityCenterTitle", fallback: "Recovery required")
      /// Enter seed phrase to recover control
      static let securityFactors = L10n.tr("Localizable", "securityProblems_no9_securityFactors", fallback: "Enter seed phrase to recover control")
      /// Enter seed phrase to recover control
      static let seedPhrases = L10n.tr("Localizable", "securityProblems_no9_seedPhrases", fallback: "Enter seed phrase to recover control")
      /// Recovery required
      static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no9_walletSettingsPersonas", fallback: "Recovery required")
    }
  }
  enum SeedPhrases {
    /// Please write down your Seed Phrase
    static let backupWarning = L10n.tr("Localizable", "seedPhrases_backupWarning", fallback: "Please write down your Seed Phrase")
    /// Hidden Accounts only
    static let hiddenAccountsOnly = L10n.tr("Localizable", "seedPhrases_hiddenAccountsOnly", fallback: "Hidden Accounts only")
    /// A Seed Phrase provides full access to your accounts and funds. When viewing, ensure you’re in a safe environment and no one is looking at your screen.
    static let message = L10n.tr("Localizable", "seedPhrases_message", fallback: "A Seed Phrase provides full access to your accounts and funds. When viewing, ensure you’re in a safe environment and no one is looking at your screen.")
    /// Seed Phrases
    static let title = L10n.tr("Localizable", "seedPhrases_title", fallback: "Seed Phrases")
    /// You are responsible for the security of your Seed Phrase
    static let warning = L10n.tr("Localizable", "seedPhrases_warning", fallback: "You are responsible for the security of your Seed Phrase")
    enum SeedPhrase {
      /// Seed Phrase Entry Required
      static let headingNeedsImport = L10n.tr("Localizable", "seedPhrases_seedPhrase_headingNeedsImport", fallback: "Seed Phrase Entry Required")
      /// Reveal Seed Phrase
      static let headingReveal = L10n.tr("Localizable", "seedPhrases_seedPhrase_headingReveal", fallback: "Reveal Seed Phrase")
      /// Seed Phrase
      static let headingScan = L10n.tr("Localizable", "seedPhrases_seedPhrase_headingScan", fallback: "Seed Phrase")
      /// Connected to %d Accounts
      static func multipleConnectedAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "seedPhrases_seedPhrase_multipleConnectedAccounts", p1, fallback: "Connected to %d Accounts")
      }
      /// Not connected to any Accounts
      static let noConnectedAccounts = L10n.tr("Localizable", "seedPhrases_seedPhrase_noConnectedAccounts", fallback: "Not connected to any Accounts")
      /// Connected to 1 Account
      static let oneConnectedAccount = L10n.tr("Localizable", "seedPhrases_seedPhrase_oneConnectedAccount", fallback: "Connected to 1 Account")
    }
  }
  enum Settings {
    /// Account Security & Settings
    static let accountSecurityAndSettings = L10n.tr("Localizable", "settings_accountSecurityAndSettings", fallback: "Account Security & Settings")
    /// App Settings
    static let appSettings = L10n.tr("Localizable", "settings_appSettings", fallback: "App Settings")
    /// Version: %@ build #%@
    static func appVersion(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "settings_appVersion", String(describing: p1), String(describing: p2), fallback: "Version: %@ build #%@")
    }
    /// Authorized dApps
    static let authorizedDapps = L10n.tr("Localizable", "settings_authorizedDapps", fallback: "Authorized dApps")
    /// Personas
    static let personas = L10n.tr("Localizable", "settings_personas", fallback: "Personas")
    /// Please write down the seed phrase for your Personas
    static let personasSeedPhrasePrompt = L10n.tr("Localizable", "settings_personasSeedPhrasePrompt", fallback: "Please write down the seed phrase for your Personas")
    /// Settings
    static let title = L10n.tr("Localizable", "settings_title", fallback: "Settings")
    enum ImportFromLegacyWalletHeader {
      /// Import Legacy Accounts
      static let importLegacyAccounts = L10n.tr("Localizable", "settings_importFromLegacyWalletHeader_importLegacyAccounts", fallback: "Import Legacy Accounts")
      /// Get started importing your Olympia accounts into your new Radix Wallet
      static let subtitle = L10n.tr("Localizable", "settings_importFromLegacyWalletHeader_subtitle", fallback: "Get started importing your Olympia accounts into your new Radix Wallet")
      /// Radix Olympia Desktop Wallet user?
      static let title = L10n.tr("Localizable", "settings_importFromLegacyWalletHeader_title", fallback: "Radix Olympia Desktop Wallet user?")
    }
    enum LinkToConnectorHeader {
      /// Link to Connector
      static let linkToConnector = L10n.tr("Localizable", "settings_linkToConnectorHeader_linkToConnector", fallback: "Link to Connector")
      /// Scan the QR code in the Radix Wallet Connector extension
      static let subtitle = L10n.tr("Localizable", "settings_linkToConnectorHeader_subtitle", fallback: "Scan the QR code in the Radix Wallet Connector extension")
      /// Link your Wallet to a Desktop Browser
      static let title = L10n.tr("Localizable", "settings_linkToConnectorHeader_title", fallback: "Link your Wallet to a Desktop Browser")
    }
  }
  enum Splash {
    /// This app requires your phone to have a passcode set up
    static let passcodeNotSetMessage = L10n.tr("Localizable", "splash_passcodeNotSetMessage", fallback: "This app requires your phone to have a passcode set up")
    /// Passcode not set up
    static let passcodeNotSetTitle = L10n.tr("Localizable", "splash_passcodeNotSetTitle", fallback: "Passcode not set up")
    /// Tap to unlock
    static let tapAnywhereToUnlock = L10n.tr("Localizable", "splash_tapAnywhereToUnlock", fallback: "Tap to unlock")
    enum IncompatibleProfileVersionAlert {
      /// Delete Wallet Data
      static let delete = L10n.tr("Localizable", "splash_incompatibleProfileVersionAlert_delete", fallback: "Delete Wallet Data")
      /// For this Preview wallet version, you must delete your wallet data to continue.
      static let message = L10n.tr("Localizable", "splash_incompatibleProfileVersionAlert_message", fallback: "For this Preview wallet version, you must delete your wallet data to continue.")
      /// Wallet Data is Incompatible
      static let title = L10n.tr("Localizable", "splash_incompatibleProfileVersionAlert_title", fallback: "Wallet Data is Incompatible")
    }
    enum PasscodeCheckFailedAlert {
      /// Passcode is not set up. Please update settings.
      static let message = L10n.tr("Localizable", "splash_passcodeCheckFailedAlert_message", fallback: "Passcode is not set up. Please update settings.")
      /// Warning
      static let title = L10n.tr("Localizable", "splash_passcodeCheckFailedAlert_title", fallback: "Warning")
    }
    enum ProfileOnAnotherDeviceAlert {
      /// Ask Later (no changes)
      static let askLater = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_askLater", fallback: "Ask Later (no changes)")
      /// Claim Existing Wallet
      static let claimExisting = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_claimExisting", fallback: "Claim Existing Wallet")
      /// Clear Wallet on This Phone
      static let claimHere = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_claimHere", fallback: "Clear Wallet on This Phone")
      /// This wallet is currently configured with a set of Accounts and Personas in use by a different phone.
      /// 
      /// To make changes to this wallet, you must claim it for use on this phone instead, removing access by the other phone.
      /// 
      /// Or you can clear this wallet from this phone and start fresh.
      static let message = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_message", fallback: "This wallet is currently configured with a set of Accounts and Personas in use by a different phone.\n\nTo make changes to this wallet, you must claim it for use on this phone instead, removing access by the other phone.\n\nOr you can clear this wallet from this phone and start fresh.")
      /// Claim This Wallet?
      static let title = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_title", fallback: "Claim This Wallet?")
    }
    enum RootDetection {
      /// I Understand the Risk
      static let acknowledgeButton = L10n.tr("Localizable", "splash_rootDetection_acknowledgeButton", fallback: "I Understand the Risk")
      /// It appears that your device might be rooted. To ensure the security of your Accounts and assets, using the Radix Wallet on rooted devices is not recommended. Please confirm if you wish to continue anyway at your own risk.
      static let messageAndroid = L10n.tr("Localizable", "splash_rootDetection_messageAndroid", fallback: "It appears that your device might be rooted. To ensure the security of your Accounts and assets, using the Radix Wallet on rooted devices is not recommended. Please confirm if you wish to continue anyway at your own risk.")
      /// It appears that your device might be jailbroken. To ensure the security of your Accounts and assets, using the Radix Wallet on jailbroken devices is not recommended. Please confirm if you wish to continue anyway at your own risk.
      static let messageIOS = L10n.tr("Localizable", "splash_rootDetection_messageIOS", fallback: "It appears that your device might be jailbroken. To ensure the security of your Accounts and assets, using the Radix Wallet on jailbroken devices is not recommended. Please confirm if you wish to continue anyway at your own risk.")
      /// Possible jailbreak detected
      static let titleIOS = L10n.tr("Localizable", "splash_rootDetection_titleIOS", fallback: "Possible jailbreak detected")
    }
  }
  enum Survey {
    /// 10 - Very likely
    static let highestScoreLabel = L10n.tr("Localizable", "survey_highestScoreLabel", fallback: "10 - Very likely")
    /// 0 - Not likely
    static let lowestScoreLabel = L10n.tr("Localizable", "survey_lowestScoreLabel", fallback: "0 - Not likely")
    /// Submit Feedback - Thanks!
    static let submitButton = L10n.tr("Localizable", "survey_submitButton", fallback: "Submit Feedback - Thanks!")
    /// How likely are you to recommend Radix and the Radix Wallet to your friends or colleagues?
    static let subtitle = L10n.tr("Localizable", "survey_subtitle", fallback: "How likely are you to recommend Radix and the Radix Wallet to your friends or colleagues?")
    /// How's it Going?
    static let title = L10n.tr("Localizable", "survey_title", fallback: "How's it Going?")
    enum Reason {
      /// Let us know...
      static let fieldHint = L10n.tr("Localizable", "survey_reason_fieldHint", fallback: "Let us know...")
      /// What’s the main reason for your score?
      static let heading = L10n.tr("Localizable", "survey_reason_heading", fallback: "What’s the main reason for your score?")
    }
  }
  enum TimeFormatting {
    /// %@ ago
    static func ago(_ p1: Any) -> String {
      return L10n.tr("Localizable", "timeFormatting_ago", String(describing: p1), fallback: "%@ ago")
    }
    /// Just now
    static let justNow = L10n.tr("Localizable", "timeFormatting_justNow", fallback: "Just now")
    /// Today
    static let today = L10n.tr("Localizable", "timeFormatting_today", fallback: "Today")
    /// Tomorrow
    static let tomorrow = L10n.tr("Localizable", "timeFormatting_tomorrow", fallback: "Tomorrow")
    /// Yesterday
    static let yesterday = L10n.tr("Localizable", "timeFormatting_yesterday", fallback: "Yesterday")
  }
  enum TransactionHistory {
    /// This transaction cannot be summarized. Only the raw transaction manifest may be viewed.
    static let complexTransaction = L10n.tr("Localizable", "transactionHistory_complexTransaction", fallback: "This transaction cannot be summarized. Only the raw transaction manifest may be viewed.")
    /// Deposited
    static let depositedSection = L10n.tr("Localizable", "transactionHistory_depositedSection", fallback: "Deposited")
    /// Failed Transaction
    static let failedTransaction = L10n.tr("Localizable", "transactionHistory_failedTransaction", fallback: "Failed Transaction")
    /// No deposits or withdrawals from this account in this transaction.
    static let noBalanceChanges = L10n.tr("Localizable", "transactionHistory_noBalanceChanges", fallback: "No deposits or withdrawals from this account in this transaction.")
    /// You have no Transactions.
    static let noTransactions = L10n.tr("Localizable", "transactionHistory_noTransactions", fallback: "You have no Transactions.")
    /// Settings
    static let settingsSection = L10n.tr("Localizable", "transactionHistory_settingsSection", fallback: "Settings")
    /// History
    static let title = L10n.tr("Localizable", "transactionHistory_title", fallback: "History")
    /// Updated Account Deposit Settings
    static let updatedDepositSettings = L10n.tr("Localizable", "transactionHistory_updatedDepositSettings", fallback: "Updated Account Deposit Settings")
    /// Withdrawn
    static let withdrawnSection = L10n.tr("Localizable", "transactionHistory_withdrawnSection", fallback: "Withdrawn")
    enum DatePrefix {
      /// Today
      static let today = L10n.tr("Localizable", "transactionHistory_datePrefix_today", fallback: "Today")
      /// Yesterday
      static let yesterday = L10n.tr("Localizable", "transactionHistory_datePrefix_yesterday", fallback: "Yesterday")
    }
    enum Filters {
      /// Type of Asset
      static let assetTypeLabel = L10n.tr("Localizable", "transactionHistory_filters_assetTypeLabel", fallback: "Type of Asset")
      /// NFTs
      static let assetTypeNFTsLabel = L10n.tr("Localizable", "transactionHistory_filters_assetTypeNFTsLabel", fallback: "NFTs")
      /// Clear All
      static let clearAll = L10n.tr("Localizable", "transactionHistory_filters_clearAll", fallback: "Clear All")
      /// Deposits
      static let depositsType = L10n.tr("Localizable", "transactionHistory_filters_depositsType", fallback: "Deposits")
      /// Show All NFTs
      static let nftShowAll = L10n.tr("Localizable", "transactionHistory_filters_nftShowAll", fallback: "Show All NFTs")
      /// Show Less NFTs
      static let nftShowLess = L10n.tr("Localizable", "transactionHistory_filters_nftShowLess", fallback: "Show Less NFTs")
      /// Show Results
      static let showResultsButton = L10n.tr("Localizable", "transactionHistory_filters_showResultsButton", fallback: "Show Results")
      /// Filter
      static let title = L10n.tr("Localizable", "transactionHistory_filters_title", fallback: "Filter")
      /// Show All Tokens
      static let tokenShowAll = L10n.tr("Localizable", "transactionHistory_filters_tokenShowAll", fallback: "Show All Tokens")
      /// Show Less Tokens
      static let tokenShowLess = L10n.tr("Localizable", "transactionHistory_filters_tokenShowLess", fallback: "Show Less Tokens")
      /// Tokens
      static let tokensLabel = L10n.tr("Localizable", "transactionHistory_filters_tokensLabel", fallback: "Tokens")
      /// Type of Transaction
      static let transactionTypeLabel = L10n.tr("Localizable", "transactionHistory_filters_transactionTypeLabel", fallback: "Type of Transaction")
      /// Withdrawals
      static let withdrawalsType = L10n.tr("Localizable", "transactionHistory_filters_withdrawalsType", fallback: "Withdrawals")
    }
    enum ManifestClass {
      /// Deposit Settings
      static let accountSettings = L10n.tr("Localizable", "transactionHistory_manifestClass_AccountSettings", fallback: "Deposit Settings")
      /// Claim Stake
      static let claim = L10n.tr("Localizable", "transactionHistory_manifestClass_Claim", fallback: "Claim Stake")
      /// Contribute
      static let contribute = L10n.tr("Localizable", "transactionHistory_manifestClass_Contribute", fallback: "Contribute")
      /// General
      static let general = L10n.tr("Localizable", "transactionHistory_manifestClass_General", fallback: "General")
      /// Other
      static let other = L10n.tr("Localizable", "transactionHistory_manifestClass_Other", fallback: "Other")
      /// Redeem
      static let redeem = L10n.tr("Localizable", "transactionHistory_manifestClass_Redeem", fallback: "Redeem")
      /// Stake
      static let staking = L10n.tr("Localizable", "transactionHistory_manifestClass_Staking", fallback: "Stake")
      /// Transfer
      static let transfer = L10n.tr("Localizable", "transactionHistory_manifestClass_Transfer", fallback: "Transfer")
      /// Request Unstake
      static let unstaking = L10n.tr("Localizable", "transactionHistory_manifestClass_Unstaking", fallback: "Request Unstake")
    }
  }
  enum TransactionReview {
    /// Approve
    static let approveButtonTitle = L10n.tr("Localizable", "transactionReview_approveButtonTitle", fallback: "Approve")
    /// Claim from validators
    static let claimFromValidatorsHeading = L10n.tr("Localizable", "transactionReview_claimFromValidatorsHeading", fallback: "Claim from validators")
    /// Customize Guarantees
    static let customizeGuaranteesButtonTitle = L10n.tr("Localizable", "transactionReview_customizeGuaranteesButtonTitle", fallback: "Customize Guarantees")
    /// Depositing To
    static let depositsHeading = L10n.tr("Localizable", "transactionReview_depositsHeading", fallback: "Depositing To")
    /// Estimated
    static let estimated = L10n.tr("Localizable", "transactionReview_estimated", fallback: "Estimated")
    /// Account
    static let externalAccountName = L10n.tr("Localizable", "transactionReview_externalAccountName", fallback: "Account")
    /// Guaranteed
    static let guaranteed = L10n.tr("Localizable", "transactionReview_guaranteed", fallback: "Guaranteed")
    /// Message
    static let messageHeading = L10n.tr("Localizable", "transactionReview_messageHeading", fallback: "Message")
    /// Contributing to pools
    static let poolContributionHeading = L10n.tr("Localizable", "transactionReview_poolContributionHeading", fallback: "Contributing to pools")
    /// Unknown pool
    static let poolNameUnknown = L10n.tr("Localizable", "transactionReview_poolNameUnknown", fallback: "Unknown pool")
    /// Redeeming from pools
    static let poolRedemptionHeading = L10n.tr("Localizable", "transactionReview_poolRedemptionHeading", fallback: "Redeeming from pools")
    /// Pool Units
    static let poolUnits = L10n.tr("Localizable", "transactionReview_poolUnits", fallback: "Pool Units")
    /// Presenting
    static let presentingHeading = L10n.tr("Localizable", "transactionReview_presentingHeading", fallback: "Presenting")
    /// Proposed by %@
    static func proposingDappSubtitle(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transactionReview_proposingDappSubtitle", String(describing: p1), fallback: "Proposed by %@")
    }
    /// Raw Transaction
    static let rawTransactionTitle = L10n.tr("Localizable", "transactionReview_rawTransactionTitle", fallback: "Raw Transaction")
    /// Sending to
    static let sendingToHeading = L10n.tr("Localizable", "transactionReview_sendingToHeading", fallback: "Sending to")
    /// Slide to Sign
    static let slideToSign = L10n.tr("Localizable", "transactionReview_slideToSign", fallback: "Slide to Sign")
    /// Staking to Validators
    static let stakingToValidatorsHeading = L10n.tr("Localizable", "transactionReview_stakingToValidatorsHeading", fallback: "Staking to Validators")
    /// Third-party deposit exceptions
    static let thirdPartyDepositExceptionsHeading = L10n.tr("Localizable", "transactionReview_thirdPartyDepositExceptionsHeading", fallback: "Third-party deposit exceptions")
    /// Third-party deposit setting
    static let thirdPartyDepositSettingHeading = L10n.tr("Localizable", "transactionReview_thirdPartyDepositSettingHeading", fallback: "Third-party deposit setting")
    /// Review Your Transaction
    static let title = L10n.tr("Localizable", "transactionReview_title", fallback: "Review Your Transaction")
    /// To be claimed
    static let toBeClaimed = L10n.tr("Localizable", "transactionReview_toBeClaimed", fallback: "To be claimed")
    /// Review Your Transfer
    static let transferTitle = L10n.tr("Localizable", "transactionReview_transferTitle", fallback: "Review Your Transfer")
    /// Unknown
    static let unknown = L10n.tr("Localizable", "transactionReview_unknown", fallback: "Unknown")
    /// %d Unknown Components
    static func unknownComponents(_ p1: Int) -> String {
      return L10n.tr("Localizable", "transactionReview_unknownComponents", p1, fallback: "%d Unknown Components")
    }
    /// %d Pool Components
    static func unknownPools(_ p1: Int) -> String {
      return L10n.tr("Localizable", "transactionReview_unknownPools", p1, fallback: "%d Pool Components")
    }
    /// Unnamed dApp
    static let unnamedDapp = L10n.tr("Localizable", "transactionReview_unnamedDapp", fallback: "Unnamed dApp")
    /// Requesting unstake from validators
    static let unstakingFromValidatorsHeading = L10n.tr("Localizable", "transactionReview_unstakingFromValidatorsHeading", fallback: "Requesting unstake from validators")
    /// Using dApps
    static let usingDappsHeading = L10n.tr("Localizable", "transactionReview_usingDappsHeading", fallback: "Using dApps")
    /// Withdrawing From
    static let withdrawalsHeading = L10n.tr("Localizable", "transactionReview_withdrawalsHeading", fallback: "Withdrawing From")
    /// Worth
    static let worth = L10n.tr("Localizable", "transactionReview_worth", fallback: "Worth")
    /// %@ XRD
    static func xrdAmount(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transactionReview_xrdAmount", String(describing: p1), fallback: "%@ XRD")
    }
    enum AccountDepositSettings {
      /// Allow third parties to deposit **any asset** to this account.
      static let acceptAllRule = L10n.tr("Localizable", "transactionReview_accountDepositSettings_acceptAllRule", fallback: "Allow third parties to deposit **any asset** to this account.")
      /// Allow third parties to deposit **only assets this account has already held**.
      static let acceptKnownRule = L10n.tr("Localizable", "transactionReview_accountDepositSettings_acceptKnownRule", fallback: "Allow third parties to deposit **only assets this account has already held**.")
      /// Allow
      static let assetChangeAllow = L10n.tr("Localizable", "transactionReview_accountDepositSettings_assetChangeAllow", fallback: "Allow")
      /// Remove Exception
      static let assetChangeClear = L10n.tr("Localizable", "transactionReview_accountDepositSettings_assetChangeClear", fallback: "Remove Exception")
      /// Disallow
      static let assetChangeDisallow = L10n.tr("Localizable", "transactionReview_accountDepositSettings_assetChangeDisallow", fallback: "Disallow")
      /// **Disallow** all deposits from third parties without your consent.
      static let denyAllRule = L10n.tr("Localizable", "transactionReview_accountDepositSettings_denyAllRule", fallback: "**Disallow** all deposits from third parties without your consent.")
      /// Add Depositor
      static let depositorChangeAdd = L10n.tr("Localizable", "transactionReview_accountDepositSettings_depositorChangeAdd", fallback: "Add Depositor")
      /// Remove Depositor
      static let depositorChangeRemove = L10n.tr("Localizable", "transactionReview_accountDepositSettings_depositorChangeRemove", fallback: "Remove Depositor")
      /// Third-party deposit setting
      static let subtitle = L10n.tr("Localizable", "transactionReview_accountDepositSettings_subtitle", fallback: "Third-party deposit setting")
      /// Review New Deposit Settings
      static let title = L10n.tr("Localizable", "transactionReview_accountDepositSettings_title", fallback: "Review New Deposit Settings")
    }
    enum FeePayerValidation {
      /// Fee payer account required
      static let feePayerRequired = L10n.tr("Localizable", "transactionReview_feePayerValidation_feePayerRequired", fallback: "Fee payer account required")
      /// Not enough XRD for transaction fee
      static let insufficientBalance = L10n.tr("Localizable", "transactionReview_feePayerValidation_insufficientBalance", fallback: "Not enough XRD for transaction fee")
      /// Account will be linked on ledger to your other Accounts in this transaction
      static let linksNewAccount = L10n.tr("Localizable", "transactionReview_feePayerValidation_linksNewAccount", fallback: "Account will be linked on ledger to your other Accounts in this transaction")
    }
    enum Guarantees {
      /// Apply
      static let applyButtonText = L10n.tr("Localizable", "transactionReview_guarantees_applyButtonText", fallback: "Apply")
      /// Set guaranteed minimum %%
      static let setGuaranteedMinimum = L10n.tr("Localizable", "transactionReview_guarantees_setGuaranteedMinimum", fallback: "Set guaranteed minimum %%")
      /// Protect yourself by setting guaranteed minimums for estimated deposits
      static let subtitle = L10n.tr("Localizable", "transactionReview_guarantees_subtitle", fallback: "Protect yourself by setting guaranteed minimums for estimated deposits")
      /// Customize Guarantees
      static let title = L10n.tr("Localizable", "transactionReview_guarantees_title", fallback: "Customize Guarantees")
    }
    enum HiddenAsset {
      /// This asset is hidden and will not be visible in your Account
      static let deposit = L10n.tr("Localizable", "transactionReview_hiddenAsset_deposit", fallback: "This asset is hidden and will not be visible in your Account")
      /// This asset is hidden and is not visible in your Account
      static let withdraw = L10n.tr("Localizable", "transactionReview_hiddenAsset_withdraw", fallback: "This asset is hidden and is not visible in your Account")
    }
    enum NetworkFee {
      /// The network is currently congested. Add a tip to speed up your transfer.
      static let congestedText = L10n.tr("Localizable", "transactionReview_networkFee_congestedText", fallback: "The network is currently congested. Add a tip to speed up your transfer.")
      /// Customize
      static let customizeButtonTitle = L10n.tr("Localizable", "transactionReview_networkFee_customizeButtonTitle", fallback: "Customize")
      /// Transaction Fee
      static let heading = L10n.tr("Localizable", "transactionReview_networkFee_heading", fallback: "Transaction Fee")
    }
    enum NoMnemonicError {
      /// The required seed phrase is missing. Please return to the account and begin the recovery process.
      static let text = L10n.tr("Localizable", "transactionReview_noMnemonicError_text", fallback: "The required seed phrase is missing. Please return to the account and begin the recovery process.")
      /// Could Not Complete
      static let title = L10n.tr("Localizable", "transactionReview_noMnemonicError_title", fallback: "Could Not Complete")
    }
    enum NonConformingManifestWarning {
      /// This is a complex transaction that cannot be summarized - the raw transaction manifest will be shown. Do not submit unless you understand the contents.
      static let message = L10n.tr("Localizable", "transactionReview_nonConformingManifestWarning_message", fallback: "This is a complex transaction that cannot be summarized - the raw transaction manifest will be shown. Do not submit unless you understand the contents.")
      /// Warning
      static let title = L10n.tr("Localizable", "transactionReview_nonConformingManifestWarning_title", fallback: "Warning")
    }
    enum PrepareForSigning {
      /// Preparing transaction for signing
      static let body = L10n.tr("Localizable", "transactionReview_prepareForSigning_body", fallback: "Preparing transaction for signing")
      /// Preparing Transaction
      static let navigationTitle = L10n.tr("Localizable", "transactionReview_prepareForSigning_navigationTitle", fallback: "Preparing Transaction")
    }
    enum SubmitTransaction {
      /// Successfully committed
      static let displayCommitted = L10n.tr("Localizable", "transactionReview_submitTransaction_displayCommitted", fallback: "Successfully committed")
      /// Failed
      static let displayFailed = L10n.tr("Localizable", "transactionReview_submitTransaction_displayFailed", fallback: "Failed")
      /// Rejected
      static let displayRejected = L10n.tr("Localizable", "transactionReview_submitTransaction_displayRejected", fallback: "Rejected")
      /// Submitted but not confirmed
      static let displaySubmittedUnknown = L10n.tr("Localizable", "transactionReview_submitTransaction_displaySubmittedUnknown", fallback: "Submitted but not confirmed")
      /// Submitting
      static let displaySubmitting = L10n.tr("Localizable", "transactionReview_submitTransaction_displaySubmitting", fallback: "Submitting")
      /// Submitting Transaction
      static let navigationTitle = L10n.tr("Localizable", "transactionReview_submitTransaction_navigationTitle", fallback: "Submitting Transaction")
      /// Status
      static let status = L10n.tr("Localizable", "transactionReview_submitTransaction_status", fallback: "Status")
      /// Transaction ID
      static let txID = L10n.tr("Localizable", "transactionReview_submitTransaction_txID", fallback: "Transaction ID")
    }
    enum UnacceptableManifest {
      /// A proposed transaction was rejected because it contains one or more reserved instructions.
      static let rejected = L10n.tr("Localizable", "transactionReview_unacceptableManifest_rejected", fallback: "A proposed transaction was rejected because it contains one or more reserved instructions.")
    }
  }
  enum TransactionSigning {
    /// Incoming Transaction
    static let preparingTransaction = L10n.tr("Localizable", "transactionSigning_preparingTransaction", fallback: "Incoming Transaction")
    /// Submitting transaction…
    static let signingAndSubmittingTransaction = L10n.tr("Localizable", "transactionSigning_signingAndSubmittingTransaction", fallback: "Submitting transaction…")
    /// Approve Transaction
    static let signTransactionButtonTitle = L10n.tr("Localizable", "transactionSigning_signTransactionButtonTitle", fallback: "Approve Transaction")
    /// Approve Transaction
    static let title = L10n.tr("Localizable", "transactionSigning_title", fallback: "Approve Transaction")
  }
  enum TransactionStatus {
    enum AssertionFailure {
      /// A guarantee on transaction results was not met. Consider reducing your preferred guarantee %%
      static let text = L10n.tr("Localizable", "transactionStatus_assertionFailure_text", fallback: "A guarantee on transaction results was not met. Consider reducing your preferred guarantee %%")
    }
    enum Completing {
      /// Completing Transaction…
      static let text = L10n.tr("Localizable", "transactionStatus_completing_text", fallback: "Completing Transaction…")
    }
    enum DismissDialog {
      /// Stop waiting for transaction result? The transaction will not be canceled.
      static let message = L10n.tr("Localizable", "transactionStatus_dismissDialog_message", fallback: "Stop waiting for transaction result? The transaction will not be canceled.")
    }
    enum DismissalDisabledDialog {
      /// This transaction requires to be completed
      static let text = L10n.tr("Localizable", "transactionStatus_dismissalDisabledDialog_text", fallback: "This transaction requires to be completed")
      /// Dismiss
      static let title = L10n.tr("Localizable", "transactionStatus_dismissalDisabledDialog_title", fallback: "Dismiss")
    }
    enum Error {
      /// This transaction was rejected and is unlikely to be processed, but could potentially be processed within the next %@ minutes. It is likely that the dApp you are using proposed a transaction that includes an action that is not currently valid.
      static func text(_ p1: Any) -> String {
        return L10n.tr("Localizable", "transactionStatus_error_text", String(describing: p1), fallback: "This transaction was rejected and is unlikely to be processed, but could potentially be processed within the next %@ minutes. It is likely that the dApp you are using proposed a transaction that includes an action that is not currently valid.")
      }
      /// Transaction Error
      static let title = L10n.tr("Localizable", "transactionStatus_error_title", fallback: "Transaction Error")
    }
    enum Failed {
      /// Your transaction was processed, but had a problem that caused it to fail permanently
      static let text = L10n.tr("Localizable", "transactionStatus_failed_text", fallback: "Your transaction was processed, but had a problem that caused it to fail permanently")
      /// Transaction Failed
      static let title = L10n.tr("Localizable", "transactionStatus_failed_title", fallback: "Transaction Failed")
    }
    enum Failure {
      /// Transaction was rejected as invalid by the Radix Network.
      static let text = L10n.tr("Localizable", "transactionStatus_failure_text", fallback: "Transaction was rejected as invalid by the Radix Network.")
      /// Something Went Wrong
      static let title = L10n.tr("Localizable", "transactionStatus_failure_title", fallback: "Something Went Wrong")
    }
    enum Rejected {
      /// Your transaction was improperly constructed and cannot be processed
      static let text = L10n.tr("Localizable", "transactionStatus_rejected_text", fallback: "Your transaction was improperly constructed and cannot be processed")
      /// Transaction Rejected
      static let title = L10n.tr("Localizable", "transactionStatus_rejected_title", fallback: "Transaction Rejected")
    }
    enum Success {
      /// Your transaction was successful
      static let text = L10n.tr("Localizable", "transactionStatus_success_text", fallback: "Your transaction was successful")
      /// Transaction Success
      static let title = L10n.tr("Localizable", "transactionStatus_success_title", fallback: "Transaction Success")
    }
    enum TransactionID {
      /// Transaction ID: 
      static let text = L10n.tr("Localizable", "transactionStatus_transactionID_text", fallback: "Transaction ID: ")
    }
  }
  enum Troubleshooting {
    /// Account Recovery
    static let accountRecovery = L10n.tr("Localizable", "troubleshooting_accountRecovery", fallback: "Account Recovery")
    /// Reset Account
    static let resetAccount = L10n.tr("Localizable", "troubleshooting_resetAccount", fallback: "Reset Account")
    /// Support and Community
    static let supportAndCommunity = L10n.tr("Localizable", "troubleshooting_supportAndCommunity", fallback: "Support and Community")
    /// Troubleshooting
    static let title = L10n.tr("Localizable", "troubleshooting_title", fallback: "Troubleshooting")
    enum AccountScan {
      /// Recover Accounts with a seed phrase or Ledger device
      static let subtitle = L10n.tr("Localizable", "troubleshooting_accountScan_subtitle", fallback: "Recover Accounts with a seed phrase or Ledger device")
      /// Account Recovery Scan
      static let title = L10n.tr("Localizable", "troubleshooting_accountScan_title", fallback: "Account Recovery Scan")
    }
    enum ContactSupport {
      /// Connect directly with the Radix support team
      static let subtitle = L10n.tr("Localizable", "troubleshooting_contactSupport_subtitle", fallback: "Connect directly with the Radix support team")
      /// Contact Support
      static let title = L10n.tr("Localizable", "troubleshooting_contactSupport_title", fallback: "Contact Support")
    }
    enum Discord {
      /// Connect to the official Radix Discord channel to join the community and ask for help.
      static let subtitle = L10n.tr("Localizable", "troubleshooting_discord_subtitle", fallback: "Connect to the official Radix Discord channel to join the community and ask for help.")
      /// Discord
      static let title = L10n.tr("Localizable", "troubleshooting_discord_title", fallback: "Discord")
    }
    enum FactoryReset {
      /// Restore your Radix wallet to its original state
      static let subtitle = L10n.tr("Localizable", "troubleshooting_factoryReset_subtitle", fallback: "Restore your Radix wallet to its original state")
      /// Factory Reset
      static let title = L10n.tr("Localizable", "troubleshooting_factoryReset_title", fallback: "Factory Reset")
    }
    enum LegacyImport {
      /// Import Accounts from an Olympia wallet
      static let subtitle = L10n.tr("Localizable", "troubleshooting_legacyImport_subtitle", fallback: "Import Accounts from an Olympia wallet")
      /// Import from a Legacy Wallet
      static let title = L10n.tr("Localizable", "troubleshooting_legacyImport_title", fallback: "Import from a Legacy Wallet")
    }
  }
  enum WalletSettings {
    /// App version: %@
    static func appVersion(_ p1: Any) -> String {
      return L10n.tr("Localizable", "walletSettings_appVersion", String(describing: p1), fallback: "App version: %@")
    }
    /// Wallet Settings
    static let title = L10n.tr("Localizable", "walletSettings_title", fallback: "Wallet Settings")
    enum Connectors {
      /// Connect to desktop through the Radix Connector browser extension
      static let subtitle = L10n.tr("Localizable", "walletSettings_connectors_subtitle", fallback: "Connect to desktop through the Radix Connector browser extension")
      /// Linked Connectors
      static let title = L10n.tr("Localizable", "walletSettings_connectors_title", fallback: "Linked Connectors")
    }
    enum Dapps {
      /// Manage the Radix dApps you're connected to
      static let subtitle = L10n.tr("Localizable", "walletSettings_dapps_subtitle", fallback: "Manage the Radix dApps you're connected to")
      /// Approved dApps
      static let title = L10n.tr("Localizable", "walletSettings_dapps_title", fallback: "Approved dApps")
    }
    enum LinkToConnectorHeader {
      /// Link to Connector
      static let button = L10n.tr("Localizable", "walletSettings_linkToConnectorHeader_button", fallback: "Link to Connector")
      /// Scan the QR code in the Radix Wallet Connector extension
      static let subtitle = L10n.tr("Localizable", "walletSettings_linkToConnectorHeader_subtitle", fallback: "Scan the QR code in the Radix Wallet Connector extension")
      /// Link your Wallet to a desktop browser
      static let title = L10n.tr("Localizable", "walletSettings_linkToConnectorHeader_title", fallback: "Link your Wallet to a desktop browser")
    }
    enum Personas {
      /// Please write down the seed phrase for your Personas
      static let hint = L10n.tr("Localizable", "walletSettings_personas_hint", fallback: "Please write down the seed phrase for your Personas")
      /// Manage Radix dApp login details
      static let subtitle = L10n.tr("Localizable", "walletSettings_personas_subtitle", fallback: "Manage Radix dApp login details")
      /// Personas
      static let title = L10n.tr("Localizable", "walletSettings_personas_title", fallback: "Personas")
    }
    enum Preferences {
      /// Deposits, hidden Accounts and Personas, and advanced preferences
      static let subtitle = L10n.tr("Localizable", "walletSettings_preferences_subtitle", fallback: "Deposits, hidden Accounts and Personas, and advanced preferences")
      /// Preferences
      static let title = L10n.tr("Localizable", "walletSettings_preferences_title", fallback: "Preferences")
    }
    enum SecurityCenter {
      /// Manage your wallet security settings
      static let subtitle = L10n.tr("Localizable", "walletSettings_securityCenter_subtitle", fallback: "Manage your wallet security settings")
      /// Security Center
      static let title = L10n.tr("Localizable", "walletSettings_securityCenter_title", fallback: "Security Center")
    }
    enum Troubleshooting {
      /// Add your existing Accounts and contact support
      static let subtitle = L10n.tr("Localizable", "walletSettings_troubleshooting_subtitle", fallback: "Add your existing Accounts and contact support")
      /// Troubleshooting
      static let title = L10n.tr("Localizable", "walletSettings_troubleshooting_title", fallback: "Troubleshooting")
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
