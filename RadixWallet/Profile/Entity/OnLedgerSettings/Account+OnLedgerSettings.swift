import EngineToolkit

// MARK: - Profile.Network.Account.OnLedgerSettings
extension Profile.Network.Account {
	public struct OnLedgerSettings: Hashable, Sendable, Codable {
		/// Controls the ability of third-parties to deposit into this account
		public var thirdPartyDeposits: ThirdPartyDeposits

		public init(thirdPartyDeposits: ThirdPartyDeposits) {
			self.thirdPartyDeposits = thirdPartyDeposits
		}

		/// The default value for newly created accounts.
		/// After the account is created the OnLedgerSettings will be updated either by User or by syncing with the Ledger.
		public static let `default` = Self(thirdPartyDeposits: .default)

		/// The value used for "recovered" accounts, rediscovered using "Account Recovery Scan", either
		/// from onboarding (assembly of Profile from mnemonic) or from App Settings.
		public static let unknown = Self(thirdPartyDeposits: .unknown)
	}
}

// MARK: - Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits
extension Profile.Network.Account.OnLedgerSettings {
	public struct ThirdPartyDeposits: Hashable, Sendable, Codable {
		/// The general deposit rule to apply
		// FIXME: Is this actually different from AccountDefaultDepositRule
		public enum DepositRule: String, Hashable, Sendable, Codable, CaseIterable {
			case acceptAll
			case acceptKnown
			case denyAll
		}

		/// The addresses that can be added as exception to the `DepositRule`
		public enum DepositorAddress: Hashable, Sendable, Codable {
			case resourceAddress(ResourceAddress)
			case nonFungibleGlobalID(NonFungibleGlobalId)
		}

		/// The exception kind for deposit address
		public enum DepositAddressExceptionRule: String, Hashable, Sendable, Codable, CaseIterable {
			/// A resource can always be deposited in to the account by third-parties
			case allow
			/// A resource can never be deposited in to the account by third-parties
			case deny
		}

		/// The specific Asset exception rule
		public struct AssetException: Hashable, Sendable, Codable {
			public let address: ResourceAddress
			public let exceptionRule: DepositAddressExceptionRule

			public init(address: ResourceAddress, exceptionRule: DepositAddressExceptionRule) {
				self.address = address
				self.exceptionRule = exceptionRule
			}
		}

		/// Controls the ability of thir-parties to deposit into this account
		public var depositRule: DepositRule

		/// Denies or allows third-party deposits of specific assets by ignoring the `depositMode`,
		/// `nil` means that the account was "recovered" using "Account Recovery Scan" features,
		/// thus the value is unknown.
		private var assetsExceptionList: OrderedSet<AssetException>?

		public func assetsExceptionSet() -> OrderedSet<AssetException> {
			assetsExceptionList ?? []
		}

		public var isAssetsExceptionsUnknown: Bool {
			assetsExceptionList == nil
		}

		public mutating func updateAssetsExceptionList(_ update: (inout OrderedSet<AssetException>?) -> Void) {
			update(&self.assetsExceptionList)
		}

		public mutating func setAssetsExceptionList(
			_ new: OrderedSet<AssetException>?
		) {
			updateAssetsExceptionList { $0 = new }
		}

		public mutating func removeAllAssetsExceptions() {
			assetsExceptionList = []
		}

		public mutating func appendToAssetsExceptionList(_ new: AssetException) {
			if assetsExceptionList == nil {
				assetsExceptionList = [new]
			} else {
				assetsExceptionList!.updateOrAppend(new)
			}
		}

		/// Allows certain third-party depositors to deposit assets freely.
		/// Note: There is no `deny` counterpart for this, `nil` means that the account was
		/// "recovered" using "Account Recovery Scan" features. thus the value is unknown.
		private var depositorsAllowList: OrderedSet<DepositorAddress>?

		public var isAllowedDepositorsUnknown: Bool {
			depositorsAllowList == nil
		}

		public func depositorsAllowSet() -> OrderedSet<DepositorAddress> {
			depositorsAllowList ?? []
		}

		public mutating func removeAllAllowedDepositors() {
			depositorsAllowList = []
		}

		public mutating func appendToDepositorsAllowList(_ new: DepositorAddress) {
			if depositorsAllowList == nil {
				depositorsAllowList = [new]
			} else {
				depositorsAllowList!.updateOrAppend(new)
			}
		}

		public mutating func updateDepositorsAllowList(_ update: (inout OrderedSet<DepositorAddress>?) -> Void) {
			update(&self.depositorsAllowList)
		}

		public mutating func setDepositorsAllowList(_ new: OrderedSet<DepositorAddress>?) {
			updateDepositorsAllowList { $0 = new }
		}

		public init(
			depositRule: DepositRule,
			assetsExceptionList: OrderedSet<AssetException>?,
			depositorsAllowList: OrderedSet<DepositorAddress>?
		) {
			self.depositRule = depositRule
			self.assetsExceptionList = assetsExceptionList
			self.depositorsAllowList = depositorsAllowList
		}

		/// On Ledger default is `acceptAll` for deposit mode and empty lists
		public static let `default` = Self(
			depositRule: .acceptAll,
			assetsExceptionList: [],
			depositorsAllowList: []
		)

		/// Used on recovered account
		public static let unknown = Self(
			depositRule: .acceptAll,
			assetsExceptionList: nil,
			depositorsAllowList: nil
		)
	}
}

extension Profile.Network.Account.OnLedgerSettings.ThirdPartyDeposits.DepositorAddress {
	private enum CodingKeys: String, CodingKey {
		case discriminator
		case value
	}

	enum Discriminator: String, Sendable, Hashable, CustomStringConvertible, Codable {
		case resourceAddress, nonFungibleGlobalID

		public var description: String {
			rawValue
		}
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let discriminator = try container.decode(Discriminator.self, forKey: .discriminator)
		let value = try container.decode(String.self, forKey: .value)

		switch discriminator {
		case .resourceAddress:
			self = try .resourceAddress(.init(validatingAddress: value))
		case .nonFungibleGlobalID:
			self = try .nonFungibleGlobalID(.init(nonFungibleGlobalId: value))
		}
	}

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		switch self {
		case let .resourceAddress(address):
			try container.encode(Discriminator.resourceAddress, forKey: .discriminator)
			try container.encode(address.address, forKey: .value)

		case let .nonFungibleGlobalID(id):
			try container.encode(Discriminator.nonFungibleGlobalID, forKey: .discriminator)
			try container.encode(id.asStr(), forKey: .value)
		}
	}
}
