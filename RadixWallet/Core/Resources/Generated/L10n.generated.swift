// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  internal enum Account {
    /// Badges
    internal static let badges = L10n.tr("Localizable", "account_badges", fallback: "Badges")
    /// NFTs
    internal static let nfts = L10n.tr("Localizable", "account_nfts", fallback: "NFTs")
    /// Pool Units
    internal static let poolUnits = L10n.tr("Localizable", "account_poolUnits", fallback: "Pool Units")
    /// Staking
    internal static let staking = L10n.tr("Localizable", "account_staking", fallback: "Staking")
    /// Tokens
    internal static let tokens = L10n.tr("Localizable", "account_tokens", fallback: "Tokens")
    /// Transfer
    internal static let transfer = L10n.tr("Localizable", "account_transfer", fallback: "Transfer")
    internal enum Nfts {
      /// %d in this collection
      internal static func itemsCount(_ p1: Int) -> String {
        return L10n.tr("Localizable", "account_nfts_itemsCount", p1, fallback: "%d in this collection")
      }
    }
    internal enum PoolUnits {
      /// Missing Total supply - could not calculate redemption value
      internal static let noTotalSupply = L10n.tr("Localizable", "account_poolUnits_noTotalSupply", fallback: "Missing Total supply - could not calculate redemption value")
      /// Unknown
      internal static let unknownPoolUnitName = L10n.tr("Localizable", "account_poolUnits_unknownPoolUnitName", fallback: "Unknown")
      /// Unknown
      internal static let unknownSymbolName = L10n.tr("Localizable", "account_poolUnits_unknownSymbolName", fallback: "Unknown")
      /// Unknown
      internal static let unknownValidatorName = L10n.tr("Localizable", "account_poolUnits_unknownValidatorName", fallback: "Unknown")
      internal enum Details {
        /// Current Redeemable Value
        internal static let currentRedeemableValue = L10n.tr("Localizable", "account_poolUnits_details_currentRedeemableValue", fallback: "Current Redeemable Value")
      }
    }
    internal enum Staking {
      /// Claim
      internal static let claim = L10n.tr("Localizable", "account_staking_claim", fallback: "Claim")
      /// Current Stake: %@
      internal static func currentStake(_ p1: Any) -> String {
        return L10n.tr("Localizable", "account_staking_currentStake", String(describing: p1), fallback: "Current Stake: %@")
      }
      /// Liquid Stake Units
      internal static let liquidStakeUnits = L10n.tr("Localizable", "account_staking_liquidStakeUnits", fallback: "Liquid Stake Units")
      /// Radix Network XRD Stake Summary
      internal static let lsuResourceHeader = L10n.tr("Localizable", "account_staking_lsuResourceHeader", fallback: "Radix Network XRD Stake Summary")
      /// Ready to be claimed
      internal static let readyToBeClaimed = L10n.tr("Localizable", "account_staking_readyToBeClaimed", fallback: "Ready to be claimed")
      /// Ready to Claim
      internal static let readyToClaim = L10n.tr("Localizable", "account_staking_readyToClaim", fallback: "Ready to Claim")
      /// Stake Claim NFTs
      internal static let stakeClaimNFTs = L10n.tr("Localizable", "account_staking_stakeClaimNFTs", fallback: "Stake Claim NFTs")
      /// Staked
      internal static let staked = L10n.tr("Localizable", "account_staking_staked", fallback: "Staked")
      /// STAKED VALIDATORS (%d)
      internal static func stakedValidators(_ p1: Int) -> String {
        return L10n.tr("Localizable", "account_staking_stakedValidators", p1, fallback: "STAKED VALIDATORS (%d)")
      }
      /// Unstaking
      internal static let unstaking = L10n.tr("Localizable", "account_staking_unstaking", fallback: "Unstaking")
      /// WORTH
      internal static let worth = L10n.tr("Localizable", "account_staking_worth", fallback: "WORTH")
    }
  }
  internal enum AccountRecoveryScan {
    /// Use Ledger Hardware Wallet
    internal static let ledgerButtonTitle = L10n.tr("Localizable", "accountRecoveryScan_ledgerButtonTitle", fallback: "Use Ledger Hardware Wallet")
    /// Note: You must still use the new *Radix Babylon* app on your Ledger device, not the old Radix Ledger app.
    internal static let olympiaLedgerNote = L10n.tr("Localizable", "accountRecoveryScan_olympiaLedgerNote", fallback: "Note: You must still use the new *Radix Babylon* app on your Ledger device, not the old Radix Ledger app.")
    /// Use Seed Phrase
    internal static let seedPhraseButtonTitle = L10n.tr("Localizable", "accountRecoveryScan_seedPhraseButtonTitle", fallback: "Use Seed Phrase")
    /// The Radix Wallet can scan for previously used accounts using a bare seed phrase or Ledger hardware wallet device
    internal static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_subtitle", fallback: "The Radix Wallet can scan for previously used accounts using a bare seed phrase or Ledger hardware wallet device")
    /// Account Recovery Scan
    internal static let title = L10n.tr("Localizable", "accountRecoveryScan_title", fallback: "Account Recovery Scan")
    internal enum BabylonSection {
      /// Scan for Accounts originally created on the **Babylon** network.
      internal static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_babylonSection_subtitle", fallback: "Scan for Accounts originally created on the **Babylon** network.")
      /// Babylon Accounts
      internal static let title = L10n.tr("Localizable", "accountRecoveryScan_babylonSection_title", fallback: "Babylon Accounts")
    }
    internal enum ChooseSeedPhrase {
      /// Add Babylon Seed Phrase
      internal static let addButtonBabylon = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_addButtonBabylon", fallback: "Add Babylon Seed Phrase")
      /// Add Olympia Seed Phrase
      internal static let addButtonOlympia = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_addButtonOlympia", fallback: "Add Olympia Seed Phrase")
      /// Continue
      internal static let continueButton = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_continueButton", fallback: "Continue")
      /// Enter Seed Phrase
      internal static let importMnemonicTitleBabylon = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_importMnemonicTitleBabylon", fallback: "Enter Seed Phrase")
      /// Enter Legacy Seed Phrase
      internal static let importMnemonicTitleOlympia = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_importMnemonicTitleOlympia", fallback: "Enter Legacy Seed Phrase")
      /// Choose the Babylon seed phrase for use for derivation:
      internal static let subtitleBabylon = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_subtitleBabylon", fallback: "Choose the Babylon seed phrase for use for derivation:")
      /// Choose the "Legacy" Olympia seed phrase for use for derivation:
      internal static let subtitleOlympia = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_subtitleOlympia", fallback: "Choose the \"Legacy\" Olympia seed phrase for use for derivation:")
      /// Choose Seed Phrase
      internal static let title = L10n.tr("Localizable", "accountRecoveryScan_chooseSeedPhrase_title", fallback: "Choose Seed Phrase")
    }
    internal enum InProgress {
      /// **Babylon Seed Phrase**
      internal static let factorSourceBabylonSeedPhrase = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceBabylonSeedPhrase", fallback: "**Babylon Seed Phrase**")
      /// Signing Factor
      internal static let factorSourceFallback = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceFallback", fallback: "Signing Factor")
      /// **Ledger hardware wallet device**
      internal static let factorSourceLedgerHardwareDevice = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceLedgerHardwareDevice", fallback: "**Ledger hardware wallet device**")
      /// **Olympia Seed Phrase**
      internal static let factorSourceOlympiaSeedPhrase = L10n.tr("Localizable", "accountRecoveryScan_inProgress_factorSourceOlympiaSeedPhrase", fallback: "**Olympia Seed Phrase**")
      /// Scanning for Accounts that have been included in at least one transaction, using:
      internal static let headerSubtitle = L10n.tr("Localizable", "accountRecoveryScan_inProgress_headerSubtitle", fallback: "Scanning for Accounts that have been included in at least one transaction, using:")
      /// Scanning in progress
      internal static let headerTitle = L10n.tr("Localizable", "accountRecoveryScan_inProgress_headerTitle", fallback: "Scanning in progress")
      /// Unnamed
      internal static let nameOfRecoveredAccount = L10n.tr("Localizable", "accountRecoveryScan_inProgress_nameOfRecoveredAccount", fallback: "Unnamed")
      /// Scanning network
      internal static let scanningNetwork = L10n.tr("Localizable", "accountRecoveryScan_inProgress_scanningNetwork", fallback: "Scanning network")
    }
    internal enum OlympiaSection {
      /// Note: You will still use the new **Radix Babylon** app on your Ledger device, not the old Radix Ledger app.
      internal static let footnote = L10n.tr("Localizable", "accountRecoveryScan_olympiaSection_footnote", fallback: "Note: You will still use the new **Radix Babylon** app on your Ledger device, not the old Radix Ledger app.")
      /// Scan for Accounts originally created on the **Olympia** network.
      /// 
      /// (If you have Olympia Accounts in the Radix Olympia Desktop Wallet, consider using **Import from a Legacy Wallet** instead.
      internal static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_olympiaSection_subtitle", fallback: "Scan for Accounts originally created on the **Olympia** network.\n\n(If you have Olympia Accounts in the Radix Olympia Desktop Wallet, consider using **Import from a Legacy Wallet** instead.")
      /// Olympia Accounts
      internal static let title = L10n.tr("Localizable", "accountRecoveryScan_olympiaSection_title", fallback: "Olympia Accounts")
    }
    internal enum ScanComplete {
      /// Continue
      internal static let continueButton = L10n.tr("Localizable", "accountRecoveryScan_scanComplete_continueButton", fallback: "Continue")
      /// The first **%d** potential Accounts from this signing factor were scanned. The following Accounts had at least one transaction:
      internal static func headerSubtitle(_ p1: Int) -> String {
        return L10n.tr("Localizable", "accountRecoveryScan_scanComplete_headerSubtitle", p1, fallback: "The first **%d** potential Accounts from this signing factor were scanned. The following Accounts had at least one transaction:")
      }
      /// Scan Complete
      internal static let headerTitle = L10n.tr("Localizable", "accountRecoveryScan_scanComplete_headerTitle", fallback: "Scan Complete")
      /// No new accounts found
      internal static let noAccounts = L10n.tr("Localizable", "accountRecoveryScan_scanComplete_noAccounts", fallback: "No new accounts found")
      /// Tap here to scan the next %d
      internal static func scanNextBatchButton(_ p1: Int) -> String {
        return L10n.tr("Localizable", "accountRecoveryScan_scanComplete_scanNextBatchButton", p1, fallback: "Tap here to scan the next %d")
      }
    }
    internal enum SelectInactiveAccounts {
      /// Continue
      internal static let continueButton = L10n.tr("Localizable", "accountRecoveryScan_selectInactiveAccounts_continueButton", fallback: "Continue")
      internal enum Header {
        /// These Accounts were never used, but you **may** have created them. Select any addresses that you wish to keep:
        internal static let subtitle = L10n.tr("Localizable", "accountRecoveryScan_selectInactiveAccounts_header_subtitle", fallback: "These Accounts were never used, but you **may** have created them. Select any addresses that you wish to keep:")
        /// Add Inactive Accounts?
        internal static let title = L10n.tr("Localizable", "accountRecoveryScan_selectInactiveAccounts_header_title", fallback: "Add Inactive Accounts?")
      }
    }
  }
  internal enum AccountSecuritySettings {
    internal enum AccountRecoveryScan {
      /// Using seed phrase or Ledger device
      internal static let subtitle = L10n.tr("Localizable", "accountSecuritySettings_accountRecoveryScan_subtitle", fallback: "Using seed phrase or Ledger device")
      /// Account Recovery Scan
      internal static let title = L10n.tr("Localizable", "accountSecuritySettings_accountRecoveryScan_title", fallback: "Account Recovery Scan")
    }
    internal enum Backups {
      /// Backups
      internal static let title = L10n.tr("Localizable", "accountSecuritySettings_backups_title", fallback: "Backups")
    }
    internal enum DepositGuarantees {
      /// Set your default guaranteed minimum for estimated deposits
      internal static let subtitle = L10n.tr("Localizable", "accountSecuritySettings_depositGuarantees_subtitle", fallback: "Set your default guaranteed minimum for estimated deposits")
      /// Set the guaranteed minimum deposit to be applied whenever a deposit in a transaction can only be estimated.
      /// 
      /// You can always change the guarantee from this default in each transaction.
      internal static let text = L10n.tr("Localizable", "accountSecuritySettings_depositGuarantees_text", fallback: "Set the guaranteed minimum deposit to be applied whenever a deposit in a transaction can only be estimated.\n\nYou can always change the guarantee from this default in each transaction.")
      /// Default Deposit Guarantees
      internal static let title = L10n.tr("Localizable", "accountSecuritySettings_depositGuarantees_title", fallback: "Default Deposit Guarantees")
    }
    internal enum ImportFromLegacyWallet {
      /// Import from a Legacy Wallet
      internal static let title = L10n.tr("Localizable", "accountSecuritySettings_importFromLegacyWallet_title", fallback: "Import from a Legacy Wallet")
    }
    internal enum LedgerHardwareWallets {
      /// Ledger Hardware Wallets
      internal static let title = L10n.tr("Localizable", "accountSecuritySettings_ledgerHardwareWallets_title", fallback: "Ledger Hardware Wallets")
    }
    internal enum SeedPhrases {
      /// Seed Phrases
      internal static let title = L10n.tr("Localizable", "accountSecuritySettings_seedPhrases_title", fallback: "Seed Phrases")
    }
  }
  internal enum AccountSettings {
    /// Account Color
    internal static let accountColor = L10n.tr("Localizable", "accountSettings_accountColor", fallback: "Account Color")
    /// Select from a list of unique colors
    internal static let accountColorSubtitle = L10n.tr("Localizable", "accountSettings_accountColorSubtitle", fallback: "Select from a list of unique colors")
    /// Account Hidden
    internal static let accountHidden = L10n.tr("Localizable", "accountSettings_accountHidden", fallback: "Account Hidden")
    /// Account Name
    internal static let accountLabel = L10n.tr("Localizable", "accountSettings_accountLabel", fallback: "Account Name")
    /// Name your account
    internal static let accountLabelSubtitle = L10n.tr("Localizable", "accountSettings_accountLabelSubtitle", fallback: "Name your account")
    /// Delete Account
    internal static let deleteAccount = L10n.tr("Localizable", "accountSettings_deleteAccount", fallback: "Delete Account")
    /// Set development preferences
    internal static let developmentHeading = L10n.tr("Localizable", "accountSettings_developmentHeading", fallback: "Set development preferences")
    /// Dev Preferences
    internal static let devPreferences = L10n.tr("Localizable", "accountSettings_devPreferences", fallback: "Dev Preferences")
    /// Get XRD Test Tokens
    internal static let getXrdTestTokens = L10n.tr("Localizable", "accountSettings_getXrdTestTokens", fallback: "Get XRD Test Tokens")
    /// Hide Account
    internal static let hideAccount = L10n.tr("Localizable", "accountSettings_hideAccount", fallback: "Hide Account")
    /// Are you sure you want to hide this account?
    internal static let hideAccountConfirmation = L10n.tr("Localizable", "accountSettings_hideAccountConfirmation", fallback: "Are you sure you want to hide this account?")
    /// Hide This Account
    internal static let hideThisAccount = L10n.tr("Localizable", "accountSettings_hideThisAccount", fallback: "Hide This Account")
    /// This may take several seconds, please wait for completion
    internal static let loadingPrompt = L10n.tr("Localizable", "accountSettings_loadingPrompt", fallback: "This may take several seconds, please wait for completion")
    /// Personalize this Account
    internal static let personalizeHeading = L10n.tr("Localizable", "accountSettings_personalizeHeading", fallback: "Personalize this Account")
    /// Set how you want this Account to work
    internal static let setBehaviorHeading = L10n.tr("Localizable", "accountSettings_setBehaviorHeading", fallback: "Set how you want this Account to work")
    /// Show Assets with Tags
    internal static let showAssets = L10n.tr("Localizable", "accountSettings_showAssets", fallback: "Show Assets with Tags")
    /// Select which tags to show for assets in this Account
    internal static let showAssetsSubtitle = L10n.tr("Localizable", "accountSettings_showAssetsSubtitle", fallback: "Select which tags to show for assets in this Account")
    /// Show Account QR Code
    internal static let showQR = L10n.tr("Localizable", "accountSettings_showQR", fallback: "Show Account QR Code")
    /// Allow/Deny Specific Assets
    internal static let specificAssetsDeposits = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits", fallback: "Allow/Deny Specific Assets")
    /// Third-party Deposits
    internal static let thirdPartyDeposits = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits", fallback: "Third-party Deposits")
    /// Choose who can deposit into your Account
    internal static let thirdPartyDepositsSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDepositsSubtitle", fallback: "Choose who can deposit into your Account")
    /// Account Settings
    internal static let title = L10n.tr("Localizable", "accountSettings_title", fallback: "Account Settings")
    /// Updated
    internal static let updatedAccountHUDMessage = L10n.tr("Localizable", "accountSettings_updatedAccountHUDMessage", fallback: "Updated")
    internal enum AccountColor {
      /// Selected
      internal static let selected = L10n.tr("Localizable", "accountSettings_accountColor_selected", fallback: "Selected")
      /// Select the color for this Account
      internal static let text = L10n.tr("Localizable", "accountSettings_accountColor_text", fallback: "Select the color for this Account")
    }
    internal enum AccountDeleted {
      /// Go to Homescreen
      internal static let button = L10n.tr("Localizable", "accountSettings_accountDeleted_button", fallback: "Go to Homescreen")
      /// Your Account has been permanently deleted. Your wallet settings have been updated.
      internal static let message = L10n.tr("Localizable", "accountSettings_accountDeleted_message", fallback: "Your Account has been permanently deleted. Your wallet settings have been updated.")
      /// Account Deleted
      internal static let title = L10n.tr("Localizable", "accountSettings_accountDeleted_title", fallback: "Account Deleted")
    }
    internal enum AssetsWillBeLostWarning {
      /// If you do not transfer your assets out of this Account, they will be lost forever.
      internal static let message = L10n.tr("Localizable", "accountSettings_assetsWillBeLostWarning_message", fallback: "If you do not transfer your assets out of this Account, they will be lost forever.")
      /// Assets Will Be Lost
      internal static let title = L10n.tr("Localizable", "accountSettings_assetsWillBeLostWarning_title", fallback: "Assets Will Be Lost")
    }
    internal enum CannotDeleteAccountWarning {
      /// Too many assets currently held in Account to perform deletion. Move some and try again.
      internal static let message = L10n.tr("Localizable", "accountSettings_cannotDeleteAccountWarning_message", fallback: "Too many assets currently held in Account to perform deletion. Move some and try again.")
      /// Cannot Delete Account
      internal static let title = L10n.tr("Localizable", "accountSettings_cannotDeleteAccountWarning_title", fallback: "Cannot Delete Account")
    }
    internal enum DeleteAccount {
      /// You’re about to permanently delete this Account. Once this is done, you will not be able to recover access.
      internal static let message = L10n.tr("Localizable", "accountSettings_deleteAccount_message", fallback: "You’re about to permanently delete this Account. Once this is done, you will not be able to recover access.")
      /// Delete This Account?
      internal static let title = L10n.tr("Localizable", "accountSettings_deleteAccount_title", fallback: "Delete This Account?")
    }
    internal enum HideAccount {
      /// Hide Account
      internal static let button = L10n.tr("Localizable", "accountSettings_hideAccount_button", fallback: "Hide Account")
      /// Hide this Account in your wallet? You can always unhide it from the main application settings.
      internal static let message = L10n.tr("Localizable", "accountSettings_hideAccount_message", fallback: "Hide this Account in your wallet? You can always unhide it from the main application settings.")
      /// Hide This Account
      internal static let title = L10n.tr("Localizable", "accountSettings_hideAccount_title", fallback: "Hide This Account")
    }
    internal enum MoveAssets {
      /// Before deleting this Account, choose another one to transfer your assets to.
      internal static let message = L10n.tr("Localizable", "accountSettings_moveAssets_message", fallback: "Before deleting this Account, choose another one to transfer your assets to.")
      /// You don’t have any other accounts with enough XRD.
      internal static let noAccountsWarning = L10n.tr("Localizable", "accountSettings_moveAssets_noAccountsWarning", fallback: "You don’t have any other accounts with enough XRD.")
      /// The new Account must hold enough XRD to pay the transaction fee.
      internal static let note = L10n.tr("Localizable", "accountSettings_moveAssets_note", fallback: "The new Account must hold enough XRD to pay the transaction fee.")
      /// Skip
      internal static let skipButton = L10n.tr("Localizable", "accountSettings_moveAssets_skipButton", fallback: "Skip")
      /// Move Assets to Another Account
      internal static let title = L10n.tr("Localizable", "accountSettings_moveAssets_title", fallback: "Move Assets to Another Account")
    }
    internal enum NonTransferableAssetsWarning {
      /// Some of your assets are non-transferable, and will be lost.
      internal static let message = L10n.tr("Localizable", "accountSettings_nonTransferableAssetsWarning_message", fallback: "Some of your assets are non-transferable, and will be lost.")
      /// Assets Will Be Lost
      internal static let title = L10n.tr("Localizable", "accountSettings_nonTransferableAssetsWarning_title", fallback: "Assets Will Be Lost")
    }
    internal enum RenameAccount {
      /// Update
      internal static let button = L10n.tr("Localizable", "accountSettings_renameAccount_button", fallback: "Update")
      /// Enter a new label for this Account
      internal static let subtitle = L10n.tr("Localizable", "accountSettings_renameAccount_subtitle", fallback: "Enter a new label for this Account")
      /// Rename Account
      internal static let title = L10n.tr("Localizable", "accountSettings_renameAccount_title", fallback: "Rename Account")
    }
    internal enum ShowAssets {
      /// Recommended
      internal static let recommended = L10n.tr("Localizable", "accountSettings_showAssets_recommended", fallback: "Recommended")
      /// Select the ones you’d like shown on all your assets.
      internal static let selectShown = L10n.tr("Localizable", "accountSettings_showAssets_selectShown", fallback: "Select the ones you’d like shown on all your assets.")
      /// Asset creators can add tags to them. You can choose which tags you want to see in this Account.
      internal static let text = L10n.tr("Localizable", "accountSettings_showAssets_text", fallback: "Asset creators can add tags to them. You can choose which tags you want to see in this Account.")
    }
    internal enum SpecificAssetsDeposits {
      /// Allow Deposits
      internal static let addAnAssetAllow = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetAllow", fallback: "Allow Deposits")
      /// Add Asset
      internal static let addAnAssetButton = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetButton", fallback: "Add Asset")
      /// Deny Deposits
      internal static let addAnAssetDeny = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetDeny", fallback: "Deny Deposits")
      /// Resource Address
      internal static let addAnAssetInputHint = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetInputHint", fallback: "Resource Address")
      /// Enter the asset’s resource address (starting with “reso”)
      internal static let addAnAssetSubtitle = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetSubtitle", fallback: "Enter the asset’s resource address (starting with “reso”)")
      /// Add an Asset
      internal static let addAnAssetTitle = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_addAnAssetTitle", fallback: "Add an Asset")
      /// Allow
      internal static let allow = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allow", fallback: "Allow")
      /// The holder of the following badges may always deposit accounts to this account.
      internal static let allowDepositors = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allowDepositors", fallback: "The holder of the following badges may always deposit accounts to this account.")
      /// Add a specific badge by its resource address to allow all deposits from its holder.
      internal static let allowDepositorsNoResources = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allowDepositorsNoResources", fallback: "Add a specific badge by its resource address to allow all deposits from its holder.")
      /// The following resource addresses may always be deposited to this account by third parties.
      internal static let allowInfo = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_allowInfo", fallback: "The following resource addresses may always be deposited to this account by third parties.")
      /// Deny
      internal static let deny = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_deny", fallback: "Deny")
      /// The following resource addresses may never be deposited to this account by third parties.
      internal static let denyInfo = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_denyInfo", fallback: "The following resource addresses may never be deposited to this account by third parties.")
      /// Add a specific asset by its resource address to allow all third-party deposits
      internal static let emptyAllowAll = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_emptyAllowAll", fallback: "Add a specific asset by its resource address to allow all third-party deposits")
      /// Add a specific asset by its resource address to deny all third-party deposits
      internal static let emptyDenyAll = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_emptyDenyAll", fallback: "Add a specific asset by its resource address to deny all third-party deposits")
      /// Sorry, this Account's third-party exceptions and depositor lists are in an unknown state and cannot be viewed or edited because it was imported using only a seed phrase or Ledger. A forthcoming wallet update will enable viewing and editing of these lists.
      internal static let modificationDisabledForRecoveredAccount = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_modificationDisabledForRecoveredAccount", fallback: "Sorry, this Account's third-party exceptions and depositor lists are in an unknown state and cannot be viewed or edited because it was imported using only a seed phrase or Ledger. A forthcoming wallet update will enable viewing and editing of these lists.")
      /// Remove Asset
      internal static let removeAsset = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeAsset", fallback: "Remove Asset")
      /// The asset will be removed from the allow list
      internal static let removeAssetMessageAllow = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeAssetMessageAllow", fallback: "The asset will be removed from the allow list")
      /// The asset will be removed from the deny list
      internal static let removeAssetMessageDeny = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeAssetMessageDeny", fallback: "The asset will be removed from the deny list")
      /// The badge will be removed from the list
      internal static let removeBadgeMessageDepositors = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeBadgeMessageDepositors", fallback: "The badge will be removed from the list")
      /// Remove Depositor
      internal static let removeDepositor = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeDepositor", fallback: "Remove Depositor")
      /// The depositor will be removed from the allow list
      internal static let removeDepositorMessage = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_removeDepositorMessage", fallback: "The depositor will be removed from the allow list")
      /// Select exception list
      internal static let resourceListPicker = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_resourceListPicker", fallback: "Select exception list")
      /// Update
      internal static let update = L10n.tr("Localizable", "accountSettings_specificAssetsDeposits_update", fallback: "Update")
    }
    internal enum ThirdPartyDeposits {
      /// Accept all deposits
      internal static let acceptAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAll", fallback: "Accept all deposits")
      /// Allow third-parties to deposit any asset
      internal static let acceptAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_acceptAllSubtitle", fallback: "Allow third-parties to deposit any asset")
      /// Enter the badge’s resource address (starting with “reso”)
      internal static let addDepositorSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_addDepositorSubtitle", fallback: "Enter the badge’s resource address (starting with “reso”)")
      /// Add a Depositor Badge
      internal static let addDepositorTitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_addDepositorTitle", fallback: "Add a Depositor Badge")
      /// Allow/Deny specific assets
      internal static let allowDenySpecific = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowDenySpecific", fallback: "Allow/Deny specific assets")
      /// Deny or allow third-party deposits of specific assets, ignoring the setting above
      internal static let allowDenySpecificSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowDenySpecificSubtitle", fallback: "Deny or allow third-party deposits of specific assets, ignoring the setting above")
      /// Allow specific depositors
      internal static let allowSpecificDepositors = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowSpecificDepositors", fallback: "Allow specific depositors")
      /// Add Depositor Badge
      internal static let allowSpecificDepositorsButton = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowSpecificDepositorsButton", fallback: "Add Depositor Badge")
      /// Allow certain third party depositors to deposit assets freely
      internal static let allowSpecificDepositorsSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_allowSpecificDepositorsSubtitle", fallback: "Allow certain third party depositors to deposit assets freely")
      /// Deny all
      internal static let denyAll = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAll", fallback: "Deny all")
      /// Deny all third-party deposits
      internal static let denyAllSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAllSubtitle", fallback: "Deny all third-party deposits")
      /// This account will not be able to receive "air drops" or be used by a trusted contact to assist with account recovery.
      internal static let denyAllWarning = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_denyAllWarning", fallback: "This account will not be able to receive \"air drops\" or be used by a trusted contact to assist with account recovery.")
      /// Discard Changes
      internal static let discardChanges = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_discardChanges", fallback: "Discard Changes")
      /// Are you sure you want to discard changes?
      internal static let discardMessage = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_discardMessage", fallback: "Are you sure you want to discard changes?")
      /// Keep Editing
      internal static let keepEditing = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_keepEditing", fallback: "Keep Editing")
      /// Only accept known
      internal static let onlyKnown = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_onlyKnown", fallback: "Only accept known")
      /// Allow third-parties to deposit only assets this Account already holds
      internal static let onlyKnownSubtitle = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_onlyKnownSubtitle", fallback: "Allow third-parties to deposit only assets this Account already holds")
      /// Choose if you want to allow third parties to directly deposit assets into your Account. Deposits that you approve yourself in your Radix Wallet are always accepted.
      internal static let text = L10n.tr("Localizable", "accountSettings_thirdPartyDeposits_text", fallback: "Choose if you want to allow third parties to directly deposit assets into your Account. Deposits that you approve yourself in your Radix Wallet are always accepted.")
    }
  }
  internal enum AddLedgerDevice {
    internal enum AddDevice {
      /// Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.
      internal static let body1 = L10n.tr("Localizable", "addLedgerDevice_addDevice_body1", fallback: "Let’s set up a Ledger hardware wallet device. You will be able to use it to create new Ledger-secured Accounts, or import Ledger-secured Accounts from the Radix Olympia Desktop Wallet.")
      /// Connect your Ledger to a computer running a linked Radix Connector browser extension, and make sure the Radix Babylon app is running on the Ledger device.
      internal static let body2 = L10n.tr("Localizable", "addLedgerDevice_addDevice_body2", fallback: "Connect your Ledger to a computer running a linked Radix Connector browser extension, and make sure the Radix Babylon app is running on the Ledger device.")
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "addLedgerDevice_addDevice_continue", fallback: "Continue")
      /// Add Ledger Device
      internal static let title = L10n.tr("Localizable", "addLedgerDevice_addDevice_title", fallback: "Add Ledger Device")
    }
    internal enum AlreadyAddedAlert {
      /// You have already added this Ledger as: %@
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "addLedgerDevice_alreadyAddedAlert_message", String(describing: p1), fallback: "You have already added this Ledger as: %@")
      }
      /// Ledger Already Added
      internal static let title = L10n.tr("Localizable", "addLedgerDevice_alreadyAddedAlert_title", fallback: "Ledger Already Added")
    }
    internal enum NameLedger {
      /// Save and Continue
      internal static let continueButtonTitle = L10n.tr("Localizable", "addLedgerDevice_nameLedger_continueButtonTitle", fallback: "Save and Continue")
      /// Detected type: %@
      internal static func detectedType(_ p1: Any) -> String {
        return L10n.tr("Localizable", "addLedgerDevice_nameLedger_detectedType", String(describing: p1), fallback: "Detected type: %@")
      }
      /// This will be displayed when you’re prompted to sign with this Ledger device.
      internal static let fieldHint = L10n.tr("Localizable", "addLedgerDevice_nameLedger_fieldHint", fallback: "This will be displayed when you’re prompted to sign with this Ledger device.")
      /// Green Ledger Nano S+
      internal static let namePlaceholder = L10n.tr("Localizable", "addLedgerDevice_nameLedger_namePlaceholder", fallback: "Green Ledger Nano S+")
      /// What would you like to call this Ledger device?
      internal static let subtitle = L10n.tr("Localizable", "addLedgerDevice_nameLedger_subtitle", fallback: "What would you like to call this Ledger device?")
      /// Name Your Ledger
      internal static let title = L10n.tr("Localizable", "addLedgerDevice_nameLedger_title", fallback: "Name Your Ledger")
    }
  }
  internal enum AddressAction {
    /// Copied to Clipboard
    internal static let copiedToClipboard = L10n.tr("Localizable", "addressAction_copiedToClipboard", fallback: "Copied to Clipboard")
    /// Copy Address
    internal static let copyAddress = L10n.tr("Localizable", "addressAction_copyAddress", fallback: "Copy Address")
    /// Copy NFT ID
    internal static let copyNftId = L10n.tr("Localizable", "addressAction_copyNftId", fallback: "Copy NFT ID")
    /// Copy Transaction ID
    internal static let copyTransactionId = L10n.tr("Localizable", "addressAction_copyTransactionId", fallback: "Copy Transaction ID")
    /// There is no web browser installed in this device
    internal static let noWebBrowserInstalled = L10n.tr("Localizable", "addressAction_noWebBrowserInstalled", fallback: "There is no web browser installed in this device")
    /// Show Address QR Code
    internal static let showAccountQR = L10n.tr("Localizable", "addressAction_showAccountQR", fallback: "Show Address QR Code")
    /// Verify Address with Ledger
    internal static let verifyAddressLedger = L10n.tr("Localizable", "addressAction_verifyAddressLedger", fallback: "Verify Address with Ledger")
    /// View on Radix Dashboard
    internal static let viewOnDashboard = L10n.tr("Localizable", "addressAction_viewOnDashboard", fallback: "View on Radix Dashboard")
    internal enum QrCodeView {
      /// Could not create QR code
      internal static let failureLabel = L10n.tr("Localizable", "addressAction_qrCodeView_failureLabel", fallback: "Could not create QR code")
      /// QR code for an account
      internal static let qrCodeLabel = L10n.tr("Localizable", "addressAction_qrCodeView_qrCodeLabel", fallback: "QR code for an account")
    }
    internal enum VerifyAddressLedger {
      /// Verify address request failed
      internal static let error = L10n.tr("Localizable", "addressAction_verifyAddressLedger_error", fallback: "Verify address request failed")
      /// Address verified
      internal static let success = L10n.tr("Localizable", "addressAction_verifyAddressLedger_success", fallback: "Address verified")
    }
  }
  internal enum AddressDetails {
    /// Copy
    internal static let copy = L10n.tr("Localizable", "addressDetails_copy", fallback: "Copy")
    /// Enlarge
    internal static let enlarge = L10n.tr("Localizable", "addressDetails_enlarge", fallback: "Enlarge")
    /// Full address
    internal static let fullAddress = L10n.tr("Localizable", "addressDetails_fullAddress", fallback: "Full address")
    /// Address QR Code
    internal static let qrCode = L10n.tr("Localizable", "addressDetails_qrCode", fallback: "Address QR Code")
    /// Could not create QR code
    internal static let qrCodeFailure = L10n.tr("Localizable", "addressDetails_qrCodeFailure", fallback: "Could not create QR code")
    /// Share
    internal static let share = L10n.tr("Localizable", "addressDetails_share", fallback: "Share")
    /// Verify Address on Ledger Device
    internal static let verifyOnLedger = L10n.tr("Localizable", "addressDetails_verifyOnLedger", fallback: "Verify Address on Ledger Device")
    /// View on Radix Dashboard
    internal static let viewOnDashboard = L10n.tr("Localizable", "addressDetails_viewOnDashboard", fallback: "View on Radix Dashboard")
  }
  internal enum AndroidProfileBackup {
    /// Back up is turned off
    internal static let disabledText = L10n.tr("Localizable", "androidProfileBackup_disabledText", fallback: "Back up is turned off")
    /// Last Backed up: %@
    internal static func lastBackedUp(_ p1: Any) -> String {
      return L10n.tr("Localizable", "androidProfileBackup_lastBackedUp", String(describing: p1), fallback: "Last Backed up: %@")
    }
    /// Not backed up yet
    internal static let noLastBackUp = L10n.tr("Localizable", "androidProfileBackup_noLastBackUp", fallback: "Not backed up yet")
    /// Open System Backup Settings
    internal static let openSystemBackupSettings = L10n.tr("Localizable", "androidProfileBackup_openSystemBackupSettings", fallback: "Open System Backup Settings")
    internal enum BackupWalletData {
      /// Warning: If disabled you might lose access to your Accounts and Personas.
      internal static let message = L10n.tr("Localizable", "androidProfileBackup_backupWalletData_message", fallback: "Warning: If disabled you might lose access to your Accounts and Personas.")
      /// Backup Wallet Data to Cloud
      internal static let title = L10n.tr("Localizable", "androidProfileBackup_backupWalletData_title", fallback: "Backup Wallet Data to Cloud")
    }
    internal enum DeleteWallet {
      /// Delete Wallet
      internal static let confirmButton = L10n.tr("Localizable", "androidProfileBackup_deleteWallet_confirmButton", fallback: "Delete Wallet")
      /// You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any cloud backup.
      /// 
      /// **Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**
      internal static let subtitle = L10n.tr("Localizable", "androidProfileBackup_deleteWallet_subtitle", fallback: "You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any cloud backup.\n\n**Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**")
    }
  }
  internal enum AndroidRecoverProfileBackup {
    /// No wallet backups available
    internal static let noBackupsAvailable = L10n.tr("Localizable", "androidRecoverProfileBackup_noBackupsAvailable", fallback: "No wallet backups available")
    internal enum Choose {
      /// Choose a backup from Google Drive
      internal static let title = L10n.tr("Localizable", "androidRecoverProfileBackup_choose_title", fallback: "Choose a backup from Google Drive")
    }
  }
  internal enum AppSettings {
    /// Customize your Radix Wallet
    internal static let subtitle = L10n.tr("Localizable", "appSettings_subtitle", fallback: "Customize your Radix Wallet")
    /// App Settings
    internal static let title = L10n.tr("Localizable", "appSettings_title", fallback: "App Settings")
    internal enum CrashReporting {
      /// I'm aware Radix Wallet will send crash reports together with device state from the moment of crash.
      internal static let subtitle = L10n.tr("Localizable", "appSettings_crashReporting_subtitle", fallback: "I'm aware Radix Wallet will send crash reports together with device state from the moment of crash.")
      /// Crash Reporting
      internal static let title = L10n.tr("Localizable", "appSettings_crashReporting_title", fallback: "Crash Reporting")
    }
    internal enum DeveloperMode {
      /// Warning: Disables website validity checks
      internal static let subtitle = L10n.tr("Localizable", "appSettings_developerMode_subtitle", fallback: "Warning: Disables website validity checks")
      /// Developer Mode
      internal static let title = L10n.tr("Localizable", "appSettings_developerMode_title", fallback: "Developer Mode")
    }
    internal enum EntityHiding {
      /// %d Account currently hidden
      internal static func hiddenAccount(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenAccount", p1, fallback: "%d Account currently hidden")
      }
      /// %d Accounts currently hidden
      internal static func hiddenAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenAccounts", p1, fallback: "%d Accounts currently hidden")
      }
      /// %d Persona currently hidden
      internal static func hiddenPersona(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenPersona", p1, fallback: "%d Persona currently hidden")
      }
      /// %d Personas currently hidden
      internal static func hiddenPersonas(_ p1: Int) -> String {
        return L10n.tr("Localizable", "appSettings_entityHiding_hiddenPersonas", p1, fallback: "%d Personas currently hidden")
      }
      /// Manage hiding
      internal static let subtitle = L10n.tr("Localizable", "appSettings_entityHiding_subtitle", fallback: "Manage hiding")
      /// Accounts and Personas you have created can be hidden in your Radix Wallet, acting as if “deleted”.
      internal static let text = L10n.tr("Localizable", "appSettings_entityHiding_text", fallback: "Accounts and Personas you have created can be hidden in your Radix Wallet, acting as if “deleted”.")
      /// Account & Persona Hiding
      internal static let title = L10n.tr("Localizable", "appSettings_entityHiding_title", fallback: "Account & Persona Hiding")
      /// Unhide All
      internal static let unhideAllButton = L10n.tr("Localizable", "appSettings_entityHiding_unhideAllButton", fallback: "Unhide All")
      /// Are you sure you wish to unhide all Accounts and Personas? This cannot be undone.
      internal static let unhideAllConfirmation = L10n.tr("Localizable", "appSettings_entityHiding_unhideAllConfirmation", fallback: "Are you sure you wish to unhide all Accounts and Personas? This cannot be undone.")
      /// Unhide Accounts & Personas
      internal static let unhideAllSection = L10n.tr("Localizable", "appSettings_entityHiding_unhideAllSection", fallback: "Unhide Accounts & Personas")
    }
    internal enum Gateways {
      /// Network Gateways
      internal static let title = L10n.tr("Localizable", "appSettings_gateways_title", fallback: "Network Gateways")
    }
    internal enum LinkedConnectors {
      /// Linked Connectors
      internal static let title = L10n.tr("Localizable", "appSettings_linkedConnectors_title", fallback: "Linked Connectors")
    }
  }
  internal enum AssetDetails {
    /// Associated dApps
    internal static let associatedDapps = L10n.tr("Localizable", "assetDetails_associatedDapps", fallback: "Associated dApps")
    /// Behavior
    internal static let behavior = L10n.tr("Localizable", "assetDetails_behavior", fallback: "Behavior")
    /// Current Supply
    internal static let currentSupply = L10n.tr("Localizable", "assetDetails_currentSupply", fallback: "Current Supply")
    /// Divisibility
    internal static let divisibility = L10n.tr("Localizable", "assetDetails_divisibility", fallback: "Divisibility")
    /// Hide Asset
    internal static let hideAsset = L10n.tr("Localizable", "assetDetails_hideAsset", fallback: "Hide Asset")
    /// Hide Collection
    internal static let hideCollection = L10n.tr("Localizable", "assetDetails_hideCollection", fallback: "Hide Collection")
    /// For more info
    internal static let moreInfo = L10n.tr("Localizable", "assetDetails_moreInfo", fallback: "For more info")
    /// Name
    internal static let name = L10n.tr("Localizable", "assetDetails_name", fallback: "Name")
    /// Address
    internal static let resourceAddress = L10n.tr("Localizable", "assetDetails_resourceAddress", fallback: "Address")
    /// Unknown
    internal static let supplyUnkown = L10n.tr("Localizable", "assetDetails_supplyUnkown", fallback: "Unknown")
    /// Tags
    internal static let tags = L10n.tr("Localizable", "assetDetails_tags", fallback: "Tags")
    /// Validator
    internal static let validator = L10n.tr("Localizable", "assetDetails_validator", fallback: "Validator")
    internal enum NFTDetails {
      /// complex data
      internal static let complexData = L10n.tr("Localizable", "assetDetails_NFTDetails_complexData", fallback: "complex data")
      /// Description
      internal static let description = L10n.tr("Localizable", "assetDetails_NFTDetails_description", fallback: "Description")
      /// ID
      internal static let id = L10n.tr("Localizable", "assetDetails_NFTDetails_id", fallback: "ID")
      /// Name
      internal static let name = L10n.tr("Localizable", "assetDetails_NFTDetails_name", fallback: "Name")
      /// %d NFTs
      internal static func nftPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_NFTDetails_nftPlural", p1, fallback: "%d NFTs")
      }
      /// You have no NFTs
      internal static let noNfts = L10n.tr("Localizable", "assetDetails_NFTDetails_noNfts", fallback: "You have no NFTs")
      /// %d NFTs of total supply %d
      internal static func ownedOfTotal(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_NFTDetails_ownedOfTotal", p1, p2, fallback: "%d NFTs of total supply %d")
      }
      /// Name
      internal static let resourceName = L10n.tr("Localizable", "assetDetails_NFTDetails_resourceName", fallback: "Name")
    }
    internal enum BadgeDetails {
      /// You have no badges
      internal static let noBadges = L10n.tr("Localizable", "assetDetails_badgeDetails_noBadges", fallback: "You have no badges")
    }
    internal enum Behaviors {
      /// Anyone can freeze this asset in place.
      internal static let freezableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_freezableByAnyone", fallback: "Anyone can freeze this asset in place.")
      /// A third party can freeze this asset in place.
      internal static let freezableByThirdParty = L10n.tr("Localizable", "assetDetails_behaviors_freezableByThirdParty", fallback: "A third party can freeze this asset in place.")
      /// Naming and information about this asset can be changed.
      internal static let informationChangeable = L10n.tr("Localizable", "assetDetails_behaviors_informationChangeable", fallback: "Naming and information about this asset can be changed.")
      /// Anyone can change naming and information about this asset.
      internal static let informationChangeableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_informationChangeableByAnyone", fallback: "Anyone can change naming and information about this asset.")
      /// Movement of this asset can be restricted in the future.
      internal static let movementRestrictableInFuture = L10n.tr("Localizable", "assetDetails_behaviors_movementRestrictableInFuture", fallback: "Movement of this asset can be restricted in the future.")
      /// Anyone can restrict movement of this token in the future.
      internal static let movementRestrictableInFutureByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_movementRestrictableInFutureByAnyone", fallback: "Anyone can restrict movement of this token in the future.")
      /// Movement of this asset is restricted.
      internal static let movementRestricted = L10n.tr("Localizable", "assetDetails_behaviors_movementRestricted", fallback: "Movement of this asset is restricted.")
      /// Data that is set on these NFTs can be changed.
      internal static let nftDataChangeable = L10n.tr("Localizable", "assetDetails_behaviors_nftDataChangeable", fallback: "Data that is set on these NFTs can be changed.")
      /// Anyone can change data that is set on these NFTs.
      internal static let nftDataChangeableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_nftDataChangeableByAnyone", fallback: "Anyone can change data that is set on these NFTs.")
      /// Anyone can remove this asset from accounts and dApps.
      internal static let removableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_removableByAnyone", fallback: "Anyone can remove this asset from accounts and dApps.")
      /// A third party can remove this asset from accounts and dApps.
      internal static let removableByThirdParty = L10n.tr("Localizable", "assetDetails_behaviors_removableByThirdParty", fallback: "A third party can remove this asset from accounts and dApps.")
      /// This is a simple asset
      internal static let simpleAsset = L10n.tr("Localizable", "assetDetails_behaviors_simpleAsset", fallback: "This is a simple asset")
      /// The supply of this asset can be decreased.
      internal static let supplyDecreasable = L10n.tr("Localizable", "assetDetails_behaviors_supplyDecreasable", fallback: "The supply of this asset can be decreased.")
      /// Anyone can decrease the supply of this asset.
      internal static let supplyDecreasableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_supplyDecreasableByAnyone", fallback: "Anyone can decrease the supply of this asset.")
      /// The supply of this asset can be increased or decreased.
      internal static let supplyFlexible = L10n.tr("Localizable", "assetDetails_behaviors_supplyFlexible", fallback: "The supply of this asset can be increased or decreased.")
      /// Anyone can increase or decrease the supply of this asset.
      internal static let supplyFlexibleByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_supplyFlexibleByAnyone", fallback: "Anyone can increase or decrease the supply of this asset.")
      /// Only the Radix Network may increase or decrease the supply of XRD.
      internal static let supplyFlexibleXrd = L10n.tr("Localizable", "assetDetails_behaviors_supplyFlexibleXrd", fallback: "Only the Radix Network may increase or decrease the supply of XRD.")
      /// The supply of this asset can be increased.
      internal static let supplyIncreasable = L10n.tr("Localizable", "assetDetails_behaviors_supplyIncreasable", fallback: "The supply of this asset can be increased.")
      /// Anyone can increase the supply of this asset.
      internal static let supplyIncreasableByAnyone = L10n.tr("Localizable", "assetDetails_behaviors_supplyIncreasableByAnyone", fallback: "Anyone can increase the supply of this asset.")
    }
    internal enum PoolUnitDetails {
      /// You have no Pool units
      internal static let noPoolUnits = L10n.tr("Localizable", "assetDetails_poolUnitDetails_noPoolUnits", fallback: "You have no Pool units")
    }
    internal enum Staking {
      /// Current Redeemable Value
      internal static let currentRedeemableValue = L10n.tr("Localizable", "assetDetails_staking_currentRedeemableValue", fallback: "Current Redeemable Value")
      /// Ready to Claim
      internal static let readyToClaim = L10n.tr("Localizable", "assetDetails_staking_readyToClaim", fallback: "Ready to Claim")
      /// Ready to Claim in
      internal static let readyToClaimIn = L10n.tr("Localizable", "assetDetails_staking_readyToClaimIn", fallback: "Ready to Claim in")
      /// 1 day or less
      internal static let readyToClaimInDay = L10n.tr("Localizable", "assetDetails_staking_readyToClaimInDay", fallback: "1 day or less")
      /// %d days or less
      internal static func readyToClaimInDays(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_staking_readyToClaimInDays", p1, fallback: "%d days or less")
      }
      /// 1 hour or less
      internal static let readyToClaimInHour = L10n.tr("Localizable", "assetDetails_staking_readyToClaimInHour", fallback: "1 hour or less")
      /// %d hours or less
      internal static func readyToClaimInHours(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_staking_readyToClaimInHours", p1, fallback: "%d hours or less")
      }
      /// 1 minute or less
      internal static let readyToClaimInMinute = L10n.tr("Localizable", "assetDetails_staking_readyToClaimInMinute", fallback: "1 minute or less")
      /// %d minutes or less
      internal static func readyToClaimInMinutes(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetDetails_staking_readyToClaimInMinutes", p1, fallback: "%d minutes or less")
      }
    }
    internal enum StakingDetails {
      /// You have no Stakes
      internal static let noStakes = L10n.tr("Localizable", "assetDetails_stakingDetails_noStakes", fallback: "You have no Stakes")
    }
    internal enum Tags {
      /// Official Radix
      internal static let officialRadix = L10n.tr("Localizable", "assetDetails_tags_officialRadix", fallback: "Official Radix")
    }
    internal enum TokenDetails {
      /// You have no Tokens
      internal static let noTokens = L10n.tr("Localizable", "assetDetails_tokenDetails_noTokens", fallback: "You have no Tokens")
    }
  }
  internal enum AssetTransfer {
    /// Scan a QR code of a Radix Account address from another wallet or an exchange.
    internal static let qrScanInstructions = L10n.tr("Localizable", "assetTransfer_qrScanInstructions", fallback: "Scan a QR code of a Radix Account address from another wallet or an exchange.")
    /// Continue
    internal static let sendTransferButton = L10n.tr("Localizable", "assetTransfer_sendTransferButton", fallback: "Continue")
    /// Message
    internal static let transactionMessage = L10n.tr("Localizable", "assetTransfer_transactionMessage", fallback: "Message")
    /// Add a message
    internal static let transactionMessagePlaceholder = L10n.tr("Localizable", "assetTransfer_transactionMessagePlaceholder", fallback: "Add a message")
    internal enum AccountList {
      /// Add Transfer
      internal static let addAccountButton = L10n.tr("Localizable", "assetTransfer_accountList_addAccountButton", fallback: "Add Transfer")
      /// Account
      internal static let externalAccountName = L10n.tr("Localizable", "assetTransfer_accountList_externalAccountName", fallback: "Account")
      /// From
      internal static let fromLabel = L10n.tr("Localizable", "assetTransfer_accountList_fromLabel", fallback: "From")
      /// To
      internal static let toLabel = L10n.tr("Localizable", "assetTransfer_accountList_toLabel", fallback: "To")
    }
    internal enum AddAssets {
      /// Choose %d Assets
      internal static func buttonAssets(_ p1: Int) -> String {
        return L10n.tr("Localizable", "assetTransfer_addAssets_buttonAssets", p1, fallback: "Choose %d Assets")
      }
      /// Select Assets
      internal static let buttonAssetsNone = L10n.tr("Localizable", "assetTransfer_addAssets_buttonAssetsNone", fallback: "Select Assets")
      /// Choose 1 Asset
      internal static let buttonAssetsOne = L10n.tr("Localizable", "assetTransfer_addAssets_buttonAssetsOne", fallback: "Choose 1 Asset")
      /// Choose Asset(s) to Send
      internal static let navigationTitle = L10n.tr("Localizable", "assetTransfer_addAssets_navigationTitle", fallback: "Choose Asset(s) to Send")
    }
    internal enum ChooseReceivingAccount {
      /// Enter Radix Account address
      internal static let addressFieldPlaceholder = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_addressFieldPlaceholder", fallback: "Enter Radix Account address")
      /// Account already added
      internal static let alreadyAddedError = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_alreadyAddedError", fallback: "Account already added")
      /// Or: Choose one of your own Accounts
      internal static let chooseOwnAccount = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_chooseOwnAccount", fallback: "Or: Choose one of your own Accounts")
      /// Enter or scan an Account address
      internal static let enterManually = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_enterManually", fallback: "Enter or scan an Account address")
      /// Invalid address
      internal static let invalidAddressError = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_invalidAddressError", fallback: "Invalid address")
      /// Choose Receiving Account
      internal static let navigationTitle = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_navigationTitle", fallback: "Choose Receiving Account")
      /// Scan Account QR Code
      internal static let scanQRNavigationTitle = L10n.tr("Localizable", "assetTransfer_chooseReceivingAccount_scanQRNavigationTitle", fallback: "Scan Account QR Code")
    }
    internal enum DepositStatus {
      /// Recipient does not accept these tokens
      internal static let denied = L10n.tr("Localizable", "assetTransfer_depositStatus_denied", fallback: "Recipient does not accept these tokens")
      /// Additional signature required to deposit
      internal static let signatureRequired = L10n.tr("Localizable", "assetTransfer_depositStatus_signatureRequired", fallback: "Additional signature required to deposit")
    }
    internal enum Error {
      /// Total amount exceeds your current balance
      internal static let insufficientBalance = L10n.tr("Localizable", "assetTransfer_error_insufficientBalance", fallback: "Total amount exceeds your current balance")
      /// Resource already added
      internal static let resourceAlreadyAdded = L10n.tr("Localizable", "assetTransfer_error_resourceAlreadyAdded", fallback: "Resource already added")
      /// Address is not valid on current network
      internal static let wrongNetwork = L10n.tr("Localizable", "assetTransfer_error_wrongNetwork", fallback: "Address is not valid on current network")
    }
    internal enum ExtraSignature {
      /// You will be asked for an extra signature
      internal static let label = L10n.tr("Localizable", "assetTransfer_extraSignature_label", fallback: "You will be asked for an extra signature")
    }
    internal enum FungibleResource {
      /// Balance: %@
      internal static func balance(_ p1: Any) -> String {
        return L10n.tr("Localizable", "assetTransfer_fungibleResource_balance", String(describing: p1), fallback: "Balance: %@")
      }
      /// Total exceeds your current balance
      internal static let totalExceedsBalance = L10n.tr("Localizable", "assetTransfer_fungibleResource_totalExceedsBalance", fallback: "Total exceeds your current balance")
    }
    internal enum Header {
      /// Add Message
      internal static let addMessageButton = L10n.tr("Localizable", "assetTransfer_header_addMessageButton", fallback: "Add Message")
      /// Transfer
      internal static let transfer = L10n.tr("Localizable", "assetTransfer_header_transfer", fallback: "Transfer")
    }
    internal enum MaxAmountDialog {
      /// Sending the full amount of XRD in this account will require you to pay the transaction fee from a different account. Or, the wallet can reduce the amount transferred so the fee can be paid from this account. Choose the amount to transfer:
      internal static let body = L10n.tr("Localizable", "assetTransfer_maxAmountDialog_body", fallback: "Sending the full amount of XRD in this account will require you to pay the transaction fee from a different account. Or, the wallet can reduce the amount transferred so the fee can be paid from this account. Choose the amount to transfer:")
      /// %@ (save 1 XRD for fee)
      internal static func saveXrdForFeeButton(_ p1: Any) -> String {
        return L10n.tr("Localizable", "assetTransfer_maxAmountDialog_saveXrdForFeeButton", String(describing: p1), fallback: "%@ (save 1 XRD for fee)")
      }
      /// %@ (send all XRD)
      internal static func sendAllButton(_ p1: Any) -> String {
        return L10n.tr("Localizable", "assetTransfer_maxAmountDialog_sendAllButton", String(describing: p1), fallback: "%@ (send all XRD)")
      }
      /// Sending All XRD
      internal static let title = L10n.tr("Localizable", "assetTransfer_maxAmountDialog_title", fallback: "Sending All XRD")
    }
    internal enum ReceivingAccount {
      /// Add Assets
      internal static let addAssetsButton = L10n.tr("Localizable", "assetTransfer_receivingAccount_addAssetsButton", fallback: "Add Assets")
      /// Choose Account
      internal static let chooseAccountButton = L10n.tr("Localizable", "assetTransfer_receivingAccount_chooseAccountButton", fallback: "Choose Account")
    }
  }
  internal enum AuthorizedDapps {
    /// A deposit from this dApp is available. Go to your Accounts to view and claim.
    internal static let pendingDeposit = L10n.tr("Localizable", "authorizedDapps_pendingDeposit", fallback: "A deposit from this dApp is available. Go to your Accounts to view and claim.")
    /// These are the dApps that you have logged into using the Radix Wallet.
    internal static let subtitle = L10n.tr("Localizable", "authorizedDapps_subtitle", fallback: "These are the dApps that you have logged into using the Radix Wallet.")
    /// Approved dApps
    internal static let title = L10n.tr("Localizable", "authorizedDapps_title", fallback: "Approved dApps")
    internal enum DAppDetails {
      /// dApp Definition
      internal static let dAppDefinition = L10n.tr("Localizable", "authorizedDapps_dAppDetails_dAppDefinition", fallback: "dApp Definition")
      /// Available deposits from this dApp will not be shown
      internal static let depositsHidden = L10n.tr("Localizable", "authorizedDapps_dAppDetails_depositsHidden", fallback: "Available deposits from this dApp will not be shown")
      /// Show direct deposits to claim
      internal static let depositsTitle = L10n.tr("Localizable", "authorizedDapps_dAppDetails_depositsTitle", fallback: "Show direct deposits to claim")
      /// Available deposits from this dApp will be shown on the recipient Accounts
      internal static let depositsVisible = L10n.tr("Localizable", "authorizedDapps_dAppDetails_depositsVisible", fallback: "Available deposits from this dApp will be shown on the recipient Accounts")
      /// Forget this dApp
      internal static let forgetDapp = L10n.tr("Localizable", "authorizedDapps_dAppDetails_forgetDapp", fallback: "Forget this dApp")
      /// Missing description
      internal static let missingDescription = L10n.tr("Localizable", "authorizedDapps_dAppDetails_missingDescription", fallback: "Missing description")
      /// Associated NFTs
      internal static let nfts = L10n.tr("Localizable", "authorizedDapps_dAppDetails_nfts", fallback: "Associated NFTs")
      /// No Personas have been used to login to this dApp.
      internal static let noPersonasHeading = L10n.tr("Localizable", "authorizedDapps_dAppDetails_noPersonasHeading", fallback: "No Personas have been used to login to this dApp.")
      /// Here are the Personas that you have used to login to this dApp.
      internal static let personasHeading = L10n.tr("Localizable", "authorizedDapps_dAppDetails_personasHeading", fallback: "Here are the Personas that you have used to login to this dApp.")
      /// Associated Tokens
      internal static let tokens = L10n.tr("Localizable", "authorizedDapps_dAppDetails_tokens", fallback: "Associated Tokens")
      /// Unknown name
      internal static let unknownTokenName = L10n.tr("Localizable", "authorizedDapps_dAppDetails_unknownTokenName", fallback: "Unknown name")
      /// Website
      internal static let website = L10n.tr("Localizable", "authorizedDapps_dAppDetails_website", fallback: "Website")
    }
    internal enum ForgetDappAlert {
      /// Forget dApp?
      internal static let forget = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_forget", fallback: "Forget dApp?")
      /// Do you really want to forget this dApp and remove its permissions for all Personas?
      internal static let message = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_message", fallback: "Do you really want to forget this dApp and remove its permissions for all Personas?")
      /// Forget This dApp
      internal static let title = L10n.tr("Localizable", "authorizedDapps_forgetDappAlert_title", fallback: "Forget This dApp")
    }
    internal enum PersonaDetails {
      /// Here are the Account names and addresses that you are currently sharing with %@.
      internal static func accountSharingDescription(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_accountSharingDescription", String(describing: p1), fallback: "Here are the Account names and addresses that you are currently sharing with %@.")
      }
      /// Here are the dApps you have logged into with this Persona.
      internal static let authorizedDappsHeading = L10n.tr("Localizable", "authorizedDapps_personaDetails_authorizedDappsHeading", fallback: "Here are the dApps you have logged into with this Persona.")
      /// Edit
      internal static let edit = L10n.tr("Localizable", "authorizedDapps_personaDetails_edit", fallback: "Edit")
      /// Edit Account Sharing
      internal static let editAccountSharing = L10n.tr("Localizable", "authorizedDapps_personaDetails_editAccountSharing", fallback: "Edit Account Sharing")
      /// Edit Avatar
      internal static let editAvatarButtonTitle = L10n.tr("Localizable", "authorizedDapps_personaDetails_editAvatarButtonTitle", fallback: "Edit Avatar")
      /// Edit Persona
      internal static let editPersona = L10n.tr("Localizable", "authorizedDapps_personaDetails_editPersona", fallback: "Edit Persona")
      /// Email Address
      internal static let emailAddress = L10n.tr("Localizable", "authorizedDapps_personaDetails_emailAddress", fallback: "Email Address")
      /// First Name
      internal static let firstName = L10n.tr("Localizable", "authorizedDapps_personaDetails_firstName", fallback: "First Name")
      /// Full Name
      internal static let fullName = L10n.tr("Localizable", "authorizedDapps_personaDetails_fullName", fallback: "Full Name")
      /// Given Name(s)
      internal static let givenName = L10n.tr("Localizable", "authorizedDapps_personaDetails_givenName", fallback: "Given Name(s)")
      /// Are you sure you want to hide this persona?
      internal static let hidePersonaConfirmation = L10n.tr("Localizable", "authorizedDapps_personaDetails_hidePersonaConfirmation", fallback: "Are you sure you want to hide this persona?")
      /// Hide This Persona
      internal static let hideThisPersona = L10n.tr("Localizable", "authorizedDapps_personaDetails_hideThisPersona", fallback: "Hide This Persona")
      /// Last Name
      internal static let lastName = L10n.tr("Localizable", "authorizedDapps_personaDetails_lastName", fallback: "Last Name")
      /// Family Name
      internal static let nameFamily = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameFamily", fallback: "Family Name")
      /// Name Order
      internal static let nameVariant = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameVariant", fallback: "Name Order")
      /// Eastern style (family name first)
      internal static let nameVariantEastern = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameVariantEastern", fallback: "Eastern style (family name first)")
      /// Western style (given name(s) first)
      internal static let nameVariantWestern = L10n.tr("Localizable", "authorizedDapps_personaDetails_nameVariantWestern", fallback: "Western style (given name(s) first)")
      /// Nickname
      internal static let nickname = L10n.tr("Localizable", "authorizedDapps_personaDetails_nickname", fallback: "Nickname")
      /// You are not sharing any personal data with %@.
      internal static func notSharingAnything(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_notSharingAnything", String(describing: p1), fallback: "You are not sharing any personal data with %@.")
      }
      /// Persona Hidden
      internal static let personaHidden = L10n.tr("Localizable", "authorizedDapps_personaDetails_personaHidden", fallback: "Persona Hidden")
      /// Persona Label
      internal static let personaLabelHeading = L10n.tr("Localizable", "authorizedDapps_personaDetails_personaLabelHeading", fallback: "Persona Label")
      /// Here is the personal data that you are sharing with %@.
      internal static func personalDataSharingDescription(_ p1: Any) -> String {
        return L10n.tr("Localizable", "authorizedDapps_personaDetails_personalDataSharingDescription", String(describing: p1), fallback: "Here is the personal data that you are sharing with %@.")
      }
      /// Phone Number
      internal static let phoneNumber = L10n.tr("Localizable", "authorizedDapps_personaDetails_phoneNumber", fallback: "Phone Number")
      /// Disconnect Persona from this dApp
      internal static let removeAuthorization = L10n.tr("Localizable", "authorizedDapps_personaDetails_removeAuthorization", fallback: "Disconnect Persona from this dApp")
    }
    internal enum RemoveAuthorizationAlert {
      /// Continue
      internal static let confirm = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_confirm", fallback: "Continue")
      /// This dApp will no longer have authorization to see data associated with this Persona, unless you choose to login with it again in the future.
      internal static let message = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_message", fallback: "This dApp will no longer have authorization to see data associated with this Persona, unless you choose to login with it again in the future.")
      /// Remove Authorization
      internal static let title = L10n.tr("Localizable", "authorizedDapps_removeAuthorizationAlert_title", fallback: "Remove Authorization")
    }
  }
  internal enum Biometrics {
    internal enum AppLockAvailableAlert {
      /// Your phone was updated and now supports Apple's built-in App Lock feature.
      internal static let message = L10n.tr("Localizable", "biometrics_appLockAvailableAlert_message", fallback: "Your phone was updated and now supports Apple's built-in App Lock feature.")
      /// Advanced Lock Disabled
      internal static let title = L10n.tr("Localizable", "biometrics_appLockAvailableAlert_title", fallback: "Advanced Lock Disabled")
    }
    internal enum DeviceNotSecureAlert {
      /// Your device currently has no device access security set, such as biometrics or a PIN. The Radix Wallet requires this to be set for your security.
      internal static let message = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_message", fallback: "Your device currently has no device access security set, such as biometrics or a PIN. The Radix Wallet requires this to be set for your security.")
      /// Open Settings
      internal static let openSettings = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_openSettings", fallback: "Open Settings")
      /// Quit
      internal static let quit = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_quit", fallback: "Quit")
      /// Unsecured Device
      internal static let title = L10n.tr("Localizable", "biometrics_deviceNotSecureAlert_title", fallback: "Unsecured Device")
    }
    internal enum Prompt {
      /// Checking accounts.
      internal static let checkingAccounts = L10n.tr("Localizable", "biometrics_prompt_checkingAccounts", fallback: "Checking accounts.")
      /// Create Auth signing key.
      internal static let createSignAuthKey = L10n.tr("Localizable", "biometrics_prompt_createSignAuthKey", fallback: "Create Auth signing key.")
      /// Authenticate to create new %@ with this phone.
      internal static func creationOfEntity(_ p1: Any) -> String {
        return L10n.tr("Localizable", "biometrics_prompt_creationOfEntity", String(describing: p1), fallback: "Authenticate to create new %@ with this phone.")
      }
      /// Display seed phrase.
      internal static let displaySeedPhrase = L10n.tr("Localizable", "biometrics_prompt_displaySeedPhrase", fallback: "Display seed phrase.")
      /// Check if seed phrase already exists.
      internal static let importOlympiaAccounts = L10n.tr("Localizable", "biometrics_prompt_importOlympiaAccounts", fallback: "Check if seed phrase already exists.")
      /// Authenticate to sign proof with this phone.
      internal static let signAuthChallenge = L10n.tr("Localizable", "biometrics_prompt_signAuthChallenge", fallback: "Authenticate to sign proof with this phone.")
      /// Authenticate to sign transaction with this phone.
      internal static let signTransaction = L10n.tr("Localizable", "biometrics_prompt_signTransaction", fallback: "Authenticate to sign transaction with this phone.")
      /// Authenticate to continue
      internal static let title = L10n.tr("Localizable", "biometrics_prompt_title", fallback: "Authenticate to continue")
      /// Update account metadata.
      internal static let updateAccountMetadata = L10n.tr("Localizable", "biometrics_prompt_updateAccountMetadata", fallback: "Update account metadata.")
    }
  }
  internal enum Common {
    /// Account
    internal static let account = L10n.tr("Localizable", "common_account", fallback: "Account")
    /// Bad HTTP response status code %d
    internal static func badHttpResponseStatusCode(_ p1: Int) -> String {
      return L10n.tr("Localizable", "common_badHttpResponseStatusCode", p1, fallback: "Bad HTTP response status code %d")
    }
    /// Cancel
    internal static let cancel = L10n.tr("Localizable", "common_cancel", fallback: "Cancel")
    /// Choose
    internal static let choose = L10n.tr("Localizable", "common_choose", fallback: "Choose")
    /// Component
    internal static let component = L10n.tr("Localizable", "common_component", fallback: "Component")
    /// Confirm
    internal static let confirm = L10n.tr("Localizable", "common_confirm", fallback: "Confirm")
    /// Continue
    internal static let `continue` = L10n.tr("Localizable", "common_continue", fallback: "Continue")
    /// Copy
    internal static let copy = L10n.tr("Localizable", "common_copy", fallback: "Copy")
    /// Connected to a test network, not Radix main network.
    internal static let developerDisclaimerText = L10n.tr("Localizable", "common_developerDisclaimerText", fallback: "Connected to a test network, not Radix main network.")
    /// Dismiss
    internal static let dismiss = L10n.tr("Localizable", "common_dismiss", fallback: "Dismiss")
    /// Done
    internal static let done = L10n.tr("Localizable", "common_done", fallback: "Done")
    /// An Error Occurred
    internal static let errorAlertTitle = L10n.tr("Localizable", "common_errorAlertTitle", fallback: "An Error Occurred")
    /// History
    internal static let history = L10n.tr("Localizable", "common_history", fallback: "History")
    /// Invalid
    internal static let invalid = L10n.tr("Localizable", "common_invalid", fallback: "Invalid")
    /// Max
    internal static let max = L10n.tr("Localizable", "common_max", fallback: "Max")
    /// None
    internal static let `none` = L10n.tr("Localizable", "common_none", fallback: "None")
    /// OK
    internal static let ok = L10n.tr("Localizable", "common_ok", fallback: "OK")
    /// Optional
    internal static let `optional` = L10n.tr("Localizable", "common_optional", fallback: "Optional")
    /// Persona
    internal static let persona = L10n.tr("Localizable", "common_persona", fallback: "Persona")
    /// Pool
    internal static let pool = L10n.tr("Localizable", "common_pool", fallback: "Pool")
    /// Public
    internal static let `public` = L10n.tr("Localizable", "common_public", fallback: "Public")
    /// Gateway access blocked due to exceeding rate limit. Please wait a few minutes to retry.
    internal static let rateLimitReached = L10n.tr("Localizable", "common_rateLimitReached", fallback: "Gateway access blocked due to exceeding rate limit. Please wait a few minutes to retry.")
    /// Remove
    internal static let remove = L10n.tr("Localizable", "common_remove", fallback: "Remove")
    /// Retry
    internal static let retry = L10n.tr("Localizable", "common_retry", fallback: "Retry")
    /// Save
    internal static let save = L10n.tr("Localizable", "common_save", fallback: "Save")
    /// Show Less
    internal static let showLess = L10n.tr("Localizable", "common_showLess", fallback: "Show Less")
    /// Show More
    internal static let showMore = L10n.tr("Localizable", "common_showMore", fallback: "Show More")
    /// Something Went Wrong
    internal static let somethingWentWrong = L10n.tr("Localizable", "common_somethingWentWrong", fallback: "Something Went Wrong")
    /// Settings
    internal static let systemSettings = L10n.tr("Localizable", "common_systemSettings", fallback: "Settings")
    /// Unauthorized
    internal static let unauthorized = L10n.tr("Localizable", "common_unauthorized", fallback: "Unauthorized")
    internal enum NoMnemonicAlert {
      /// The required seed phrase is missing. Please return to the account and begin the recovery process.
      internal static let text = L10n.tr("Localizable", "common_noMnemonicAlert_text", fallback: "The required seed phrase is missing. Please return to the account and begin the recovery process.")
      /// Could Not Complete
      internal static let title = L10n.tr("Localizable", "common_noMnemonicAlert_title", fallback: "Could Not Complete")
    }
  }
  internal enum ConfigurationBackup {
    /// You need an up-to-date Configuration Backup to recover your Accounts and Personas if you lose access to them.
    /// 
    /// Your Backup does not contain your keys or seed phrase.
    internal static let heading = L10n.tr("Localizable", "configurationBackup_heading", fallback: "You need an up-to-date Configuration Backup to recover your Accounts and Personas if you lose access to them.\n\nYour Backup does not contain your keys or seed phrase.")
    /// Configuration Backup
    internal static let title = L10n.tr("Localizable", "configurationBackup_title", fallback: "Configuration Backup")
    internal enum Automated {
      /// Your list of Accounts and the factors required to recover them
      internal static let accountsItemSubtitle = L10n.tr("Localizable", "configurationBackup_automated_accountsItemSubtitle", fallback: "Your list of Accounts and the factors required to recover them")
      /// Accounts
      internal static let accountsItemTitle = L10n.tr("Localizable", "configurationBackup_automated_accountsItemTitle", fallback: "Accounts")
      /// Login to Google Drive for Backups
      internal static let cloudUpdatedLoginButtonAndroid = L10n.tr("Localizable", "configurationBackup_automated_cloudUpdatedLoginButtonAndroid", fallback: "Login to Google Drive for Backups")
      /// Skip for Now
      internal static let cloudUpdatedSkipButtonAndroid = L10n.tr("Localizable", "configurationBackup_automated_cloudUpdatedSkipButtonAndroid", fallback: "Skip for Now")
      /// The Radix Wallet has an all new and improved backup system.
      /// 
      /// To continue, log in with the Google Drive account you want to use for backups.
      internal static let cloudUpdatedSubtitleAndroid = L10n.tr("Localizable", "configurationBackup_automated_cloudUpdatedSubtitleAndroid", fallback: "The Radix Wallet has an all new and improved backup system.\n\nTo continue, log in with the Google Drive account you want to use for backups.")
      /// Backups on Google Drive Have Updated
      internal static let cloudUpdatedTitleAndroid = L10n.tr("Localizable", "configurationBackup_automated_cloudUpdatedTitleAndroid", fallback: "Backups on Google Drive Have Updated")
      /// Delete
      internal static let deleteOutdatedBackupIOS = L10n.tr("Localizable", "configurationBackup_automated_deleteOutdatedBackupIOS", fallback: "Delete")
      /// Disconnect
      internal static let disconnectAndroid = L10n.tr("Localizable", "configurationBackup_automated_disconnectAndroid", fallback: "Disconnect")
      /// Last backup: %@
      internal static func lastBackup(_ p1: Any) -> String {
        return L10n.tr("Localizable", "configurationBackup_automated_lastBackup", String(describing: p1), fallback: "Last backup: %@")
      }
      /// Logged in as:
      internal static let loggedInAsAndroid = L10n.tr("Localizable", "configurationBackup_automated_loggedInAsAndroid", fallback: "Logged in as:")
      /// Log in to Google Drive
      internal static let logInAndroid = L10n.tr("Localizable", "configurationBackup_automated_logInAndroid", fallback: "Log in to Google Drive")
      /// Out-of-date backup still present on iCloud
      internal static let outdatedBackupIOS = L10n.tr("Localizable", "configurationBackup_automated_outdatedBackupIOS", fallback: "Out-of-date backup still present on iCloud")
      /// Your list of Personas and the factors required to recover them. Also your Persona data.
      internal static let personasItemSubtitle = L10n.tr("Localizable", "configurationBackup_automated_personasItemSubtitle", fallback: "Your list of Personas and the factors required to recover them. Also your Persona data.")
      /// Personas
      internal static let personasItemTitle = L10n.tr("Localizable", "configurationBackup_automated_personasItemTitle", fallback: "Personas")
      /// The list of security factors you need to recover your Accounts and Personas.
      internal static let securityFactorsItemSubtitle = L10n.tr("Localizable", "configurationBackup_automated_securityFactorsItemSubtitle", fallback: "The list of security factors you need to recover your Accounts and Personas.")
      /// Security Factors
      internal static let securityFactorsItemTitle = L10n.tr("Localizable", "configurationBackup_automated_securityFactorsItemTitle", fallback: "Security Factors")
      /// Configuration Backup status
      internal static let text = L10n.tr("Localizable", "configurationBackup_automated_text", fallback: "Configuration Backup status")
      /// Automated Google Drive Backups
      internal static let toggleAndroid = L10n.tr("Localizable", "configurationBackup_automated_toggleAndroid", fallback: "Automated Google Drive Backups")
      /// Automated iCloud Backups
      internal static let toggleIOS = L10n.tr("Localizable", "configurationBackup_automated_toggleIOS", fallback: "Automated iCloud Backups")
      /// Your general settings, such as trusted dApps, linked Connectors and wallet display settings.
      internal static let walletSettingsItemSubtitle = L10n.tr("Localizable", "configurationBackup_automated_walletSettingsItemSubtitle", fallback: "Your general settings, such as trusted dApps, linked Connectors and wallet display settings.")
      /// Wallet settings
      internal static let walletSettingsItemTitle = L10n.tr("Localizable", "configurationBackup_automated_walletSettingsItemTitle", fallback: "Wallet settings")
      /// Clear Wallet on This Phone
      internal static let walletTransferredClearButton = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredClearButton", fallback: "Clear Wallet on This Phone")
      /// If this was done in error, you can reclaim control to this phone. You won’t be able to access it from your old phone after the transfer.
      internal static let walletTransferredExplanation1 = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredExplanation1", fallback: "If this was done in error, you can reclaim control to this phone. You won’t be able to access it from your old phone after the transfer.")
      /// Or, you can clear the wallet configuration from this phone and start fresh.
      internal static let walletTransferredExplanation2 = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredExplanation2", fallback: "Or, you can clear the wallet configuration from this phone and start fresh.")
      /// The current wallet configuration is now controlled by another phone.
      internal static let walletTransferredSubtitle = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredSubtitle", fallback: "The current wallet configuration is now controlled by another phone.")
      /// Wallet Control Has Been Transferred
      internal static let walletTransferredTitle = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredTitle", fallback: "Wallet Control Has Been Transferred")
      /// Transfer Control Back to This Phone
      internal static let walletTransferredTransferBackButton = L10n.tr("Localizable", "configurationBackup_automated_walletTransferredTransferBackButton", fallback: "Transfer Control Back to This Phone")
      /// Without an updated Configuration Backup, you cannot recover your Accounts and Personas.
      internal static let warning = L10n.tr("Localizable", "configurationBackup_automated_warning", fallback: "Without an updated Configuration Backup, you cannot recover your Accounts and Personas.")
    }
    internal enum Manual {
      /// Export Backup File
      internal static let exportButton = L10n.tr("Localizable", "configurationBackup_manual_exportButton", fallback: "Export Backup File")
      /// Manual backup
      internal static let heading = L10n.tr("Localizable", "configurationBackup_manual_heading", fallback: "Manual backup")
      /// Last backup: %@
      internal static func lastBackup(_ p1: Any) -> String {
        return L10n.tr("Localizable", "configurationBackup_manual_lastBackup", String(describing: p1), fallback: "Last backup: %@")
      }
      /// You can export your own Configuration Backup file and save it locally
      internal static let text = L10n.tr("Localizable", "configurationBackup_manual_text", fallback: "You can export your own Configuration Backup file and save it locally")
      /// You’ll need to export a new Backup file each time you make a change in your wallet.
      internal static let warning = L10n.tr("Localizable", "configurationBackup_manual_warning", fallback: "You’ll need to export a new Backup file each time you make a change in your wallet.")
    }
  }
  internal enum ConfirmMnemonicBackedUp {
    /// Confirm you have written down the seed phrase by entering the missing words below.
    internal static let subtitle = L10n.tr("Localizable", "confirmMnemonicBackedUp_subtitle", fallback: "Confirm you have written down the seed phrase by entering the missing words below.")
    /// Confirm Your Seed Phrase
    internal static let title = L10n.tr("Localizable", "confirmMnemonicBackedUp_title", fallback: "Confirm Your Seed Phrase")
  }
  internal enum Confirmation {
    internal enum HideAccount {
      /// Hide Account
      internal static let button = L10n.tr("Localizable", "confirmation_hideAccount_button", fallback: "Hide Account")
      /// Hide this Account in your wallet? You can always unhide it from the main application settings.
      internal static let message = L10n.tr("Localizable", "confirmation_hideAccount_message", fallback: "Hide this Account in your wallet? You can always unhide it from the main application settings.")
      /// Hide This Account
      internal static let title = L10n.tr("Localizable", "confirmation_hideAccount_title", fallback: "Hide This Account")
    }
    internal enum HideAsset {
      /// Hide Asset
      internal static let button = L10n.tr("Localizable", "confirmation_hideAsset_button", fallback: "Hide Asset")
      /// Hide this asset in your Radix Wallet? You can always unhide it in your account settings.
      internal static let message = L10n.tr("Localizable", "confirmation_hideAsset_message", fallback: "Hide this asset in your Radix Wallet? You can always unhide it in your account settings.")
      /// Hide Asset
      internal static let title = L10n.tr("Localizable", "confirmation_hideAsset_title", fallback: "Hide Asset")
    }
    internal enum HideCollection {
      /// Hide
      internal static let button = L10n.tr("Localizable", "confirmation_hideCollection_button", fallback: "Hide")
      /// Hide **%@** NFT Collection in your Radix Wallet? You can always unhide it in your account settings.
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "confirmation_hideCollection_message", String(describing: p1), fallback: "Hide **%@** NFT Collection in your Radix Wallet? You can always unhide it in your account settings.")
      }
      /// Hide Collection
      internal static let title = L10n.tr("Localizable", "confirmation_hideCollection_title", fallback: "Hide Collection")
    }
  }
  internal enum CreateAccount {
    /// Create First Account
    internal static let titleFirst = L10n.tr("Localizable", "createAccount_titleFirst", fallback: "Create First Account")
    /// Create New Account
    internal static let titleNotFirst = L10n.tr("Localizable", "createAccount_titleNotFirst", fallback: "Create New Account")
    internal enum Completion {
      /// Your Account lives on the Radix Network and you can access it any time in your Radix Wallet.
      internal static let explanation = L10n.tr("Localizable", "createAccount_completion_explanation", fallback: "Your Account lives on the Radix Network and you can access it any time in your Radix Wallet.")
      /// You’ve created your first Account!
      internal static let subtitleFirst = L10n.tr("Localizable", "createAccount_completion_subtitleFirst", fallback: "You’ve created your first Account!")
      /// Your Account has been created.
      internal static let subtitleNotFirst = L10n.tr("Localizable", "createAccount_completion_subtitleNotFirst", fallback: "Your Account has been created.")
    }
    internal enum Introduction {
      /// Create an Account
      internal static let title = L10n.tr("Localizable", "createAccount_introduction_title", fallback: "Create an Account")
    }
    internal enum NameNewAccount {
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "createAccount_nameNewAccount_continue", fallback: "Continue")
      /// This can be changed any time.
      internal static let explanation = L10n.tr("Localizable", "createAccount_nameNewAccount_explanation", fallback: "This can be changed any time.")
      /// e.g. My Main Account
      internal static let placeholder = L10n.tr("Localizable", "createAccount_nameNewAccount_placeholder", fallback: "e.g. My Main Account")
      /// What would you like to call your Account?
      internal static let subtitle = L10n.tr("Localizable", "createAccount_nameNewAccount_subtitle", fallback: "What would you like to call your Account?")
    }
  }
  internal enum CreateEntity {
    internal enum Completion {
      /// Choose Accounts
      internal static let destinationChooseAccounts = L10n.tr("Localizable", "createEntity_completion_destinationChooseAccounts", fallback: "Choose Accounts")
      /// Persona Selection
      internal static let destinationChoosePersonas = L10n.tr("Localizable", "createEntity_completion_destinationChoosePersonas", fallback: "Persona Selection")
      /// Gateways
      internal static let destinationGateways = L10n.tr("Localizable", "createEntity_completion_destinationGateways", fallback: "Gateways")
      /// Account List
      internal static let destinationHome = L10n.tr("Localizable", "createEntity_completion_destinationHome", fallback: "Account List")
      /// Persona List
      internal static let destinationPersonaList = L10n.tr("Localizable", "createEntity_completion_destinationPersonaList", fallback: "Persona List")
      /// Continue to %@
      internal static func goToDestination(_ p1: Any) -> String {
        return L10n.tr("Localizable", "createEntity_completion_goToDestination", String(describing: p1), fallback: "Continue to %@")
      }
      /// Congratulations
      internal static let title = L10n.tr("Localizable", "createEntity_completion_title", fallback: "Congratulations")
    }
    internal enum Ledger {
      /// Create Ledger Account
      internal static let createAccount = L10n.tr("Localizable", "createEntity_ledger_createAccount", fallback: "Create Ledger Account")
      /// Create Ledger Persona
      internal static let createPersona = L10n.tr("Localizable", "createEntity_ledger_createPersona", fallback: "Create Ledger Persona")
    }
    internal enum NameNewEntity {
      /// Your Account lives on the Radix Network and you can access it any time in your Wallet.
      internal static let explanation = L10n.tr("Localizable", "createEntity_nameNewEntity_explanation", fallback: "Your Account lives on the Radix Network and you can access it any time in your Wallet.")
      /// You will be asked to sign transactions with the Ledger device you select.
      internal static let ledgerSubtitle = L10n.tr("Localizable", "createEntity_nameNewEntity_ledgerSubtitle", fallback: "You will be asked to sign transactions with the Ledger device you select.")
      /// Create with Ledger Hardware Wallet
      internal static let ledgerTitle = L10n.tr("Localizable", "createEntity_nameNewEntity_ledgerTitle", fallback: "Create with Ledger Hardware Wallet")
    }
  }
  internal enum CreatePersona {
    /// Empty display name
    internal static let emptyDisplayName = L10n.tr("Localizable", "createPersona_emptyDisplayName", fallback: "Empty display name")
    /// Required field
    internal static let requiredField = L10n.tr("Localizable", "createPersona_requiredField", fallback: "Required field")
    /// Save and Continue
    internal static let saveAndContinueButtonTitle = L10n.tr("Localizable", "createPersona_saveAndContinueButtonTitle", fallback: "Save and Continue")
    internal enum Completion {
      /// Personal data that you add to your Persona will only be shared with dApps with your permission.
      internal static let explanation = L10n.tr("Localizable", "createPersona_completion_explanation", fallback: "Personal data that you add to your Persona will only be shared with dApps with your permission.")
      /// You’ve created your first Persona!
      internal static let subtitleFirst = L10n.tr("Localizable", "createPersona_completion_subtitleFirst", fallback: "You’ve created your first Persona!")
      /// Your Persona has been created.
      internal static let subtitleNotFirst = L10n.tr("Localizable", "createPersona_completion_subtitleNotFirst", fallback: "Your Persona has been created.")
    }
    internal enum Explanation {
      /// Some dApps may request personal information, like name or email address, that can be added to your Persona. Add some data now if you like.
      internal static let someDappsMayRequest = L10n.tr("Localizable", "createPersona_explanation_someDappsMayRequest", fallback: "Some dApps may request personal information, like name or email address, that can be added to your Persona. Add some data now if you like.")
      /// This will be shared with dApps you login to
      internal static let thisWillBeShared = L10n.tr("Localizable", "createPersona_explanation_thisWillBeShared", fallback: "This will be shared with dApps you login to")
    }
    internal enum Introduction {
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "createPersona_introduction_continue", fallback: "Continue")
      /// A Persona is an identity that you own and control. You can have as many as you like.
      internal static let subtitle1 = L10n.tr("Localizable", "createPersona_introduction_subtitle1", fallback: "A Persona is an identity that you own and control. You can have as many as you like.")
      /// Personas are used to login to dApps on Radix. dApps may request access to personal information associated with your Persona, like your name or email address.
      internal static let subtitle2 = L10n.tr("Localizable", "createPersona_introduction_subtitle2", fallback: "Personas are used to login to dApps on Radix. dApps may request access to personal information associated with your Persona, like your name or email address.")
      /// Create a Persona
      internal static let title = L10n.tr("Localizable", "createPersona_introduction_title", fallback: "Create a Persona")
    }
    internal enum NameNewPersona {
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "createPersona_nameNewPersona_continue", fallback: "Continue")
      /// e.g. My Main Persona
      internal static let placeholder = L10n.tr("Localizable", "createPersona_nameNewPersona_placeholder", fallback: "e.g. My Main Persona")
      /// What would you like to call your Persona?
      internal static let subtitle = L10n.tr("Localizable", "createPersona_nameNewPersona_subtitle", fallback: "What would you like to call your Persona?")
    }
  }
  internal enum CustomizeNetworkFees {
    /// Change
    internal static let changeButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_changeButtonTitle", fallback: "Change")
    /// Effective Tip
    internal static let effectiveTip = L10n.tr("Localizable", "customizeNetworkFees_effectiveTip", fallback: "Effective Tip")
    /// Estimated Transaction Fees
    internal static let feeBreakdownTitle = L10n.tr("Localizable", "customizeNetworkFees_feeBreakdownTitle", fallback: "Estimated Transaction Fees")
    /// Network Execution
    internal static let networkExecution = L10n.tr("Localizable", "customizeNetworkFees_networkExecution", fallback: "Network Execution")
    /// Network Fee
    internal static let networkFee = L10n.tr("Localizable", "customizeNetworkFees_networkFee", fallback: "Network Fee")
    /// Network Finalization
    internal static let networkFinalization = L10n.tr("Localizable", "customizeNetworkFees_networkFinalization", fallback: "Network Finalization")
    /// Network Storage
    internal static let networkStorage = L10n.tr("Localizable", "customizeNetworkFees_networkStorage", fallback: "Network Storage")
    /// No account selected
    internal static let noAccountSelected = L10n.tr("Localizable", "customizeNetworkFees_noAccountSelected", fallback: "No account selected")
    /// None due
    internal static let noneDue = L10n.tr("Localizable", "customizeNetworkFees_noneDue", fallback: "None due")
    /// None required
    internal static let noneRequired = L10n.tr("Localizable", "customizeNetworkFees_noneRequired", fallback: "None required")
    /// Padding
    internal static let padding = L10n.tr("Localizable", "customizeNetworkFees_padding", fallback: "Padding")
    /// Adjust Fee Padding Amount (XRD)
    internal static let paddingFieldLabel = L10n.tr("Localizable", "customizeNetworkFees_paddingFieldLabel", fallback: "Adjust Fee Padding Amount (XRD)")
    /// Paid by dApps
    internal static let paidByDApps = L10n.tr("Localizable", "customizeNetworkFees_paidByDApps", fallback: "Paid by dApps")
    /// Pay fee from
    internal static let payFeeFrom = L10n.tr("Localizable", "customizeNetworkFees_payFeeFrom", fallback: "Pay fee from")
    /// Royalties
    internal static let royalties = L10n.tr("Localizable", "customizeNetworkFees_royalties", fallback: "Royalties")
    /// Royalty fee
    internal static let royaltyFee = L10n.tr("Localizable", "customizeNetworkFees_royaltyFee", fallback: "Royalty fee")
    /// (%% of Execution + Finalization Fees)
    internal static let tipFieldInfo = L10n.tr("Localizable", "customizeNetworkFees_tipFieldInfo", fallback: "(%% of Execution + Finalization Fees)")
    /// Adjust Tip to Lock
    internal static let tipFieldLabel = L10n.tr("Localizable", "customizeNetworkFees_tipFieldLabel", fallback: "Adjust Tip to Lock")
    /// Transaction Fee
    internal static let totalFee = L10n.tr("Localizable", "customizeNetworkFees_totalFee", fallback: "Transaction Fee")
    /// View Advanced Mode
    internal static let viewAdvancedModeButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_viewAdvancedModeButtonTitle", fallback: "View Advanced Mode")
    /// View Normal Mode
    internal static let viewNormalModeButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_viewNormalModeButtonTitle", fallback: "View Normal Mode")
    internal enum AdvancedMode {
      /// Fully customize fee payment for this transaction. Not recomended unless you are a developer or advanced user.
      internal static let subtitle = L10n.tr("Localizable", "customizeNetworkFees_advancedMode_subtitle", fallback: "Fully customize fee payment for this transaction. Not recomended unless you are a developer or advanced user.")
      /// Advanced Customize Fees
      internal static let title = L10n.tr("Localizable", "customizeNetworkFees_advancedMode_title", fallback: "Advanced Customize Fees")
    }
    internal enum NormalMode {
      /// Choose what account to pay the transaction fee from, or add a "tip" to speed up your transaction if necessary.
      internal static let subtitle = L10n.tr("Localizable", "customizeNetworkFees_normalMode_subtitle", fallback: "Choose what account to pay the transaction fee from, or add a \"tip\" to speed up your transaction if necessary.")
      /// Customize Fees
      internal static let title = L10n.tr("Localizable", "customizeNetworkFees_normalMode_title", fallback: "Customize Fees")
    }
    internal enum SelectFeePayer {
      /// Select Fee Payer
      internal static let navigationTitle = L10n.tr("Localizable", "customizeNetworkFees_selectFeePayer_navigationTitle", fallback: "Select Fee Payer")
      /// Select Account
      internal static let selectAccountButtonTitle = L10n.tr("Localizable", "customizeNetworkFees_selectFeePayer_selectAccountButtonTitle", fallback: "Select Account")
      /// Select an account to pay %@ XRD transaction fee
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "customizeNetworkFees_selectFeePayer_subtitle", String(describing: p1), fallback: "Select an account to pay %@ XRD transaction fee")
      }
    }
    internal enum TotalFee {
      /// (maximum to lock)
      internal static let info = L10n.tr("Localizable", "customizeNetworkFees_totalFee_info", fallback: "(maximum to lock)")
    }
    internal enum Warning {
      /// Not enough XRD for transaction fee
      internal static let insufficientBalance = L10n.tr("Localizable", "customizeNetworkFees_warning_insufficientBalance", fallback: "Not enough XRD for transaction fee")
      /// Please select a fee payer for the transaction fee
      internal static let selectFeePayer = L10n.tr("Localizable", "customizeNetworkFees_warning_selectFeePayer", fallback: "Please select a fee payer for the transaction fee")
    }
  }
  internal enum DAppRequest {
    /// Loading…
    internal static let metadataLoadingPrompt = L10n.tr("Localizable", "dAppRequest_metadataLoadingPrompt", fallback: "Loading…")
    internal enum AccountPermission {
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "dAppRequest_accountPermission_continue", fallback: "Continue")
      /// %d or more accounts
      internal static func numberOfAccountsAtLeast(_ p1: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsAtLeast", p1, fallback: "%d or more accounts")
      }
      /// Any number of accounts
      internal static let numberOfAccountsAtLeastZero = L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsAtLeastZero", fallback: "Any number of accounts")
      /// %d accounts
      internal static func numberOfAccountsExactly(_ p1: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsExactly", p1, fallback: "%d accounts")
      }
      /// 1 account
      internal static let numberOfAccountsExactlyOne = L10n.tr("Localizable", "dAppRequest_accountPermission_numberOfAccountsExactlyOne", fallback: "1 account")
      /// **%@** is requesting permission to *always* be able to view Account information when you login with this Persona.
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountPermission_subtitle", String(describing: p1), fallback: "**%@** is requesting permission to *always* be able to view Account information when you login with this Persona.")
      }
      /// Account Permission
      internal static let title = L10n.tr("Localizable", "dAppRequest_accountPermission_title", fallback: "Account Permission")
      /// You can update this permission in wallet settings for this dApp at any time.
      internal static let updateInSettingsExplanation = L10n.tr("Localizable", "dAppRequest_accountPermission_updateInSettingsExplanation", fallback: "You can update this permission in wallet settings for this dApp at any time.")
    }
    internal enum AccountsProofOfOwnership {
      /// **%@** is requesting verification that you own the following Account(s).
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_accountsProofOfOwnership_subtitle", String(describing: p1), fallback: "**%@** is requesting verification that you own the following Account(s).")
      }
      /// Verify Account Ownership
      internal static let title = L10n.tr("Localizable", "dAppRequest_accountsProofOfOwnership_title", fallback: "Verify Account Ownership")
    }
    internal enum ChooseAccounts {
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "dAppRequest_chooseAccounts_continue", fallback: "Continue")
      /// Create a New Account
      internal static let createNewAccount = L10n.tr("Localizable", "dAppRequest_chooseAccounts_createNewAccount", fallback: "Create a New Account")
      /// You are now connected to %@. You can change your preferences for this dApp in wallet settings at any time.
      internal static func successMessage(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccounts_successMessage", String(describing: p1), fallback: "You are now connected to %@. You can change your preferences for this dApp in wallet settings at any time.")
      }
      /// dApp Connection Successful
      internal static let successTitle = L10n.tr("Localizable", "dAppRequest_chooseAccounts_successTitle", fallback: "dApp Connection Successful")
      /// DApp error
      internal static let verificationErrorTitle = L10n.tr("Localizable", "dAppRequest_chooseAccounts_verificationErrorTitle", fallback: "DApp error")
    }
    internal enum ChooseAccountsOneTime {
      /// **%@** is making a one-time request for at least %d accounts.
      internal static func subtitleAtLeast(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeast", String(describing: p1), p2, fallback: "**%@** is making a one-time request for at least %d accounts.")
      }
      /// **%@** is making a one-time request for at least 1 account.
      internal static func subtitleAtLeastOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastOne", String(describing: p1), fallback: "**%@** is making a one-time request for at least 1 account.")
      }
      /// **%@** is making a one-time request for any number of accounts.
      internal static func subtitleAtLeastZero(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleAtLeastZero", String(describing: p1), fallback: "**%@** is making a one-time request for any number of accounts.")
      }
      /// **%@** is making a one-time request for %d accounts.
      internal static func subtitleExactly(_ p1: Any, _ p2: Int) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactly", String(describing: p1), p2, fallback: "**%@** is making a one-time request for %d accounts.")
      }
      /// **%@** is making a one-time request for 1 account.
      internal static func subtitleExactlyOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_subtitleExactlyOne", String(describing: p1), fallback: "**%@** is making a one-time request for 1 account.")
      }
      /// Account Request
      internal static let title = L10n.tr("Localizable", "dAppRequest_chooseAccountsOneTime_title", fallback: "Account Request")
    }
    internal enum ChooseAccountsOngoing {
      /// Choose at least %d accounts you wish to use with **%@**.
      internal static func subtitleAtLeast(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeast", p1, String(describing: p2), fallback: "Choose at least %d accounts you wish to use with **%@**.")
      }
      /// Choose at least 1 account you wish to use with **%@**.
      internal static func subtitleAtLeastOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastOne", String(describing: p1), fallback: "Choose at least 1 account you wish to use with **%@**.")
      }
      /// Choose any accounts you wish to use with **%@**.
      internal static func subtitleAtLeastZero(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleAtLeastZero", String(describing: p1), fallback: "Choose any accounts you wish to use with **%@**.")
      }
      /// Choose %d accounts you wish to use with **%@**.
      internal static func subtitleExactly(_ p1: Int, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactly", p1, String(describing: p2), fallback: "Choose %d accounts you wish to use with **%@**.")
      }
      /// Choose 1 account you wish to use with **%@**.
      internal static func subtitleExactlyOne(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_subtitleExactlyOne", String(describing: p1), fallback: "Choose 1 account you wish to use with **%@**.")
      }
      /// Account Permission
      internal static let title = L10n.tr("Localizable", "dAppRequest_chooseAccountsOngoing_title", fallback: "Account Permission")
    }
    internal enum Completion {
      /// Request from %@ complete
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_completion_subtitle", String(describing: p1), fallback: "Request from %@ complete")
      }
      /// Your pre-authorization has been included in a successful transaction.
      internal static let subtitlePreAuthorization = L10n.tr("Localizable", "dAppRequest_completion_subtitlePreAuthorization", fallback: "Your pre-authorization has been included in a successful transaction.")
      /// Success
      internal static let title = L10n.tr("Localizable", "dAppRequest_completion_title", fallback: "Success")
    }
    internal enum Login {
      /// Choose a Persona
      internal static let choosePersona = L10n.tr("Localizable", "dAppRequest_login_choosePersona", fallback: "Choose a Persona")
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "dAppRequest_login_continue", fallback: "Continue")
      /// Your last login was on %@
      internal static func lastLoginWasOn(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_lastLoginWasOn", String(describing: p1), fallback: "Your last login was on %@")
      }
      /// **%@** is requesting that you login with a Persona.
      internal static func subtitleKnownDapp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_subtitleKnownDapp", String(describing: p1), fallback: "**%@** is requesting that you login with a Persona.")
      }
      /// **%@** is requesting that you login for the first time with a Persona.
      internal static func subtitleNewDapp(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_login_subtitleNewDapp", String(describing: p1), fallback: "**%@** is requesting that you login for the first time with a Persona.")
      }
      /// Login Request
      internal static let titleKnownDapp = L10n.tr("Localizable", "dAppRequest_login_titleKnownDapp", fallback: "Login Request")
      /// New Login Request
      internal static let titleNewDapp = L10n.tr("Localizable", "dAppRequest_login_titleNewDapp", fallback: "New Login Request")
    }
    internal enum Metadata {
      /// Unknown dApp
      internal static let unknownName = L10n.tr("Localizable", "dAppRequest_metadata_unknownName", fallback: "Unknown dApp")
      /// Radix Wallet
      internal static let wallet = L10n.tr("Localizable", "dAppRequest_metadata_wallet", fallback: "Radix Wallet")
    }
    internal enum MetadataLoadingAlert {
      /// Danger! Bad dApp configuration, or you're being spoofed!
      internal static let message = L10n.tr("Localizable", "dAppRequest_metadataLoadingAlert_message", fallback: "Danger! Bad dApp configuration, or you're being spoofed!")
    }
    internal enum PersonaProofOfOwnership {
      /// **%@** is requesting verification of your login with the following Persona.
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personaProofOfOwnership_subtitle", String(describing: p1), fallback: "**%@** is requesting verification of your login with the following Persona.")
      }
      /// Verify Persona Login
      internal static let title = L10n.tr("Localizable", "dAppRequest_personaProofOfOwnership_title", fallback: "Verify Persona Login")
    }
    internal enum PersonalDataBox {
      /// Edit
      internal static let edit = L10n.tr("Localizable", "dAppRequest_personalDataBox_edit", fallback: "Edit")
      /// Required information:
      internal static let requiredInformation = L10n.tr("Localizable", "dAppRequest_personalDataBox_requiredInformation", fallback: "Required information:")
    }
    internal enum PersonalDataOneTime {
      /// Choose the data to provide
      internal static let chooseDataToProvide = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_chooseDataToProvide", fallback: "Choose the data to provide")
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_continue", fallback: "Continue")
      /// **%@** is requesting that you provide some pieces of personal data **just one time**
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataOneTime_subtitle", String(describing: p1), fallback: "**%@** is requesting that you provide some pieces of personal data **just one time**")
      }
      /// One-Time Data Request
      internal static let title = L10n.tr("Localizable", "dAppRequest_personalDataOneTime_title", fallback: "One-Time Data Request")
    }
    internal enum PersonalDataPermission {
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "dAppRequest_personalDataPermission_continue", fallback: "Continue")
      /// **%@** is requesting permission to **always** be able to view the following personal data when you login with this Persona.
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_personalDataPermission_subtitle", String(describing: p1), fallback: "**%@** is requesting permission to **always** be able to view the following personal data when you login with this Persona.")
      }
      /// Personal Data Permission
      internal static let title = L10n.tr("Localizable", "dAppRequest_personalDataPermission_title", fallback: "Personal Data Permission")
      /// You can update this permission in your Settings at any time.
      internal static let updateInSettingsExplanation = L10n.tr("Localizable", "dAppRequest_personalDataPermission_updateInSettingsExplanation", fallback: "You can update this permission in your Settings at any time.")
    }
    internal enum RequestMalformedAlert {
      /// Request received from dApp is invalid.
      internal static let message = L10n.tr("Localizable", "dAppRequest_requestMalformedAlert_message", fallback: "Request received from dApp is invalid.")
    }
    internal enum RequestPersonaNotFoundAlert {
      /// dApp specified an invalid Persona.
      internal static let message = L10n.tr("Localizable", "dAppRequest_requestPersonaNotFoundAlert_message", fallback: "dApp specified an invalid Persona.")
    }
    internal enum RequestWrongNetworkAlert {
      /// dApp made a request intended for network %@, but you are currently connected to %@.
      internal static func message(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_requestWrongNetworkAlert_message", String(describing: p1), String(describing: p2), fallback: "dApp made a request intended for network %@, but you are currently connected to %@.")
      }
    }
    internal enum ResponseFailureAlert {
      /// Failed to send request response to dApp.
      internal static let message = L10n.tr("Localizable", "dAppRequest_responseFailureAlert_message", fallback: "Failed to send request response to dApp.")
    }
    internal enum ValidationOutcome {
      /// Invalid value of `numberOfAccountsInvalid`: must not be `exactly(0)` nor can `quantity` be negative
      internal static let devExplanationBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationBadContent", fallback: "Invalid value of `numberOfAccountsInvalid`: must not be `exactly(0)` nor can `quantity` be negative")
      /// %@ (CE: %@, wallet: %@)
      internal static func devExplanationIncompatibleVersion(_ p1: Any, _ p2: Any, _ p3: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationIncompatibleVersion", String(describing: p1), String(describing: p2), String(describing: p3), fallback: "%@ (CE: %@, wallet: %@)")
      }
      /// '%@' is not valid account address.
      internal static func devExplanationInvalidDappDefinitionAddress(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationInvalidDappDefinitionAddress", String(describing: p1), fallback: "'%@' is not valid account address.")
      }
      /// '%@' is not valid origin.
      internal static func devExplanationInvalidOrigin(_ p1: Any) -> String {
        return L10n.tr("Localizable", "dAppRequest_validationOutcome_devExplanationInvalidOrigin", String(describing: p1), fallback: "'%@' is not valid origin.")
      }
      /// dApp specified an invalid Persona or Account
      internal static let invalidPersonaOrAccoubts = L10n.tr("Localizable", "dAppRequest_validationOutcome_invalidPersonaOrAccoubts", fallback: "dApp specified an invalid Persona or Account")
      /// Could not validate the dApp.
      internal static let invalidRequestMessage = L10n.tr("Localizable", "dAppRequest_validationOutcome_invalidRequestMessage", fallback: "Could not validate the dApp.")
      /// Invalid Request.
      internal static let invalidRequestTitle = L10n.tr("Localizable", "dAppRequest_validationOutcome_invalidRequestTitle", fallback: "Invalid Request.")
      /// Pre-authorization request was rejected because you weren't given enough time to review it.
      internal static let preAuthorizationExpirationTooClose = L10n.tr("Localizable", "dAppRequest_validationOutcome_preAuthorizationExpirationTooClose", fallback: "Pre-authorization request was rejected because you weren't given enough time to review it.")
      /// Pre-authorization request was rejected because it has already expired.
      internal static let preAuthorizationExpired = L10n.tr("Localizable", "dAppRequest_validationOutcome_preAuthorizationExpired", fallback: "Pre-authorization request was rejected because it has already expired.")
      /// Invalid data in request
      internal static let shortExplanationBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationBadContent", fallback: "Invalid data in request")
      /// Please update Radix Wallet
      internal static let shortExplanationIncompatibleVersionCEGreater = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationIncompatibleVersionCEGreater", fallback: "Please update Radix Wallet")
      /// Please update Radix Connector browser extension
      internal static let shortExplanationIncompatibleVersionCENotGreater = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationIncompatibleVersionCENotGreater", fallback: "Please update Radix Connector browser extension")
      /// Invalid dApp Definition Address
      internal static let shortExplanationInvalidDappDefinitionAddress = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationInvalidDappDefinitionAddress", fallback: "Invalid dApp Definition Address")
      /// Invalid origin
      internal static let shortExplanationInvalidOrigin = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationInvalidOrigin", fallback: "Invalid origin")
      /// Radix Connect connection error
      internal static let shortExplanationP2PError = L10n.tr("Localizable", "dAppRequest_validationOutcome_shortExplanationP2PError", fallback: "Radix Connect connection error")
      /// Invalid content
      internal static let subtitleBadContent = L10n.tr("Localizable", "dAppRequest_validationOutcome_subtitleBadContent", fallback: "Invalid content")
      /// Incompatible connector extension
      internal static let subtitleIncompatibleVersion = L10n.tr("Localizable", "dAppRequest_validationOutcome_subtitleIncompatibleVersion", fallback: "Incompatible connector extension")
      /// Network mismatch
      internal static let subtitleWrongNetworkID = L10n.tr("Localizable", "dAppRequest_validationOutcome_subtitleWrongNetworkID", fallback: "Network mismatch")
    }
  }
  internal enum DisplayMnemonics {
    /// Write Down this Seed Phrase
    internal static let backUpWarning = L10n.tr("Localizable", "displayMnemonics_backUpWarning", fallback: "Write Down this Seed Phrase")
    /// Begin seed phrase entry
    internal static let seedPhraseEntryWarning = L10n.tr("Localizable", "displayMnemonics_seedPhraseEntryWarning", fallback: "Begin seed phrase entry")
    /// Seed Phrases
    internal static let seedPhrases = L10n.tr("Localizable", "displayMnemonics_seedPhrases", fallback: "Seed Phrases")
    /// You are responsible for the security of your Seed Phrase
    internal static let seedPhraseSecurityInfo = L10n.tr("Localizable", "displayMnemonics_seedPhraseSecurityInfo", fallback: "You are responsible for the security of your Seed Phrase")
    internal enum CautionAlert {
      /// A seed phrase provides full control of its Accounts. Do not view in a public area. Write down the seed phrase words securely. Screenshots are disabled.
      internal static let message = L10n.tr("Localizable", "displayMnemonics_cautionAlert_message", fallback: "A seed phrase provides full control of its Accounts. Do not view in a public area. Write down the seed phrase words securely. Screenshots are disabled.")
      /// Reveal Seed Phrase
      internal static let revealButtonLabel = L10n.tr("Localizable", "displayMnemonics_cautionAlert_revealButtonLabel", fallback: "Reveal Seed Phrase")
      /// Use Caution
      internal static let title = L10n.tr("Localizable", "displayMnemonics_cautionAlert_title", fallback: "Use Caution")
    }
    internal enum ConnectedAccountsLabel {
      /// Connected to %d Accounts
      internal static func many(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsLabel_many", p1, fallback: "Connected to %d Accounts")
      }
      /// Connected to %d Account
      internal static func one(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsLabel_one", p1, fallback: "Connected to %d Account")
      }
    }
    internal enum ConnectedAccountsPersonasLabel {
      /// Connected to Personas and to %d Accounts
      internal static func many(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsPersonasLabel_many", p1, fallback: "Connected to Personas and to %d Accounts")
      }
      /// Connected to Personas and %d Account
      internal static func one(_ p1: Int) -> String {
        return L10n.tr("Localizable", "displayMnemonics_connectedAccountsPersonasLabel_one", p1, fallback: "Connected to Personas and %d Account")
      }
    }
  }
  internal enum EditPersona {
    /// Add a Field
    internal static let addAField = L10n.tr("Localizable", "editPersona_addAField", fallback: "Add a Field")
    /// Required by dApp
    internal static let requiredByDapp = L10n.tr("Localizable", "editPersona_requiredByDapp", fallback: "Required by dApp")
    /// The following information can be seen if requested by the dApp
    internal static let sharedInformationHeading = L10n.tr("Localizable", "editPersona_sharedInformationHeading", fallback: "The following information can be seen if requested by the dApp")
    internal enum AddAField {
      /// Add Data Fields
      internal static let add = L10n.tr("Localizable", "editPersona_addAField_add", fallback: "Add Data Fields")
      /// Choose one or more data fields to add to this Persona.
      internal static let subtitle = L10n.tr("Localizable", "editPersona_addAField_subtitle", fallback: "Choose one or more data fields to add to this Persona.")
      /// Add a Field
      internal static let title = L10n.tr("Localizable", "editPersona_addAField_title", fallback: "Add a Field")
    }
    internal enum CloseConfirmationDialog {
      /// Discard Changes
      internal static let discardChanges = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_discardChanges", fallback: "Discard Changes")
      /// Keep Editing
      internal static let keepEditing = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_keepEditing", fallback: "Keep Editing")
      /// Are you sure you want to discard changes to this Persona?
      internal static let message = L10n.tr("Localizable", "editPersona_closeConfirmationDialog_message", fallback: "Are you sure you want to discard changes to this Persona?")
    }
    internal enum Error {
      /// Label cannot be blank
      internal static let blank = L10n.tr("Localizable", "editPersona_error_blank", fallback: "Label cannot be blank")
      /// Invalid email address
      internal static let invalidEmailAddress = L10n.tr("Localizable", "editPersona_error_invalidEmailAddress", fallback: "Invalid email address")
      /// Required field for this dApp
      internal static let requiredByDapp = L10n.tr("Localizable", "editPersona_error_requiredByDapp", fallback: "Required field for this dApp")
    }
  }
  internal enum EncryptProfileBackup {
    internal enum ConfirmPasswordField {
      /// Passwords do not match
      internal static let error = L10n.tr("Localizable", "encryptProfileBackup_confirmPasswordField_error", fallback: "Passwords do not match")
      /// Confirm password
      internal static let placeholder = L10n.tr("Localizable", "encryptProfileBackup_confirmPasswordField_placeholder", fallback: "Confirm password")
    }
    internal enum EnterPasswordField {
      /// Enter password
      internal static let placeholder = L10n.tr("Localizable", "encryptProfileBackup_enterPasswordField_placeholder", fallback: "Enter password")
    }
    internal enum Header {
      /// Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.
      internal static let subtitle = L10n.tr("Localizable", "encryptProfileBackup_header_subtitle", fallback: "Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.")
      /// Encrypt Wallet Backup File
      internal static let title = L10n.tr("Localizable", "encryptProfileBackup_header_title", fallback: "Encrypt Wallet Backup File")
    }
  }
  internal enum EnterSeedPhrase {
    /// Enter Babylon Seed Phrase
    internal static let titleBabylon = L10n.tr("Localizable", "enterSeedPhrase_titleBabylon", fallback: "Enter Babylon Seed Phrase")
    /// Enter Main Seed Phrase
    internal static let titleBabylonMain = L10n.tr("Localizable", "enterSeedPhrase_titleBabylonMain", fallback: "Enter Main Seed Phrase")
    /// Enter Olympia Seed Phrase
    internal static let titleOlympia = L10n.tr("Localizable", "enterSeedPhrase_titleOlympia", fallback: "Enter Olympia Seed Phrase")
    /// For your safety, make sure no one is looking at your screen. Never give your seed phrase to anyone for any reason.
    internal static let warning = L10n.tr("Localizable", "enterSeedPhrase_warning", fallback: "For your safety, make sure no one is looking at your screen. Never give your seed phrase to anyone for any reason.")
    internal enum Header {
      /// Enter Seed Phrase
      internal static let title = L10n.tr("Localizable", "enterSeedPhrase_header_title", fallback: "Enter Seed Phrase")
      /// Enter Main Seed Phrase
      internal static let titleMain = L10n.tr("Localizable", "enterSeedPhrase_header_titleMain", fallback: "Enter Main Seed Phrase")
    }
  }
  internal enum Error {
    /// Email Support
    internal static let emailSupportButtonTitle = L10n.tr("Localizable", "error_emailSupportButtonTitle", fallback: "Email Support")
    /// Please email support to automatically provide debugging info, and get assistance.
    /// Code: %@
    internal static func emailSupportMessage(_ p1: Any) -> String {
      return L10n.tr("Localizable", "error_emailSupportMessage", String(describing: p1), fallback: "Please email support to automatically provide debugging info, and get assistance.\nCode: %@")
    }
    internal enum AccountLabel {
      /// Account label required
      internal static let missing = L10n.tr("Localizable", "error_accountLabel_missing", fallback: "Account label required")
      /// Account label too long
      internal static let tooLong = L10n.tr("Localizable", "error_accountLabel_tooLong", fallback: "Account label too long")
    }
    internal enum DappRequest {
      /// Invalid Persona specified by dApp
      internal static let invalidPersonaId = L10n.tr("Localizable", "error_dappRequest_invalidPersonaId", fallback: "Invalid Persona specified by dApp")
      /// Invalid request
      internal static let invalidRequest = L10n.tr("Localizable", "error_dappRequest_invalidRequest", fallback: "Invalid request")
    }
    internal enum PersonaLabel {
      /// Persona label too long
      internal static let tooLong = L10n.tr("Localizable", "error_personaLabel_tooLong", fallback: "Persona label too long")
    }
    internal enum ProfileLoad {
      /// Failed to import Radix Wallet backup: %@
      internal static func decodingError(_ p1: Any) -> String {
        return L10n.tr("Localizable", "error_profileLoad_decodingError", String(describing: p1), fallback: "Failed to import Radix Wallet backup: %@")
      }
      /// Failed to import Radix Wallet backup, error: %@, version: %@
      internal static func failedToCreateProfileFromSnapshot(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "error_profileLoad_failedToCreateProfileFromSnapshot", String(describing: p1), String(describing: p2), fallback: "Failed to import Radix Wallet backup, error: %@, version: %@")
      }
    }
    internal enum TransactionFailure {
      /// Your current Ledger settings only allow signing of simple token transfers. Please either enable "verbose mode" (to see full transaction manifests) or "blind signing mode" (to enable signing of complex transaction manifest hashes) on your Ledger app device.
      internal static let blindSigningNotEnabledButRequired = L10n.tr("Localizable", "error_transactionFailure_blindSigningNotEnabledButRequired", fallback: "Your current Ledger settings only allow signing of simple token transfers. Please either enable \"verbose mode\" (to see full transaction manifests) or \"blind signing mode\" (to enable signing of complex transaction manifest hashes) on your Ledger app device.")
      /// Failed to commit transaction
      internal static let commit = L10n.tr("Localizable", "error_transactionFailure_commit", fallback: "Failed to commit transaction")
      /// One of the receiving accounts does not allow Third-Party deposits
      internal static let doesNotAllowThirdPartyDeposits = L10n.tr("Localizable", "error_transactionFailure_doesNotAllowThirdPartyDeposits", fallback: "One of the receiving accounts does not allow Third-Party deposits")
      /// Failed to convert transaction manifest
      internal static let duplicate = L10n.tr("Localizable", "error_transactionFailure_duplicate", fallback: "Failed to convert transaction manifest")
      /// Failed to get epoch
      internal static let epoch = L10n.tr("Localizable", "error_transactionFailure_epoch", fallback: "Failed to get epoch")
      /// Failed to add Guarantee, try a different percentage, or try skip adding a guarantee.
      internal static let failedToAddGuarantee = L10n.tr("Localizable", "error_transactionFailure_failedToAddGuarantee", fallback: "Failed to add Guarantee, try a different percentage, or try skip adding a guarantee.")
      /// Failed to add Transaction Fee, try a different amount of fee payer.
      internal static let failedToAddLockFee = L10n.tr("Localizable", "error_transactionFailure_failedToAddLockFee", fallback: "Failed to add Transaction Fee, try a different amount of fee payer.")
      /// Failed to find ledger
      internal static let failedToFindLedger = L10n.tr("Localizable", "error_transactionFailure_failedToFindLedger", fallback: "Failed to find ledger")
      /// Failed to build transaction header
      internal static let header = L10n.tr("Localizable", "error_transactionFailure_header", fallback: "Failed to build transaction header")
      /// Failed to convert transaction manifest
      internal static let manifest = L10n.tr("Localizable", "error_transactionFailure_manifest", fallback: "Failed to convert transaction manifest")
      /// You don't have access to some accounts or personas required to authorise this transaction
      internal static let missingSigners = L10n.tr("Localizable", "error_transactionFailure_missingSigners", fallback: "You don't have access to some accounts or personas required to authorise this transaction")
      /// Wrong network
      internal static let network = L10n.tr("Localizable", "error_transactionFailure_network", fallback: "Wrong network")
      /// No funds to approve transaction
      internal static let noFundsToApproveTransaction = L10n.tr("Localizable", "error_transactionFailure_noFundsToApproveTransaction", fallback: "No funds to approve transaction")
      /// Failed to poll transaction status
      internal static let pollStatus = L10n.tr("Localizable", "error_transactionFailure_pollStatus", fallback: "Failed to poll transaction status")
      /// Failed to prepare transaction
      internal static let prepare = L10n.tr("Localizable", "error_transactionFailure_prepare", fallback: "Failed to prepare transaction")
      /// Transaction rejected
      internal static let rejected = L10n.tr("Localizable", "error_transactionFailure_rejected", fallback: "Transaction rejected")
      /// Failed to convert transaction manifest
      internal static let rejectedByUser = L10n.tr("Localizable", "error_transactionFailure_rejectedByUser", fallback: "Failed to convert transaction manifest")
      /// A proposed transaction could not be processed.
      internal static let reviewFailure = L10n.tr("Localizable", "error_transactionFailure_reviewFailure", fallback: "A proposed transaction could not be processed.")
      /// Failed to submit transaction
      internal static let submit = L10n.tr("Localizable", "error_transactionFailure_submit", fallback: "Failed to submit transaction")
      /// Unknown error
      internal static let unknown = L10n.tr("Localizable", "error_transactionFailure_unknown", fallback: "Unknown error")
    }
  }
  internal enum FactorSourceActions {
    internal enum CreateAccount {
      /// Creating Account
      internal static let title = L10n.tr("Localizable", "factorSourceActions_createAccount_title", fallback: "Creating Account")
    }
    internal enum CreateKey {
      /// Creating Key
      internal static let title = L10n.tr("Localizable", "factorSourceActions_createKey_title", fallback: "Creating Key")
    }
    internal enum CreatePersona {
      /// Creating Persona
      internal static let title = L10n.tr("Localizable", "factorSourceActions_createPersona_title", fallback: "Creating Persona")
    }
    internal enum DeriveAccounts {
      /// Deriving Accounts
      internal static let title = L10n.tr("Localizable", "factorSourceActions_deriveAccounts_title", fallback: "Deriving Accounts")
    }
    internal enum Device {
      /// Authenticate to your phone to complete using your phone's signing key.
      internal static let message = L10n.tr("Localizable", "factorSourceActions_device_message", fallback: "Authenticate to your phone to complete using your phone's signing key.")
      /// Authenticate to your phone to sign.
      internal static let messageSignature = L10n.tr("Localizable", "factorSourceActions_device_messageSignature", fallback: "Authenticate to your phone to sign.")
    }
    internal enum EncryptMessage {
      /// Encrypting Message
      internal static let title = L10n.tr("Localizable", "factorSourceActions_encryptMessage_title", fallback: "Encrypting Message")
    }
    internal enum Ledger {
      /// Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.
      internal static let message = L10n.tr("Localizable", "factorSourceActions_ledger_message", fallback: "Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.")
      /// Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.
      /// **Derivation may take up to a minute.**
      internal static let messageDeriveAccounts = L10n.tr("Localizable", "factorSourceActions_ledger_messageDeriveAccounts", fallback: "Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.\n**Derivation may take up to a minute.**")
      /// Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.
      /// **Complete signing on the device.**
      internal static let messageSignature = L10n.tr("Localizable", "factorSourceActions_ledger_messageSignature", fallback: "Make sure the following **Ledger hardware wallet** is connected to a computer with a linked Radix Connector browser extension.\n**Complete signing on the device.**")
    }
    internal enum ProveOwnership {
      /// Proving Ownership
      internal static let title = L10n.tr("Localizable", "factorSourceActions_proveOwnership_title", fallback: "Proving Ownership")
    }
    internal enum Signature {
      /// Signature Request
      internal static let title = L10n.tr("Localizable", "factorSourceActions_signature_title", fallback: "Signature Request")
    }
  }
  internal enum FactorSources {
    internal enum Card {
      /// %d Accounts
      internal static func accountPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "factorSources_card_accountPlural", p1, fallback: "%d Accounts")
      }
      /// 1 Account
      internal static let accountSingular = L10n.tr("Localizable", "factorSources_card_accountSingular", fallback: "1 Account")
      /// Tap to your phone to approve
      internal static let arculusCardDescription = L10n.tr("Localizable", "factorSources_card_arculusCardDescription", fallback: "Tap to your phone to approve")
      /// Arculus Card
      internal static let arculusCardTitle = L10n.tr("Localizable", "factorSources_card_arculusCardTitle", fallback: "Arculus Card")
      /// Use phone biometrics/PIN to approve
      internal static let deviceDescription = L10n.tr("Localizable", "factorSources_card_deviceDescription", fallback: "Use phone biometrics/PIN to approve")
      /// Biometrics/PIN
      internal static let deviceTitle = L10n.tr("Localizable", "factorSources_card_deviceTitle", fallback: "Biometrics/PIN")
      /// Hidden Accounts or Personas
      internal static let hiddenAccountsOrPersonas = L10n.tr("Localizable", "factorSources_card_hiddenAccountsOrPersonas", fallback: "Hidden Accounts or Personas")
      /// **Last Used:** %@
      internal static func lastUsed(_ p1: Any) -> String {
        return L10n.tr("Localizable", "factorSources_card_lastUsed", String(describing: p1), fallback: "**Last Used:** %@")
      }
      /// Connect via USB to approve
      internal static let ledgerDescription = L10n.tr("Localizable", "factorSources_card_ledgerDescription", fallback: "Connect via USB to approve")
      /// Ledger Nano
      internal static let ledgerTitle = L10n.tr("Localizable", "factorSources_card_ledgerTitle", fallback: "Ledger Nano")
      /// Linked to %@ and %@
      internal static func linkedAccountsAndPersonas(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "factorSources_card_linkedAccountsAndPersonas", String(describing: p1), String(describing: p2), fallback: "Linked to %@ and %@")
      }
      /// Linked to %@ and %@ (and some hidden)
      internal static func linkedAccountsAndPersonasSomeHidden(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "factorSources_card_linkedAccountsAndPersonasSomeHidden", String(describing: p1), String(describing: p2), fallback: "Linked to %@ and %@ (and some hidden)")
      }
      /// Linked to %@
      internal static func linkedAccountsOrPersonas(_ p1: Any) -> String {
        return L10n.tr("Localizable", "factorSources_card_linkedAccountsOrPersonas", String(describing: p1), fallback: "Linked to %@")
      }
      /// Linked to %@ (and some hidden)
      internal static func linkedAccountsOrPersonasSomeHidden(_ p1: Any) -> String {
        return L10n.tr("Localizable", "factorSources_card_linkedAccountsOrPersonasSomeHidden", String(describing: p1), fallback: "Linked to %@ (and some hidden)")
      }
      /// Enter a seed phrase to approve
      internal static let passphraseDescription = L10n.tr("Localizable", "factorSources_card_passphraseDescription", fallback: "Enter a seed phrase to approve")
      /// Mnemonic
      internal static let passphraseTitle = L10n.tr("Localizable", "factorSources_card_passphraseTitle", fallback: "Mnemonic")
      /// Enter a decentralized password to approve
      internal static let passwordDescription = L10n.tr("Localizable", "factorSources_card_passwordDescription", fallback: "Enter a decentralized password to approve")
      /// Password
      internal static let passwordTitle = L10n.tr("Localizable", "factorSources_card_passwordTitle", fallback: "Password")
      /// %d Personas
      internal static func personaPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "factorSources_card_personaPlural", p1, fallback: "%d Personas")
      }
      /// 1 Persona
      internal static let personaSingular = L10n.tr("Localizable", "factorSources_card_personaSingular", fallback: "1 Persona")
    }
    internal enum ChangeMain {
      /// Select the biometrics/PIN factor that will be automatically selected when you create a new Account or Persona.
      internal static let subtitle = L10n.tr("Localizable", "factorSources_changeMain_subtitle", fallback: "Select the biometrics/PIN factor that will be automatically selected when you create a new Account or Persona.")
      /// Change Default Biometrics/PIN
      internal static let title = L10n.tr("Localizable", "factorSources_changeMain_title", fallback: "Change Default Biometrics/PIN")
    }
    internal enum Detail {
      /// Advanced
      internal static let advanced = L10n.tr("Localizable", "factorSources_detail_advanced", fallback: "Advanced")
      /// Change PIN
      internal static let changePin = L10n.tr("Localizable", "factorSources_detail_changePin", fallback: "Change PIN")
      /// Enter seed phrase to recover use of this factor
      internal static let enterSeedPhrase = L10n.tr("Localizable", "factorSources_detail_enterSeedPhrase", fallback: "Enter seed phrase to recover use of this factor")
      /// **Last used:** %@
      internal static func lastUsed(_ p1: Any) -> String {
        return L10n.tr("Localizable", "factorSources_detail_lastUsed", String(describing: p1), fallback: "**Last used:** %@")
      }
      /// Manage Factor
      internal static let manage = L10n.tr("Localizable", "factorSources_detail_manage", fallback: "Manage Factor")
      /// Rename this factor
      internal static let rename = L10n.tr("Localizable", "factorSources_detail_rename", fallback: "Rename this factor")
      /// Seed Phrase Lost
      internal static let seedPhraseLost = L10n.tr("Localizable", "factorSources_detail_seedPhraseLost", fallback: "Seed Phrase Lost")
      /// Spot Check
      internal static let spotCheck = L10n.tr("Localizable", "factorSources_detail_spotCheck", fallback: "Spot Check")
      /// Test
      internal static let test = L10n.tr("Localizable", "factorSources_detail_test", fallback: "Test")
      /// Test that you can use this factor
      internal static let testCanUse = L10n.tr("Localizable", "factorSources_detail_testCanUse", fallback: "Test that you can use this factor")
      /// View Seed Phrase
      internal static let viewSeedPhrase = L10n.tr("Localizable", "factorSources_detail_viewSeedPhrase", fallback: "View Seed Phrase")
      /// Write down the seed phrase for advanced recovery
      internal static let writeSeedPhrase = L10n.tr("Localizable", "factorSources_detail_writeSeedPhrase", fallback: "Write down the seed phrase for advanced recovery")
    }
    internal enum Kind {
      /// Phone
      internal static let device = L10n.tr("Localizable", "factorSources_kind_device", fallback: "Phone")
      /// Ledger
      internal static let ledgerHQHardwareWallet = L10n.tr("Localizable", "factorSources_kind_ledgerHQHardwareWallet", fallback: "Ledger")
      /// Seed phrase
      internal static let offDeviceMnemonic = L10n.tr("Localizable", "factorSources_kind_offDeviceMnemonic", fallback: "Seed phrase")
      /// Security Questions
      internal static let securityQuestions = L10n.tr("Localizable", "factorSources_kind_securityQuestions", fallback: "Security Questions")
      /// Third-party
      internal static let trustedContact = L10n.tr("Localizable", "factorSources_kind_trustedContact", fallback: "Third-party")
    }
    internal enum List {
      /// Add Arculus Card
      internal static let arculusCardAdd = L10n.tr("Localizable", "factorSources_list_arculusCardAdd", fallback: "Add Arculus Card")
      /// Arculus not working. Try adding it again
      internal static let arculusCardNotWorking = L10n.tr("Localizable", "factorSources_list_arculusCardNotWorking", fallback: "Arculus not working. Try adding it again")
      /// Change
      internal static let change = L10n.tr("Localizable", "factorSources_list_change", fallback: "Change")
      /// Default
      internal static let `default` = L10n.tr("Localizable", "factorSources_list_default", fallback: "Default")
      /// Add Biometrics/PIN
      internal static let deviceAdd = L10n.tr("Localizable", "factorSources_list_deviceAdd", fallback: "Add Biometrics/PIN")
      /// Add New Ledger Nano
      internal static let ledgerAdd = L10n.tr("Localizable", "factorSources_list_ledgerAdd", fallback: "Add New Ledger Nano")
      /// This factor has been lost
      internal static let lostFactorSource = L10n.tr("Localizable", "factorSources_list_lostFactorSource", fallback: "This factor has been lost")
      /// Others
      internal static let others = L10n.tr("Localizable", "factorSources_list_others", fallback: "Others")
      /// Add New Passphrase
      internal static let passphraseAdd = L10n.tr("Localizable", "factorSources_list_passphraseAdd", fallback: "Add New Passphrase")
      /// Add New Password
      internal static let passwordAdd = L10n.tr("Localizable", "factorSources_list_passwordAdd", fallback: "Add New Password")
      /// Write down seed phrase to make this factor recoverable
      internal static let seedPhraseNotRecoverable = L10n.tr("Localizable", "factorSources_list_seedPhraseNotRecoverable", fallback: "Write down seed phrase to make this factor recoverable")
      /// This seed phrase has been written down
      internal static let seedPhraseWrittenDown = L10n.tr("Localizable", "factorSources_list_seedPhraseWrittenDown", fallback: "This seed phrase has been written down")
    }
  }
  internal enum FactoryReset {
    /// Once you’ve completed a factory reset, you will not be able to access your Accounts and Personas unless you do a full recovery.
    internal static let disclosure = L10n.tr("Localizable", "factoryReset_disclosure", fallback: "Once you’ve completed a factory reset, you will not be able to access your Accounts and Personas unless you do a full recovery.")
    /// A factory reset will restore your Radix wallet to its original settings. All of your data and preferences will be erased.
    internal static let message = L10n.tr("Localizable", "factoryReset_message", fallback: "A factory reset will restore your Radix wallet to its original settings. All of your data and preferences will be erased.")
    /// Your wallet is recoverable
    internal static let recoverable = L10n.tr("Localizable", "factoryReset_recoverable", fallback: "Your wallet is recoverable")
    /// Reset Wallet
    internal static let resetWallet = L10n.tr("Localizable", "factoryReset_resetWallet", fallback: "Reset Wallet")
    /// Security Center status
    internal static let status = L10n.tr("Localizable", "factoryReset_status", fallback: "Security Center status")
    /// Factory Reset
    internal static let title = L10n.tr("Localizable", "factoryReset_title", fallback: "Factory Reset")
    internal enum Dialog {
      /// Return wallet to factory settings? You cannot undo this.
      internal static let message = L10n.tr("Localizable", "factoryReset_dialog_message", fallback: "Return wallet to factory settings? You cannot undo this.")
      /// Confirm factory reset
      internal static let title = L10n.tr("Localizable", "factoryReset_dialog_title", fallback: "Confirm factory reset")
    }
    internal enum Unrecoverable {
      /// Your wallet is currently unrecoverable. If you do a factory reset now, you will never be able to access your Accounts and Personas again.
      internal static let message = L10n.tr("Localizable", "factoryReset_unrecoverable_message", fallback: "Your wallet is currently unrecoverable. If you do a factory reset now, you will never be able to access your Accounts and Personas again.")
      /// Your wallet is not recoverable
      internal static let title = L10n.tr("Localizable", "factoryReset_unrecoverable_title", fallback: "Your wallet is not recoverable")
    }
  }
  internal enum Gateways {
    /// Add New Gateway
    internal static let addNewGatewayButtonTitle = L10n.tr("Localizable", "gateways_addNewGatewayButtonTitle", fallback: "Add New Gateway")
    /// RCnet Gateway
    internal static let rcNetGateway = L10n.tr("Localizable", "gateways_rcNetGateway", fallback: "RCnet Gateway")
    /// Choose the gateway your wallet will use to connect to the Radix Network or test networks. Only change this if you know what you’re doing.
    internal static let subtitle = L10n.tr("Localizable", "gateways_subtitle", fallback: "Choose the gateway your wallet will use to connect to the Radix Network or test networks. Only change this if you know what you’re doing.")
    /// Gateways
    internal static let title = L10n.tr("Localizable", "gateways_title", fallback: "Gateways")
    internal enum AddNewGateway {
      /// Add Gateway
      internal static let addGatewayButtonTitle = L10n.tr("Localizable", "gateways_addNewGateway_addGatewayButtonTitle", fallback: "Add Gateway")
      /// This gateway is already added
      internal static let errorDuplicateURL = L10n.tr("Localizable", "gateways_addNewGateway_errorDuplicateURL", fallback: "This gateway is already added")
      /// No gateway found at specified URL
      internal static let errorNoGatewayFound = L10n.tr("Localizable", "gateways_addNewGateway_errorNoGatewayFound", fallback: "No gateway found at specified URL")
      /// There was an error establishing a connection
      internal static let establishingConnectionErrorMessage = L10n.tr("Localizable", "gateways_addNewGateway_establishingConnectionErrorMessage", fallback: "There was an error establishing a connection")
      /// Enter a gateway URL
      internal static let subtitle = L10n.tr("Localizable", "gateways_addNewGateway_subtitle", fallback: "Enter a gateway URL")
      /// Enter full URL
      internal static let textFieldPlaceholder = L10n.tr("Localizable", "gateways_addNewGateway_textFieldPlaceholder", fallback: "Enter full URL")
      /// Add New Gateway
      internal static let title = L10n.tr("Localizable", "gateways_addNewGateway_title", fallback: "Add New Gateway")
    }
    internal enum RemoveGatewayAlert {
      /// You will no longer be able to connect to this gateway.
      internal static let message = L10n.tr("Localizable", "gateways_removeGatewayAlert_message", fallback: "You will no longer be able to connect to this gateway.")
      /// Remove Gateway
      internal static let title = L10n.tr("Localizable", "gateways_removeGatewayAlert_title", fallback: "Remove Gateway")
    }
  }
  internal enum HiddenAssets {
    /// Tokens
    internal static let fungibles = L10n.tr("Localizable", "hiddenAssets_fungibles", fallback: "Tokens")
    /// NFTs
    internal static let nonFungibles = L10n.tr("Localizable", "hiddenAssets_nonFungibles", fallback: "NFTs")
    /// Pool Units
    internal static let poolUnits = L10n.tr("Localizable", "hiddenAssets_poolUnits", fallback: "Pool Units")
    /// You have hidden the following assets. While hidden, you will not see these in any of your Accounts.
    internal static let text = L10n.tr("Localizable", "hiddenAssets_text", fallback: "You have hidden the following assets. While hidden, you will not see these in any of your Accounts.")
    /// Hidden Assets
    internal static let title = L10n.tr("Localizable", "hiddenAssets_title", fallback: "Hidden Assets")
    /// Unhide
    internal static let unhide = L10n.tr("Localizable", "hiddenAssets_unhide", fallback: "Unhide")
    internal enum NonFungibles {
      /// %d in this collection
      internal static func count(_ p1: Int) -> String {
        return L10n.tr("Localizable", "hiddenAssets_nonFungibles_count", p1, fallback: "%d in this collection")
      }
    }
    internal enum UnhideConfirmation {
      /// Make this asset visible in your Accounts again?
      internal static let asset = L10n.tr("Localizable", "hiddenAssets_unhideConfirmation_asset", fallback: "Make this asset visible in your Accounts again?")
      /// Make this collection visible in your Accounts again?
      internal static let collection = L10n.tr("Localizable", "hiddenAssets_unhideConfirmation_collection", fallback: "Make this collection visible in your Accounts again?")
    }
  }
  internal enum HiddenEntities {
    /// Accounts
    internal static let accounts = L10n.tr("Localizable", "hiddenEntities_accounts", fallback: "Accounts")
    /// Personas
    internal static let personas = L10n.tr("Localizable", "hiddenEntities_personas", fallback: "Personas")
    /// You have hidden the following Personas and Accounts. They remain on the Radix Network, but while hidden, your wallet will treat them as if they don’t exist.
    internal static let text = L10n.tr("Localizable", "hiddenEntities_text", fallback: "You have hidden the following Personas and Accounts. They remain on the Radix Network, but while hidden, your wallet will treat them as if they don’t exist.")
    /// Hidden Personas & Accounts
    internal static let title = L10n.tr("Localizable", "hiddenEntities_title", fallback: "Hidden Personas & Accounts")
    /// Unhide
    internal static let unhide = L10n.tr("Localizable", "hiddenEntities_unhide", fallback: "Unhide")
    /// Make this Account visible in your wallet again?
    internal static let unhideAccountsConfirmation = L10n.tr("Localizable", "hiddenEntities_unhideAccountsConfirmation", fallback: "Make this Account visible in your wallet again?")
    /// Make this Persona visible in your wallet again?
    internal static let unhidePersonasConfirmation = L10n.tr("Localizable", "hiddenEntities_unhidePersonasConfirmation", fallback: "Make this Persona visible in your wallet again?")
  }
  internal enum HomePage {
    /// %@ has a deposit for you to claim
    internal static func accountLockerClaim(_ p1: Any) -> String {
      return L10n.tr("Localizable", "homePage_accountLockerClaim", String(describing: p1), fallback: "%@ has a deposit for you to claim")
    }
    /// I have written down this seed phrase
    internal static let backedUpMnemonicHeading = L10n.tr("Localizable", "homePage_backedUpMnemonicHeading", fallback: "I have written down this seed phrase")
    /// Create a New Account
    internal static let createNewAccount = L10n.tr("Localizable", "homePage_createNewAccount", fallback: "Create a New Account")
    /// Legacy
    internal static let legacyAccountHeading = L10n.tr("Localizable", "homePage_legacyAccountHeading", fallback: "Legacy")
    /// Please write down seed phrase to ensure Account control
    internal static let securityPromptBackup = L10n.tr("Localizable", "homePage_securityPromptBackup", fallback: "Please write down seed phrase to ensure Account control")
    /// Seed phrase required - begin entry
    internal static let securityPromptRecover = L10n.tr("Localizable", "homePage_securityPromptRecover", fallback: "Seed phrase required - begin entry")
    /// Welcome. Here are all your Accounts on the Radix Network.
    internal static let subtitle = L10n.tr("Localizable", "homePage_subtitle", fallback: "Welcome. Here are all your Accounts on the Radix Network.")
    /// Radix Wallet
    internal static let title = L10n.tr("Localizable", "homePage_title", fallback: "Radix Wallet")
    /// Total value
    internal static let totalValue = L10n.tr("Localizable", "homePage_totalValue", fallback: "Total value")
    internal enum AccountsTag {
      /// dApp Definition
      internal static let dAppDefinition = L10n.tr("Localizable", "homePage_accountsTag_dAppDefinition", fallback: "dApp Definition")
      /// Ledger
      internal static let ledgerBabylon = L10n.tr("Localizable", "homePage_accountsTag_ledgerBabylon", fallback: "Ledger")
      /// Legacy (Ledger)
      internal static let ledgerLegacy = L10n.tr("Localizable", "homePage_accountsTag_ledgerLegacy", fallback: "Legacy (Ledger)")
      /// Legacy
      internal static let legacySoftware = L10n.tr("Localizable", "homePage_accountsTag_legacySoftware", fallback: "Legacy")
    }
    internal enum DeletedAccountWarning {
      /// Your Radix Wallet is syncing, and removing the Account from view.
      internal static let message = L10n.tr("Localizable", "homePage_deletedAccountWarning_message", fallback: "Your Radix Wallet is syncing, and removing the Account from view.")
      /// Previously Deleted Account Detected
      internal static let title = L10n.tr("Localizable", "homePage_deletedAccountWarning_title", fallback: "Previously Deleted Account Detected")
    }
    internal enum ProfileOlympiaError {
      /// Affected Accounts
      internal static let affectedAccounts = L10n.tr("Localizable", "homePage_profileOlympiaError_affectedAccounts", fallback: "Affected Accounts")
      /// Affected Personas
      internal static let affectedPersonas = L10n.tr("Localizable", "homePage_profileOlympiaError_affectedPersonas", fallback: "Affected Personas")
      /// OK (%d)
      internal static func okCountdown(_ p1: Int) -> String {
        return L10n.tr("Localizable", "homePage_profileOlympiaError_okCountdown", p1, fallback: "OK (%d)")
      }
      /// Your wallet is in a rare condition that must be resolved manually. Please email support at hello@radixdlt.com with subject line BDFS ERROR. Somebody will respond and help you resolve the issue safely.
      internal static let subtitle = L10n.tr("Localizable", "homePage_profileOlympiaError_subtitle", fallback: "Your wallet is in a rare condition that must be resolved manually. Please email support at hello@radixdlt.com with subject line BDFS ERROR. Somebody will respond and help you resolve the issue safely.")
      /// SERIOUS ERROR - PLEASE READ
      internal static let title = L10n.tr("Localizable", "homePage_profileOlympiaError_title", fallback: "SERIOUS ERROR - PLEASE READ")
    }
    internal enum RadixBanner {
      /// Get Started Now
      internal static let action = L10n.tr("Localizable", "homePage_radixBanner_action", fallback: "Get Started Now")
      /// Complete setting up your wallet and start staking, using dApps and more!
      internal static let subtitle = L10n.tr("Localizable", "homePage_radixBanner_subtitle", fallback: "Complete setting up your wallet and start staking, using dApps and more!")
      /// Start Using Radix
      internal static let title = L10n.tr("Localizable", "homePage_radixBanner_title", fallback: "Start Using Radix")
    }
    internal enum SecureFolder {
      /// Your wallet has encountered a problem that should be resolved before you continue use. If you have a Samsung phone, this may be caused by putting the Radix Wallet in the "Secure Folder". Please contact support at hello@radixdlt.com for assistance.
      internal static let warning = L10n.tr("Localizable", "homePage_secureFolder_warning", fallback: "Your wallet has encountered a problem that should be resolved before you continue use. If you have a Samsung phone, this may be caused by putting the Radix Wallet in the \"Secure Folder\". Please contact support at hello@radixdlt.com for assistance.")
    }
    internal enum VisitDashboard {
      /// Ready to get started using the Radix Network and your Wallet?
      internal static let subtitle = L10n.tr("Localizable", "homePage_visitDashboard_subtitle", fallback: "Ready to get started using the Radix Network and your Wallet?")
      /// Visit the Radix Dashboard
      internal static let title = L10n.tr("Localizable", "homePage_visitDashboard_title", fallback: "Visit the Radix Dashboard")
    }
  }
  internal enum HomePageCarousel {
    internal enum ContinueOnDapp {
      /// You can now connect with your Radix Wallet. Tap to dismiss.
      internal static let text = L10n.tr("Localizable", "homePageCarousel_continueOnDapp_text", fallback: "You can now connect with your Radix Wallet. Tap to dismiss.")
      /// Continue on dApp in browser
      internal static let title = L10n.tr("Localizable", "homePageCarousel_continueOnDapp_title", fallback: "Continue on dApp in browser")
    }
    internal enum DiscoverRadix {
      /// Start RadQuest, learn about Radix, earn XRD and collectibles.
      internal static let text = L10n.tr("Localizable", "homePageCarousel_discoverRadix_text", fallback: "Start RadQuest, learn about Radix, earn XRD and collectibles.")
      /// Discover Radix. Get XRD
      internal static let title = L10n.tr("Localizable", "homePageCarousel_discoverRadix_title", fallback: "Discover Radix. Get XRD")
    }
    internal enum DiscoverRadixDapps {
      /// Start digging into Web3 dApps on the Radix Ecosystem directory.
      internal static let text = L10n.tr("Localizable", "homePageCarousel_discoverRadixDapps_text", fallback: "Start digging into Web3 dApps on the Radix Ecosystem directory.")
      /// Discover Radix dApps
      internal static let title = L10n.tr("Localizable", "homePageCarousel_discoverRadixDapps_title", fallback: "Discover Radix dApps")
    }
    internal enum RejoinRadquest {
      /// Continue your Radix journey in your browser. Tap to dismiss.
      internal static let text = L10n.tr("Localizable", "homePageCarousel_rejoinRadquest_text", fallback: "Continue your Radix journey in your browser. Tap to dismiss.")
      /// Rejoin RadQuest
      internal static let title = L10n.tr("Localizable", "homePageCarousel_rejoinRadquest_title", fallback: "Rejoin RadQuest")
    }
    internal enum UseDappsOnDesktop {
      /// Connect to dApps on the big screen with Radix Connector.
      internal static let text = L10n.tr("Localizable", "homePageCarousel_useDappsOnDesktop_text", fallback: "Connect to dApps on the big screen with Radix Connector.")
      /// Use dApps on Desktop
      internal static let title = L10n.tr("Localizable", "homePageCarousel_useDappsOnDesktop_title", fallback: "Use dApps on Desktop")
    }
  }
  internal enum IOSProfileBackup {
    /// Available backups:
    internal static let cloudBackupWallet = L10n.tr("Localizable", "iOSProfileBackup_cloudBackupWallet", fallback: "Available backups:")
    /// Backup created by: %@
    internal static func creatingDevice(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_creatingDevice", String(describing: p1), fallback: "Backup created by: %@")
    }
    /// Creation date: %@
    internal static func creationDateLabel(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_creationDateLabel", String(describing: p1), fallback: "Creation date: %@")
    }
    /// Import From Backup
    internal static let importBackupWallet = L10n.tr("Localizable", "iOSProfileBackup_importBackupWallet", fallback: "Import From Backup")
    /// Incompatible Wallet data
    internal static let incompatibleWalletDataLabel = L10n.tr("Localizable", "iOSProfileBackup_incompatibleWalletDataLabel", fallback: "Incompatible Wallet data")
    /// Last modified date: %@
    internal static func lastModifedDateLabel(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_lastModifedDateLabel", String(describing: p1), fallback: "Last modified date: %@")
    }
    /// Last used on device: %@
    internal static func lastUsedOnDeviceLabel(_ p1: Any) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_lastUsedOnDeviceLabel", String(describing: p1), fallback: "Last used on device: %@")
    }
    /// Wallet Data Backup
    internal static let navigationTitle = L10n.tr("Localizable", "iOSProfileBackup_navigationTitle", fallback: "Wallet Data Backup")
    /// Number of networks: %d
    internal static func numberOfNetworksLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_numberOfNetworksLabel", p1, fallback: "Number of networks: %d")
    }
    /// Unable to find wallet backup in iCloud.
    internal static let profileNotFoundInCloud = L10n.tr("Localizable", "iOSProfileBackup_profileNotFoundInCloud", fallback: "Unable to find wallet backup in iCloud.")
    /// Number of Accounts: %d
    internal static func totalAccountsNumberLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_totalAccountsNumberLabel", p1, fallback: "Number of Accounts: %d")
    }
    /// Number of Personas: %d
    internal static func totalPersonasNumberLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "iOSProfileBackup_totalPersonasNumberLabel", p1, fallback: "Number of Personas: %d")
    }
    /// Use iCloud Backup Data
    internal static let useICloudBackup = L10n.tr("Localizable", "iOSProfileBackup_useICloudBackup", fallback: "Use iCloud Backup Data")
    internal enum AutomaticBackups {
      /// Disable Backup to iCloud
      internal static let disable = L10n.tr("Localizable", "iOSProfileBackup_automaticBackups_disable", fallback: "Disable Backup to iCloud")
      /// Enable Backup to iCloud
      internal static let enable = L10n.tr("Localizable", "iOSProfileBackup_automaticBackups_enable", fallback: "Enable Backup to iCloud")
      /// Automatic continuous backups
      internal static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_automaticBackups_subtitle", fallback: "Automatic continuous backups")
    }
    internal enum ConfirmCloudSyncDisableAlert {
      /// Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?
      internal static let title = L10n.tr("Localizable", "iOSProfileBackup_confirmCloudSyncDisableAlert_title", fallback: "Disabling iCloud sync will delete the iCloud backup data, are you sure you want to disable iCloud sync?")
    }
    internal enum DeleteWallet {
      /// Delete Wallet and iCloud Backup
      internal static let confirmButton = L10n.tr("Localizable", "iOSProfileBackup_deleteWallet_confirmButton", fallback: "Delete Wallet and iCloud Backup")
      /// You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any iCloud backup.
      /// 
      /// **Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**
      internal static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_deleteWallet_subtitle", fallback: "You may delete your wallet. This will clear the Radix Wallet app, clears its contents, and delete any iCloud backup.\n\n**Access to any Accounts or Personas will be permanently lost unless you have a manual backup file.**")
    }
    internal enum ICloudSyncEnabledAlert {
      /// iCloud sync is now enabled, but it might take up to an hour before your wallet data is uploaded to iCloud.
      internal static let message = L10n.tr("Localizable", "iOSProfileBackup_iCloudSyncEnabledAlert_message", fallback: "iCloud sync is now enabled, but it might take up to an hour before your wallet data is uploaded to iCloud.")
      /// Enabling iCloud sync
      internal static let title = L10n.tr("Localizable", "iOSProfileBackup_iCloudSyncEnabledAlert_title", fallback: "Enabling iCloud sync")
    }
    internal enum ProfileSync {
      /// Warning: If disabled you might lose access to your Accounts and Personas.
      internal static let subtitle = L10n.tr("Localizable", "iOSProfileBackup_profileSync_subtitle", fallback: "Warning: If disabled you might lose access to your Accounts and Personas.")
      /// Sync Wallet Data to iCloud
      internal static let title = L10n.tr("Localizable", "iOSProfileBackup_profileSync_title", fallback: "Sync Wallet Data to iCloud")
    }
  }
  internal enum ImportMnemonic {
    /// Advanced Mode
    internal static let advancedModeButton = L10n.tr("Localizable", "importMnemonic_advancedModeButton", fallback: "Advanced Mode")
    /// Incorrect seed phrase
    internal static let checksumFailure = L10n.tr("Localizable", "importMnemonic_checksumFailure", fallback: "Incorrect seed phrase")
    /// Failed to validate all accounts against mnemonic
    internal static let failedToValidateAllAccounts = L10n.tr("Localizable", "importMnemonic_failedToValidateAllAccounts", fallback: "Failed to validate all accounts against mnemonic")
    /// Import
    internal static let importSeedPhrase = L10n.tr("Localizable", "importMnemonic_importSeedPhrase", fallback: "Import")
    /// Import Seed Phrase
    internal static let navigationTitle = L10n.tr("Localizable", "importMnemonic_navigationTitle", fallback: "Import Seed Phrase")
    /// Backup Seed Phrase
    internal static let navigationTitleBackup = L10n.tr("Localizable", "importMnemonic_navigationTitleBackup", fallback: "Backup Seed Phrase")
    /// Number of Seed Phrase Words
    internal static let numberOfWordsPicker = L10n.tr("Localizable", "importMnemonic_numberOfWordsPicker", fallback: "Number of Seed Phrase Words")
    /// Passphrase
    internal static let passphrase = L10n.tr("Localizable", "importMnemonic_passphrase", fallback: "Passphrase")
    /// Optional BIP39 Passphrase. This is not your wallet password, and the Radix Desktop Wallet did not use a BIP39 passphrase. This is only to support import from other wallets that may have used one.
    internal static let passphraseHint = L10n.tr("Localizable", "importMnemonic_passphraseHint", fallback: "Optional BIP39 Passphrase. This is not your wallet password, and the Radix Desktop Wallet did not use a BIP39 passphrase. This is only to support import from other wallets that may have used one.")
    /// Passphrase
    internal static let passphrasePlaceholder = L10n.tr("Localizable", "importMnemonic_passphrasePlaceholder", fallback: "Passphrase")
    /// Regular Mode
    internal static let regularModeButton = L10n.tr("Localizable", "importMnemonic_regularModeButton", fallback: "Regular Mode")
    /// Imported Seed Phrase
    internal static let seedPhraseImported = L10n.tr("Localizable", "importMnemonic_seedPhraseImported", fallback: "Imported Seed Phrase")
    /// Success
    internal static let verificationSuccess = L10n.tr("Localizable", "importMnemonic_verificationSuccess", fallback: "Success")
    /// Word %d
    internal static func wordHeading(_ p1: Int) -> String {
      return L10n.tr("Localizable", "importMnemonic_wordHeading", p1, fallback: "Word %d")
    }
    /// Wrong mnemmonic
    internal static let wrongMnemonicHUD = L10n.tr("Localizable", "importMnemonic_wrongMnemonicHUD", fallback: "Wrong mnemmonic")
    internal enum BackedUpAlert {
      /// Yes, I have written it down
      internal static let confirmAction = L10n.tr("Localizable", "importMnemonic_backedUpAlert_confirmAction", fallback: "Yes, I have written it down")
      /// Are you sure you have securely written down this seed phrase? You will need it to recover access if you lose your phone.
      internal static let message = L10n.tr("Localizable", "importMnemonic_backedUpAlert_message", fallback: "Are you sure you have securely written down this seed phrase? You will need it to recover access if you lose your phone.")
      /// No, not yet
      internal static let noAction = L10n.tr("Localizable", "importMnemonic_backedUpAlert_noAction", fallback: "No, not yet")
      /// Confirm Seed Phrase Saved
      internal static let title = L10n.tr("Localizable", "importMnemonic_backedUpAlert_title", fallback: "Confirm Seed Phrase Saved")
    }
    internal enum OffDevice {
      /// Without revealing location, vague hint on where this mnemonic is backed up, if anywhere.
      internal static let locationHint = L10n.tr("Localizable", "importMnemonic_offDevice_locationHint", fallback: "Without revealing location, vague hint on where this mnemonic is backed up, if anywhere.")
      /// In that book my mother used to read to me at my best childhoods summer vacation place
      internal static let locationPlaceholder = L10n.tr("Localizable", "importMnemonic_offDevice_locationPlaceholder", fallback: "In that book my mother used to read to me at my best childhoods summer vacation place")
      /// Backup location?
      internal static let locationPrimaryHeading = L10n.tr("Localizable", "importMnemonic_offDevice_locationPrimaryHeading", fallback: "Backup location?")
      /// Save with description
      internal static let saveWithDescription = L10n.tr("Localizable", "importMnemonic_offDevice_saveWithDescription", fallback: "Save with description")
      /// Save without description
      internal static let saveWithoutDescription = L10n.tr("Localizable", "importMnemonic_offDevice_saveWithoutDescription", fallback: "Save without description")
      /// Without revealing the words, what comes to mind when reading this seed phrase?
      internal static let storyHint = L10n.tr("Localizable", "importMnemonic_offDevice_storyHint", fallback: "Without revealing the words, what comes to mind when reading this seed phrase?")
      /// Hitchcock's The Birds mixed with Office space
      internal static let storyPlaceholder = L10n.tr("Localizable", "importMnemonic_offDevice_storyPlaceholder", fallback: "Hitchcock's The Birds mixed with Office space")
      /// Tell a story
      internal static let storyPrimaryHeading = L10n.tr("Localizable", "importMnemonic_offDevice_storyPrimaryHeading", fallback: "Tell a story")
    }
    internal enum ShieldPrompt {
      /// Please write down seed phrase to ensure Account control
      internal static let backupSeedPhrase = L10n.tr("Localizable", "importMnemonic_shieldPrompt_backupSeedPhrase", fallback: "Please write down seed phrase to ensure Account control")
      /// Enter this Account's seed phrase
      internal static let enterSeedPhrase = L10n.tr("Localizable", "importMnemonic_shieldPrompt_enterSeedPhrase", fallback: "Enter this Account's seed phrase")
    }
    internal enum TempAndroid {
      /// Change seed phrase length
      internal static let changeSeedPhrase = L10n.tr("Localizable", "importMnemonic_tempAndroid_changeSeedPhrase", fallback: "Change seed phrase length")
      /// Recover Mnemonic
      internal static let heading = L10n.tr("Localizable", "importMnemonic_tempAndroid_heading", fallback: "Recover Mnemonic")
      /// %d word seed phrase
      internal static func seedLength(_ p1: Int) -> String {
        return L10n.tr("Localizable", "importMnemonic_tempAndroid_seedLength", p1, fallback: "%d word seed phrase")
      }
    }
  }
  internal enum ImportOlympiaAccounts {
    /// Already imported
    internal static let alreadyImported = L10n.tr("Localizable", "importOlympiaAccounts_alreadyImported", fallback: "Already imported")
    /// BIP39 passphrase
    internal static let bip39passphrase = L10n.tr("Localizable", "importOlympiaAccounts_bip39passphrase", fallback: "BIP39 passphrase")
    /// Import
    internal static let importLabel = L10n.tr("Localizable", "importOlympiaAccounts_importLabel", fallback: "Import")
    /// Invalid Mnemonic
    internal static let invalidMnemonic = L10n.tr("Localizable", "importOlympiaAccounts_invalidMnemonic", fallback: "Invalid Mnemonic")
    /// Invalid QR code
    internal static let invalidPayload = L10n.tr("Localizable", "importOlympiaAccounts_invalidPayload", fallback: "Invalid QR code")
    /// No mnemonic found for accounts
    internal static let noMnemonicFound = L10n.tr("Localizable", "importOlympiaAccounts_noMnemonicFound", fallback: "No mnemonic found for accounts")
    /// No new accounts were found on this Ledger device
    internal static let noNewAccounts = L10n.tr("Localizable", "importOlympiaAccounts_noNewAccounts", fallback: "No new accounts were found on this Ledger device")
    /// Passphrase
    internal static let passphrase = L10n.tr("Localizable", "importOlympiaAccounts_passphrase", fallback: "Passphrase")
    /// Seed phrase
    internal static let seedPhrase = L10n.tr("Localizable", "importOlympiaAccounts_seedPhrase", fallback: "Seed phrase")
    internal enum AccountsToImport {
      /// Import %d accounts
      internal static func buttonManyAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_buttonManyAccounts", p1, fallback: "Import %d accounts")
      }
      /// Import 1 account
      internal static let buttonOneAcccount = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_buttonOneAcccount", fallback: "Import 1 account")
      /// Ledger (Legacy)
      internal static let ledgerAccount = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_ledgerAccount", fallback: "Ledger (Legacy)")
      /// Legacy Account
      internal static let legacyAccount = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_legacyAccount", fallback: "Legacy Account")
      /// New Address
      internal static let newAddressLabel = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_newAddressLabel", fallback: "New Address")
      /// Olympia Address (Obsolete)
      internal static let olympiaAddressLabel = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_olympiaAddressLabel", fallback: "Olympia Address (Obsolete)")
      /// The following accounts will be imported into this Radix Wallet.
      internal static let subtitle = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_subtitle", fallback: "The following accounts will be imported into this Radix Wallet.")
      /// Import Accounts
      internal static let title = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_title", fallback: "Import Accounts")
      /// Unnamed
      internal static let unnamed = L10n.tr("Localizable", "importOlympiaAccounts_accountsToImport_unnamed", fallback: "Unnamed")
    }
    internal enum Completion {
      /// Continue to Account List
      internal static let accountListButtonTitle = L10n.tr("Localizable", "importOlympiaAccounts_completion_accountListButtonTitle", fallback: "Continue to Account List")
      /// Your Accounts live on the Radix Network and you can access them anytime in your Wallet.
      internal static let explanation = L10n.tr("Localizable", "importOlympiaAccounts_completion_explanation", fallback: "Your Accounts live on the Radix Network and you can access them anytime in your Wallet.")
      /// You've now imported these Accounts:
      internal static let subtitleMultiple = L10n.tr("Localizable", "importOlympiaAccounts_completion_subtitleMultiple", fallback: "You've now imported these Accounts:")
      /// You've now imported this Account:
      internal static let subtitleSingle = L10n.tr("Localizable", "importOlympiaAccounts_completion_subtitleSingle", fallback: "You've now imported this Account:")
      /// Congratulations
      internal static let title = L10n.tr("Localizable", "importOlympiaAccounts_completion_title", fallback: "Congratulations")
    }
    internal enum ScanQR {
      /// Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.
      internal static let instructions = L10n.tr("Localizable", "importOlympiaAccounts_scanQR_instructions", fallback: "Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.")
      /// Scanned: %d/%d
      internal static func scannedLabel(_ p1: Int, _ p2: Int) -> String {
        return L10n.tr("Localizable", "importOlympiaAccounts_scanQR_scannedLabel", p1, p2, fallback: "Scanned: %d/%d")
      }
      /// Import Legacy Olympia Accounts
      internal static let title = L10n.tr("Localizable", "importOlympiaAccounts_scanQR_title", fallback: "Import Legacy Olympia Accounts")
    }
    internal enum VerifySeedPhrase {
      /// Do not throw away this seed phrase! You will still need it if you need to recover access to your Olympia accounts in the future.
      internal static let keepSeedPhrasePrompt = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_keepSeedPhrasePrompt", fallback: "Do not throw away this seed phrase! You will still need it if you need to recover access to your Olympia accounts in the future.")
      /// I Understand
      internal static let keepSeedPhrasePromptConfirmation = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_keepSeedPhrasePromptConfirmation", fallback: "I Understand")
      /// Warning
      internal static let keepSeedPhraseTitle = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_keepSeedPhraseTitle", fallback: "Warning")
      /// To complete importing your accounts, please view your seed phrase in the Radix Desktop Wallet and enter the words here.
      internal static let subtitle = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_subtitle", fallback: "To complete importing your accounts, please view your seed phrase in the Radix Desktop Wallet and enter the words here.")
      /// Verify With Your Seed Phrase
      internal static let title = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_title", fallback: "Verify With Your Seed Phrase")
      /// This will give this Radix Wallet control of your accounts. Never give your seed phrase to anyone for any reason.
      internal static let warning = L10n.tr("Localizable", "importOlympiaAccounts_verifySeedPhrase_warning", fallback: "This will give this Radix Wallet control of your accounts. Never give your seed phrase to anyone for any reason.")
    }
  }
  internal enum ImportOlympiaLedgerAccounts {
    /// Accounts remaining to verify: %d
    internal static func accountCount(_ p1: Int) -> String {
      return L10n.tr("Localizable", "importOlympiaLedgerAccounts_accountCount", p1, fallback: "Accounts remaining to verify: %d")
    }
    /// Continue
    internal static let continueButtonTitle = L10n.tr("Localizable", "importOlympiaLedgerAccounts_continueButtonTitle", fallback: "Continue")
    /// Connect your next Ledger device, launch the Radix Babylon app on it, and tap Continue here.
    internal static let instruction = L10n.tr("Localizable", "importOlympiaLedgerAccounts_instruction", fallback: "Connect your next Ledger device, launch the Radix Babylon app on it, and tap Continue here.")
    /// Already verified Ledger devices:
    internal static let listHeading = L10n.tr("Localizable", "importOlympiaLedgerAccounts_listHeading", fallback: "Already verified Ledger devices:")
    /// You are attempting to import one or more Olympia accounts that must be verified with a Ledger hardware wallet device.
    internal static let subtitle = L10n.tr("Localizable", "importOlympiaLedgerAccounts_subtitle", fallback: "You are attempting to import one or more Olympia accounts that must be verified with a Ledger hardware wallet device.")
    /// Verify With Ledger Device
    internal static let title = L10n.tr("Localizable", "importOlympiaLedgerAccounts_title", fallback: "Verify With Ledger Device")
  }
  internal enum InfoLink {
    internal enum Glossary {
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
      internal static let accounts = L10n.tr("Localizable", "infoLink_glossary_accounts", fallback: "## Radix Accounts\n\nAccounts are secure containers for any kind of digital asset on the [Radix Network](?glossaryAnchor=radixnetwork).\n\n---\n\nUnlike an account on a bank or other service, there is no company that controls your Radix Accounts for you. Your [Radix Wallet](?glossaryAnchor=radixwallet) app on your phone gives you direct access to your Accounts on the network, and can help you regain access to your Accounts if you lose your phone.\n\nCompared to accounts on other crypto networks, Radix Accounts are so much more clever, they’re sometimes called “Smart Accounts”.\n\n[Learn more about Smart Accounts](https://learn.radixdlt.com/article/what-are-smart-accounts) ↗\n\n[Read about Smart Account multi-factor and other features](https://www.radixdlt.com/blog/how-radix-multi-factor-smart-accounts-work-and-what-they-can-do) ↗")
      /// ## Arculus Card
      /// 
      /// Arculus Cards are secure third-party "hardware wallet" cryptographic signing devices in a convenient credit card form factor. To use it, you only need to tap it to the NFC reader on your phone.
      /// 
      /// Using a hardware signing device like an Arculus Card provides strong security because it requires physical access to the card to use it. If you use it in a [Security Shields](?glossaryAnchor=securityshields), you can combine it with other factors you have so that even if the card is lost or stolen, your funds are safe and you can reconfigure the Shield to remove the lost Arculus Card, and carry on as before. No seed phrase backup needed.
      internal static let arculus = L10n.tr("Localizable", "infoLink_glossary_arculus", fallback: "## Arculus Card\n\nArculus Cards are secure third-party \"hardware wallet\" cryptographic signing devices in a convenient credit card form factor. To use it, you only need to tap it to the NFC reader on your phone.\n\nUsing a hardware signing device like an Arculus Card provides strong security because it requires physical access to the card to use it. If you use it in a [Security Shields](?glossaryAnchor=securityshields), you can combine it with other factors you have so that even if the card is lost or stolen, your funds are safe and you can reconfigure the Shield to remove the lost Arculus Card, and carry on as before. No seed phrase backup needed.")
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
      internal static let badges = L10n.tr("Localizable", "infoLink_glossary_badges", fallback: "## Badges\n\nRadix Badges are tokens or NFTs that are used to prove their holder is authorized to claim something, access something or perform a certain action within the Radix Network. Any token on Radix can be used as a badge, but dApps may often create special tokens specifically for use as a badge.\n\n---\n\n[Tokens](?glossaryAnchor=tokens) and [NFTs](?glossaryAnchor=nfts) can represent almost anything. The [Radix Network](?glossaryAnchor=radixnetwork) makes it possible to use ownership of a token or NFT to authorize the holder to access to certain [dApp](?glossaryAnchor=dapps) functionality. Tokens or NFTs used in this way are referred to as “badges”, indicating that only the holder of the badge can use it for authorization.\n\nWhen a badge is used to authorize access in a [transaction](?glossaryAnchor=transactions), you will see it listed in the [Radix Wallet’s](?glossaryAnchor=radixwallet) summary of the transaction under “presenting”. The badge isn’t being sent anywhere; all that’s happening is that you are providing proof that you own the badge.\n\n[Learn more about Radix badges](https://learn.radixdlt.com/article/whats-a-badge) ↗")
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
      /// 
      /// [Learn more about the asset behaviors ↗](https://learn.radixdlt.com/article/what-are-radix-asset-behaviors)
      internal static let behaviors = L10n.tr("Localizable", "infoLink_glossary_behaviors", fallback: "## Asset Behaviors\n\nAsset behaviors define the rules that were placed on a [token](?glossaryAnchor=tokens) or [NFT](?glossaryAnchor=nfts) when it was created. They ensure all users know exactly what actions can be performed on any asset. And they’re labeled in everyday language so everyone can read them, understand them and know the nature of the asset they’re holding.\n\n---\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) is built differently to all other blockchains. One of the great benefits of this is that assets – tokens and NFTs – are native to the ecosystem. So unlike on networks such as Ethereum, where tokens are not really tokens but just balances on a smart contract, assets on Radix act like real-life assets. With real-life assets of different kinds, you know who can create it, destory it, take it away from you or freeze it within your bank account. Similarly with Radix, you’ll always know how assets will behave and what someone can do to them.\n\nWhen anyone creates a token or NFT on Radix, there is a list of behaviors they can apply to them. Things like being able to increase the token’s supply, being able to change an NFT’s image and description, or being able to remove a token from someone’s account. There are plenty of valid reasons for why someone might want to do these things, but it’s always good to know if they can. \n\nJust tap into any token in the Radix Wallet to get a full list of its behaviors.\n\n[Learn more about the asset behaviors ↗](https://learn.radixdlt.com/article/what-are-radix-asset-behaviors)")
      /// ## Biometrics/PIN
      /// 
      /// A biometrics/PIN factor is a 24-word seed phrase protected and accessed via your phone's biometrics or PIN security feature. Unlike most crypto wallets, there isn't a single seed phrase controlling all of your stuff – it's just 1 type of factor you can use to protect [Accounts](?glossaryAnchor=accounts) and [Personas](?glossaryAnchor=personas) or use as part of multi-factor [Security Shields](?glossaryAnchor=securityshields).
      /// 
      /// Because this is the only kind of factor held on your phone, it won't automatically transfer if you move to a different phone with your [Radix Wallet](?glossaryAnchor=radixwallet). Using a Security Shield for your Accounts and Personas enables easy transfer of wallet control without having to write down and enter a seed phrase. If you create Accounts or Personas with a biometrics/PIN factor, and you don't apply a Security Shield, you'll need to enter the seed phrase to recover access on a different phone.
      internal static let biometricspin = L10n.tr("Localizable", "infoLink_glossary_biometricspin", fallback: "## Biometrics/PIN\n\nA biometrics/PIN factor is a 24-word seed phrase protected and accessed via your phone's biometrics or PIN security feature. Unlike most crypto wallets, there isn't a single seed phrase controlling all of your stuff – it's just 1 type of factor you can use to protect [Accounts](?glossaryAnchor=accounts) and [Personas](?glossaryAnchor=personas) or use as part of multi-factor [Security Shields](?glossaryAnchor=securityshields).\n\nBecause this is the only kind of factor held on your phone, it won't automatically transfer if you move to a different phone with your [Radix Wallet](?glossaryAnchor=radixwallet). Using a Security Shield for your Accounts and Personas enables easy transfer of wallet control without having to write down and enter a seed phrase. If you create Accounts or Personas with a biometrics/PIN factor, and you don't apply a Security Shield, you'll need to enter the seed phrase to recover access on a different phone.")
      /// ## Bridging
      /// 
      /// Bridging is the process of getting assets into and out of the [Radix Network](?glossaryAnchor=radixnetwork). Assets on Radix can be held by your [Radix Wallet](?glossaryAnchor=radixnetwork), and used with [dApps](?glossaryAnchor=dapps) on Radix. There are a variety of dApps that provide bridging in different ways, for different assets.
      /// 
      /// Sometimes bridging involves converting an asset into a different form that can live on Radix. For example, dollars (USD) in your bank account might be bridged into Radix and become xUSDC tokens in your Radix Wallet. Or your Bitcoin (BTC) might be bridged into xwBTC tokens.
      /// 
      /// Sometimes bridging works as a swap, similar to a [DEX](?glossaryAnchor=dex). In this case you might swap one asset outside Radix for a different asset within Radix. Maybe you swap ETH (on the Ethereum network) for XRD tokens (on the Radix Network) at a current market price.
      internal static let bridging = L10n.tr("Localizable", "infoLink_glossary_bridging", fallback: "## Bridging\n\nBridging is the process of getting assets into and out of the [Radix Network](?glossaryAnchor=radixnetwork). Assets on Radix can be held by your [Radix Wallet](?glossaryAnchor=radixnetwork), and used with [dApps](?glossaryAnchor=dapps) on Radix. There are a variety of dApps that provide bridging in different ways, for different assets.\n\nSometimes bridging involves converting an asset into a different form that can live on Radix. For example, dollars (USD) in your bank account might be bridged into Radix and become xUSDC tokens in your Radix Wallet. Or your Bitcoin (BTC) might be bridged into xwBTC tokens.\n\nSometimes bridging works as a swap, similar to a [DEX](?glossaryAnchor=dex). In this case you might swap one asset outside Radix for a different asset within Radix. Maybe you swap ETH (on the Ethereum network) for XRD tokens (on the Radix Network) at a current market price.")
      /// ## How your Security Shield is Built
      /// 
      /// A good [Security Shield](?glossaryAnchor=securityshields) combines safety and reliability. No one else should be able to access it and even if you lose your phone you should always be able to recover access to your [Accounts](?glossaryAnchor=accounts) and [Personas](?glossaryAnchor=personas).
      /// 
      /// Your [Radix Wallet](?glossaryAnchor=radixwallet) will help you by suggesting a good Shield configuration once you’ve added the required security factors. Once this is done, you can edit it to suit your requirements and the Radix Wallet has 3 rules in place to ensure those edits don't make your Shield unsafe or innaccessible.
      /// 
      /// 1. [Password](?glossaryAnchor=passwords) cannot be used alone. They are useful factors but aren't secure enough to be used by themselves.
      /// 2. To make sure you won't lose access if you lose 1 of your factors, you must always have at least 2 factors options to start a Shield recovery.
      /// 3. To make sure nobody can take away your Shield by stealing just 1 factor, if you are only using 1 factor for regular access, you cannot use that factor again for recovery. And you also cannot use the same factor to both start and confirm a recovery.
      /// 
      /// Once you've finalized the setup of factors for a Shield, you’ll be ready to apply it to your chosen Accounts and Personas on the [Radix Network](?glossaryAnchor=radixnetwork) with 1 or more [transactions](?glossaryAnchor=transactions).
      internal static let buildingshield = L10n.tr("Localizable", "infoLink_glossary_buildingshield", fallback: "## How your Security Shield is Built\n\nA good [Security Shield](?glossaryAnchor=securityshields) combines safety and reliability. No one else should be able to access it and even if you lose your phone you should always be able to recover access to your [Accounts](?glossaryAnchor=accounts) and [Personas](?glossaryAnchor=personas).\n\nYour [Radix Wallet](?glossaryAnchor=radixwallet) will help you by suggesting a good Shield configuration once you’ve added the required security factors. Once this is done, you can edit it to suit your requirements and the Radix Wallet has 3 rules in place to ensure those edits don't make your Shield unsafe or innaccessible.\n\n1. [Password](?glossaryAnchor=passwords) cannot be used alone. They are useful factors but aren't secure enough to be used by themselves.\n2. To make sure you won't lose access if you lose 1 of your factors, you must always have at least 2 factors options to start a Shield recovery.\n3. To make sure nobody can take away your Shield by stealing just 1 factor, if you are only using 1 factor for regular access, you cannot use that factor again for recovery. And you also cannot use the same factor to both start and confirm a recovery.\n\nOnce you've finalized the setup of factors for a Shield, you’ll be ready to apply it to your chosen Accounts and Personas on the [Radix Network](?glossaryAnchor=radixnetwork) with 1 or more [transactions](?glossaryAnchor=transactions).")
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
      internal static let claimnfts = L10n.tr("Localizable", "infoLink_glossary_claimnfts", fallback: "## Stake Claim NFTs\n\nStake claim [NFTs](?glossaryAnchor=NFTs) are tokens that represent a quantity of unstaked XRD that the user can claim from a [validator](?glossaryAnchor=validators) to receive back [XRD](?glossaryAnchor=xrd).\n\n---\n\nAfter a user requests an unstake using a quantity of [liquid stake units](?glossaryAnchor=liquidstakeunits), they receive a stake claim NFT that represents the quantity and validator of that particular unstake request. Like LSUs, stake claim NFTs are freely transferable.\n\nAfter the require unstaking delay is over, the user can do a special claim transaction to return the stake claim NFT to the validator and receive the amount of XRD due.\n\n[Learn how to Stake and Unstake XRD](https://learn.radixdlt.com/article/how-to-stake-and-unstake-xrd) ↗")
      /// ## √ Connect Button
      /// 
      /// [dApps](?glossaryAnchor=dapps) built on Radix should always include a button marked **√ Connect**. Start here to connect your [Radix Wallet](?glossaryAnchor=radixwallet) to the dApp.
      /// 
      /// In most cases, the √ Connect button will include a menu where you can Connect Now, often asking your Radix Wallet to log in with a Persona. After logging in, that menu should provide a variety of features and information to help you manage your login and sharing with that dApp.
      internal static let connectbutton = L10n.tr("Localizable", "infoLink_glossary_connectbutton", fallback: "## √ Connect Button\n\n[dApps](?glossaryAnchor=dapps) built on Radix should always include a button marked **√ Connect**. Start here to connect your [Radix Wallet](?glossaryAnchor=radixwallet) to the dApp.\n\nIn most cases, the √ Connect button will include a menu where you can Connect Now, often asking your Radix Wallet to log in with a Persona. After logging in, that menu should provide a variety of features and information to help you manage your login and sharing with that dApp.")
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
      internal static let dapps = L10n.tr("Localizable", "infoLink_glossary_dapps", fallback: "## dApps\n\nDecentralized applications, or dApps, are basically any application that makes use of web3 features.\n\n---\n\nIn web3, users control their own digital assets and identity. That’s much different from typical webpages and other apps today. For example, to access your money, you have to do it through a banking or payments app. Your login to every website is owned by that website, or else you use something like your Google login, which is owned by Google.\n\nBut in web3, you can hold your money in an [account](?glossaryAnchor=accounts) that you control directly with a [wallet](?glossaryAnchor=radixwallet) app, and you can create your own [login](?glossaryAnchor=personas) in your wallet app and use that in many places.\n\nDoing things that way is “decentralized” – and it means that websites and applications need to be built specially to interact with wallet apps, self-owned accounts, and self-owned logins. That’s what makes them dApps.\n\nIn the end, web3 dApps can do many things that were never possible before. For example, a [decentralized exchange](?glossaryAnchor=dex) dApp can let you instantly swap between two different kinds of assets right from your wallet in just a tap.\n\n[Visit the Radix dApp Ecosystem Page](https://www.radixdlt.com/ecosystem) ↗")
      /// ## Radix Dashboard
      /// 
      /// The Radix Dashboard is a [dApp](?glossaryAnchor=dapps) created by the same team as the [Radix Wallet](?glossaryAnchor=radixwallet) to help users interact with the [Radix Network](?glossaryAnchor=radixnetwork) directly.
      /// 
      /// You can look up information about things on the Radix Network by entering its address, such as: Accounts, tokens, NFTs, components (smart contracts), and more.
      /// 
      /// You can also use the Radix Dashboard’s [network staking](?glossaryAnchor=networkstaking) feature to view the list of current Radix Network validators, stake XRD, and manage your existing network staking.
      /// 
      /// [Visit the Radix Dashboard](https://dashboard.radixdlt.com) ↗
      internal static let dashboard = L10n.tr("Localizable", "infoLink_glossary_dashboard", fallback: "## Radix Dashboard\n\nThe Radix Dashboard is a [dApp](?glossaryAnchor=dapps) created by the same team as the [Radix Wallet](?glossaryAnchor=radixwallet) to help users interact with the [Radix Network](?glossaryAnchor=radixnetwork) directly.\n\nYou can look up information about things on the Radix Network by entering its address, such as: Accounts, tokens, NFTs, components (smart contracts), and more.\n\nYou can also use the Radix Dashboard’s [network staking](?glossaryAnchor=networkstaking) feature to view the list of current Radix Network validators, stake XRD, and manage your existing network staking.\n\n[Visit the Radix Dashboard](https://dashboard.radixdlt.com) ↗")
      /// ## Decentralized Exchange (DEX)
      /// 
      /// A decentralized exchange, or “DEX” for short, is a [dApp](?glossaryAnchor=dapps) that offers something a bit like a much more powerful web3 version of a foreign currency exchange counter at the airport.
      /// 
      /// ---
      /// 
      /// A DEX dApp lets users do instant and fully automated swaps between a huge variety of tokens or other digital assets. The exchange logic runs right on the [Radix Network](?glossaryAnchor=radixnetwork) itself. This means that a DEX swap is done with a [transaction](?glossaryAnchor=transactions) and the [Radix Wallet](?glossaryAnchor=radixwallet) can show you exactly what’s going to happen, and let you apply [deposit guarantees](?glossaryAnchor=guarantees) to the results.
      /// 
      /// [Learn more about DEX dApps](https://learn.radixdlt.com/article/whats-a-dex) ↗
      internal static let dex = L10n.tr("Localizable", "infoLink_glossary_dex", fallback: "## Decentralized Exchange (DEX)\n\nA decentralized exchange, or “DEX” for short, is a [dApp](?glossaryAnchor=dapps) that offers something a bit like a much more powerful web3 version of a foreign currency exchange counter at the airport.\n\n---\n\nA DEX dApp lets users do instant and fully automated swaps between a huge variety of tokens or other digital assets. The exchange logic runs right on the [Radix Network](?glossaryAnchor=radixnetwork) itself. This means that a DEX swap is done with a [transaction](?glossaryAnchor=transactions) and the [Radix Wallet](?glossaryAnchor=radixwallet) can show you exactly what’s going to happen, and let you apply [deposit guarantees](?glossaryAnchor=guarantees) to the results.\n\n[Learn more about DEX dApps](https://learn.radixdlt.com/article/whats-a-dex) ↗")
      /// ## Gateways
      /// 
      /// A gateway is your pathway to connect to the [Radix Network](?glossaryAnchor=radixnetwork) – it enables users to communicate with the Radix Network and transfer data to and from it. 
      /// 
      /// ---
      /// 
      /// You can add additional gateways in your Radix Wallet and switch between them. Each gateway will connect your wallet to a particular network. The Radix Network (known as “mainnet”) is the primary network where all real assets, including the real XRD of value, are located. However a gateway might target a test network (like “Stokenet”) where developers can experiment with updates and new features before they go live on Bablyon. None of the assets on these test networks, including XRD, have any value.
      /// 
      /// The [Radix Wallet](?glossaryAnchor=radixwallet) comes automatically connected to a Radix Network mainnet gateway operated by the creators of the Radix Wallet, but there are community-run gateways that users can choose to use as well. Because anyone can create a new gateway, third-party gateways should always be accessed with caution.
      internal static let gateways = L10n.tr("Localizable", "infoLink_glossary_gateways", fallback: "## Gateways\n\nA gateway is your pathway to connect to the [Radix Network](?glossaryAnchor=radixnetwork) – it enables users to communicate with the Radix Network and transfer data to and from it. \n\n---\n\nYou can add additional gateways in your Radix Wallet and switch between them. Each gateway will connect your wallet to a particular network. The Radix Network (known as “mainnet”) is the primary network where all real assets, including the real XRD of value, are located. However a gateway might target a test network (like “Stokenet”) where developers can experiment with updates and new features before they go live on Bablyon. None of the assets on these test networks, including XRD, have any value.\n\nThe [Radix Wallet](?glossaryAnchor=radixwallet) comes automatically connected to a Radix Network mainnet gateway operated by the creators of the Radix Wallet, but there are community-run gateways that users can choose to use as well. Because anyone can create a new gateway, third-party gateways should always be accessed with caution.")
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
      internal static let guarantees = L10n.tr("Localizable", "infoLink_glossary_guarantees", fallback: "## Deposit Guarantees\n\nSome Radix [transactions](?glossaryAnchor=transactions) may have unpredictable results. In these cases, deposit guarantees make sure you never get less than you expect when you do a transaction.\n\n---\n\nFor example, the result of a swap between assets using a [DEX](?glossaryAnchor=dex) depends on a current market price of the assets involved. You may see one price when considering the swap, but it typically changes by the time the network processes it. Deposit guarantees protect you by letting you specify a minimum amount that must be deposited to your account at the end of the swap transaction.\n\nTo make this possible, the [Radix Network](?glossaryAnchor=radixnetwork) app and [Radix Wallet](?glossaryAnchor=radixwallet) work together. The wallet will show you whenever a deposit to your account is “estimated” rather than of a known quantity. And whenever that's true, you can set your own “guarantees” in the wallet on those estimated deposits – putting a limit on how much you expect to get for you to be willing to go through with the transaction. If that guarantee isn't met at the time the transaction is processed, the deal is off! The transaction is rejected by the Radix Network and no assets change hands.\n\n[Learn more about deposit guarantees](https://learn.radixdlt.com/article/what-are-customizable-transaction-guarantees-on-radix) ↗")
      /// ## Ledger Nano
      /// 
      /// A Ledger Nano is a secure third-party "hardware wallet" cryptographic signing device popular with many crypto users. To use it, you need to connect it via USB to a computer with a linked [Radix Connector](?glossaryAnchor=radixconnector) browser extension. From here, you can approve signatures by following the Nano's on-screen instructions.
      /// 
      /// Using a hardware signing device like a Ledger Nano provides strong security because it requires physical access to the device to use it. If you use it in a [Security Shields](?glossaryAnchor=securityshields), you can combine it with other factors you have so that even if the device is lost or stolen, your funds are safe and you can reconfigure the Shield to remove the lost device from it. No seed phrase backup needed.
      internal static let ledgernano = L10n.tr("Localizable", "infoLink_glossary_ledgernano", fallback: "## Ledger Nano\n\nA Ledger Nano is a secure third-party \"hardware wallet\" cryptographic signing device popular with many crypto users. To use it, you need to connect it via USB to a computer with a linked [Radix Connector](?glossaryAnchor=radixconnector) browser extension. From here, you can approve signatures by following the Nano's on-screen instructions.\n\nUsing a hardware signing device like a Ledger Nano provides strong security because it requires physical access to the device to use it. If you use it in a [Security Shields](?glossaryAnchor=securityshields), you can combine it with other factors you have so that even if the device is lost or stolen, your funds are safe and you can reconfigure the Shield to remove the lost device from it. No seed phrase backup needed.")
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
      internal static let liquidstakeunits = L10n.tr("Localizable", "infoLink_glossary_liquidstakeunits", fallback: "## Liquid Stake Unit\n\nA liquid stake unit (LSU) is a type of token within the [Radix Network](?glossaryAnchor=radixnetwork) that represents the amount of [XRD](?glossaryAnchor=xrd) a user has staked to a certain validator. LSUs are freely transferable in Radix’s DeFi ecosystem and can be traded as assets.\n\n---\n\nWhenever a user stakes XRD to a validator, they receive an LSU in return that is specific to that validator. The amount of LSU represents the quantity of XRD stake to that validator, which will increase as new emissions are provided.\n\nBecause they're liquid, LSUs can be traded within the Radix Network like any other asset. The holder of the LSU can also redeem the XRD that they represent.\n\nTo request an unstake of XRD tokens, the user does a special transaction to send some LSU back to the validator component, which returns a [stake claim NFT](?glossaryAnchor=claimnfts) that can later be redeemed for the XRD after an unstaking delay.\n\n[Learn how to Stake and Unstake XRD](https://learn.radixdlt.com/article/how-to-stake-and-unstake-xrd) ↗")
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
      internal static let networkstaking = L10n.tr("Localizable", "infoLink_glossary_networkstaking", fallback: "## Radix Network Staking\n\nAn important feature of the [Radix Network](?glossaryAnchor=radixnetwork) is that users can “stake” [XRD tokens](?glossaryAnchor=xrd) to increase the security of the network, and be rewarded for doing so.\n\n---\n\nThe process involves choosing one or more [validators](?glossaryAnchor=validators) to stake to, and then doing a [transaction](?glossaryAnchor=transactions) to send some XRD to the network to support those validators. You can unstake the XRD later to get them back – and you’ll find that you accumulated extra XRD in the meantime.\n\nThe extra XRD you earn is proportional to how much XRD you stake, and is often called an “APY” (annual percentage yield).\n\nYou can stake, unstake, and check on your validators and APY returns using the [Radix Dashboard](?glossaryAnchor=dashboard) dApp.\n\nStaking is a great way to put your XRD to work and earn a return, but it’s **not simply free money**. Choosing validators is like voting for who will run the Radix Network. If you choose a bad validator, you might help slow down the network or even help attack it. And you might not get the APY you expect.\n\nGet started with the links below before you stake a meaningful amount of XRD.\n\n[Introduction to Radix staking](https://learn.radixdlt.com/article/start-here-radix-staking-introduction) ↗\n\n[Learn how to choose validators](https://learn.radixdlt.com/article/how-should-i-choose-validators-to-stake-to) ↗")
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
      internal static let nfts = L10n.tr("Localizable", "infoLink_glossary_nfts", fallback: "## Non-fungible Token (NFT)\n\nNon-fungible tokens are a special class of web3 [token](?glossaryAnchor=tokens) where each token has a unique identity.\n\nLike other tokens, they can represent many things. But NFTs are used to represent things where each is different from another, like pieces of art, loan positions, treasury bonds, tickets to assigned-seating events, collectible cards, or equipment in games.\n\n---\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) has special features specifically to make the creation and use of non-fungible tokens on Radix safe and predictable, and the [Radix Wallet](?glossaryAnchor=radixwallet) can automatically provide useful information about the NFTs you hold in your [Accounts](?glossaryAnchor=accounts).\n\n[Learn more about NFTs](https://learn.radixdlt.com/article/what-is-an-nft) ↗\n\n[Find out why tokens on Radix are better than other crypto networks](https://www.radixdlt.com/blog/its-10pm-do-you-know-where-your-tokens-are) ↗")
      /// ## Passphrases
      /// 
      /// A passphrase is a 24-word BIP39 seed phrase. Unlike with most crypto wallets though, it's a specific type of seed phrase that isn't held on your phone so it can't be accessed with the help of your phone's biometrics or PIN features. It must be typed in word by word every time you use it to sign [transactions](?glossaryAnchor=transactions). This means it must be written down and should be stored (ideally not electronically) in a secret location. For this reason, this factor source is best left to experienced users.
      /// 
      /// If you prefer to use a seed phrase held on this device for easy usage, like a typical crypto wallet, please see the [biometrics/PIN](?glossaryAnchor=biometricspin) factor type.
      internal static let passphrases = L10n.tr("Localizable", "infoLink_glossary_passphrases", fallback: "## Passphrases\n\nA passphrase is a 24-word BIP39 seed phrase. Unlike with most crypto wallets though, it's a specific type of seed phrase that isn't held on your phone so it can't be accessed with the help of your phone's biometrics or PIN features. It must be typed in word by word every time you use it to sign [transactions](?glossaryAnchor=transactions). This means it must be written down and should be stored (ideally not electronically) in a secret location. For this reason, this factor source is best left to experienced users.\n\nIf you prefer to use a seed phrase held on this device for easy usage, like a typical crypto wallet, please see the [biometrics/PIN](?glossaryAnchor=biometricspin) factor type.")
      /// ## Passwords
      /// 
      /// Password can be used as a type of security factor in the [Radix Wallet](?glossaryAnchor=radixwallet). A password can be useful to add additional security to your [Security Shields](?glossaryAnchor=securityshields) in combination with other factors. To be secure, your password must be at least 16-characters long and it should be impossible for someone else to guess. If you write it down, make sure you don't do this electronically and keep it stored in a safe place.
      /// 
      /// Passwords on Radix are different from normal passwords because they're decentralized. They're not held in a central server or even in your Radix Wallet app. Through some cryptographic magic, the [Radix Network](?glossaryAnchor=radixnetwork) itself can check if your password is correct without storing it. It's provides the security of [web3](?glossaryAnchor=web3) with the easy functionality of web2.
      internal static let passwords = L10n.tr("Localizable", "infoLink_glossary_passwords", fallback: "## Passwords\n\nPassword can be used as a type of security factor in the [Radix Wallet](?glossaryAnchor=radixwallet). A password can be useful to add additional security to your [Security Shields](?glossaryAnchor=securityshields) in combination with other factors. To be secure, your password must be at least 16-characters long and it should be impossible for someone else to guess. If you write it down, make sure you don't do this electronically and keep it stored in a safe place.\n\nPasswords on Radix are different from normal passwords because they're decentralized. They're not held in a central server or even in your Radix Wallet app. Through some cryptographic magic, the [Radix Network](?glossaryAnchor=radixnetwork) itself can check if your password is correct without storing it. It's provides the security of [web3](?glossaryAnchor=web3) with the easy functionality of web2.")
      /// ## Why your Accounts will be linked
      /// 
      /// Paying your transaction fee from this Account will make you identifiable on ledger as both the owner of the fee-paying Account and all other Accounts you use in this transaction.
      /// 
      /// This is because you’ll sign the transactions from each Account at the same time, so your Accounts will be linked together in the transaction record.
      internal static let payingaccount = L10n.tr("Localizable", "infoLink_glossary_payingaccount", fallback: "## Why your Accounts will be linked\n\nPaying your transaction fee from this Account will make you identifiable on ledger as both the owner of the fee-paying Account and all other Accounts you use in this transaction.\n\nThis is because you’ll sign the transactions from each Account at the same time, so your Accounts will be linked together in the transaction record.")
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
      internal static let personas = L10n.tr("Localizable", "infoLink_glossary_personas", fallback: "## Radix Personas\n\nPersonas are the web3 replacement for the old email address and password login. Using a Persona of your choice, you can securely log in to [dApps](?glossaryAnchor=dapps) built on Radix without having to remember a password at all.\n\n---\n\nUsing your [Radix Wallet](?glossaryAnchor=radixwallet) app, you can create as many Personas as you like. Personas can also hold pieces of your personal information - like name and email address - that dApps can request access to, if you want to give permission.\n\n[Learn more about Personas](https://learn.radixdlt.com/article/what-are-personas-and-identities) ↗\n\n[Find out how Personas are logins for the web3 era](https://www.radixdlt.com/blog/personas-logins-for-the-web3-era) ↗")
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
      internal static let poolunits = L10n.tr("Localizable", "infoLink_glossary_poolunits", fallback: "## Pool Units\n\nPool units are fungible [tokens](?glossaryAnchor=tokens) that represent the proportional size of a user's contribution to a liquidity pool\n\nPool units are redeemable for the user's portion of the pool but can also be traded, sold and used in DeFi applications.\n\n---\n\nLiquidity pools play an integral role in lending and swapping on DeFi platforms. They work by liquidity providers (LPs) contributing tokens to a pool, thus creating a market for people to lend, borrow and swap. In return, these LPs receive tokens to show they've made a contribution to the pool. LPs usually get rewarded for their contributions in the form of fees paid by the people using the DeFi platform to swap and borrow crypto, but there are other ways for them to earn revenue.\n\nWith other wallets on other blockchains, this process raises risks. Other wallets can’t tell an LP what the tokens they received for providing liquidity are worth. Other wallets can’t even be sure they are actually tokens that represent a portion of a pool or that the tokens are redeemable. They don’t provide any confidence.\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) solves this with a native package called a “pool”. This package automatically implements the logic of minting and burning pool units in the proportion to other LPs’ contributions. It also means your [Radix Wallet](?glossaryAnchor=radixwallet) can always read what your pool units are worth and ensures they’re always redeemable for tokens from the liquidity pool.\n\n[Learn more about pool units](https://learn.radixdlt.com/article/what-are-pool-units-or-native-lp-tokens) ↗")
      /// ## Possible dApp Calls
      /// 
      /// When a dApp requests a [pre-authorization](?glossaryAnchor=preauthorizations), you may see in the summary "possible dApp calls". This simply indicates that the dApp may add additional actions to your pre-authorization before submitting the transaction to the Radix Network.
      /// 
      /// Not to worry - you are only approving and signing what you can see in your wallet. Nothing added by the dApp can do anything with your accounts and assets without your knowledge.
      internal static let possibledappcalls = L10n.tr("Localizable", "infoLink_glossary_possibledappcalls", fallback: "## Possible dApp Calls\n\nWhen a dApp requests a [pre-authorization](?glossaryAnchor=preauthorizations), you may see in the summary \"possible dApp calls\". This simply indicates that the dApp may add additional actions to your pre-authorization before submitting the transaction to the Radix Network.\n\nNot to worry - you are only approving and signing what you can see in your wallet. Nothing added by the dApp can do anything with your accounts and assets without your knowledge.")
      /// ## Pre-authorizations
      /// 
      /// Pre-authorizations are a way for a [dApp](?glossaryAnchor=dapps) to request your authorization to do something specific with your accounts and assets. When you approve a pre-authorization, it is provided to the dApp which can use it to create a [transaction](?glossaryAnchor=transactions) on the Radix Network.
      /// 
      /// ---
      /// 
      /// A pre-authorization request looks very similar to a transaction request in your wallet. In both cases, you get to review exactly what's going to happen with your own accounts and assets.
      /// 
      /// However, after you sign a pre-authorization, it is not submitted directly to the Radix Network like a transaction request. Instead, it is provided back to the dApp that requested it. The dApp can then include that pre-authorization in a transaction that it creates and submits.
      /// 
      /// This makes it possible for dApps to do helpful things, such as:
      /// 
      /// • Pay the [transaction fees](?glossaryAnchor=transactionfee) for you.
      /// • Do transactions involving multiple people.
      /// • Mint a badge or NFT and directly deposit it to your account.
      /// 
      /// In all of these cases, the dApp still needs you to approve and sign any interactions with your accounts and assets - the Radix Network guarantees it.
      /// 
      /// Because the pre-authorization is provided back to the dApp, there is a time limit how long it lasts. Once this time limit is up, the pre-authorization expires and can't be used. A dApp will need to make a request for another one. You can see how long you have until your pre-authoirzation expires in the pre-authorization summary.
      internal static let preauthorizations = L10n.tr("Localizable", "infoLink_glossary_preauthorizations", fallback: "## Pre-authorizations\n\nPre-authorizations are a way for a [dApp](?glossaryAnchor=dapps) to request your authorization to do something specific with your accounts and assets. When you approve a pre-authorization, it is provided to the dApp which can use it to create a [transaction](?glossaryAnchor=transactions) on the Radix Network.\n\n---\n\nA pre-authorization request looks very similar to a transaction request in your wallet. In both cases, you get to review exactly what's going to happen with your own accounts and assets.\n\nHowever, after you sign a pre-authorization, it is not submitted directly to the Radix Network like a transaction request. Instead, it is provided back to the dApp that requested it. The dApp can then include that pre-authorization in a transaction that it creates and submits.\n\nThis makes it possible for dApps to do helpful things, such as:\n\n• Pay the [transaction fees](?glossaryAnchor=transactionfee) for you.\n• Do transactions involving multiple people.\n• Mint a badge or NFT and directly deposit it to your account.\n\nIn all of these cases, the dApp still needs you to approve and sign any interactions with your accounts and assets - the Radix Network guarantees it.\n\nBecause the pre-authorization is provided back to the dApp, there is a time limit how long it lasts. Once this time limit is up, the pre-authorization expires and can't be used. A dApp will need to make a request for another one. You can see how long you have until your pre-authoirzation expires in the pre-authorization summary.")
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
      internal static let radixconnect = L10n.tr("Localizable", "infoLink_glossary_radixconnect", fallback: "## Radix Connect\n\nRadix Connect is the technology that lets users connect their [Radix Wallet](?glossaryAnchor=radixwallet) to [dApps](?glossaryAnchor=dapps) in mobile or desktop web browsers – and even more places in the future.\n\n---\n\nTo use Radix Connect with desktop browsers, there is a simple one-time setup flow that links the Radix Wallet on mobile to a desktop browser using the [Radix Connector browser extension](?glossaryAnchor=radixconnector). This extension provides a QR code to scan with your Radix Wallet, which setting up a connection between your Radix Wallet and your desktop browser.\n\nThe connection is fully end-to-end encrypted and is also peer-to-peer, meaning there will be no centralized server holding your data or sending your messages back and forth.\n\nOn mobile, the process is even easier. dApps in your mobile browser can directly connect to your Radix Wallet app running on the same phone.\n\n[Learn more about Radix Connect](https://learn.radixdlt.com/article/what-is-radix-connect) ↗")
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
      internal static let radixconnector = L10n.tr("Localizable", "infoLink_glossary_radixconnector", fallback: "## Radix Connector Browser Extension\n\nWhen you want to use [dApp websites](?glossaryAnchor=dapps) on your desktop web browser, the Radix Connect browser extension helps make the connection to your [Radix Wallet](?glossaryAnchor=radixwallet) mobile app, quickly and securely.\n\n---\n\nAll you need to do is install it in your preferred desktop browser, link it to your Radix Wallet app via QR code, and it sits quietly in the background making the magic happen. It will also give you your list of [Accounts](?glossaryAnchor=accounts) for easy copying of addresses on desktop.\n\nTo download and set up the Radix Connector browser extension, visit **wallet.radixdlt.com** in your preferred desktop browser.\n\n[Learn more about the Radix Connector browser extension](https://learn.radixdlt.com/article/what-is-the-radix-connector-browser-extension) ↗")
      /// ## The Radix Network
      /// 
      /// Radix is an open network that makes [web3](?glossaryAnchor=web3) possible. Think of the Radix Network as a public place on the internet where users can directly control their own digital assets, and where those assets can move effortlessly between users and applications – without relying on any company.
      /// 
      /// ---
      /// 
      /// You can view and freely [transfer](?glossaryAnchor=transfers) your assets on the Radix Network using the [Radix Wallet](?glossaryAnchor=radixwallet) app. Applications built using the Radix Network’s capabilities (called [dApps](?glossaryAnchor=dapps) have the ability to interact with these assets and identities, letting you do things that weren't possible before on the web.
      /// 
      /// [Visit the official Radix homepage](https://radixdlt.com) ↗
      /// 
      /// [Learn more about the Radix Network](https://learn.radixdlt.com/article/what-are-the-radix-public-network-and-radix-ledger) ↗
      internal static let radixnetwork = L10n.tr("Localizable", "infoLink_glossary_radixnetwork", fallback: "## The Radix Network\n\nRadix is an open network that makes [web3](?glossaryAnchor=web3) possible. Think of the Radix Network as a public place on the internet where users can directly control their own digital assets, and where those assets can move effortlessly between users and applications – without relying on any company.\n\n---\n\nYou can view and freely [transfer](?glossaryAnchor=transfers) your assets on the Radix Network using the [Radix Wallet](?glossaryAnchor=radixwallet) app. Applications built using the Radix Network’s capabilities (called [dApps](?glossaryAnchor=dapps) have the ability to interact with these assets and identities, letting you do things that weren't possible before on the web.\n\n[Visit the official Radix homepage](https://radixdlt.com) ↗\n\n[Learn more about the Radix Network](https://learn.radixdlt.com/article/what-are-the-radix-public-network-and-radix-ledger) ↗")
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
      internal static let radixwallet = L10n.tr("Localizable", "infoLink_glossary_radixwallet", fallback: "## Radix Wallet\n\nThe Radix Wallet is an iOS and Android mobile app that is your gateway to the capabilities of the Radix Network.\n\n---\n\nIt helps you create and use [Accounts](?glossaryAnchor=accounts) that can hold all of your digital assets on Radix, and [Personas](?glossaryAnchor=personas) that you can use to securely log in to [dApps](?glossaryAnchor=dapps) built on Radix without a password.\n\nThe Radix Wallet also makes sure that you are always in control of [transactions](?glossaryAnchor=transactions) that interact with your Accounts and assets.\n\nThink of the Radix Wallet as your companion as you move between dApps on Radix – keeping your assets safe, and letting you choose who you are and what you bring with you on each dApp.\n\nThe Radix Wallet was created by the team who created the Radix Network’s technology, and is offered for free (and open-source) to let anyone use Radix and dApps built on Radix.\n\n[Get the Radix Wallet](https://wallet.radixdlt.com/) ↗\n\n[Learn more about the Radix Wallet](https://learn.radixdlt.com/article/what-is-the-radix-wallet) ↗")
      /// ## Security Shields
      /// 
      /// Security Shields give users multi-factor access to their [Accounts](?glossaryAnchor=accounts) and [Personas](?glossaryAnchor=personas) while maintaining decentralization and full self-custody. They provide 2 critical functions. They allow users to rely on more than 1 security factor for regular access and for recoveries in the event that another security factor is lost.
      /// 
      /// The process to create a Shield is simple and once it’s finished, it can be applied to Accounts and Personas on the [Radix Network](?glossaryAnchor=radixnetwork) itself, providing robust and reliable security without compromising true trustless decentralization. There are no central servers that hold your Security Shield or secret keys – on Radix, it’s all done on the blockchain directly, so you're always in control. It's "your keys, your crypto", but without being stuck with 1 key you can't change.
      /// 
      /// ---
      /// 
      /// Shields are made up of 2 groups of factors.
      /// 
      /// **Regular Access**
      /// 
      /// This part of your Security Shield defines the factors you'll use for normal usage, like signing [transactions](?glossaryAnchor=transactions) to withdrawing assets from your Accounts.
      /// 
      /// When choosing your factors for regular access, consider how often you’ll be using them. If it’s every day, choose ones you can access easily. A single factor can be used, but it's recommended to use more than one for additional security. For example, a [password](?glossaryAnchor=passwords) is an easy second factor to add security for more sensitive Accounts.
      /// 
      /// For convenience, you'll also choose a single factor you'll use to prove ownerhip – like when you log in to [dApps](?glossaryAnchor=dapps) or if they request access to your Accounts.
      /// 
      /// **Recovery**
      /// 
      /// This part of your Security Shield is made up of the factors that help you recover access to shielded Accounts and Personas in the event that you lose access to them or want to transfer control. For example, if you move your wallet to a new phone, you'll use the Shield's recovery feature to change the biometrics/PIN factor to a new one on your new phone.
      /// 
      /// You'll need to choose 1 or more factors that can start a recovery and 1 or more factors that can confirm the recovery. In most cases, you'll start and confirm the recovery in a single step, but in the worst case, a timed "emergency fallback" will let you start a recovery with just 1 factor and confirm it after a safe delay.
      /// 
      /// You can choose the time period for your emergency fallback factor. Make sure you choose a time period long enough that you'll be likely to open your [Radix Wallet](?glossaryAnchor=radixwallet) and cancel the recovery if anyone ever steals 1 of your factors and attempts to take control of your Accounts and Personas.
      /// 
      /// Your Radix Wallet will help you build your Security Shield and once it’s finished, you’ll need to sign some transactions to apply it on the Radix Network to the Accounts and Personas of your choice.
      internal static let securityshields = L10n.tr("Localizable", "infoLink_glossary_securityshields", fallback: "## Security Shields\n\nSecurity Shields give users multi-factor access to their [Accounts](?glossaryAnchor=accounts) and [Personas](?glossaryAnchor=personas) while maintaining decentralization and full self-custody. They provide 2 critical functions. They allow users to rely on more than 1 security factor for regular access and for recoveries in the event that another security factor is lost.\n\nThe process to create a Shield is simple and once it’s finished, it can be applied to Accounts and Personas on the [Radix Network](?glossaryAnchor=radixnetwork) itself, providing robust and reliable security without compromising true trustless decentralization. There are no central servers that hold your Security Shield or secret keys – on Radix, it’s all done on the blockchain directly, so you're always in control. It's \"your keys, your crypto\", but without being stuck with 1 key you can't change.\n\n---\n\nShields are made up of 2 groups of factors.\n\n**Regular Access**\n\nThis part of your Security Shield defines the factors you'll use for normal usage, like signing [transactions](?glossaryAnchor=transactions) to withdrawing assets from your Accounts.\n\nWhen choosing your factors for regular access, consider how often you’ll be using them. If it’s every day, choose ones you can access easily. A single factor can be used, but it's recommended to use more than one for additional security. For example, a [password](?glossaryAnchor=passwords) is an easy second factor to add security for more sensitive Accounts.\n\nFor convenience, you'll also choose a single factor you'll use to prove ownerhip – like when you log in to [dApps](?glossaryAnchor=dapps) or if they request access to your Accounts.\n\n**Recovery**\n\nThis part of your Security Shield is made up of the factors that help you recover access to shielded Accounts and Personas in the event that you lose access to them or want to transfer control. For example, if you move your wallet to a new phone, you'll use the Shield's recovery feature to change the biometrics/PIN factor to a new one on your new phone.\n\nYou'll need to choose 1 or more factors that can start a recovery and 1 or more factors that can confirm the recovery. In most cases, you'll start and confirm the recovery in a single step, but in the worst case, a timed \"emergency fallback\" will let you start a recovery with just 1 factor and confirm it after a safe delay.\n\nYou can choose the time period for your emergency fallback factor. Make sure you choose a time period long enough that you'll be likely to open your [Radix Wallet](?glossaryAnchor=radixwallet) and cancel the recovery if anyone ever steals 1 of your factors and attempts to take control of your Accounts and Personas.\n\nYour Radix Wallet will help you build your Security Shield and once it’s finished, you’ll need to sign some transactions to apply it on the Radix Network to the Accounts and Personas of your choice.")
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
      internal static let tokens = L10n.tr("Localizable", "infoLink_glossary_tokens", fallback: "## Token\n\nToken is the general term for any kind of web3 asset that you can hold in a crypto wallet.\n\nTokens can represent many things, like dollars and euros, shares of companies, cryptocurrencies, or imaginary currencies in games. One special kind of token on Radix is [XRD](?glossaryAnchor=xrd).\n\n---\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) has special features specifically to make the creation and use of tokens on Radix safe and predictable, and the [Radix Wallet](?glossaryAnchor=radixwallet) can automatically provide useful information about the tokens you hold in your [Accounts](?glossaryAnchor=accounts).\n\nUsually “token” is used specifically to refer to assets that are all alike. For example, one XRD token is exactly the same as any other XRD token. Assets where each token has a unique identity have a special term: [a non-fungible token or NFT](?glossaryAnchor=nfts).\n\n[Learn more about tokens](https://learn.radixdlt.com/article/what-is-a-token) ↗\n\n[Find out why tokens on Radix are better than other crypto networks](https://www.radixdlt.com/blog/its-10pm-do-you-know-where-your-tokens-are) ↗")
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
      internal static let transactionfee = L10n.tr("Localizable", "infoLink_glossary_transactionfee", fallback: "## Transaction Fee\n\nEach time a [transaction](?glossaryAnchor=transactions) is submitted to the [Radix Network](?glossaryAnchor=radixnetwork), a _very_ small fee (usually only a few cents) has to be paid to the network itself.\n\nThis fee must be paid in [XRD tokens](?glossaryAnchor=xrd) and is paid as a part of each transaction.\n\n---\n\nFor transactions you submit to the network in your [Radix Wallet](?glossaryAnchor=radixwallet), you will see how much it will cost before you submit, and you can choose which [Account](?glossaryAnchor=accounts) you want to pay the fee from.\n\nTransactions fees on Radix are split into 3 parts.\n\n**Network fees**: These support Radix [node operators](?glossaryAnchor=validators) who validate transactions and secure the Radix Network. The size of network fees reflect the burden each transaction puts on the network.\n\n**Royalties**: These are set by developers who deploy code or run applications on the network. Royalties allow developers to collect a “use fee” every time their work is used as part of a transaction.\n\n**Tips**: These are optional payments users can make directly to validators to prioritize their own transactions during periods of high network demand. \n\n[Learn more about transaction fees](https://learn.radixdlt.com/article/how-do-transaction-fees-work-on-radix) ↗")
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
      internal static let transactions = L10n.tr("Localizable", "infoLink_glossary_transactions", fallback: "## Transactions\n\nAny time a user or application wants to move assets around on the [Radix Network](?glossaryAnchor=radixnetwork), they must sign and submit a transaction to the network to do it.\n\n---\n\nA transaction on Radix is basically a set of instructions to the network that might include things like “withdraw 10 XRD from my account” or “pass 2 RadGem NFTs to RadQuest”.\n\nTransactions can be very simple – like sending tokens to somebody – or can be complex, with lots of steps and interactions with dApps. But no matter what, any time a transaction touches your own assets, you will see and approve it in your [Radix Wallet](?glossaryAnchor=radixwallet) app first.\n\n[Learn more about transactions](https://learn.radixdlt.com/article/what-is-a-transaction-in-crypto) ↗\n\n[Find out how transactions on Radix are better than other crypto networks](https://www.radixdlt.com/blog/radixs-asset-oriented-transactions) ↗")
      /// ## Asset Transfers
      /// 
      /// The simplest kind of [transaction](?glossaryAnchor=transactions) on Radix is an asset transfer. It is simply a transaction to move a [token](?glossaryAnchor=tokens) or [NFT](?glossaryAnchor=nfts) from one [Account](?glossaryAnchor=accounts) to another.
      /// 
      /// The [Radix Wallet](?glossaryAnchor=radixwallet) lets you do asset transfers from your own Accounts without using any other [dApp](?glossaryAnchor=dapps). Simply go into the Account, tap the “Transfer” button, and fill in the recipient and the assets you want to transfer there. You can even choose multiple recipients and assets in a single asset transfer transaction.
      internal static let transfers = L10n.tr("Localizable", "infoLink_glossary_transfers", fallback: "## Asset Transfers\n\nThe simplest kind of [transaction](?glossaryAnchor=transactions) on Radix is an asset transfer. It is simply a transaction to move a [token](?glossaryAnchor=tokens) or [NFT](?glossaryAnchor=nfts) from one [Account](?glossaryAnchor=accounts) to another.\n\nThe [Radix Wallet](?glossaryAnchor=radixwallet) lets you do asset transfers from your own Accounts without using any other [dApp](?glossaryAnchor=dapps). Simply go into the Account, tap the “Transfer” button, and fill in the recipient and the assets you want to transfer there. You can even choose multiple recipients and assets in a single asset transfer transaction.")
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
      internal static let validators = L10n.tr("Localizable", "infoLink_glossary_validators", fallback: "## Radix Network Validators\n\nThe [Radix Network](?glossaryAnchor=radixnetwork) is an open network that anybody can freely use. To make that possible, the network isn’t run by a company, but by an open community of “validators”.\n\n---\n\nEach validator is a server run by somebody that helps “validate” [transactions](?glossaryAnchor=transactions). Working together, validators make sure that transactions are correctly processed and committed on the Radix Network.\n\nWhen you [stake XRD tokens to the network](?glossaryAnchor=networkstaking), you select validators that you trust to correctly and reliably keep running the Radix Network - it's a big responsibility, kind of like voting in an open election to pick good leaders.\n\nStart with the link below to consider how you choose the validators that you stake to.\n\n[Learn how to choose validators](https://learn.radixdlt.com/article/how-should-i-choose-validators-to-stake-to) ↗")
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
      internal static let web3 = L10n.tr("Localizable", "infoLink_glossary_web3", fallback: "## Web3\n\nWeb3 is the name given to the latest stage in the evolution of the internet. It is underpinned by blockchain technology and is intended to give users more control over their online assets, identity, and data.\n\n---\n\nIn the beginning, the web was all about just viewing content produced by other people. Here’s a webpage, look at it, click it. That was Web1.\n\n**Web2** made it possible for users to create their own content online. Social media, social news, photo sharing, and more became possible – communicating on the web became a 2-way street\n\nHowever, parts of the web are still a 1-way street. While we have control of what we create and share, we don’t have control over _what we own_ and _who we are_. Your money and everything you can do with it is still locked inside separate bank or payment apps, and your logins are specific to every website (if not controlled by Google or Apple or Meta).\n\n**Web3** now adds the ability for users to own their own digital assets and digital identities online, and allows websites and other applications to interact with these truly digital-native assets and identities in powerful new ways.\n\nCryptocurrencies like Bitcoin were the very beginning of web3, but it goes so much further. In web3, “Decentralized Finance” becomes possible, making finance cheaper, better, and more accessible to anyone – financial services compete to put your money to work, rather than charging you for the privilege of holding it. And new things become possible; imagine logging out of your favorite game, but taking your equipment with you to trade with others directly, outside the game?\n\nThis new capability is generally enabled by blockchain technology, but it is in its early days. [Radix](?glossaryAnchor=radixnetwork) is pushing the cutting edge of making web3 ready for average users and real applications that matter.")
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
      internal static let xrd = L10n.tr("Localizable", "infoLink_glossary_xrd", fallback: "## XRD Token\n\nXRD is the official Radix Network token.\n\n---\n\n It is created by the [Radix Network](?glossaryAnchor=radixnetwork) itself and users and applications can use it to use features of the network. For example, [transaction fees](?glossaryAnchor=transactionfee) are always paid in XRD, and XRD is the only token that can be used to participate in [Radix Network staking](?glossaryAnchor=networkstaking).\n\nBecause XRD has a special role on Radix, XRD is also frequently used by [dApps](?glossaryAnchor=dapps) on Radix as a convenient form of money to pay for things and to enable exchanges with other tokens.\n\n[Buy XRD tokens](https://www.radixdlt.com/token) ↗\n\n[Learn more about the XRD token](https://learn.radixdlt.com/article/what-is-the-xrd-token) ↗")
    }
    internal enum Title {
      /// Learn about Arculus Cards
      internal static let arculus = L10n.tr("Localizable", "infoLink_title_arculus", fallback: "Learn about Arculus Cards")
      /// What are behaviors?
      internal static let behaviors = L10n.tr("Localizable", "infoLink_title_behaviors", fallback: "What are behaviors?")
      /// Learn about biometrics/PIN
      internal static let biometricspin = L10n.tr("Localizable", "infoLink_title_biometricspin", fallback: "Learn about biometrics/PIN")
      /// How your Security Shield is built
      internal static let buildingshield = L10n.tr("Localizable", "infoLink_title_buildingshield", fallback: "How your Security Shield is built")
      /// What is a dApp?
      internal static let dapps = L10n.tr("Localizable", "infoLink_title_dapps", fallback: "What is a dApp?")
      /// What is a Gateway?
      internal static let gateways = L10n.tr("Localizable", "infoLink_title_gateways", fallback: "What is a Gateway?")
      /// How do guarantees work?
      internal static let guarantees = L10n.tr("Localizable", "infoLink_title_guarantees", fallback: "How do guarantees work?")
      /// Learn about Ledger Nanos
      internal static let ledgernano = L10n.tr("Localizable", "infoLink_title_ledgernano", fallback: "Learn about Ledger Nanos")
      /// What is Staking?
      internal static let networkstaking = L10n.tr("Localizable", "infoLink_title_networkstaking", fallback: "What is Staking?")
      /// What are NFTs?
      internal static let nfts = L10n.tr("Localizable", "infoLink_title_nfts", fallback: "What are NFTs?")
      /// Learn about passphrases
      internal static let passphrases = L10n.tr("Localizable", "infoLink_title_passphrases", fallback: "Learn about passphrases")
      /// Learn about passwords
      internal static let passwords = L10n.tr("Localizable", "infoLink_title_passwords", fallback: "Learn about passwords")
      /// What is a Persona?
      internal static let personas = L10n.tr("Localizable", "infoLink_title_personas", fallback: "What is a Persona?")
      /// Learn about Personas
      internal static let personasLearnAbout = L10n.tr("Localizable", "infoLink_title_personasLearnAbout", fallback: "Learn about Personas")
      /// What are Pool units?
      internal static let poolunits = L10n.tr("Localizable", "infoLink_title_poolunits", fallback: "What are Pool units?")
      /// Learn more about Radix Connect
      internal static let radixconnect = L10n.tr("Localizable", "infoLink_title_radixconnect", fallback: "Learn more about Radix Connect")
      /// Learn about Security Shields
      internal static let securityshields = L10n.tr("Localizable", "infoLink_title_securityshields", fallback: "Learn about Security Shields")
      /// What are Tokens?
      internal static let tokens = L10n.tr("Localizable", "infoLink_title_tokens", fallback: "What are Tokens?")
      /// How do fees work?
      internal static let transactionfee = L10n.tr("Localizable", "infoLink_title_transactionfee", fallback: "How do fees work?")
    }
  }
  internal enum InteractionReview {
    /// At least
    internal static let atLeast = L10n.tr("Localizable", "interactionReview_atLeast", fallback: "At least")
    /// Claim from validators
    internal static let claimFromValidatorsHeading = L10n.tr("Localizable", "interactionReview_claimFromValidatorsHeading", fallback: "Claim from validators")
    /// Customize Guarantees
    internal static let customizeGuaranteesButtonTitle = L10n.tr("Localizable", "interactionReview_customizeGuaranteesButtonTitle", fallback: "Customize Guarantees")
    /// Depositing To
    internal static let depositsHeading = L10n.tr("Localizable", "interactionReview_depositsHeading", fallback: "Depositing To")
    /// Estimated
    internal static let estimated = L10n.tr("Localizable", "interactionReview_estimated", fallback: "Estimated")
    /// Account
    internal static let externalAccountName = L10n.tr("Localizable", "interactionReview_externalAccountName", fallback: "Account")
    /// Guaranteed
    internal static let guaranteed = L10n.tr("Localizable", "interactionReview_guaranteed", fallback: "Guaranteed")
    /// Message
    internal static let messageHeading = L10n.tr("Localizable", "interactionReview_messageHeading", fallback: "Message")
    /// No more than
    internal static let noMoreThan = L10n.tr("Localizable", "interactionReview_noMoreThan", fallback: "No more than")
    /// Contributing to pools
    internal static let poolContributionHeading = L10n.tr("Localizable", "interactionReview_poolContributionHeading", fallback: "Contributing to pools")
    /// Redeeming from pools
    internal static let poolRedemptionHeading = L10n.tr("Localizable", "interactionReview_poolRedemptionHeading", fallback: "Redeeming from pools")
    /// Possible dApp calls
    internal static let possibleDappCalls = L10n.tr("Localizable", "interactionReview_possibleDappCalls", fallback: "Possible dApp calls")
    /// Presenting
    internal static let presentingHeading = L10n.tr("Localizable", "interactionReview_presentingHeading", fallback: "Presenting")
    /// Slide to Sign
    internal static let slideToSign = L10n.tr("Localizable", "interactionReview_slideToSign", fallback: "Slide to Sign")
    /// Staking to Validators
    internal static let stakingToValidatorsHeading = L10n.tr("Localizable", "interactionReview_stakingToValidatorsHeading", fallback: "Staking to Validators")
    /// Proposed by %@
    internal static func subtitle(_ p1: Any) -> String {
      return L10n.tr("Localizable", "interactionReview_subtitle", String(describing: p1), fallback: "Proposed by %@")
    }
    /// Third-party deposit exceptions
    internal static let thirdPartyDepositExceptionsHeading = L10n.tr("Localizable", "interactionReview_thirdPartyDepositExceptionsHeading", fallback: "Third-party deposit exceptions")
    /// Third-party deposit setting
    internal static let thirdPartyDepositSettingHeading = L10n.tr("Localizable", "interactionReview_thirdPartyDepositSettingHeading", fallback: "Third-party deposit setting")
    /// To be claimed
    internal static let toBeClaimed = L10n.tr("Localizable", "interactionReview_toBeClaimed", fallback: "To be claimed")
    /// %d Unknown Components
    internal static func unknownComponents(_ p1: Int) -> String {
      return L10n.tr("Localizable", "interactionReview_unknownComponents", p1, fallback: "%d Unknown Components")
    }
    /// %d Pool Components
    internal static func unknownPools(_ p1: Int) -> String {
      return L10n.tr("Localizable", "interactionReview_unknownPools", p1, fallback: "%d Pool Components")
    }
    /// Requesting unstake from validators
    internal static let unstakingFromValidatorsHeading = L10n.tr("Localizable", "interactionReview_unstakingFromValidatorsHeading", fallback: "Requesting unstake from validators")
    /// Using dApps
    internal static let usingDappsHeading = L10n.tr("Localizable", "interactionReview_usingDappsHeading", fallback: "Using dApps")
    /// Withdrawing From
    internal static let withdrawalsHeading = L10n.tr("Localizable", "interactionReview_withdrawalsHeading", fallback: "Withdrawing From")
    /// Worth
    internal static let worth = L10n.tr("Localizable", "interactionReview_worth", fallback: "Worth")
    internal enum DepositExceptions {
      /// Allow
      internal static let assetChangeAllow = L10n.tr("Localizable", "interactionReview_depositExceptions_assetChangeAllow", fallback: "Allow")
      /// Remove Exception
      internal static let assetChangeClear = L10n.tr("Localizable", "interactionReview_depositExceptions_assetChangeClear", fallback: "Remove Exception")
      /// Disallow
      internal static let assetChangeDisallow = L10n.tr("Localizable", "interactionReview_depositExceptions_assetChangeDisallow", fallback: "Disallow")
      /// Add Depositor
      internal static let depositorChangeAdd = L10n.tr("Localizable", "interactionReview_depositExceptions_depositorChangeAdd", fallback: "Add Depositor")
      /// Remove Depositor
      internal static let depositorChangeRemove = L10n.tr("Localizable", "interactionReview_depositExceptions_depositorChangeRemove", fallback: "Remove Depositor")
    }
    internal enum DepositSettings {
      /// Allow third parties to deposit **any asset** to this account.
      internal static let acceptAllRule = L10n.tr("Localizable", "interactionReview_depositSettings_acceptAllRule", fallback: "Allow third parties to deposit **any asset** to this account.")
      /// Allow third parties to deposit **only assets this account has already held**.
      internal static let acceptKnownRule = L10n.tr("Localizable", "interactionReview_depositSettings_acceptKnownRule", fallback: "Allow third parties to deposit **only assets this account has already held**.")
      /// **Disallow** all deposits from third parties without your consent.
      internal static let denyAllRule = L10n.tr("Localizable", "interactionReview_depositSettings_denyAllRule", fallback: "**Disallow** all deposits from third parties without your consent.")
    }
    internal enum HiddenAsset {
      /// This asset is hidden and will not be visible in your Account
      internal static let deposit = L10n.tr("Localizable", "interactionReview_hiddenAsset_deposit", fallback: "This asset is hidden and will not be visible in your Account")
      /// This asset is hidden and is not visible in your Account
      internal static let withdraw = L10n.tr("Localizable", "interactionReview_hiddenAsset_withdraw", fallback: "This asset is hidden and is not visible in your Account")
    }
    internal enum Unknown {
      /// Amount of deposit is unknown
      internal static let amount = L10n.tr("Localizable", "interactionReview_unknown_amount", fallback: "Amount of deposit is unknown")
      /// Unknown deposits to this account may occur
      internal static let deposits = L10n.tr("Localizable", "interactionReview_unknown_deposits", fallback: "Unknown deposits to this account may occur")
    }
  }
  internal enum LedgerHardwareDevices {
    /// Added
    internal static let addedHeading = L10n.tr("Localizable", "ledgerHardwareDevices_addedHeading", fallback: "Added")
    /// Add Ledger Device
    internal static let addNewLedger = L10n.tr("Localizable", "ledgerHardwareDevices_addNewLedger", fallback: "Add Ledger Device")
    /// Continue
    internal static let continueWithLedger = L10n.tr("Localizable", "ledgerHardwareDevices_continueWithLedger", fallback: "Continue")
    /// What is a Ledger Factor Source
    internal static let ledgerFactorSourceInfoCaption = L10n.tr("Localizable", "ledgerHardwareDevices_ledgerFactorSourceInfoCaption", fallback: "What is a Ledger Factor Source")
    /// Choose Ledger
    internal static let navigationTitleAllowSelection = L10n.tr("Localizable", "ledgerHardwareDevices_navigationTitleAllowSelection", fallback: "Choose Ledger")
    /// Ledger Devices
    internal static let navigationTitleGeneral = L10n.tr("Localizable", "ledgerHardwareDevices_navigationTitleGeneral", fallback: "Ledger Devices")
    /// Choose Ledger Device
    internal static let navigationTitleNoSelection = L10n.tr("Localizable", "ledgerHardwareDevices_navigationTitleNoSelection", fallback: "Choose Ledger Device")
    /// Here are all the Ledger devices you have added.
    internal static let subtitleAllLedgers = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleAllLedgers", fallback: "Here are all the Ledger devices you have added.")
    /// Could not find Ledger devices
    internal static let subtitleFailure = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleFailure", fallback: "Could not find Ledger devices")
    /// No Ledger devices currently added to your Radix Wallet
    internal static let subtitleNoLedgers = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleNoLedgers", fallback: "No Ledger devices currently added to your Radix Wallet")
    /// Choose a Ledger device to use
    internal static let subtitleSelectLedger = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleSelectLedger", fallback: "Choose a Ledger device to use")
    /// Choose an existing Ledger or add a new one
    internal static let subtitleSelectLedgerExisting = L10n.tr("Localizable", "ledgerHardwareDevices_subtitleSelectLedgerExisting", fallback: "Choose an existing Ledger or add a new one")
    /// Last Used
    internal static let usedHeading = L10n.tr("Localizable", "ledgerHardwareDevices_usedHeading", fallback: "Last Used")
    internal enum CouldNotSign {
      /// Transaction could not be signed. To sign complex transactions, please enable either "blind signing" or "verbose mode" in the Radix app on your Ledger device.
      internal static let message = L10n.tr("Localizable", "ledgerHardwareDevices_couldNotSign_message", fallback: "Transaction could not be signed. To sign complex transactions, please enable either \"blind signing\" or \"verbose mode\" in the Radix app on your Ledger device.")
      /// Could Not Sign
      internal static let title = L10n.tr("Localizable", "ledgerHardwareDevices_couldNotSign_title", fallback: "Could Not Sign")
    }
    internal enum LinkConnectorAlert {
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_continue", fallback: "Continue")
      /// To use a Ledger hardware wallet device, it must be connected to a computer running the Radix Connector browser extension.
      internal static let message = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_message", fallback: "To use a Ledger hardware wallet device, it must be connected to a computer running the Radix Connector browser extension.")
      /// Link a Connector
      internal static let title = L10n.tr("Localizable", "ledgerHardwareDevices_linkConnectorAlert_title", fallback: "Link a Connector")
    }
    internal enum Verification {
      /// Address verified
      internal static let addressVerified = L10n.tr("Localizable", "ledgerHardwareDevices_verification_addressVerified", fallback: "Address verified")
      /// Verify address: Returned bad response
      internal static let badResponse = L10n.tr("Localizable", "ledgerHardwareDevices_verification_badResponse", fallback: "Verify address: Returned bad response")
      /// Verify address: Mismatched addresses
      internal static let mismatch = L10n.tr("Localizable", "ledgerHardwareDevices_verification_mismatch", fallback: "Verify address: Mismatched addresses")
      /// Verify address: Request failed
      internal static let requestFailed = L10n.tr("Localizable", "ledgerHardwareDevices_verification_requestFailed", fallback: "Verify address: Request failed")
    }
  }
  internal enum LinkedConnectors {
    /// Changing a Connector’s type is not supported.
    internal static let changingPurposeNotSupportedErrorMessage = L10n.tr("Localizable", "linkedConnectors_changingPurposeNotSupportedErrorMessage", fallback: "Changing a Connector’s type is not supported.")
    /// Please scan the QR code provided by your Radix Wallet Connector browser extension.
    internal static let incorrectQrMessage = L10n.tr("Localizable", "linkedConnectors_incorrectQrMessage", fallback: "Please scan the QR code provided by your Radix Wallet Connector browser extension.")
    /// Incorrect QR code scanned.
    internal static let incorrectQrTitle = L10n.tr("Localizable", "linkedConnectors_incorrectQrTitle", fallback: "Incorrect QR code scanned.")
    /// Last connected %@
    internal static func lastConnected(_ p1: Any) -> String {
      return L10n.tr("Localizable", "linkedConnectors_lastConnected", String(describing: p1), fallback: "Last connected %@")
    }
    /// Link Failed
    internal static let linkFailedErrorTitle = L10n.tr("Localizable", "linkedConnectors_linkFailedErrorTitle", fallback: "Link Failed")
    /// Link New Connector
    internal static let linkNewConnector = L10n.tr("Localizable", "linkedConnectors_linkNewConnector", fallback: "Link New Connector")
    /// This is an old version of the Radix Connector browser extension. Please update to the latest Connector and try linking again.
    internal static let oldQRErrorMessage = L10n.tr("Localizable", "linkedConnectors_oldQRErrorMessage", fallback: "This is an old version of the Radix Connector browser extension. Please update to the latest Connector and try linking again.")
    /// Your Radix Wallet is linked to the following desktop browsers using the Connector browser extension.
    internal static let subtitle = L10n.tr("Localizable", "linkedConnectors_subtitle", fallback: "Your Radix Wallet is linked to the following desktop browsers using the Connector browser extension.")
    /// Linked Connectors
    internal static let title = L10n.tr("Localizable", "linkedConnectors_title", fallback: "Linked Connectors")
    /// This type of Connector link is not supported.
    internal static let unknownPurposeErrorMessage = L10n.tr("Localizable", "linkedConnectors_unknownPurposeErrorMessage", fallback: "This type of Connector link is not supported.")
    internal enum ApproveExistingConnector {
      /// This appears to be a Radix Connector you previously linked to. Link will be updated.
      internal static let message = L10n.tr("Localizable", "linkedConnectors_approveExistingConnector_message", fallback: "This appears to be a Radix Connector you previously linked to. Link will be updated.")
      /// Update Link
      internal static let title = L10n.tr("Localizable", "linkedConnectors_approveExistingConnector_title", fallback: "Update Link")
    }
    internal enum ApproveNewConnector {
      /// This Connector will be trusted to verify the dApp origin of requests to this wallet.
      /// 
      /// Only continue if you are linking to the **official Radix Connector browser extension** - or a Connector you control and trust.
      internal static let message = L10n.tr("Localizable", "linkedConnectors_approveNewConnector_message", fallback: "This Connector will be trusted to verify the dApp origin of requests to this wallet.\n\nOnly continue if you are linking to the **official Radix Connector browser extension** - or a Connector you control and trust.")
      /// Link Connector
      internal static let title = L10n.tr("Localizable", "linkedConnectors_approveNewConnector_title", fallback: "Link Connector")
    }
    internal enum CameraPermissionDeniedAlert {
      /// Camera access is required to link to a Connector.
      internal static let message = L10n.tr("Localizable", "linkedConnectors_cameraPermissionDeniedAlert_message", fallback: "Camera access is required to link to a Connector.")
      /// Access Required
      internal static let title = L10n.tr("Localizable", "linkedConnectors_cameraPermissionDeniedAlert_title", fallback: "Access Required")
    }
    internal enum LocalNetworkPermissionDeniedAlert {
      /// Local network access is required to link to a Connector.
      internal static let message = L10n.tr("Localizable", "linkedConnectors_localNetworkPermissionDeniedAlert_message", fallback: "Local network access is required to link to a Connector.")
      /// Access Required
      internal static let title = L10n.tr("Localizable", "linkedConnectors_localNetworkPermissionDeniedAlert_title", fallback: "Access Required")
    }
    internal enum NameNewConnector {
      /// Continue
      internal static let saveLinkButtonTitle = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_saveLinkButtonTitle", fallback: "Continue")
      /// What would you like to call this Radix Connector installation?
      internal static let subtitle = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_subtitle", fallback: "What would you like to call this Radix Connector installation?")
      /// Name this connector e.g. ‘Chrome on MacBook Pro’
      internal static let textFieldHint = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_textFieldHint", fallback: "Name this connector e.g. ‘Chrome on MacBook Pro’")
      /// e.g. Chrome on Personal Laptop
      internal static let textFieldPlaceholder = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_textFieldPlaceholder", fallback: "e.g. Chrome on Personal Laptop")
      /// Name New Connector
      internal static let title = L10n.tr("Localizable", "linkedConnectors_nameNewConnector_title", fallback: "Name New Connector")
    }
    internal enum NewConnection {
      /// Linking…
      internal static let linking = L10n.tr("Localizable", "linkedConnectors_newConnection_linking", fallback: "Linking…")
      /// Open your Radix Connector extension's menu by clicking its icon in your list of browser extensions, and scan the QR code shown.
      internal static let subtitle = L10n.tr("Localizable", "linkedConnectors_newConnection_subtitle", fallback: "Open your Radix Connector extension's menu by clicking its icon in your list of browser extensions, and scan the QR code shown.")
      /// Link Connector
      internal static let title = L10n.tr("Localizable", "linkedConnectors_newConnection_title", fallback: "Link Connector")
    }
    internal enum RelinkConnectors {
      /// Any Connectors you had linked to this wallet using a different phone have been disconnected
      /// 
      /// **Please re-link your Connector(s) to use with this phone.**
      internal static let afterProfileRestoreMessage = L10n.tr("Localizable", "linkedConnectors_relinkConnectors_afterProfileRestoreMessage", fallback: "Any Connectors you had linked to this wallet using a different phone have been disconnected\n\n**Please re-link your Connector(s) to use with this phone.**")
      /// Radix Connector now supports linking multiple phones with one browser.
      /// 
      /// To support this feature, we've had to disconnect your existing links – **please re-link your Connector(s).**
      internal static let afterUpdateMessage = L10n.tr("Localizable", "linkedConnectors_relinkConnectors_afterUpdateMessage", fallback: "Radix Connector now supports linking multiple phones with one browser.\n\nTo support this feature, we've had to disconnect your existing links – **please re-link your Connector(s).**")
      /// Later
      internal static let laterButton = L10n.tr("Localizable", "linkedConnectors_relinkConnectors_laterButton", fallback: "Later")
      /// Re-link Connector
      internal static let title = L10n.tr("Localizable", "linkedConnectors_relinkConnectors_title", fallback: "Re-link Connector")
    }
    internal enum RemoveConnectionAlert {
      /// You will no longer be able to connect your wallet to this device and browser combination.
      internal static let message = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_message", fallback: "You will no longer be able to connect your wallet to this device and browser combination.")
      /// Remove
      internal static let removeButtonTitle = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_removeButtonTitle", fallback: "Remove")
      /// Remove Connection
      internal static let title = L10n.tr("Localizable", "linkedConnectors_removeConnectionAlert_title", fallback: "Remove Connection")
    }
    internal enum RenameConnector {
      /// Linked Connector name required
      internal static let errorEmpty = L10n.tr("Localizable", "linkedConnectors_renameConnector_errorEmpty", fallback: "Linked Connector name required")
      /// Enter a new name for this Linked Connector
      internal static let subtitle = L10n.tr("Localizable", "linkedConnectors_renameConnector_subtitle", fallback: "Enter a new name for this Linked Connector")
      /// Updated
      internal static let successHud = L10n.tr("Localizable", "linkedConnectors_renameConnector_successHud", fallback: "Updated")
      /// Rename Connector
      internal static let title = L10n.tr("Localizable", "linkedConnectors_renameConnector_title", fallback: "Rename Connector")
      /// Update
      internal static let update = L10n.tr("Localizable", "linkedConnectors_renameConnector_update", fallback: "Update")
    }
  }
  internal enum Misc {
    internal enum RemoteThumbnails {
      /// Can't load image
      internal static let loadingFailure = L10n.tr("Localizable", "misc_remoteThumbnails_loadingFailure", fallback: "Can't load image")
      /// Can't displays image of vector type
      internal static let vectorImageFailure = L10n.tr("Localizable", "misc_remoteThumbnails_vectorImageFailure", fallback: "Can't displays image of vector type")
    }
  }
  internal enum MobileConnect {
    /// Switch back to your browser to continue
    internal static let interactionSuccess = L10n.tr("Localizable", "mobileConnect_interactionSuccess", fallback: "Switch back to your browser to continue")
    /// Does the website address match what you’re expecting?
    internal static let linkBody1 = L10n.tr("Localizable", "mobileConnect_linkBody1", fallback: "Does the website address match what you’re expecting?")
    /// If you came from a social media ad, is the website legitimate?
    internal static let linkBody2 = L10n.tr("Localizable", "mobileConnect_linkBody2", fallback: "If you came from a social media ad, is the website legitimate?")
    /// Before you connect to **%@**, you might want to check:
    internal static func linkSubtitle(_ p1: Any) -> String {
      return L10n.tr("Localizable", "mobileConnect_linkSubtitle", String(describing: p1), fallback: "Before you connect to **%@**, you might want to check:")
    }
    /// Have you come from a genuine website?
    internal static let linkTitle = L10n.tr("Localizable", "mobileConnect_linkTitle", fallback: "Have you come from a genuine website?")
    internal enum NoProfileDialog {
      /// You can proceed with this request after you create or restore your Radix Wallet.
      internal static let subtitle = L10n.tr("Localizable", "mobileConnect_noProfileDialog_subtitle", fallback: "You can proceed with this request after you create or restore your Radix Wallet.")
      /// dApp Request
      internal static let title = L10n.tr("Localizable", "mobileConnect_noProfileDialog_title", fallback: "dApp Request")
    }
  }
  internal enum Onboarding {
    /// I'm a New Radix Wallet User
    internal static let newUser = L10n.tr("Localizable", "onboarding_newUser", fallback: "I'm a New Radix Wallet User")
    /// Restore Wallet from Backup
    internal static let restoreFromBackup = L10n.tr("Localizable", "onboarding_restoreFromBackup", fallback: "Restore Wallet from Backup")
    internal enum CloudAndroid {
      /// Back up to Google Drive
      internal static let backupButton = L10n.tr("Localizable", "onboarding_cloudAndroid_backupButton", fallback: "Back up to Google Drive")
      /// Connect to Google Drive to automatically backup your Radix wallet settings.
      internal static let backupSubtitle = L10n.tr("Localizable", "onboarding_cloudAndroid_backupSubtitle", fallback: "Connect to Google Drive to automatically backup your Radix wallet settings.")
      /// Back up your Wallet Settings
      internal static let backupTitle = L10n.tr("Localizable", "onboarding_cloudAndroid_backupTitle", fallback: "Back up your Wallet Settings")
      /// Skip
      internal static let skip = L10n.tr("Localizable", "onboarding_cloudAndroid_skip", fallback: "Skip")
    }
    internal enum CloudRestoreAndroid {
      /// Log in to Google Drive to restore your Radix wallet from Backup.
      internal static let backupSubtitle = L10n.tr("Localizable", "onboarding_cloudRestoreAndroid_backupSubtitle", fallback: "Log in to Google Drive to restore your Radix wallet from Backup.")
      /// Restore Wallet from Backup
      internal static let backupTitle = L10n.tr("Localizable", "onboarding_cloudRestoreAndroid_backupTitle", fallback: "Restore Wallet from Backup")
      /// Log in to Google Drive
      internal static let loginButton = L10n.tr("Localizable", "onboarding_cloudRestoreAndroid_loginButton", fallback: "Log in to Google Drive")
      /// Skip
      internal static let skip = L10n.tr("Localizable", "onboarding_cloudRestoreAndroid_skip", fallback: "Skip")
    }
    internal enum Eula {
      /// Accept
      internal static let accept = L10n.tr("Localizable", "onboarding_eula_accept", fallback: "Accept")
      /// To proceed, you must accept the user terms below.
      internal static let headerSubtitle = L10n.tr("Localizable", "onboarding_eula_headerSubtitle", fallback: "To proceed, you must accept the user terms below.")
      /// User Terms
      internal static let headerTitle = L10n.tr("Localizable", "onboarding_eula_headerTitle", fallback: "User Terms")
    }
    internal enum Step1 {
      /// Your direct connection to the Radix Network
      internal static let subtitle = L10n.tr("Localizable", "onboarding_step1_subtitle", fallback: "Your direct connection to the Radix Network")
      /// Welcome to the Radix Wallet
      internal static let title = L10n.tr("Localizable", "onboarding_step1_title", fallback: "Welcome to the Radix Wallet")
    }
    internal enum Step2 {
      /// Let's get started
      internal static let subtitle = L10n.tr("Localizable", "onboarding_step2_subtitle", fallback: "Let's get started")
      /// A World of Possibilities
      internal static let title = L10n.tr("Localizable", "onboarding_step2_title", fallback: "A World of Possibilities")
    }
    internal enum Step3 {
      /// Connect and transact securely with a world of web3 dApps, tokens, NFTs, and much more
      internal static let subtitle = L10n.tr("Localizable", "onboarding_step3_subtitle", fallback: "Connect and transact securely with a world of web3 dApps, tokens, NFTs, and much more")
      /// Your phone is your login
      internal static let title = L10n.tr("Localizable", "onboarding_step3_title", fallback: "Your phone is your login")
    }
  }
  internal enum Personas {
    /// Create a New Persona
    internal static let createNewPersona = L10n.tr("Localizable", "personas_createNewPersona", fallback: "Create a New Persona")
    /// Here are all of your current Personas in your Radix Wallet.
    internal static let subtitle = L10n.tr("Localizable", "personas_subtitle", fallback: "Here are all of your current Personas in your Radix Wallet.")
    /// Personas
    internal static let title = L10n.tr("Localizable", "personas_title", fallback: "Personas")
    /// Write down main seed phrase
    internal static let writeSeedPhrase = L10n.tr("Localizable", "personas_writeSeedPhrase", fallback: "Write down main seed phrase")
  }
  internal enum PreAuthorizationReview {
    /// Incoming Pre-Authorization
    internal static let loading = L10n.tr("Localizable", "preAuthorizationReview_loading", fallback: "Incoming Pre-Authorization")
    /// Slide to Sign and Return
    internal static let slideToSign = L10n.tr("Localizable", "preAuthorizationReview_slideToSign", fallback: "Slide to Sign and Return")
    /// Review your Pre-Authorization
    internal static let title = L10n.tr("Localizable", "preAuthorizationReview_title", fallback: "Review your Pre-Authorization")
    internal enum Expiration {
      /// Valid for **%@ after approval**
      internal static func afterDelay(_ p1: Any) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_expiration_afterDelay", String(describing: p1), fallback: "Valid for **%@ after approval**")
      }
      /// Valid for the next **%@**
      internal static func atTime(_ p1: Any) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_expiration_atTime", String(describing: p1), fallback: "Valid for the next **%@**")
      }
      /// Pre-authorization is no longer valid
      internal static let expired = L10n.tr("Localizable", "preAuthorizationReview_expiration_expired", fallback: "Pre-authorization is no longer valid")
    }
    internal enum ExpiredStatus {
      /// Switch back to your browser to try again
      internal static let retryInBrowser = L10n.tr("Localizable", "preAuthorizationReview_expiredStatus_retryInBrowser", fallback: "Switch back to your browser to try again")
      /// Your pre-authorization has expired and can no longer be used.
      internal static let subtitle = L10n.tr("Localizable", "preAuthorizationReview_expiredStatus_subtitle", fallback: "Your pre-authorization has expired and can no longer be used.")
      /// Pre-Authorization Timed Out
      internal static let title = L10n.tr("Localizable", "preAuthorizationReview_expiredStatus_title", fallback: "Pre-Authorization Timed Out")
    }
    internal enum Fees {
      /// Network fees will be paid by the dApp
      internal static let subtitle = L10n.tr("Localizable", "preAuthorizationReview_fees_subtitle", fallback: "Network fees will be paid by the dApp")
      /// Pre-authorization will be returned to %@ for processing.
      internal static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_fees_title", String(describing: p1), fallback: "Pre-authorization will be returned to %@ for processing.")
      }
    }
    internal enum RawManifestAlert {
      /// This is a complex pre-authorization that cannot be summarized - the raw pre-authorization manifest will be shown. Do not sign and return unless you understand the contents.
      internal static let message = L10n.tr("Localizable", "preAuthorizationReview_rawManifestAlert_message", fallback: "This is a complex pre-authorization that cannot be summarized - the raw pre-authorization manifest will be shown. Do not sign and return unless you understand the contents.")
      /// Warning
      internal static let title = L10n.tr("Localizable", "preAuthorizationReview_rawManifestAlert_title", fallback: "Warning")
    }
    internal enum TimeFormat {
      /// 1 day
      internal static let day = L10n.tr("Localizable", "preAuthorizationReview_timeFormat_day", fallback: "1 day")
      /// %d days
      internal static func days(_ p1: Int) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_timeFormat_days", p1, fallback: "%d days")
      }
      /// %@ hour
      internal static func hour(_ p1: Any) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_timeFormat_hour", String(describing: p1), fallback: "%@ hour")
      }
      /// %@ hours
      internal static func hours(_ p1: Any) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_timeFormat_hours", String(describing: p1), fallback: "%@ hours")
      }
      /// %@ minute
      internal static func minute(_ p1: Any) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_timeFormat_minute", String(describing: p1), fallback: "%@ minute")
      }
      /// %@ minutes
      internal static func minutes(_ p1: Any) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_timeFormat_minutes", String(describing: p1), fallback: "%@ minutes")
      }
      /// 1 second
      internal static let second = L10n.tr("Localizable", "preAuthorizationReview_timeFormat_second", fallback: "1 second")
      /// %d seconds
      internal static func seconds(_ p1: Int) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_timeFormat_seconds", p1, fallback: "%d seconds")
      }
    }
    internal enum UnknownStatus {
      /// %@ has **%@** to use this pre-authorization
      internal static func expiration(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_unknownStatus_expiration", String(describing: p1), String(describing: p2), fallback: "%@ has **%@** to use this pre-authorization")
      }
      /// Pre-Authorization ID
      internal static let identifier = L10n.tr("Localizable", "preAuthorizationReview_unknownStatus_identifier", fallback: "Pre-Authorization ID")
      /// Checking one last time..
      internal static let lastCheck = L10n.tr("Localizable", "preAuthorizationReview_unknownStatus_lastCheck", fallback: "Checking one last time..")
      /// Your pre-authorization has been sent to %@
      internal static func subtitle(_ p1: Any) -> String {
        return L10n.tr("Localizable", "preAuthorizationReview_unknownStatus_subtitle", String(describing: p1), fallback: "Your pre-authorization has been sent to %@")
      }
      /// Pre-Authorization Sent
      internal static let title = L10n.tr("Localizable", "preAuthorizationReview_unknownStatus_title", fallback: "Pre-Authorization Sent")
    }
  }
  internal enum Preferences {
    /// Advanced Preferences
    internal static let advancedPreferences = L10n.tr("Localizable", "preferences_advancedPreferences", fallback: "Advanced Preferences")
    /// Display
    internal static let displayPreferences = L10n.tr("Localizable", "preferences_displayPreferences", fallback: "Display")
    /// Network Gateways
    internal static let gateways = L10n.tr("Localizable", "preferences_gateways", fallback: "Network Gateways")
    /// Preferences
    internal static let title = L10n.tr("Localizable", "preferences_title", fallback: "Preferences")
    internal enum AdvancedLock {
      /// Re-authenticate when switching between apps
      internal static let subtitle = L10n.tr("Localizable", "preferences_advancedLock_subtitle", fallback: "Re-authenticate when switching between apps")
      /// Advanced Lock
      internal static let title = L10n.tr("Localizable", "preferences_advancedLock_title", fallback: "Advanced Lock")
    }
    internal enum AdvancedLockAndroid {
      /// Re-authenticate when switching, prevent screen recording
      internal static let subtitle = L10n.tr("Localizable", "preferences_advancedLockAndroid_subtitle", fallback: "Re-authenticate when switching, prevent screen recording")
    }
    internal enum DepositGuarantees {
      /// Set your guaranteed minimum for estimated deposits
      internal static let subtitle = L10n.tr("Localizable", "preferences_depositGuarantees_subtitle", fallback: "Set your guaranteed minimum for estimated deposits")
      /// Default Deposit Guarantees
      internal static let title = L10n.tr("Localizable", "preferences_depositGuarantees_title", fallback: "Default Deposit Guarantees")
    }
    internal enum DeveloperMode {
      /// Warning: disables website validity checks
      internal static let subtitle = L10n.tr("Localizable", "preferences_developerMode_subtitle", fallback: "Warning: disables website validity checks")
      /// Developer Mode
      internal static let title = L10n.tr("Localizable", "preferences_developerMode_title", fallback: "Developer Mode")
    }
    internal enum HiddenAssets {
      /// Manage hidden Tokens, NFTs, and other asset types
      internal static let subtitle = L10n.tr("Localizable", "preferences_hiddenAssets_subtitle", fallback: "Manage hidden Tokens, NFTs, and other asset types")
      /// Hidden Assets
      internal static let title = L10n.tr("Localizable", "preferences_hiddenAssets_title", fallback: "Hidden Assets")
    }
    internal enum HiddenEntities {
      /// Manage hidden Personas and Accounts
      internal static let subtitle = L10n.tr("Localizable", "preferences_hiddenEntities_subtitle", fallback: "Manage hidden Personas and Accounts")
      /// Hidden Personas & Accounts
      internal static let title = L10n.tr("Localizable", "preferences_hiddenEntities_title", fallback: "Hidden Personas & Accounts")
    }
  }
  internal enum ProfileBackup {
    /// Backing up your wallet ensures that you can restore access to your Accounts, Personas, and wallet settings on a new phone by re-entering your seed phrase(s).
    /// 
    /// **For security, backups do not contain any seed phrases or private keys. You must write them down separately.**
    internal static let headerTitle = L10n.tr("Localizable", "profileBackup_headerTitle", fallback: "Backing up your wallet ensures that you can restore access to your Accounts, Personas, and wallet settings on a new phone by re-entering your seed phrase(s).\n\n**For security, backups do not contain any seed phrases or private keys. You must write them down separately.**")
    internal enum AutomaticBackups {
      /// Automatic Backups (recommended)
      internal static let title = L10n.tr("Localizable", "profileBackup_automaticBackups_title", fallback: "Automatic Backups (recommended)")
    }
    internal enum DeleteWallet {
      /// Delete Wallet
      internal static let buttonTitle = L10n.tr("Localizable", "profileBackup_deleteWallet_buttonTitle", fallback: "Delete Wallet")
    }
    internal enum DeleteWalletDialog {
      /// Delete Wallet
      internal static let confirm = L10n.tr("Localizable", "profileBackup_deleteWalletDialog_confirm", fallback: "Delete Wallet")
      /// WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.
      internal static let message = L10n.tr("Localizable", "profileBackup_deleteWalletDialog_message", fallback: "WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.")
    }
    internal enum IncorrectPasswordAlert {
      /// Failed to decrypt using provided password.
      internal static let messageDecryption = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_messageDecryption", fallback: "Failed to decrypt using provided password.")
      /// Failed to encrypt using provided password.
      internal static let messageEncryption = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_messageEncryption", fallback: "Failed to encrypt using provided password.")
      /// OK
      internal static let okAction = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_okAction", fallback: "OK")
      /// Incorrect password
      internal static let title = L10n.tr("Localizable", "profileBackup_incorrectPasswordAlert_title", fallback: "Incorrect password")
    }
    internal enum ManualBackups {
      /// Confirm password
      internal static let confirmPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_confirmPasswordPlaceholder", fallback: "Confirm password")
      /// Enter the password you chose when you originally encrypted this Wallet Backup file.
      internal static let decryptBackupSubtitle = L10n.tr("Localizable", "profileBackup_manualBackups_decryptBackupSubtitle", fallback: "Enter the password you chose when you originally encrypted this Wallet Backup file.")
      /// Decrypt Wallet Backup File
      internal static let decryptBackupTitle = L10n.tr("Localizable", "profileBackup_manualBackups_decryptBackupTitle", fallback: "Decrypt Wallet Backup File")
      /// Yes
      internal static let encryptBackupDialogConfirm = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupDialogConfirm", fallback: "Yes")
      /// No
      internal static let encryptBackupDialogDeny = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupDialogDeny", fallback: "No")
      /// Encrypt this backup with a password?
      internal static let encryptBackupDialogTitle = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupDialogTitle", fallback: "Encrypt this backup with a password?")
      /// Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.
      internal static let encryptBackupSubtitle = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupSubtitle", fallback: "Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.")
      /// Encrypt Wallet Backup File
      internal static let encryptBackupTitle = L10n.tr("Localizable", "profileBackup_manualBackups_encryptBackupTitle", fallback: "Encrypt Wallet Backup File")
      /// Enter password
      internal static let enterPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_enterPasswordPlaceholder", fallback: "Enter password")
      /// Export Wallet Backup File
      internal static let exportButtonTitle = L10n.tr("Localizable", "profileBackup_manualBackups_exportButtonTitle", fallback: "Export Wallet Backup File")
      /// Decryption password
      internal static let nonConformingDecryptionPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_nonConformingDecryptionPasswordPlaceholder", fallback: "Decryption password")
      /// Encryption password
      internal static let nonConformingEncryptionPasswordPlaceholder = L10n.tr("Localizable", "profileBackup_manualBackups_nonConformingEncryptionPasswordPlaceholder", fallback: "Encryption password")
      /// Passwords do not match
      internal static let passwordsMissmatchError = L10n.tr("Localizable", "profileBackup_manualBackups_passwordsMissmatchError", fallback: "Passwords do not match")
      /// A manually exported wallet backup file may also be used for recovery, along with your seed phrase(s).
      /// 
      /// Only the **current configuration** of your wallet is backed up with each manual export.
      internal static let subtitle = L10n.tr("Localizable", "profileBackup_manualBackups_subtitle", fallback: "A manually exported wallet backup file may also be used for recovery, along with your seed phrase(s).\n\nOnly the **current configuration** of your wallet is backed up with each manual export.")
      /// Exported wallet backup file
      internal static let successMessage = L10n.tr("Localizable", "profileBackup_manualBackups_successMessage", fallback: "Exported wallet backup file")
      /// Manual Backups
      internal static let title = L10n.tr("Localizable", "profileBackup_manualBackups_title", fallback: "Manual Backups")
    }
    internal enum ResetWalletDialog {
      /// WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.
      internal static let message = L10n.tr("Localizable", "profileBackup_resetWalletDialog_message", fallback: "WARNING. This will clear all contents of your Wallet. If you have no backup, you will lose access to your Accounts and Personas permanently.")
      /// Reset and Delete iCloud Backup
      internal static let resetAndDeleteBackupButtonTitle = L10n.tr("Localizable", "profileBackup_resetWalletDialog_resetAndDeleteBackupButtonTitle", fallback: "Reset and Delete iCloud Backup")
      /// Reset Wallet
      internal static let resetButtonTitle = L10n.tr("Localizable", "profileBackup_resetWalletDialog_resetButtonTitle", fallback: "Reset Wallet")
      /// Reset Wallet?
      internal static let title = L10n.tr("Localizable", "profileBackup_resetWalletDialog_title", fallback: "Reset Wallet?")
    }
  }
  internal enum RecoverProfileBackup {
    /// **Backup from:** %@
    internal static func backupFrom(_ p1: Any) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_backupFrom", String(describing: p1), fallback: "**Backup from:** %@")
    }
    /// Backup not available?
    internal static let backupNotAvailable = L10n.tr("Localizable", "recoverProfileBackup_backupNotAvailable", fallback: "Backup not available?")
    /// Could not load backups
    internal static let couldNotLoadBackups = L10n.tr("Localizable", "recoverProfileBackup_couldNotLoadBackups", fallback: "Could not load backups")
    /// Incompatible Wallet data
    internal static let incompatibleWalletDataLabel = L10n.tr("Localizable", "recoverProfileBackup_incompatibleWalletDataLabel", fallback: "Incompatible Wallet data")
    /// **Last modified:** %@
    internal static func lastModified(_ p1: Any) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_lastModified", String(describing: p1), fallback: "**Last modified:** %@")
    }
    /// Network unavailable
    internal static let networkUnavailable = L10n.tr("Localizable", "recoverProfileBackup_networkUnavailable", fallback: "Network unavailable")
    /// **Number of accounts:** %d
    internal static func numberOfAccounts(_ p1: Int) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_numberOfAccounts", p1, fallback: "**Number of accounts:** %d")
    }
    /// **Number of personas:** %d
    internal static func numberOfPersonas(_ p1: Int) -> String {
      return L10n.tr("Localizable", "recoverProfileBackup_numberOfPersonas", p1, fallback: "**Number of personas:** %d")
    }
    /// Other Restore Options
    internal static let otherRestoreOptionsButton = L10n.tr("Localizable", "recoverProfileBackup_otherRestoreOptionsButton", fallback: "Other Restore Options")
    /// The password is wrong
    internal static let passwordWrong = L10n.tr("Localizable", "recoverProfileBackup_passwordWrong", fallback: "The password is wrong")
    /// This Device
    internal static let thisDevice = L10n.tr("Localizable", "recoverProfileBackup_thisDevice", fallback: "This Device")
    internal enum Choose {
      /// Choose a backup on iCloud
      internal static let ios = L10n.tr("Localizable", "recoverProfileBackup_choose_iOS", fallback: "Choose a backup on iCloud")
    }
    internal enum Header {
      /// Select a backup to restore your Radix Wallet. You will be asked to enter your seed phrase(s) to recover control of your Accounts and Personas.
      internal static let subtitle = L10n.tr("Localizable", "recoverProfileBackup_header_subtitle", fallback: "Select a backup to restore your Radix Wallet. You will be asked to enter your seed phrase(s) to recover control of your Accounts and Personas.")
      /// Restore Wallet From Backup
      internal static let title = L10n.tr("Localizable", "recoverProfileBackup_header_title", fallback: "Restore Wallet From Backup")
    }
    internal enum ImportFileButton {
      /// Import from Backup File Instead
      internal static let title = L10n.tr("Localizable", "recoverProfileBackup_importFileButton_title", fallback: "Import from Backup File Instead")
    }
    internal enum NoBackupsAvailable {
      /// No wallet backups available on current iCloud account
      internal static let ios = L10n.tr("Localizable", "recoverProfileBackup_noBackupsAvailable_iOS", fallback: "No wallet backups available on current iCloud account")
    }
    internal enum NotLoggedIn {
      /// Not logged in to iCloud
      internal static let ios = L10n.tr("Localizable", "recoverProfileBackup_notLoggedIn_iOS", fallback: "Not logged in to iCloud")
    }
  }
  internal enum RecoverSeedPhrase {
    /// Enter This Seed Phrase
    internal static let enterButton = L10n.tr("Localizable", "recoverSeedPhrase_enterButton", fallback: "Enter This Seed Phrase")
    /// Hidden accounts only.
    internal static let hiddenAccountsOnly = L10n.tr("Localizable", "recoverSeedPhrase_hiddenAccountsOnly", fallback: "Hidden accounts only.")
    /// I Don’t Have the Main Seed Phrase
    internal static let noMainSeedPhraseButton = L10n.tr("Localizable", "recoverSeedPhrase_noMainSeedPhraseButton", fallback: "I Don’t Have the Main Seed Phrase")
    /// Skip This Seed Phrase For Now
    internal static let skipButton = L10n.tr("Localizable", "recoverSeedPhrase_skipButton", fallback: "Skip This Seed Phrase For Now")
    /// Skip Main Seed Phrase Entry
    internal static let skipMainSeedPhraseButton = L10n.tr("Localizable", "recoverSeedPhrase_skipMainSeedPhraseButton", fallback: "Skip Main Seed Phrase Entry")
    internal enum Header {
      /// Your **Personas** and the following **Accounts** are controlled by your main seed phrase. To recover control, you must re-enter it.
      internal static let subtitleMainSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_subtitleMainSeedPhrase", fallback: "Your **Personas** and the following **Accounts** are controlled by your main seed phrase. To recover control, you must re-enter it.")
      /// The Radix Wallet always uses a single main “Babylon” seed phrase to generate new Personas and new Accounts (when not using a Ledger device).
      /// 
      /// If you do not have access to your previous main seed phrase, you can skip entering it for now. **The Radix Wallet will create a new one, which will be used for new Personas and Accounts.**
      /// 
      /// Your old Accounts and Personas will still be listed, but you will have to enter their original seed phrase to use them. Alternatively, you can hide them if you no longer are interested in using them.
      internal static let subtitleNoMainSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_subtitleNoMainSeedPhrase", fallback: "The Radix Wallet always uses a single main “Babylon” seed phrase to generate new Personas and new Accounts (when not using a Ledger device).\n\nIf you do not have access to your previous main seed phrase, you can skip entering it for now. **The Radix Wallet will create a new one, which will be used for new Personas and Accounts.**\n\nYour old Accounts and Personas will still be listed, but you will have to enter their original seed phrase to use them. Alternatively, you can hide them if you no longer are interested in using them.")
      /// The following **Accounts** are controlled by a seed phrase. To recover control, you must re-enter it.
      internal static let subtitleOtherSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_subtitleOtherSeedPhrase", fallback: "The following **Accounts** are controlled by a seed phrase. To recover control, you must re-enter it.")
      /// Main Seed Phrase Required
      internal static let titleMain = L10n.tr("Localizable", "recoverSeedPhrase_header_titleMain", fallback: "Main Seed Phrase Required")
      /// No Main Seed Phrase?
      internal static let titleNoMainSeedPhrase = L10n.tr("Localizable", "recoverSeedPhrase_header_titleNoMainSeedPhrase", fallback: "No Main Seed Phrase?")
      /// Seed Phrase Required
      internal static let titleOther = L10n.tr("Localizable", "recoverSeedPhrase_header_titleOther", fallback: "Seed Phrase Required")
    }
  }
  internal enum RecoverWalletWithoutProfile {
    internal enum Complete {
      /// Continue
      internal static let continueButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_complete_continueButton", fallback: "Continue")
      /// Accounts discovered in the scan have been added to your wallet.
      /// 
      /// If you have any “Legacy” Accounts (created on the Olympia network) to import - or any Accounts using a Ledger hardware wallet device - please continue and then use the **Account Recovery Scan** option in your Radix Wallet settings under **Account Security**.
      internal static let headerSubtitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_complete_headerSubtitle", fallback: "Accounts discovered in the scan have been added to your wallet.\n\nIf you have any “Legacy” Accounts (created on the Olympia network) to import - or any Accounts using a Ledger hardware wallet device - please continue and then use the **Account Recovery Scan** option in your Radix Wallet settings under **Account Security**.")
      /// Recovery Complete
      internal static let headerTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_complete_headerTitle", fallback: "Recovery Complete")
    }
    internal enum Info {
      /// Continue
      internal static let continueButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_info_continueButton", fallback: "Continue")
      /// **If you have no wallet backup in the cloud or as an exported backup file**, you can still restore Account access only using your main “Babylon” seed phrase. You cannot recover your Account names or other wallet settings this way.
      /// 
      /// You will be asked to enter your main seed phrase. This is a set of **24 words** that the Radix Wallet mobile app showed you to write down and save securely.
      internal static let headerSubtitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_info_headerSubtitle", fallback: "**If you have no wallet backup in the cloud or as an exported backup file**, you can still restore Account access only using your main “Babylon” seed phrase. You cannot recover your Account names or other wallet settings this way.\n\nYou will be asked to enter your main seed phrase. This is a set of **24 words** that the Radix Wallet mobile app showed you to write down and save securely.")
      /// Recover Control Without Backup
      internal static let headerTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_info_headerTitle", fallback: "Recover Control Without Backup")
    }
    internal enum Start {
      /// Recover with Main Seed Phrase
      internal static let babylonSectionButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_babylonSectionButton", fallback: "Recover with Main Seed Phrase")
      /// I have my main “Babylon” 24-word seed phrase.
      internal static let babylonSectionTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_babylonSectionTitle", fallback: "I have my main “Babylon” 24-word seed phrase.")
      /// Ledger-only Restore
      internal static let hardwareSectionButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_hardwareSectionButton", fallback: "Ledger-only Restore")
      /// I only want to restore Ledger hardware wallet Accounts.
      internal static let hardwareSectionTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_hardwareSectionTitle", fallback: "I only want to restore Ledger hardware wallet Accounts.")
      /// If you have no wallet backup in the cloud, or as an exported backup file, you still have other restore options.
      internal static let headerSubtitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_headerSubtitle", fallback: "If you have no wallet backup in the cloud, or as an exported backup file, you still have other restore options.")
      /// Recover Control Without Backup
      internal static let headerTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_headerTitle", fallback: "Recover Control Without Backup")
      /// Olympia-only Restore
      internal static let olympiaSectionButton = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_olympiaSectionButton", fallback: "Olympia-only Restore")
      /// I only have Accounts created on the Radix Olympia network.
      internal static let olympiaSectionTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_olympiaSectionTitle", fallback: "I only have Accounts created on the Radix Olympia network.")
      /// Cancel
      internal static let useNewWalletAlertCancel = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertCancel", fallback: "Cancel")
      /// Continue
      internal static let useNewWalletAlertContinue = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertContinue", fallback: "Continue")
      /// Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Ledger device.
      internal static let useNewWalletAlertMessageHardware = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertMessageHardware", fallback: "Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Ledger device.")
      /// Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Olympia seed phrase.
      internal static let useNewWalletAlertMessageOlympia = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertMessageOlympia", fallback: "Tap “I'm a New Wallet User”. After completing wallet creation, in Settings you can perform an “account recovery scan” using your Olympia seed phrase.")
      /// No Main Seed Phrase?
      internal static let useNewWalletAlertTitle = L10n.tr("Localizable", "recoverWalletWithoutProfile_start_useNewWalletAlertTitle", fallback: "No Main Seed Phrase?")
    }
  }
  internal enum RenameLabel {
    /// Updated
    internal static let success = L10n.tr("Localizable", "renameLabel_success", fallback: "Updated")
    /// Update
    internal static let update = L10n.tr("Localizable", "renameLabel_update", fallback: "Update")
    internal enum Account {
      /// Account label required
      internal static let empty = L10n.tr("Localizable", "renameLabel_account_empty", fallback: "Account label required")
      /// Enter a new label for this Account
      internal static let subtitle = L10n.tr("Localizable", "renameLabel_account_subtitle", fallback: "Enter a new label for this Account")
      /// Rename Account
      internal static let title = L10n.tr("Localizable", "renameLabel_account_title", fallback: "Rename Account")
      /// Account label too long
      internal static let tooLong = L10n.tr("Localizable", "renameLabel_account_tooLong", fallback: "Account label too long")
    }
    internal enum Connector {
      /// Linked Connector name required
      internal static let empty = L10n.tr("Localizable", "renameLabel_connector_empty", fallback: "Linked Connector name required")
      /// Enter a new name for this Linked Connector
      internal static let subtitle = L10n.tr("Localizable", "renameLabel_connector_subtitle", fallback: "Enter a new name for this Linked Connector")
      /// Rename Connector
      internal static let title = L10n.tr("Localizable", "renameLabel_connector_title", fallback: "Rename Connector")
    }
    internal enum FactorSource {
      /// Factor Source name required
      internal static let empty = L10n.tr("Localizable", "renameLabel_factorSource_empty", fallback: "Factor Source name required")
      /// Enter a new name for this Factor Source
      internal static let subtitle = L10n.tr("Localizable", "renameLabel_factorSource_subtitle", fallback: "Enter a new name for this Factor Source")
      /// Rename Factor Source
      internal static let title = L10n.tr("Localizable", "renameLabel_factorSource_title", fallback: "Rename Factor Source")
      /// Factor Source name too long
      internal static let tooLong = L10n.tr("Localizable", "renameLabel_factorSource_tooLong", fallback: "Factor Source name too long")
    }
  }
  internal enum RevealSeedPhrase {
    /// Passphrase
    internal static let passphrase = L10n.tr("Localizable", "revealSeedPhrase_passphrase", fallback: "Passphrase")
    /// Reveal Seed Phrase
    internal static let title = L10n.tr("Localizable", "revealSeedPhrase_title", fallback: "Reveal Seed Phrase")
    /// For your safety, make sure no one is looking at your screen. Taking a screen shot has been disabled.
    internal static let warning = L10n.tr("Localizable", "revealSeedPhrase_warning", fallback: "For your safety, make sure no one is looking at your screen. Taking a screen shot has been disabled.")
    /// Word %d
    internal static func wordLabel(_ p1: Int) -> String {
      return L10n.tr("Localizable", "revealSeedPhrase_wordLabel", p1, fallback: "Word %d")
    }
    internal enum WarningDialog {
      /// I have written down this seed phrase
      internal static let confirmButton = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_confirmButton", fallback: "I have written down this seed phrase")
      /// Are you sure you have written down your seed phrase?
      internal static let subtitle = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_subtitle", fallback: "Are you sure you have written down your seed phrase?")
      /// Use Caution
      internal static let title = L10n.tr("Localizable", "revealSeedPhrase_warningDialog_title", fallback: "Use Caution")
    }
  }
  internal enum ScanQR {
    internal enum Account {
      /// Scan a QR code of a Radix Account address from another wallet or an exchange.
      internal static let instructions = L10n.tr("Localizable", "scanQR_account_instructions", fallback: "Scan a QR code of a Radix Account address from another wallet or an exchange.")
    }
    internal enum ConnectorExtension {
      /// Go to **wallet.radixdlt.com** in your desktop browser.
      internal static let disclosureItem1 = L10n.tr("Localizable", "scanQR_connectorExtension_disclosureItem1", fallback: "Go to **wallet.radixdlt.com** in your desktop browser.")
      /// Follow the instructions there to install the Radix Connector.
      internal static let disclosureItem2 = L10n.tr("Localizable", "scanQR_connectorExtension_disclosureItem2", fallback: "Follow the instructions there to install the Radix Connector.")
      /// Don't have the Radix Connector browser extension?
      internal static let disclosureTitle = L10n.tr("Localizable", "scanQR_connectorExtension_disclosureTitle", fallback: "Don't have the Radix Connector browser extension?")
      /// Scan the QR code in the Radix Connector browser extension.
      internal static let instructions = L10n.tr("Localizable", "scanQR_connectorExtension_instructions", fallback: "Scan the QR code in the Radix Connector browser extension.")
    }
    internal enum ImportOlympia {
      /// Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.
      internal static let instructions = L10n.tr("Localizable", "scanQR_importOlympia_instructions", fallback: "Scan the QR code shown in the Export section of the Radix Desktop Wallet for Olympia.")
    }
  }
  internal enum SecurityCenter {
    /// Decentralized security settings that give you total control over your wallet’s protection.
    internal static let subtitle = L10n.tr("Localizable", "securityCenter_subtitle", fallback: "Decentralized security settings that give you total control over your wallet’s protection.")
    /// Security Center
    internal static let title = L10n.tr("Localizable", "securityCenter_title", fallback: "Security Center")
    internal enum AnyItem {
      /// Action required
      internal static let actionRequiredStatus = L10n.tr("Localizable", "securityCenter_anyItem_actionRequiredStatus", fallback: "Action required")
    }
    internal enum ConfigurationBackupItem {
      /// Backed up
      internal static let backedUpStatus = L10n.tr("Localizable", "securityCenter_configurationBackupItem_backedUpStatus", fallback: "Backed up")
      /// A backup of your Account, Personas and wallet settings
      internal static let subtitle = L10n.tr("Localizable", "securityCenter_configurationBackupItem_subtitle", fallback: "A backup of your Account, Personas and wallet settings")
      /// Configuration Backup
      internal static let title = L10n.tr("Localizable", "securityCenter_configurationBackupItem_title", fallback: "Configuration Backup")
    }
    internal enum EncryptWalletBackup {
      /// Confirm Password
      internal static let confirmPassword = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_confirmPassword", fallback: "Confirm Password")
      /// Continue
      internal static let `continue` = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_continue", fallback: "Continue")
      /// Enter Password
      internal static let enterPassword = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_enterPassword", fallback: "Enter Password")
      /// Passwords do not match
      internal static let passwordMismatchError = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_passwordMismatchError", fallback: "Passwords do not match")
      /// Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.
      internal static let subtitle = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_subtitle", fallback: "Enter a password to encrypt this wallet backup file. You will be required to enter this password when recovering your Wallet from this file.")
      /// Encrypt Wallet Backup File
      internal static let title = L10n.tr("Localizable", "securityCenter_encryptWalletBackup_title", fallback: "Encrypt Wallet Backup File")
    }
    internal enum GoodState {
      /// Your wallet is recoverable
      internal static let heading = L10n.tr("Localizable", "securityCenter_goodState_heading", fallback: "Your wallet is recoverable")
    }
    internal enum SecurityFactorsItem {
      /// Active
      internal static let activeStatus = L10n.tr("Localizable", "securityCenter_securityFactorsItem_activeStatus", fallback: "Active")
      /// The keys you use to control your Accounts and Personas
      internal static let subtitle = L10n.tr("Localizable", "securityCenter_securityFactorsItem_subtitle", fallback: "The keys you use to control your Accounts and Personas")
      /// Security Factors
      internal static let title = L10n.tr("Localizable", "securityCenter_securityFactorsItem_title", fallback: "Security Factors")
    }
    internal enum SecurityShieldsItem {
      /// Shielded
      internal static let shieldedStatus = L10n.tr("Localizable", "securityCenter_securityShieldsItem_shieldedStatus", fallback: "Shielded")
      /// Decentralized multi-factor signing and recovery for your Accounts and Personas
      internal static let subtitle = L10n.tr("Localizable", "securityCenter_securityShieldsItem_subtitle", fallback: "Decentralized multi-factor signing and recovery for your Accounts and Personas")
      /// Security Shields
      internal static let title = L10n.tr("Localizable", "securityCenter_securityShieldsItem_title", fallback: "Security Shields")
    }
  }
  internal enum SecurityFactors {
    /// Hardware
    internal static let hardware = L10n.tr("Localizable", "securityFactors_hardware", fallback: "Hardware")
    /// Things you know
    internal static let information = L10n.tr("Localizable", "securityFactors_information", fallback: "Things you know")
    /// Manage the security factors you’ll use in your Security Shields.
    internal static let subtitle = L10n.tr("Localizable", "securityFactors_subtitle", fallback: "Manage the security factors you’ll use in your Security Shields.")
    /// Security Factors
    internal static let title = L10n.tr("Localizable", "securityFactors_title", fallback: "Security Factors")
    internal enum LedgerWallet {
      /// %d set
      internal static func counterPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "securityFactors_ledgerWallet_counterPlural", p1, fallback: "%d set")
      }
      /// 1 set
      internal static let counterSingular = L10n.tr("Localizable", "securityFactors_ledgerWallet_counterSingular", fallback: "1 set")
      /// Hardware wallet designed for holding crypto
      internal static let subtitle = L10n.tr("Localizable", "securityFactors_ledgerWallet_subtitle", fallback: "Hardware wallet designed for holding crypto")
      /// Ledger Hardware Wallets
      internal static let title = L10n.tr("Localizable", "securityFactors_ledgerWallet_title", fallback: "Ledger Hardware Wallets")
    }
    internal enum SeedPhrases {
      /// %d Seed phrases
      internal static func counterPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "securityFactors_seedPhrases_counterPlural", p1, fallback: "%d Seed phrases")
      }
      /// 1 Seed phrase
      internal static let counterSingular = L10n.tr("Localizable", "securityFactors_seedPhrases_counterSingular", fallback: "1 Seed phrase")
      /// Enter your seed phrase to recover Accounts
      internal static let enterSeedPhrase = L10n.tr("Localizable", "securityFactors_seedPhrases_enterSeedPhrase", fallback: "Enter your seed phrase to recover Accounts")
      /// Your seedphrases connected to your account
      internal static let subtitle = L10n.tr("Localizable", "securityFactors_seedPhrases_subtitle", fallback: "Your seedphrases connected to your account")
      /// Seed Phrases
      internal static let title = L10n.tr("Localizable", "securityFactors_seedPhrases_title", fallback: "Seed Phrases")
    }
    internal enum SelectFactor {
      /// Can't currently be used here. **Learn why**
      internal static let disabled = L10n.tr("Localizable", "securityFactors_selectFactor_disabled", fallback: "Can't currently be used here. **Learn why**")
      /// Select Factor Type
      internal static let title = L10n.tr("Localizable", "securityFactors_selectFactor_title", fallback: "Select Factor Type")
    }
  }
  internal enum SecurityProblems {
    internal enum Common {
      /// %d accounts
      internal static func accountPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "securityProblems_common_accountPlural", p1, fallback: "%d accounts")
      }
      /// 1 account
      internal static let accountSingular = L10n.tr("Localizable", "securityProblems_common_accountSingular", fallback: "1 account")
      /// %d personas
      internal static func personaPlural(_ p1: Int) -> String {
        return L10n.tr("Localizable", "securityProblems_common_personaPlural", p1, fallback: "%d personas")
      }
      /// 1 persona
      internal static let personaSingular = L10n.tr("Localizable", "securityProblems_common_personaSingular", fallback: "1 persona")
    }
    internal enum No3 {
      /// You need to write down a seed phrase
      internal static let accountCard = L10n.tr("Localizable", "securityProblems_no3_accountCard", fallback: "You need to write down a seed phrase")
      /// You need to write down a seed phrase
      internal static let personas = L10n.tr("Localizable", "securityProblems_no3_personas", fallback: "You need to write down a seed phrase")
      /// View and write down your seed phrase so Accounts and Personas are recoverable.
      internal static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no3_securityCenterBody", fallback: "View and write down your seed phrase so Accounts and Personas are recoverable.")
      /// %@ and %@ are not recoverable.
      internal static func securityCenterTitle(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "securityProblems_no3_securityCenterTitle", String(describing: p1), String(describing: p2), fallback: "%@ and %@ are not recoverable.")
      }
      /// %@ and %@ (plus some hidden) are not recoverable.
      internal static func securityCenterTitleHidden(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "securityProblems_no3_securityCenterTitleHidden", String(describing: p1), String(describing: p2), fallback: "%@ and %@ (plus some hidden) are not recoverable.")
      }
      /// View and write down seed phrase
      internal static let securityFactors = L10n.tr("Localizable", "securityProblems_no3_securityFactors", fallback: "View and write down seed phrase")
      /// View and write down seed phrase
      internal static let seedPhrases = L10n.tr("Localizable", "securityProblems_no3_seedPhrases", fallback: "View and write down seed phrase")
      /// Personas are not recoverable
      internal static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no3_walletSettingsPersonas", fallback: "Personas are not recoverable")
    }
    internal enum No5 {
      /// Problem with Configuration Backup
      internal static let accountCard = L10n.tr("Localizable", "securityProblems_no5_accountCard", fallback: "Problem with Configuration Backup")
      /// Automated Configuration Backup not working. Check internet connection and cloud settings.
      internal static let configurationBackup = L10n.tr("Localizable", "securityProblems_no5_configurationBackup", fallback: "Automated Configuration Backup not working. Check internet connection and cloud settings.")
      /// Problem with Configuration Backup
      internal static let personas = L10n.tr("Localizable", "securityProblems_no5_personas", fallback: "Problem with Configuration Backup")
      /// Automated Configuration Backup has stopped working. Check internet and cloud settings.
      internal static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no5_securityCenterBody", fallback: "Automated Configuration Backup has stopped working. Check internet and cloud settings.")
      /// Your wallet is not recoverable
      internal static let securityCenterTitle = L10n.tr("Localizable", "securityProblems_no5_securityCenterTitle", fallback: "Your wallet is not recoverable")
      /// Personas are not recoverable
      internal static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no5_walletSettingsPersonas", fallback: "Personas are not recoverable")
    }
    internal enum No6 {
      /// Your wallet is not recoverable
      internal static let accountCard = L10n.tr("Localizable", "securityProblems_no6_accountCard", fallback: "Your wallet is not recoverable")
      /// To secure your wallet, turn on automated backups or manually export backup file.
      internal static let configurationBackup = L10n.tr("Localizable", "securityProblems_no6_configurationBackup", fallback: "To secure your wallet, turn on automated backups or manually export backup file.")
      /// Your wallet is not recoverable
      internal static let personas = L10n.tr("Localizable", "securityProblems_no6_personas", fallback: "Your wallet is not recoverable")
      /// Configuration Backup is not up to date. Create backup now.
      internal static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no6_securityCenterBody", fallback: "Configuration Backup is not up to date. Create backup now.")
      /// Your wallet is not recoverable
      internal static let securityCenterTitle = L10n.tr("Localizable", "securityProblems_no6_securityCenterTitle", fallback: "Your wallet is not recoverable")
      /// Personas are not recoverable
      internal static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no6_walletSettingsPersonas", fallback: "Personas are not recoverable")
    }
    internal enum No7 {
      /// Configuration Backup not up to date
      internal static let accountCard = L10n.tr("Localizable", "securityProblems_no7_accountCard", fallback: "Configuration Backup not up to date")
      /// Configuration Backup not up to date. Turn on automated backups or manually export backup file.
      internal static let configurationBackup = L10n.tr("Localizable", "securityProblems_no7_configurationBackup", fallback: "Configuration Backup not up to date. Turn on automated backups or manually export backup file.")
      /// Configuration Backup not up to date
      internal static let personas = L10n.tr("Localizable", "securityProblems_no7_personas", fallback: "Configuration Backup not up to date")
      /// Accounts and Personas not recoverable. Create Configuration Backup now.
      internal static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no7_securityCenterBody", fallback: "Accounts and Personas not recoverable. Create Configuration Backup now.")
      /// Your wallet is not recoverable
      internal static let securityCenterTitle = L10n.tr("Localizable", "securityProblems_no7_securityCenterTitle", fallback: "Your wallet is not recoverable")
      /// Personas are not recoverable
      internal static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no7_walletSettingsPersonas", fallback: "Personas are not recoverable")
    }
    internal enum No9 {
      /// Recovery required
      internal static let accountCard = L10n.tr("Localizable", "securityProblems_no9_accountCard", fallback: "Recovery required")
      /// Recovery required
      internal static let personas = L10n.tr("Localizable", "securityProblems_no9_personas", fallback: "Recovery required")
      /// Enter seed phrase to recover control.
      internal static let securityCenterBody = L10n.tr("Localizable", "securityProblems_no9_securityCenterBody", fallback: "Enter seed phrase to recover control.")
      /// Recovery required
      internal static let securityCenterTitle = L10n.tr("Localizable", "securityProblems_no9_securityCenterTitle", fallback: "Recovery required")
      /// Enter seed phrase to recover use
      internal static let securityFactors = L10n.tr("Localizable", "securityProblems_no9_securityFactors", fallback: "Enter seed phrase to recover use")
      /// Enter seed phrase to recover control
      internal static let seedPhrases = L10n.tr("Localizable", "securityProblems_no9_seedPhrases", fallback: "Enter seed phrase to recover control")
      /// Recovery required
      internal static let walletSettingsPersonas = L10n.tr("Localizable", "securityProblems_no9_walletSettingsPersonas", fallback: "Recovery required")
    }
  }
  internal enum SeedPhrases {
    /// Please write down your Seed Phrase
    internal static let backupWarning = L10n.tr("Localizable", "seedPhrases_backupWarning", fallback: "Please write down your Seed Phrase")
    /// Hidden Accounts only
    internal static let hiddenAccountsOnly = L10n.tr("Localizable", "seedPhrases_hiddenAccountsOnly", fallback: "Hidden Accounts only")
    /// A Seed Phrase provides full access to your accounts and funds. When viewing, ensure you’re in a safe environment and no one is looking at your screen.
    internal static let message = L10n.tr("Localizable", "seedPhrases_message", fallback: "A Seed Phrase provides full access to your accounts and funds. When viewing, ensure you’re in a safe environment and no one is looking at your screen.")
    /// Seed Phrases
    internal static let title = L10n.tr("Localizable", "seedPhrases_title", fallback: "Seed Phrases")
    /// You are responsible for the security of your Seed Phrase
    internal static let warning = L10n.tr("Localizable", "seedPhrases_warning", fallback: "You are responsible for the security of your Seed Phrase")
    internal enum SeedPhrase {
      /// Seed Phrase Entry Required
      internal static let headingNeedsImport = L10n.tr("Localizable", "seedPhrases_seedPhrase_headingNeedsImport", fallback: "Seed Phrase Entry Required")
      /// Reveal Seed Phrase
      internal static let headingReveal = L10n.tr("Localizable", "seedPhrases_seedPhrase_headingReveal", fallback: "Reveal Seed Phrase")
      /// Seed Phrase
      internal static let headingScan = L10n.tr("Localizable", "seedPhrases_seedPhrase_headingScan", fallback: "Seed Phrase")
      /// Connected to %d Accounts
      internal static func multipleConnectedAccounts(_ p1: Int) -> String {
        return L10n.tr("Localizable", "seedPhrases_seedPhrase_multipleConnectedAccounts", p1, fallback: "Connected to %d Accounts")
      }
      /// Not connected to any Accounts
      internal static let noConnectedAccounts = L10n.tr("Localizable", "seedPhrases_seedPhrase_noConnectedAccounts", fallback: "Not connected to any Accounts")
      /// Connected to 1 Account
      internal static let oneConnectedAccount = L10n.tr("Localizable", "seedPhrases_seedPhrase_oneConnectedAccount", fallback: "Connected to 1 Account")
    }
  }
  internal enum Settings {
    /// Account Security & Settings
    internal static let accountSecurityAndSettings = L10n.tr("Localizable", "settings_accountSecurityAndSettings", fallback: "Account Security & Settings")
    /// App Settings
    internal static let appSettings = L10n.tr("Localizable", "settings_appSettings", fallback: "App Settings")
    /// Version: %@ build #%@
    internal static func appVersion(_ p1: Any, _ p2: Any) -> String {
      return L10n.tr("Localizable", "settings_appVersion", String(describing: p1), String(describing: p2), fallback: "Version: %@ build #%@")
    }
    /// Authorized dApps
    internal static let authorizedDapps = L10n.tr("Localizable", "settings_authorizedDapps", fallback: "Authorized dApps")
    /// Personas
    internal static let personas = L10n.tr("Localizable", "settings_personas", fallback: "Personas")
    /// Please write down the seed phrase for your Personas
    internal static let personasSeedPhrasePrompt = L10n.tr("Localizable", "settings_personasSeedPhrasePrompt", fallback: "Please write down the seed phrase for your Personas")
    /// Settings
    internal static let title = L10n.tr("Localizable", "settings_title", fallback: "Settings")
    internal enum ImportFromLegacyWalletHeader {
      /// Import Legacy Accounts
      internal static let importLegacyAccounts = L10n.tr("Localizable", "settings_importFromLegacyWalletHeader_importLegacyAccounts", fallback: "Import Legacy Accounts")
      /// Get started importing your Olympia accounts into your new Radix Wallet
      internal static let subtitle = L10n.tr("Localizable", "settings_importFromLegacyWalletHeader_subtitle", fallback: "Get started importing your Olympia accounts into your new Radix Wallet")
      /// Radix Olympia Desktop Wallet user?
      internal static let title = L10n.tr("Localizable", "settings_importFromLegacyWalletHeader_title", fallback: "Radix Olympia Desktop Wallet user?")
    }
    internal enum LinkToConnectorHeader {
      /// Link to Connector
      internal static let linkToConnector = L10n.tr("Localizable", "settings_linkToConnectorHeader_linkToConnector", fallback: "Link to Connector")
      /// Scan the QR code in the Radix Wallet Connector extension
      internal static let subtitle = L10n.tr("Localizable", "settings_linkToConnectorHeader_subtitle", fallback: "Scan the QR code in the Radix Wallet Connector extension")
      /// Link your Wallet to a Desktop Browser
      internal static let title = L10n.tr("Localizable", "settings_linkToConnectorHeader_title", fallback: "Link your Wallet to a Desktop Browser")
    }
  }
  internal enum ShieldSetupOnboarding {
    /// Next
    internal static let nextButtonTitle = L10n.tr("Localizable", "shieldSetupOnboarding_nextButtonTitle", fallback: "Next")
    /// Start
    internal static let startButtonTitle = L10n.tr("Localizable", "shieldSetupOnboarding_startButtonTitle", fallback: "Start")
    internal enum ApplyShieldStep {
      /// Sign a transaction to apply your Shield to your Accounts and Personas.
      /// 
      /// You can use the same Shield for all of them or create multiple Shields.
      internal static let subtitle = L10n.tr("Localizable", "shieldSetupOnboarding_applyShieldStep_subtitle", fallback: "Sign a transaction to apply your Shield to your Accounts and Personas.\n\nYou can use the same Shield for all of them or create multiple Shields.")
      /// Apply your Shield to your Accounts and Personas
      internal static let title = L10n.tr("Localizable", "shieldSetupOnboarding_applyShieldStep_title", fallback: "Apply your Shield to your Accounts and Personas")
    }
    internal enum BuildShieldStep {
      /// Add your security factors to your Radix Wallet and use them to build your Shield.
      internal static let subtitle = L10n.tr("Localizable", "shieldSetupOnboarding_buildShieldStep_subtitle", fallback: "Add your security factors to your Radix Wallet and use them to build your Shield.")
      /// Add your security factors and build your Shield
      internal static let title = L10n.tr("Localizable", "shieldSetupOnboarding_buildShieldStep_title", fallback: "Add your security factors and build your Shield")
    }
    internal enum IntroStep {
      /// Create your Security Shield by combining different security factors. Use it to safely sign transactions and recover Accounts if you’ve lost access.
      internal static let subtitle = L10n.tr("Localizable", "shieldSetupOnboarding_introStep_subtitle", fallback: "Create your Security Shield by combining different security factors. Use it to safely sign transactions and recover Accounts if you’ve lost access.")
      /// Multi-factor authentication for web3
      internal static let title = L10n.tr("Localizable", "shieldSetupOnboarding_introStep_title", fallback: "Multi-factor authentication for web3")
    }
  }
  internal enum ShieldSetupPrepareFactors {
    internal enum AddAnotherFactor {
      /// Add Factor
      internal static let button = L10n.tr("Localizable", "shieldSetupPrepareFactors_addAnotherFactor_button", fallback: "Add Factor")
      /// Choosing a mnemonic is only recommended for advanced users
      internal static let passphraseHint = L10n.tr("Localizable", "shieldSetupPrepareFactors_addAnotherFactor_passphraseHint", fallback: "Choosing a mnemonic is only recommended for advanced users")
      /// You need to add **1 more factor** to begin building your Shield.
      internal static let subtitle = L10n.tr("Localizable", "shieldSetupPrepareFactors_addAnotherFactor_subtitle", fallback: "You need to add **1 more factor** to begin building your Shield.")
      /// Add Another Factor
      internal static let title = L10n.tr("Localizable", "shieldSetupPrepareFactors_addAnotherFactor_title", fallback: "Add Another Factor")
    }
    internal enum AddHardwareFactor {
      /// Add Hardware Device
      internal static let button = L10n.tr("Localizable", "shieldSetupPrepareFactors_addHardwareFactor_button", fallback: "Add Hardware Device")
      /// I don’t have a hardware device
      internal static let noDeviceButton = L10n.tr("Localizable", "shieldSetupPrepareFactors_addHardwareFactor_noDeviceButton", fallback: "I don’t have a hardware device")
      /// Choose a hardware device to use as a security factor in your Shield.
      internal static let subtitle = L10n.tr("Localizable", "shieldSetupPrepareFactors_addHardwareFactor_subtitle", fallback: "Choose a hardware device to use as a security factor in your Shield.")
      /// Add a Hardware Device
      internal static let title = L10n.tr("Localizable", "shieldSetupPrepareFactors_addHardwareFactor_title", fallback: "Add a Hardware Device")
    }
    internal enum Completion {
      /// Build Shield
      internal static let button = L10n.tr("Localizable", "shieldSetupPrepareFactors_completion_button", fallback: "Build Shield")
      /// Before it’s finished, you’ll have the chance to review it and make any changes.
      internal static let subtitleBottom = L10n.tr("Localizable", "shieldSetupPrepareFactors_completion_subtitleBottom", fallback: "Before it’s finished, you’ll have the chance to review it and make any changes.")
      /// Now let’s build your Shield.
      internal static let subtitleTop = L10n.tr("Localizable", "shieldSetupPrepareFactors_completion_subtitleTop", fallback: "Now let’s build your Shield.")
      /// Your Factors are Ready
      internal static let title = L10n.tr("Localizable", "shieldSetupPrepareFactors_completion_title", fallback: "Your Factors are Ready")
    }
    internal enum Intro {
      /// Start
      internal static let button = L10n.tr("Localizable", "shieldSetupPrepareFactors_intro_button", fallback: "Start")
      /// A future wallet update will enable Shields without needing a hardware device.
      internal static let subtitleBottom = L10n.tr("Localizable", "shieldSetupPrepareFactors_intro_subtitleBottom", fallback: "A future wallet update will enable Shields without needing a hardware device.")
      /// You need at least **2 factors** to build a Security Shield. 1 of your factors must be a hardware device.
      internal static let subtitleTop = L10n.tr("Localizable", "shieldSetupPrepareFactors_intro_subtitleTop", fallback: "You need at least **2 factors** to build a Security Shield. 1 of your factors must be a hardware device.")
      /// Let’s Prepare your Factors
      internal static let title = L10n.tr("Localizable", "shieldSetupPrepareFactors_intro_title", fallback: "Let’s Prepare your Factors")
    }
  }
  internal enum ShieldSetupSelectFactors {
    /// Build Shield
    internal static let buildButtonTitle = L10n.tr("Localizable", "shieldSetupSelectFactors_buildButtonTitle", fallback: "Build Shield")
    /// Choose the factors you’ll use for regular access. You’ll use **all** of these factors every time you send assets.
    internal static let subtitle = L10n.tr("Localizable", "shieldSetupSelectFactors_subtitle", fallback: "Choose the factors you’ll use for regular access. You’ll use **all** of these factors every time you send assets.")
    /// Select Factors for Regular Access
    internal static let title = L10n.tr("Localizable", "shieldSetupSelectFactors_title", fallback: "Select Factors for Regular Access")
  }
  internal enum ShieldSetupStatus {
    /// Cannot use this factor type by itself
    internal static let factorCannotBeUsedByItself = L10n.tr("Localizable", "shieldSetupStatus_factorCannotBeUsedByItself", fallback: "Cannot use this factor type by itself")
    /// You cannot create a Shield with this combination of factors. **Read more**
    internal static let invalidCombination = L10n.tr("Localizable", "shieldSetupStatus_invalidCombination", fallback: "You cannot create a Shield with this combination of factors. **Read more**")
    /// Choosing 2 factors will make your Shield more secure and reliable
    internal static let recommendedFactors = L10n.tr("Localizable", "shieldSetupStatus_recommendedFactors", fallback: "Choosing 2 factors will make your Shield more secure and reliable")
    internal enum Authentication {
      /// You need to choose a factor to continue
      internal static let atLeastOneFactor = L10n.tr("Localizable", "shieldSetupStatus_authentication_atLeastOneFactor", fallback: "You need to choose a factor to continue")
    }
    internal enum Transactions {
      /// You need to select at least 1 factor for signing transactions
      internal static let atLeastOneFactor = L10n.tr("Localizable", "shieldSetupStatus_transactions_atLeastOneFactor", fallback: "You need to select at least 1 factor for signing transactions")
    }
  }
  internal enum ShieldWizardName {
    /// Give this Security Shield a name, so you can identify it later.
    internal static let subtitle = L10n.tr("Localizable", "shieldWizardName_subtitle", fallback: "Give this Security Shield a name, so you can identify it later.")
    /// Name your Security Shield
    internal static let title = L10n.tr("Localizable", "shieldWizardName_title", fallback: "Name your Security Shield")
    /// Security Shield name too long
    internal static let tooLong = L10n.tr("Localizable", "shieldWizardName_tooLong", fallback: "Security Shield name too long")
  }
  internal enum ShieldWizardRecovery {
    /// Recovery
    internal static let title = L10n.tr("Localizable", "shieldWizardRecovery_title", fallback: "Recovery")
    internal enum Combination {
      /// OR
      internal static let label = L10n.tr("Localizable", "shieldWizardRecovery_combination_label", fallback: "OR")
    }
    internal enum Confirm {
      /// Factors you can use to complete the recovery of your Accounts and Personas.
      internal static let subtitle = L10n.tr("Localizable", "shieldWizardRecovery_confirm_subtitle", fallback: "Factors you can use to complete the recovery of your Accounts and Personas.")
      /// Confirming a Recovery
      internal static let title = L10n.tr("Localizable", "shieldWizardRecovery_confirm_title", fallback: "Confirming a Recovery")
    }
    internal enum Factors {
      /// You'll need to use the following:
      internal static let title = L10n.tr("Localizable", "shieldWizardRecovery_factors_title", fallback: "You'll need to use the following:")
    }
    internal enum Fallback {
      /// We recommend setting this for an extended period, so you have time to notice and cancel a recovery you don’t want.
      internal static let note = L10n.tr("Localizable", "shieldWizardRecovery_fallback_note", fallback: "We recommend setting this for an extended period, so you have time to notice and cancel a recovery you don’t want.")
      /// Set a time period to automatically confirm recovery **WITHOUT** presenting any of the above confirmation factors.
      internal static let subtitle = L10n.tr("Localizable", "shieldWizardRecovery_fallback_subtitle", fallback: "Set a time period to automatically confirm recovery **WITHOUT** presenting any of the above confirmation factors.")
      /// Emergency Fallback
      internal static let title = L10n.tr("Localizable", "shieldWizardRecovery_fallback_title", fallback: "Emergency Fallback")
      internal enum Day {
        /// Day
        internal static let label = L10n.tr("Localizable", "shieldWizardRecovery_fallback_day_label", fallback: "Day")
      }
      internal enum Days {
        /// Days
        internal static let label = L10n.tr("Localizable", "shieldWizardRecovery_fallback_days_label", fallback: "Days")
      }
      internal enum Week {
        /// Week
        internal static let label = L10n.tr("Localizable", "shieldWizardRecovery_fallback_week_label", fallback: "Week")
      }
      internal enum Weeks {
        /// Weeks
        internal static let label = L10n.tr("Localizable", "shieldWizardRecovery_fallback_weeks_label", fallback: "Weeks")
      }
    }
    internal enum SetFallback {
      /// Set
      internal static let button = L10n.tr("Localizable", "shieldWizardRecovery_setFallback_button", fallback: "Set")
      /// Set a time period to automatically confirm recovery **WITHOUT** presenting any confirmation factors.
      internal static let subtitle = L10n.tr("Localizable", "shieldWizardRecovery_setFallback_subtitle", fallback: "Set a time period to automatically confirm recovery **WITHOUT** presenting any confirmation factors.")
      /// Emergency Fallback
      internal static let title = L10n.tr("Localizable", "shieldWizardRecovery_setFallback_title", fallback: "Emergency Fallback")
    }
    internal enum Start {
      /// Factors you can use to start recovering, and temporarily lock, Accounts and Personas if you lose access.
      internal static let subtitle = L10n.tr("Localizable", "shieldWizardRecovery_start_subtitle", fallback: "Factors you can use to start recovering, and temporarily lock, Accounts and Personas if you lose access.")
      /// Starting a Recovery
      internal static let title = L10n.tr("Localizable", "shieldWizardRecovery_start_title", fallback: "Starting a Recovery")
    }
    internal enum Step {
      /// Step 2 of 2
      internal static let title = L10n.tr("Localizable", "shieldWizardRecovery_step_title", fallback: "Step 2 of 2")
    }
  }
  internal enum ShieldWizardRegularAccess {
    /// Factors required to withdraw assets from Accounts.
    internal static let subtitle = L10n.tr("Localizable", "shieldWizardRegularAccess_subtitle", fallback: "Factors required to withdraw assets from Accounts.")
    /// Regular Access
    internal static let title = L10n.tr("Localizable", "shieldWizardRegularAccess_title", fallback: "Regular Access")
    internal enum Authentication {
      /// Single factor required to log in to dApps with Personas and prove ownership of Accounts.
      internal static let title = L10n.tr("Localizable", "shieldWizardRegularAccess_authentication_title", fallback: "Single factor required to log in to dApps with Personas and prove ownership of Accounts.")
    }
    internal enum Combination {
      /// OR
      internal static let label = L10n.tr("Localizable", "shieldWizardRegularAccess_combination_label", fallback: "OR")
    }
    internal enum Override {
      /// Add an override
      internal static let button = L10n.tr("Localizable", "shieldWizardRegularAccess_override_button", fallback: "Add an override")
      /// Or you can use the following:
      internal static let description = L10n.tr("Localizable", "shieldWizardRegularAccess_override_description", fallback: "Or you can use the following:")
      /// Override (advanced)
      internal static let title = L10n.tr("Localizable", "shieldWizardRegularAccess_override_title", fallback: "Override (advanced)")
    }
    internal enum OverrideCombination {
      /// OR
      internal static let label = L10n.tr("Localizable", "shieldWizardRegularAccess_overrideCombination_label", fallback: "OR")
    }
    internal enum SetThreshold {
      /// All (Recommended)
      internal static let all = L10n.tr("Localizable", "shieldWizardRegularAccess_setThreshold_all", fallback: "All (Recommended)")
      /// Set
      internal static let button = L10n.tr("Localizable", "shieldWizardRegularAccess_setThreshold_button", fallback: "Set")
      /// Set the number of factors required to sign
      internal static let title = L10n.tr("Localizable", "shieldWizardRegularAccess_setThreshold_title", fallback: "Set the number of factors required to sign")
    }
    internal enum Step {
      /// Step 1 of 2
      internal static let title = L10n.tr("Localizable", "shieldWizardRegularAccess_step_title", fallback: "Step 1 of 2")
    }
    internal enum ThresholdDescription {
      /// All
      internal static let all = L10n.tr("Localizable", "shieldWizardRegularAccess_thresholdDescription_all", fallback: "All")
      /// You'll need to use **%@** of the following
      internal static func title(_ p1: Any) -> String {
        return L10n.tr("Localizable", "shieldWizardRegularAccess_thresholdDescription_title", String(describing: p1), fallback: "You'll need to use **%@** of the following")
      }
    }
  }
  internal enum Splash {
    /// This app requires your phone to have a passcode set up
    internal static let passcodeNotSetMessage = L10n.tr("Localizable", "splash_passcodeNotSetMessage", fallback: "This app requires your phone to have a passcode set up")
    /// Passcode not set up
    internal static let passcodeNotSetTitle = L10n.tr("Localizable", "splash_passcodeNotSetTitle", fallback: "Passcode not set up")
    /// Tap to unlock
    internal static let tapAnywhereToUnlock = L10n.tr("Localizable", "splash_tapAnywhereToUnlock", fallback: "Tap to unlock")
    internal enum IncompatibleProfileVersionAlert {
      /// Delete Wallet Data
      internal static let delete = L10n.tr("Localizable", "splash_incompatibleProfileVersionAlert_delete", fallback: "Delete Wallet Data")
      /// For this Preview wallet version, you must delete your wallet data to continue.
      internal static let message = L10n.tr("Localizable", "splash_incompatibleProfileVersionAlert_message", fallback: "For this Preview wallet version, you must delete your wallet data to continue.")
      /// Wallet Data is Incompatible
      internal static let title = L10n.tr("Localizable", "splash_incompatibleProfileVersionAlert_title", fallback: "Wallet Data is Incompatible")
    }
    internal enum PasscodeCheckFailedAlert {
      /// Passcode is not set up. Please update settings.
      internal static let message = L10n.tr("Localizable", "splash_passcodeCheckFailedAlert_message", fallback: "Passcode is not set up. Please update settings.")
      /// Warning
      internal static let title = L10n.tr("Localizable", "splash_passcodeCheckFailedAlert_title", fallback: "Warning")
    }
    internal enum ProfileOnAnotherDeviceAlert {
      /// Ask Later (no changes)
      internal static let askLater = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_askLater", fallback: "Ask Later (no changes)")
      /// Claim Existing Wallet
      internal static let claimExisting = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_claimExisting", fallback: "Claim Existing Wallet")
      /// Clear Wallet on This Phone
      internal static let claimHere = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_claimHere", fallback: "Clear Wallet on This Phone")
      /// This wallet is currently configured with a set of Accounts and Personas in use by a different phone.
      /// 
      /// To make changes to this wallet, you must claim it for use on this phone instead, removing access by the other phone.
      /// 
      /// Or you can clear this wallet from this phone and start fresh.
      internal static let message = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_message", fallback: "This wallet is currently configured with a set of Accounts and Personas in use by a different phone.\n\nTo make changes to this wallet, you must claim it for use on this phone instead, removing access by the other phone.\n\nOr you can clear this wallet from this phone and start fresh.")
      /// Claim This Wallet?
      internal static let title = L10n.tr("Localizable", "splash_profileOnAnotherDeviceAlert_title", fallback: "Claim This Wallet?")
    }
    internal enum RootDetection {
      /// I Understand the Risk
      internal static let acknowledgeButton = L10n.tr("Localizable", "splash_rootDetection_acknowledgeButton", fallback: "I Understand the Risk")
      /// It appears that your device might be rooted. To ensure the security of your Accounts and assets, using the Radix Wallet on rooted devices is not recommended. Please confirm if you wish to continue anyway at your own risk.
      internal static let messageAndroid = L10n.tr("Localizable", "splash_rootDetection_messageAndroid", fallback: "It appears that your device might be rooted. To ensure the security of your Accounts and assets, using the Radix Wallet on rooted devices is not recommended. Please confirm if you wish to continue anyway at your own risk.")
      /// It appears that your device might be jailbroken. To ensure the security of your Accounts and assets, using the Radix Wallet on jailbroken devices is not recommended. Please confirm if you wish to continue anyway at your own risk.
      internal static let messageIOS = L10n.tr("Localizable", "splash_rootDetection_messageIOS", fallback: "It appears that your device might be jailbroken. To ensure the security of your Accounts and assets, using the Radix Wallet on jailbroken devices is not recommended. Please confirm if you wish to continue anyway at your own risk.")
      /// Possible jailbreak detected
      internal static let titleIOS = L10n.tr("Localizable", "splash_rootDetection_titleIOS", fallback: "Possible jailbreak detected")
    }
  }
  internal enum Survey {
    /// 10 - Very likely
    internal static let highestScoreLabel = L10n.tr("Localizable", "survey_highestScoreLabel", fallback: "10 - Very likely")
    /// 0 - Not likely
    internal static let lowestScoreLabel = L10n.tr("Localizable", "survey_lowestScoreLabel", fallback: "0 - Not likely")
    /// Submit Feedback - Thanks!
    internal static let submitButton = L10n.tr("Localizable", "survey_submitButton", fallback: "Submit Feedback - Thanks!")
    /// How likely are you to recommend Radix and the Radix Wallet to your friends or colleagues?
    internal static let subtitle = L10n.tr("Localizable", "survey_subtitle", fallback: "How likely are you to recommend Radix and the Radix Wallet to your friends or colleagues?")
    /// How's it Going?
    internal static let title = L10n.tr("Localizable", "survey_title", fallback: "How's it Going?")
    internal enum Reason {
      /// Let us know...
      internal static let fieldHint = L10n.tr("Localizable", "survey_reason_fieldHint", fallback: "Let us know...")
      /// What’s the main reason for your score?
      internal static let heading = L10n.tr("Localizable", "survey_reason_heading", fallback: "What’s the main reason for your score?")
    }
  }
  internal enum TimeFormatting {
    /// %@ ago
    internal static func ago(_ p1: Any) -> String {
      return L10n.tr("Localizable", "timeFormatting_ago", String(describing: p1), fallback: "%@ ago")
    }
    /// Just now
    internal static let justNow = L10n.tr("Localizable", "timeFormatting_justNow", fallback: "Just now")
    /// Today
    internal static let today = L10n.tr("Localizable", "timeFormatting_today", fallback: "Today")
    /// Tomorrow
    internal static let tomorrow = L10n.tr("Localizable", "timeFormatting_tomorrow", fallback: "Tomorrow")
    /// Yesterday
    internal static let yesterday = L10n.tr("Localizable", "timeFormatting_yesterday", fallback: "Yesterday")
  }
  internal enum TransactionHistory {
    /// This transaction cannot be summarized. Only the raw transaction manifest may be viewed.
    internal static let complexTransaction = L10n.tr("Localizable", "transactionHistory_complexTransaction", fallback: "This transaction cannot be summarized. Only the raw transaction manifest may be viewed.")
    /// Deposited
    internal static let depositedSection = L10n.tr("Localizable", "transactionHistory_depositedSection", fallback: "Deposited")
    /// Failed Transaction
    internal static let failedTransaction = L10n.tr("Localizable", "transactionHistory_failedTransaction", fallback: "Failed Transaction")
    /// No deposits or withdrawals from this account in this transaction.
    internal static let noBalanceChanges = L10n.tr("Localizable", "transactionHistory_noBalanceChanges", fallback: "No deposits or withdrawals from this account in this transaction.")
    /// You have no Transactions.
    internal static let noTransactions = L10n.tr("Localizable", "transactionHistory_noTransactions", fallback: "You have no Transactions.")
    /// Settings
    internal static let settingsSection = L10n.tr("Localizable", "transactionHistory_settingsSection", fallback: "Settings")
    /// History
    internal static let title = L10n.tr("Localizable", "transactionHistory_title", fallback: "History")
    /// Updated Account Deposit Settings
    internal static let updatedDepositSettings = L10n.tr("Localizable", "transactionHistory_updatedDepositSettings", fallback: "Updated Account Deposit Settings")
    /// Withdrawn
    internal static let withdrawnSection = L10n.tr("Localizable", "transactionHistory_withdrawnSection", fallback: "Withdrawn")
    internal enum DatePrefix {
      /// Today
      internal static let today = L10n.tr("Localizable", "transactionHistory_datePrefix_today", fallback: "Today")
      /// Yesterday
      internal static let yesterday = L10n.tr("Localizable", "transactionHistory_datePrefix_yesterday", fallback: "Yesterday")
    }
    internal enum Filters {
      /// Type of Asset
      internal static let assetTypeLabel = L10n.tr("Localizable", "transactionHistory_filters_assetTypeLabel", fallback: "Type of Asset")
      /// NFTs
      internal static let assetTypeNFTsLabel = L10n.tr("Localizable", "transactionHistory_filters_assetTypeNFTsLabel", fallback: "NFTs")
      /// Clear All
      internal static let clearAll = L10n.tr("Localizable", "transactionHistory_filters_clearAll", fallback: "Clear All")
      /// Deposits
      internal static let depositsType = L10n.tr("Localizable", "transactionHistory_filters_depositsType", fallback: "Deposits")
      /// Show All NFTs
      internal static let nftShowAll = L10n.tr("Localizable", "transactionHistory_filters_nftShowAll", fallback: "Show All NFTs")
      /// Show Less NFTs
      internal static let nftShowLess = L10n.tr("Localizable", "transactionHistory_filters_nftShowLess", fallback: "Show Less NFTs")
      /// Show Results
      internal static let showResultsButton = L10n.tr("Localizable", "transactionHistory_filters_showResultsButton", fallback: "Show Results")
      /// Filter
      internal static let title = L10n.tr("Localizable", "transactionHistory_filters_title", fallback: "Filter")
      /// Show All Tokens
      internal static let tokenShowAll = L10n.tr("Localizable", "transactionHistory_filters_tokenShowAll", fallback: "Show All Tokens")
      /// Show Less Tokens
      internal static let tokenShowLess = L10n.tr("Localizable", "transactionHistory_filters_tokenShowLess", fallback: "Show Less Tokens")
      /// Tokens
      internal static let tokensLabel = L10n.tr("Localizable", "transactionHistory_filters_tokensLabel", fallback: "Tokens")
      /// Type of Transaction
      internal static let transactionTypeLabel = L10n.tr("Localizable", "transactionHistory_filters_transactionTypeLabel", fallback: "Type of Transaction")
      /// Withdrawals
      internal static let withdrawalsType = L10n.tr("Localizable", "transactionHistory_filters_withdrawalsType", fallback: "Withdrawals")
    }
    internal enum ManifestClass {
      /// Deposit Settings
      internal static let accountSettings = L10n.tr("Localizable", "transactionHistory_manifestClass_AccountSettings", fallback: "Deposit Settings")
      /// Claim Stake
      internal static let claim = L10n.tr("Localizable", "transactionHistory_manifestClass_Claim", fallback: "Claim Stake")
      /// Contribute
      internal static let contribute = L10n.tr("Localizable", "transactionHistory_manifestClass_Contribute", fallback: "Contribute")
      /// General
      internal static let general = L10n.tr("Localizable", "transactionHistory_manifestClass_General", fallback: "General")
      /// Other
      internal static let other = L10n.tr("Localizable", "transactionHistory_manifestClass_Other", fallback: "Other")
      /// Redeem
      internal static let redeem = L10n.tr("Localizable", "transactionHistory_manifestClass_Redeem", fallback: "Redeem")
      /// Stake
      internal static let staking = L10n.tr("Localizable", "transactionHistory_manifestClass_Staking", fallback: "Stake")
      /// Transfer
      internal static let transfer = L10n.tr("Localizable", "transactionHistory_manifestClass_Transfer", fallback: "Transfer")
      /// Request Unstake
      internal static let unstaking = L10n.tr("Localizable", "transactionHistory_manifestClass_Unstaking", fallback: "Request Unstake")
    }
  }
  internal enum TransactionReview {
    /// Unknown pool
    internal static let poolNameUnknown = L10n.tr("Localizable", "transactionReview_poolNameUnknown", fallback: "Unknown pool")
    /// Pool Units
    internal static let poolUnits = L10n.tr("Localizable", "transactionReview_poolUnits", fallback: "Pool Units")
    /// Slide to Sign
    internal static let slideToSign = L10n.tr("Localizable", "transactionReview_slideToSign", fallback: "Slide to Sign")
    /// Review Your Transaction
    internal static let title = L10n.tr("Localizable", "transactionReview_title", fallback: "Review Your Transaction")
    /// Review Your Transfer
    internal static let transferTitle = L10n.tr("Localizable", "transactionReview_transferTitle", fallback: "Review Your Transfer")
    /// %d Unknown Components
    internal static func unknownComponents(_ p1: Int) -> String {
      return L10n.tr("Localizable", "transactionReview_unknownComponents", p1, fallback: "%d Unknown Components")
    }
    /// %d Pool Components
    internal static func unknownPools(_ p1: Int) -> String {
      return L10n.tr("Localizable", "transactionReview_unknownPools", p1, fallback: "%d Pool Components")
    }
    /// %@ XRD
    internal static func xrdAmount(_ p1: Any) -> String {
      return L10n.tr("Localizable", "transactionReview_xrdAmount", String(describing: p1), fallback: "%@ XRD")
    }
    internal enum DeletingAccount {
      /// Deleting Account. Permanently removing access and preventing future deposits.
      internal static let message = L10n.tr("Localizable", "transactionReview_deletingAccount_message", fallback: "Deleting Account. Permanently removing access and preventing future deposits.")
      /// Deleting Account
      internal static let title = L10n.tr("Localizable", "transactionReview_deletingAccount_title", fallback: "Deleting Account")
    }
    internal enum FeePayerValidation {
      /// Fee payer account required
      internal static let feePayerRequired = L10n.tr("Localizable", "transactionReview_feePayerValidation_feePayerRequired", fallback: "Fee payer account required")
      /// Not enough XRD for transaction fee
      internal static let insufficientBalance = L10n.tr("Localizable", "transactionReview_feePayerValidation_insufficientBalance", fallback: "Not enough XRD for transaction fee")
      /// Account will be linked on ledger to your other Accounts in this transaction
      internal static let linksNewAccount = L10n.tr("Localizable", "transactionReview_feePayerValidation_linksNewAccount", fallback: "Account will be linked on ledger to your other Accounts in this transaction")
    }
    internal enum Guarantees {
      /// Apply
      internal static let applyButtonText = L10n.tr("Localizable", "transactionReview_guarantees_applyButtonText", fallback: "Apply")
      /// Set guaranteed minimum %%
      internal static let setGuaranteedMinimum = L10n.tr("Localizable", "transactionReview_guarantees_setGuaranteedMinimum", fallback: "Set guaranteed minimum %%")
      /// Protect yourself by setting guaranteed minimums for estimated deposits
      internal static let subtitle = L10n.tr("Localizable", "transactionReview_guarantees_subtitle", fallback: "Protect yourself by setting guaranteed minimums for estimated deposits")
      /// Customize Guarantees
      internal static let title = L10n.tr("Localizable", "transactionReview_guarantees_title", fallback: "Customize Guarantees")
    }
    internal enum NetworkFee {
      /// The network is currently congested. Add a tip to speed up your transfer.
      internal static let congestedText = L10n.tr("Localizable", "transactionReview_networkFee_congestedText", fallback: "The network is currently congested. Add a tip to speed up your transfer.")
      /// Customize
      internal static let customizeButtonTitle = L10n.tr("Localizable", "transactionReview_networkFee_customizeButtonTitle", fallback: "Customize")
      /// Transaction Fee
      internal static let heading = L10n.tr("Localizable", "transactionReview_networkFee_heading", fallback: "Transaction Fee")
    }
    internal enum NonConformingManifestWarning {
      /// This is a complex transaction that cannot be summarized - the raw transaction manifest will be shown. Do not submit unless you understand the contents.
      internal static let message = L10n.tr("Localizable", "transactionReview_nonConformingManifestWarning_message", fallback: "This is a complex transaction that cannot be summarized - the raw transaction manifest will be shown. Do not submit unless you understand the contents.")
      /// Warning
      internal static let title = L10n.tr("Localizable", "transactionReview_nonConformingManifestWarning_title", fallback: "Warning")
    }
    internal enum SubmitTransaction {
      /// Transaction ID
      internal static let txID = L10n.tr("Localizable", "transactionReview_submitTransaction_txID", fallback: "Transaction ID")
    }
    internal enum UnacceptableManifest {
      /// A proposed transaction was rejected because it contains one or more reserved instructions.
      internal static let rejected = L10n.tr("Localizable", "transactionReview_unacceptableManifest_rejected", fallback: "A proposed transaction was rejected because it contains one or more reserved instructions.")
    }
  }
  internal enum TransactionSigning {
    /// Incoming Transaction
    internal static let preparingTransaction = L10n.tr("Localizable", "transactionSigning_preparingTransaction", fallback: "Incoming Transaction")
    /// Submitting transaction…
    internal static let signingAndSubmittingTransaction = L10n.tr("Localizable", "transactionSigning_signingAndSubmittingTransaction", fallback: "Submitting transaction…")
    /// Approve Transaction
    internal static let signTransactionButtonTitle = L10n.tr("Localizable", "transactionSigning_signTransactionButtonTitle", fallback: "Approve Transaction")
    /// Approve Transaction
    internal static let title = L10n.tr("Localizable", "transactionSigning_title", fallback: "Approve Transaction")
  }
  internal enum TransactionStatus {
    internal enum AssertionFailure {
      /// A guarantee on transaction results was not met. Consider reducing your preferred guarantee %%
      internal static let text = L10n.tr("Localizable", "transactionStatus_assertionFailure_text", fallback: "A guarantee on transaction results was not met. Consider reducing your preferred guarantee %%")
    }
    internal enum Completing {
      /// Completing Transaction…
      internal static let text = L10n.tr("Localizable", "transactionStatus_completing_text", fallback: "Completing Transaction…")
    }
    internal enum DismissDialog {
      /// Stop waiting for transaction result? The transaction will not be canceled.
      internal static let message = L10n.tr("Localizable", "transactionStatus_dismissDialog_message", fallback: "Stop waiting for transaction result? The transaction will not be canceled.")
    }
    internal enum DismissalDisabledDialog {
      /// This transaction requires to be completed
      internal static let text = L10n.tr("Localizable", "transactionStatus_dismissalDisabledDialog_text", fallback: "This transaction requires to be completed")
      /// Dismiss
      internal static let title = L10n.tr("Localizable", "transactionStatus_dismissalDisabledDialog_title", fallback: "Dismiss")
    }
    internal enum Error {
      /// This transaction was rejected and is unlikely to be processed, but could potentially be processed within the next %@ minutes. It is likely that the dApp you are using proposed a transaction that includes an action that is not currently valid.
      internal static func text(_ p1: Any) -> String {
        return L10n.tr("Localizable", "transactionStatus_error_text", String(describing: p1), fallback: "This transaction was rejected and is unlikely to be processed, but could potentially be processed within the next %@ minutes. It is likely that the dApp you are using proposed a transaction that includes an action that is not currently valid.")
      }
      /// Transaction Error
      internal static let title = L10n.tr("Localizable", "transactionStatus_error_title", fallback: "Transaction Error")
    }
    internal enum Failed {
      /// Your transaction was processed, but had a problem that caused it to fail permanently
      internal static let text = L10n.tr("Localizable", "transactionStatus_failed_text", fallback: "Your transaction was processed, but had a problem that caused it to fail permanently")
      /// Transaction Failed
      internal static let title = L10n.tr("Localizable", "transactionStatus_failed_title", fallback: "Transaction Failed")
    }
    internal enum Failure {
      /// Transaction was rejected as invalid by the Radix Network.
      internal static let text = L10n.tr("Localizable", "transactionStatus_failure_text", fallback: "Transaction was rejected as invalid by the Radix Network.")
      /// Something Went Wrong
      internal static let title = L10n.tr("Localizable", "transactionStatus_failure_title", fallback: "Something Went Wrong")
    }
    internal enum Rejected {
      /// Your transaction was improperly constructed and cannot be processed
      internal static let text = L10n.tr("Localizable", "transactionStatus_rejected_text", fallback: "Your transaction was improperly constructed and cannot be processed")
      /// Transaction Rejected
      internal static let title = L10n.tr("Localizable", "transactionStatus_rejected_title", fallback: "Transaction Rejected")
    }
    internal enum Success {
      /// Your transaction was successful
      internal static let text = L10n.tr("Localizable", "transactionStatus_success_text", fallback: "Your transaction was successful")
      /// Transaction Success
      internal static let title = L10n.tr("Localizable", "transactionStatus_success_title", fallback: "Transaction Success")
    }
    internal enum TransactionID {
      /// Transaction ID: 
      internal static let text = L10n.tr("Localizable", "transactionStatus_transactionID_text", fallback: "Transaction ID: ")
    }
  }
  internal enum Troubleshooting {
    /// Account Recovery
    internal static let accountRecovery = L10n.tr("Localizable", "troubleshooting_accountRecovery", fallback: "Account Recovery")
    /// Reset Account
    internal static let resetAccount = L10n.tr("Localizable", "troubleshooting_resetAccount", fallback: "Reset Account")
    /// Support and Community
    internal static let supportAndCommunity = L10n.tr("Localizable", "troubleshooting_supportAndCommunity", fallback: "Support and Community")
    /// Troubleshooting
    internal static let title = L10n.tr("Localizable", "troubleshooting_title", fallback: "Troubleshooting")
    internal enum AccountScan {
      /// Recover Accounts with a seed phrase or Ledger device
      internal static let subtitle = L10n.tr("Localizable", "troubleshooting_accountScan_subtitle", fallback: "Recover Accounts with a seed phrase or Ledger device")
      /// Account Recovery Scan
      internal static let title = L10n.tr("Localizable", "troubleshooting_accountScan_title", fallback: "Account Recovery Scan")
    }
    internal enum ContactSupport {
      /// Connect directly with the Radix support team
      internal static let subtitle = L10n.tr("Localizable", "troubleshooting_contactSupport_subtitle", fallback: "Connect directly with the Radix support team")
      /// Contact Support
      internal static let title = L10n.tr("Localizable", "troubleshooting_contactSupport_title", fallback: "Contact Support")
    }
    internal enum Discord {
      /// Connect to the official Radix Discord channel to join the community and ask for help.
      internal static let subtitle = L10n.tr("Localizable", "troubleshooting_discord_subtitle", fallback: "Connect to the official Radix Discord channel to join the community and ask for help.")
      /// Discord
      internal static let title = L10n.tr("Localizable", "troubleshooting_discord_title", fallback: "Discord")
    }
    internal enum FactoryReset {
      /// Restore your Radix wallet to its original state
      internal static let subtitle = L10n.tr("Localizable", "troubleshooting_factoryReset_subtitle", fallback: "Restore your Radix wallet to its original state")
      /// Factory Reset
      internal static let title = L10n.tr("Localizable", "troubleshooting_factoryReset_title", fallback: "Factory Reset")
    }
    internal enum LegacyImport {
      /// Import Accounts from an Olympia wallet
      internal static let subtitle = L10n.tr("Localizable", "troubleshooting_legacyImport_subtitle", fallback: "Import Accounts from an Olympia wallet")
      /// Import from a Legacy Wallet
      internal static let title = L10n.tr("Localizable", "troubleshooting_legacyImport_title", fallback: "Import from a Legacy Wallet")
    }
  }
  internal enum WalletSettings {
    /// App version: %@
    internal static func appVersion(_ p1: Any) -> String {
      return L10n.tr("Localizable", "walletSettings_appVersion", String(describing: p1), fallback: "App version: %@")
    }
    /// Wallet Settings
    internal static let title = L10n.tr("Localizable", "walletSettings_title", fallback: "Wallet Settings")
    internal enum Connectors {
      /// Connect to desktop through the Radix Connector browser extension
      internal static let subtitle = L10n.tr("Localizable", "walletSettings_connectors_subtitle", fallback: "Connect to desktop through the Radix Connector browser extension")
      /// Linked Connectors
      internal static let title = L10n.tr("Localizable", "walletSettings_connectors_title", fallback: "Linked Connectors")
    }
    internal enum Dapps {
      /// Manage the Radix dApps you're connected to
      internal static let subtitle = L10n.tr("Localizable", "walletSettings_dapps_subtitle", fallback: "Manage the Radix dApps you're connected to")
      /// Approved dApps
      internal static let title = L10n.tr("Localizable", "walletSettings_dapps_title", fallback: "Approved dApps")
    }
    internal enum LinkToConnectorHeader {
      /// Link to Connector
      internal static let button = L10n.tr("Localizable", "walletSettings_linkToConnectorHeader_button", fallback: "Link to Connector")
      /// Scan the QR code in the Radix Wallet Connector extension
      internal static let subtitle = L10n.tr("Localizable", "walletSettings_linkToConnectorHeader_subtitle", fallback: "Scan the QR code in the Radix Wallet Connector extension")
      /// Link your Wallet to a desktop browser
      internal static let title = L10n.tr("Localizable", "walletSettings_linkToConnectorHeader_title", fallback: "Link your Wallet to a desktop browser")
    }
    internal enum Personas {
      /// Please write down the seed phrase for your Personas
      internal static let hint = L10n.tr("Localizable", "walletSettings_personas_hint", fallback: "Please write down the seed phrase for your Personas")
      /// Manage Radix dApp login details
      internal static let subtitle = L10n.tr("Localizable", "walletSettings_personas_subtitle", fallback: "Manage Radix dApp login details")
      /// Personas
      internal static let title = L10n.tr("Localizable", "walletSettings_personas_title", fallback: "Personas")
    }
    internal enum Preferences {
      /// Deposits, hidden Accounts and Personas, and advanced preferences
      internal static let subtitle = L10n.tr("Localizable", "walletSettings_preferences_subtitle", fallback: "Deposits, hidden Accounts and Personas, and advanced preferences")
      /// Preferences
      internal static let title = L10n.tr("Localizable", "walletSettings_preferences_title", fallback: "Preferences")
    }
    internal enum SecurityCenter {
      /// Manage your wallet security settings
      internal static let subtitle = L10n.tr("Localizable", "walletSettings_securityCenter_subtitle", fallback: "Manage your wallet security settings")
      /// Security Center
      internal static let title = L10n.tr("Localizable", "walletSettings_securityCenter_title", fallback: "Security Center")
    }
    internal enum Troubleshooting {
      /// Add your existing Accounts and contact support
      internal static let subtitle = L10n.tr("Localizable", "walletSettings_troubleshooting_subtitle", fallback: "Add your existing Accounts and contact support")
      /// Troubleshooting
      internal static let title = L10n.tr("Localizable", "walletSettings_troubleshooting_title", fallback: "Troubleshooting")
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
