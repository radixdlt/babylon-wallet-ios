// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// MARK: - L10n
// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
	public enum AccountDetails {
		/// Transfer
		public static let transferButtonTitle = L10n.tr("Localizable", "accountDetails.transferButtonTitle", fallback: #"Transfer"#)
	}

	public enum AccountList {
		public enum Row {
			/// Copy
			public static let copyTitle = L10n.tr("Localizable", "accountList.row.copyTitle", fallback: #"Copy"#)
		}
	}

	public enum AggregatedValue {
		/// Total value
		public static let title = L10n.tr("Localizable", "aggregatedValue.title", fallback: #"Total value"#)
	}

	public enum AssetsView {
		/// Badges
		public static let badges = L10n.tr("Localizable", "assetsView.badges", fallback: #"Badges"#)
		/// NFTs
		public static let nfts = L10n.tr("Localizable", "assetsView.nfts", fallback: #"NFTs"#)
		/// Pool Share
		public static let poolShare = L10n.tr("Localizable", "assetsView.poolShare", fallback: #"Pool Share"#)
		/// Tokens
		public static let tokens = L10n.tr("Localizable", "assetsView.tokens", fallback: #"Tokens"#)
	}

	public enum CreateAccount {
		/// Continue
		public static let continueButtonTitle = L10n.tr("Localizable", "createAccount.continueButtonTitle", fallback: #"Continue"#)
		/// Create First Account
		public static let createFirstAccount = L10n.tr("Localizable", "createAccount.createFirstAccount", fallback: #"Create First Account"#)
		/// Create New Account
		public static let createNewAccount = L10n.tr("Localizable", "createAccount.createNewAccount", fallback: #"Create New Account"#)
		/// This can be changed any time
		public static let explanation = L10n.tr("Localizable", "createAccount.explanation", fallback: #"This can be changed any time"#)
		/// e.g. My First Account
		public static let placeholder = L10n.tr("Localizable", "createAccount.placeholder", fallback: #"e.g. My First Account"#)
		/// What would you like to call your account?
		public static let subtitle = L10n.tr("Localizable", "createAccount.subtitle", fallback: #"What would you like to call your account?"#)
		public enum Completion {
			/// Your account lives on the Radix Network and you can access it anytime in Radix Wallet.
			public static let explanation = L10n.tr("Localizable", "createAccount.completion.explanation", fallback: #"Your account lives on the Radix Network and you can access it anytime in Radix Wallet."#)
			/// Go to %@
			public static func returnToOrigin(_ p1: Any) -> String {
				L10n.tr("Localizable", "createAccount.completion.returnToOrigin", String(describing: p1), fallback: #"Go to %@"#)
			}

			/// You’ve created your account.
			public static let subtitle = L10n.tr("Localizable", "createAccount.completion.subtitle", fallback: #"You’ve created your account."#)
			/// Congratulations
			public static let title = L10n.tr("Localizable", "createAccount.completion.title", fallback: #"Congratulations"#)
			public enum Origin {
				/// Home
				public static let home = L10n.tr("Localizable", "createAccount.completion.origin.home", fallback: #"Home"#)
			}
		}
	}

	public enum DApp {
		/// Unknown dApp
		public static let unknownName = L10n.tr("Localizable", "dApp.unknownName", fallback: #"Unknown dApp"#)
		public enum ChooseAccounts {
			/// + Create a new Account
			public static let createNewAccount = L10n.tr("Localizable", "dApp.chooseAccounts.createNewAccount", fallback: #"+ Create a new Account"#)
			/// Choose the account(s) you wish %@ to know about
			public static func subtitle(_ p1: Any) -> String {
				L10n.tr("Localizable", "dApp.chooseAccounts.subtitle", String(describing: p1), fallback: #"Choose the account(s) you wish %@ to know about"#)
			}

			/// Choose Accounts
			public static let title = L10n.tr("Localizable", "dApp.chooseAccounts.title", fallback: #"Choose Accounts"#)
		}

		public enum ConnectionRequest {
			/// Continue
			public static let continueButtonTitle = L10n.tr("Localizable", "dApp.connectionRequest.continueButtonTitle", fallback: #"Continue"#)
			/// For this dApp to function, it needs the following:
			public static let subtitle = L10n.tr("Localizable", "dApp.connectionRequest.subtitle", fallback: #"For this dApp to function, it needs the following:"#)
			/// dApp Connection Request
			public static let title = L10n.tr("Localizable", "dApp.connectionRequest.title", fallback: #"dApp Connection Request"#)
			/// %@ wants to connect to your wallet
			public static func wantsToConnect(_ p1: Any) -> String {
				L10n.tr("Localizable", "dApp.connectionRequest.wantsToConnect", String(describing: p1), fallback: #"%@ wants to connect to your wallet"#)
			}
		}
	}

	public enum Home {
		public enum Header {
			/// Welcome, here are all your accounts on the Radix Network
			public static let subtitle = L10n.tr("Localizable", "home.header.subtitle", fallback: #"Welcome, here are all your accounts on the Radix Network"#)
			/// Radix Wallet
			public static let title = L10n.tr("Localizable", "home.header.title", fallback: #"Radix Wallet"#)
		}

		public enum VisitHub {
			/// Visit the Radix Hub
			public static let buttonTitle = L10n.tr("Localizable", "home.visitHub.buttonTitle", fallback: #"Visit the Radix Hub"#)
			/// Ready to get started using the Radix Network and your Wallet?
			public static let title = L10n.tr("Localizable", "home.visitHub.title", fallback: #"Ready to get started using the Radix Network and your Wallet?"#)
		}
	}

	public enum NftList {
		/// %d NFTs
		public static func nftPlural(_ p1: Int) -> String {
			L10n.tr("Localizable", "nftList.nftPlural", p1, fallback: #"%d NFTs"#)
		}

		/// %d of %d
		public static func ownedOfTotal(_ p1: Int, _ p2: Int) -> String {
			L10n.tr("Localizable", "nftList.ownedOfTotal", p1, p2, fallback: #"%d of %d"#)
		}

		public enum Header {
			/// - Hide
			public static let hide = L10n.tr("Localizable", "nftList.header.hide", fallback: #"- Hide"#)
			/// + Show
			public static let show = L10n.tr("Localizable", "nftList.header.show", fallback: #"+ Show"#)
			/// Unknown
			public static let supplyUnknown = L10n.tr("Localizable", "nftList.header.supplyUnknown", fallback: #"Unknown"#)
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

// MARK: - BundleToken
// swiftlint:disable convenience_type
private final class BundleToken {
	static let bundle: Bundle = {
		#if SWIFT_PACKAGE
		return Bundle(for: BundleToken.self)
		#else
		return Bundle(for: BundleToken.self)
		#endif
	}()
}

// swiftlint:enable convenience_type
