// MARK: - AppPreferences.Transaction
extension AppPreferences {
	/// Display settings in the wallet app, such as appearences, currency etc.
	public struct Transaction:
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		public static let defaultDepositGuaranteePreset = Decimal192(0.99)
		public var defaultDepositGuarantee: Decimal192

		public init(
			defaultDepositGuarantee: Decimal192 = Self.defaultDepositGuaranteePreset
		) {
			self.defaultDepositGuarantee = defaultDepositGuarantee
		}
	}
}

extension AppPreferences.Transaction {
	public static let `default` = Self()
}

extension AppPreferences.Transaction {
	public var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"defaultDepositGuarantee": defaultDepositGuarantee.formattedPlain(),
			],
			displayStyle: .struct
		)
	}

	public var description: String {
		"""
		defaultDepositGuarantee: \(defaultDepositGuarantee.formattedPlain()),
		"""
	}
}
