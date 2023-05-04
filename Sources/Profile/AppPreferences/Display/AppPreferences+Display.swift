import Prelude

// MARK: - AppPreferences.Display
extension AppPreferences {
	/// Display settings in the wallet app, such as appearences, currency etc.
	public struct Display:
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		/// Which fiat currency the prices are measured in, e.g. EUR.
		public var fiatCurrencyPriceTarget: FiatCurrency

		public var isCurrencyAmountVisible: Bool

		public var ledgerHQHardwareWalletSigningDisplayMode: FactorSource.LedgerHardwareWallet.SigningDisplayMode

		public init(
			fiatCurrencyPriceTarget: FiatCurrency = .usd,
			isCurrencyAmountVisible: Bool = true,
			ledgerHQHardwareWalletSigningDisplayMode: FactorSource.LedgerHardwareWallet.SigningDisplayMode = .default
		) {
			self.fiatCurrencyPriceTarget = fiatCurrencyPriceTarget
			self.isCurrencyAmountVisible = isCurrencyAmountVisible
			self.ledgerHQHardwareWalletSigningDisplayMode = ledgerHQHardwareWalletSigningDisplayMode
		}
	}
}

extension AppPreferences.Display {
	public static let `default` = Self()
}

extension AppPreferences.Display {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"fiatCurrencyPriceTarget": fiatCurrencyPriceTarget,
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		fiatCurrencyPriceTarget: \(fiatCurrencyPriceTarget),
		"""
	}
}
