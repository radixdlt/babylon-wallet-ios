import Foundation

// MARK: - OnNetwork.Account.AppearanceID
extension OnNetwork.Account {
	/// An identifier for a certain User Interface rendered appearance for a account (or accounts
	/// if user has many accounts, since we recycle them).
	///
	/// Typically used to identifiy gradients displayed by the Babylon Mobile Wallet, but
	/// a Dapp will get access to this appearance ID when connecting to the wallet so that
	/// the Dapp too can render the connected account with the appropriate appearance.
	public enum AppearanceID:
		UInt8,
		Sendable,
		Hashable,
		Codable,
		CustomStringConvertible,
		CaseIterable,
		Identifiable
	{
		case _0, _1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11

		public typealias ID = RawValue

		public var id: ID { rawValue }

		public init(id: ID) throws {
			guard let _self = Self(rawValue: id) else {
				throw UnknownID(unknown: id)
			}
			self = _self
		}
	}
}

extension OnNetwork.Account.AppearanceID {
	public struct UnknownID: Swift.Error {
		let unknown: OnNetwork.Account.AppearanceID.ID
	}

	public var description: String {
		String(describing: id)
	}

	public static func fromIndex(_ accountIndex: OnNetwork.Account.Index) -> Self {
		let mod = allCases.count
		let gradientIndex = accountIndex % mod
		return allCases[gradientIndex]
	}
}

extension OnNetwork.Account.AppearanceID {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(id)
	}

	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		try self.init(id: container.decode(ID.self))
	}
}
