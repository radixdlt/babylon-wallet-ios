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
  	/// Get free XRD
  	public static let faucetButtonTitle = L10n.tr("Localizable", "accountPreferences.faucetButtonTitle", fallback: "Get free XRD")
  	/// Account preferences
  	public static let title = L10n.tr("Localizable", "accountPreferences.title", fallback: "Account preferences")
	}
	public enum AggregatedValue {
  	/// Total value
  	public static let title = L10n.tr("Localizable", "aggregatedValue.title", fallback: "Total value")
	}
	public enum AssetsView {
  	/// Badges
  	public static let badges = L10n.tr("Localizable", "assetsView.badges", fallback: "Badges")
  	/// NFTs
  	public static let nfts = L10n.tr("Localizable", "assetsView.nfts", fallback: "NFTs")
  	/// Pool Share
  	public static let poolShare = L10n.tr("Localizable", "assetsView.poolShare", fallback: "Pool Share")
  	/// Tokens
  	public static let tokens = L10n.tr("Localizable", "assetsView.tokens", fallback: "Tokens")
	}
	public enum CreateAccount {
  	/// Unlock secret used to create new account.
  	public static let biometricsPrompt = L10n.tr("Localizable", "createAccount.biometricsPrompt", fallback: "Unlock secret used to create new account.")
  	/// Create Account
  	public static let createAccountButtonTitle = L10n.tr("Localizable", "createAccount.createAccountButtonTitle", fallback: "Create Account")
  	/// Create First Account
  	public static let createFirstAccount = L10n.tr("Localizable", "createAccount.createFirstAccount", fallback: "Create First Account")
  	/// Create New Account
  	public static let createNewAccount = L10n.tr("Localizable", "createAccount.createNewAccount", fallback: "Create New Account")
  	/// This can be changed any time
  	public static let explanation = L10n.tr("Localizable", "createAccount.explanation", fallback: "This can be changed any time")
  	/// e.g. My First Account
  	public static let placeholder = L10n.tr("Localizable", "createAccount.placeholder", fallback: "e.g. My First Account")
  	/// What would you like to call your account?
  	public static let subtitle = L10n.tr("Localizable", "createAccount.subtitle", fallback: "What would you like to call your account?")
  	public enum Completion {
    	/// Your account lives on the Radix Network and you can access it anytime in Radix Wallet.
    	public static let explanation = L10n.tr("Localizable", "createAccount.completion.explanation", fallback: "Your account lives on the Radix Network and you can access it anytime in Radix Wallet.")
    	/// Go to %@
    	public static func returnToOrigin(_ p1: Any) -> String {
    		return L10n.tr("Localizable", "createAccount.completion.returnToOrigin", String(describing: p1), fallback: "Go to %@")
    	}
    	/// You’ve created your account.
    	public static let subtitle = L10n.tr("Localizable", "createAccount.completion.subtitle", fallback: "You’ve created your account.")
    	/// Congratulations
    	public static let title = L10n.tr("Localizable", "createAccount.completion.title", fallback: "Congratulations")
    	public enum Origin {
      	/// Home
      	public static let home = L10n.tr("Localizable", "createAccount.completion.origin.home", fallback: "Home")
    	}
  	}
	}
	public enum DApp {
  	/// Unknown dApp
  	public static let unknownName = L10n.tr("Localizable", "dApp.unknownName", fallback: "Unknown dApp")
  	public enum ChooseAccounts {
    	/// + Create a new Account
    	public static let createNewAccount = L10n.tr("Localizable", "dApp.chooseAccounts.createNewAccount", fallback: "+ Create a new Account")
    	/// Choose %@
    	public static func explanation(_ p1: Any) -> String {
    		return L10n.tr("Localizable", "dApp.chooseAccounts.explanation", String(describing: p1), fallback: "Choose %@")
    	}
    	/// at least one account.
    	public static let explanationAtLeastOneAccount = L10n.tr("Localizable", "dApp.chooseAccounts.explanationAtLeastOneAccount", fallback: "at least one account.")
    	/// exactly one account.
    	public static let explanationExactlyOneAccount = L10n.tr("Localizable", "dApp.chooseAccounts.explanationExactlyOneAccount", fallback: "exactly one account.")
    	/// exactly #%d accounts.
    	public static func explanationExactNumberOfAccounts(_ p1: Int) -> String {
    		return L10n.tr("Localizable", "dApp.chooseAccounts.explanationExactNumberOfAccounts", p1, fallback: "exactly #%d accounts.")
    	}
    	/// Choose the account(s) you wish %@ to know about
    	public static func subtitle(_ p1: Any) -> String {
    		return L10n.tr("Localizable", "dApp.chooseAccounts.subtitle", String(describing: p1), fallback: "Choose the account(s) you wish %@ to know about")
    	}
    	/// Choose Accounts
    	public static let title = L10n.tr("Localizable", "dApp.chooseAccounts.title", fallback: "Choose Accounts")
    	/// Unnamed account
    	public static let unnamedAccount = L10n.tr("Localizable", "dApp.chooseAccounts.unnamedAccount", fallback: "Unnamed account")
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
	}
	public enum Home {
  	public enum Header {
    	/// Welcome, here are all your accounts on the Radix Network
    	public static let subtitle = L10n.tr("Localizable", "home.header.subtitle", fallback: "Welcome, here are all your accounts on the Radix Network")
    	/// Radix Wallet
    	public static let title = L10n.tr("Localizable", "home.header.title", fallback: "Radix Wallet")
  	}
  	public enum VisitHub {
    	/// Visit the Radix Hub
    	public static let buttonTitle = L10n.tr("Localizable", "home.visitHub.buttonTitle", fallback: "Visit the Radix Hub")
    	/// Ready to get started using the Radix Network and your Wallet?
    	public static let title = L10n.tr("Localizable", "home.visitHub.title", fallback: "Ready to get started using the Radix Network and your Wallet?")
  	}
	}
	public enum ImportProfile {
  	/// Import mnemonic
  	public static let importMnemonic = L10n.tr("Localizable", "importProfile.importMnemonic", fallback: "Import mnemonic")
  	/// Import profile
  	public static let importProfile = L10n.tr("Localizable", "importProfile.importProfile", fallback: "Import profile")
  	/// Mnemonic phrasec
  	public static let mnemonicPhrasec = L10n.tr("Localizable", "importProfile.mnemonicPhrasec", fallback: "Mnemonic phrasec")
  	/// Profile from snapshot
  	public static let profileFromSnapshot = L10n.tr("Localizable", "importProfile.profileFromSnapshot", fallback: "Profile from snapshot")
  	/// Save imported mnemonic
  	public static let saveImportedMnemonic = L10n.tr("Localizable", "importProfile.saveImportedMnemonic", fallback: "Save imported mnemonic")
	}
	public enum ManageGateway {
  	/// Current
  	public static let currentGatewayTitle = L10n.tr("Localizable", "manageGateway.currentGatewayTitle", fallback: "Current")
  	/// Gateway API Endpoint
  	public static let gatewayAPIEndpoint = L10n.tr("Localizable", "manageGateway.gatewayAPIEndpoint", fallback: "Gateway API Endpoint")
  	/// Network ID
  	public static let networkID = L10n.tr("Localizable", "manageGateway.networkID", fallback: "Network ID")
  	/// Network name
  	public static let networkName = L10n.tr("Localizable", "manageGateway.networkName", fallback: "Network name")
  	/// Switch To
  	public static let switchToButtonTitle = L10n.tr("Localizable", "manageGateway.switchToButtonTitle", fallback: "Switch To")
  	/// Edit Gateway API URL
  	public static let title = L10n.tr("Localizable", "manageGateway.title", fallback: "Edit Gateway API URL")
  	/// https://example.com:8080
  	public static let urlString = L10n.tr("Localizable", "manageGateway.urlString", fallback: "https://example.com:8080")
	}
	public enum ManageP2PClients {
  	/// Connection ID: %@
  	public static func connectionID(_ p1: Any) -> String {
  		return L10n.tr("Localizable", "manageP2PClients.connectionID", String(describing: p1), fallback: "Connection ID: %@")
  	}
  	/// Delete
  	public static let deleteButtonTitle = L10n.tr("Localizable", "manageP2PClients.deleteButtonTitle", fallback: "Delete")
  	/// Add new connection
  	public static let newConnectionButtonTitle = L10n.tr("Localizable", "manageP2PClients.newConnectionButtonTitle", fallback: "Add new connection")
  	/// New Connection
  	public static let newConnectionTitle = L10n.tr("Localizable", "manageP2PClients.newConnectionTitle", fallback: "New Connection")
  	/// P2P Connections
  	public static let p2PConnectionsTitle = L10n.tr("Localizable", "manageP2PClients.P2PConnectionsTitle", fallback: "P2P Connections")
  	/// Send Test Msg
  	public static let sendTestMessageButtonTitle = L10n.tr("Localizable", "manageP2PClients.sendTestMessageButtonTitle", fallback: "Send Test Msg")
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
  	public enum Header {
    	/// Unknown
    	public static let supplyUnknown = L10n.tr("Localizable", "nftList.header.supplyUnknown", fallback: "Unknown")
  	}
	}
	public enum Onboarding {
  	/// This app requires your phone having biometrics set up
  	public static let biometricsNotSetUpMessage = L10n.tr("Localizable", "onboarding.biometricsNotSetUpMessage", fallback: "This app requires your phone having biometrics set up")
  	/// Biometrics not set up
  	public static let biometricsNotSetUpTitle = L10n.tr("Localizable", "onboarding.biometricsNotSetUpTitle", fallback: "Biometrics not set up")
  	/// New Account
  	public static let newAccountButtonTitle = L10n.tr("Localizable", "onboarding.newAccountButtonTitle", fallback: "New Account")
	}
	public enum Settings {
  	/// Add Connection
  	public static let addConnectionButtonTitle = L10n.tr("Localizable", "settings.addConnectionButtonTitle", fallback: "Add Connection")
  	/// Close
  	public static let closeButtonTitle = L10n.tr("Localizable", "settings.closeButtonTitle", fallback: "Close")
  	/// Delete all & Factor Sources
  	public static let deleteAllButtonTitle = L10n.tr("Localizable", "settings.deleteAllButtonTitle", fallback: "Delete all & Factor Sources")
  	/// Edit Gateway API Endpoint
  	public static let editGatewayAPIEndpointButtonTitle = L10n.tr("Localizable", "settings.editGatewayAPIEndpointButtonTitle", fallback: "Edit Gateway API Endpoint")
  	/// Inspect Profile
  	public static let inspectProfileButtonTitle = L10n.tr("Localizable", "settings.inspectProfileButtonTitle", fallback: "Inspect Profile")
  	/// Manage Connections
  	public static let manageConnectionsButtonTitle = L10n.tr("Localizable", "settings.manageConnectionsButtonTitle", fallback: "Manage Connections")
  	/// No profile, strange
  	public static let noProfileText = L10n.tr("Localizable", "settings.noProfileText", fallback: "No profile, strange")
  	/// Settings
  	public static let title = L10n.tr("Localizable", "settings.title", fallback: "Settings")
  	/// Version: %@ build #%@
  	public static func versionInfo(_ p1: Any, _ p2: Any) -> String {
  		return L10n.tr("Localizable", "settings.versionInfo", String(describing: p1), String(describing: p2), fallback: "Version: %@ build #%@")
  	}
  	public enum Section {
    	/// Debug
    	public static let debug = L10n.tr("Localizable", "settings.section.debug", fallback: "Debug")
    	/// P2P Connections
    	public static let p2Pconnections = L10n.tr("Localizable", "settings.section.P2Pconnections", fallback: "P2P Connections")
  	}
	}
	public enum TransactionSigning {
  	/// Unlock secret used to sign TX
  	public static let biometricsPrompt = L10n.tr("Localizable", "transactionSigning.biometricsPrompt", fallback: "Unlock secret used to sign TX")
  	/// Sign Transaction
  	public static let signTransactionButtonTitle = L10n.tr("Localizable", "transactionSigning.signTransactionButtonTitle", fallback: "Sign Transaction")
  	/// Sign TX
  	public static let title = L10n.tr("Localizable", "transactionSigning.title", fallback: "Sign TX")
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
