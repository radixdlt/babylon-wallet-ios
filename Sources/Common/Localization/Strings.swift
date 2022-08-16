// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// MARK: - L10n
// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
public enum L10n {
	public enum Home {
		public enum AggregatedValue {
			/// Total value
			public static let title = L10n.tr("Localizable", "home.aggregatedValue.title", fallback: #"Total value"#)
		}

		public enum Header {
			/// Welcome, here are all your accounts on the Radar Network
			public static let subtitle = L10n.tr("Localizable", "home.header.subtitle", fallback: #"Welcome, here are all your accounts on the Radar Network"#)
			/// Radar Wallet
			public static let title = L10n.tr("Localizable", "home.header.title", fallback: #"Radar Wallet"#)
		}

		public enum VisitHub {
			/// Visit the Radar Hub
			public static let buttonTitle = L10n.tr("Localizable", "home.visitHub.buttonTitle", fallback: #"Visit the Radar Hub"#)
			/// Ready to get started using the Radar Network and your Wallet?
			public static let title = L10n.tr("Localizable", "home.visitHub.title", fallback: #"Ready to get started using the Radar Network and your Wallet?"#)
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
