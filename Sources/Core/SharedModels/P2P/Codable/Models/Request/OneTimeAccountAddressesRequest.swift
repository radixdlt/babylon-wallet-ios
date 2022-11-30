import Foundation

// MARK: - P2P.FromDapp.OneTimeAccountsReadRequestItem
public extension P2P.FromDapp {
	struct OneTimeAccountsReadRequestItem:
		Sendable,
		Hashable,
		Decodable,
		P2PFromDappWalletRequestItemProtocol
	{
		public let numberOfAddresses: Mode
		public let isRequiringOwnershipProof: Bool

		public init(
			numberOfAddresses: Mode,
			isRequiringOwnershipProof: Bool = false
		) {
			self.numberOfAddresses = numberOfAddresses
			self.isRequiringOwnershipProof = isRequiringOwnershipProof
		}
	}
}

public extension P2P.FromDapp.OneTimeAccountsReadRequestItem {
	private enum CodingKeys: String, CodingKey {
		case isRequiringOwnershipProof = "requiresProofOfOwnership"
		case numberOfAddresses
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			numberOfAddresses: .init(maybeUInt: container.decodeIfPresent(UInt.self, forKey: .numberOfAddresses)),
			isRequiringOwnershipProof: container.decode(Bool.self, forKey: .isRequiringOwnershipProof)
		)
	}
}

// MARK: - P2P.FromDapp.OneTimeAccountsReadRequestItem.Mode
public extension P2P.FromDapp.OneTimeAccountsReadRequestItem {
	enum Mode: Sendable, Hashable {
		case oneOrMore
		case exactly(NumberOfAddresses)
	}
}

public extension P2P.FromDapp.OneTimeAccountsReadRequestItem.Mode {
	init(maybeUInt: UInt?) throws {
		if let uint = maybeUInt {
			self = try .exactly(.init(oneOrMore: uint))
		} else {
			self = .oneOrMore
		}
	}

	struct NumberOfAddresses: Sendable, Hashable {
		public let oneOrMore: UInt
		public init(oneOrMore: UInt) throws {
			guard oneOrMore >= 1 else {
				throw ExpectedOneOrMore()
			}
			self.oneOrMore = oneOrMore
		}

		struct ExpectedOneOrMore: Swift.Error {}
	}
}

#if DEBUG
extension P2P.FromDapp.OneTimeAccountsReadRequestItem.Mode: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: UInt) {
		try! self.init(maybeUInt: value)
	}
}

extension P2P.FromDapp.OneTimeAccountsReadRequestItem.Mode.NumberOfAddresses: ExpressibleByIntegerLiteral {
	public init(integerLiteral value: UInt) {
		try! self.init(oneOrMore: value)
	}
}
#endif
