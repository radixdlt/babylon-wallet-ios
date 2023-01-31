import Foundation

// MARK: - TransactionHeader
public struct TransactionHeader: Sendable, Codable, Hashable {
	public let version: TXVersion
	public let networkId: NetworkID
	public let startEpochInclusive: Epoch
	public let endEpochExclusive: Epoch
	public let nonce: Nonce
	public let publicKey: Engine.PublicKey
	public let notaryAsSignatory: Bool
	public let costUnitLimit: UInt32
	public let tipPercentage: UInt8

	private enum CodingKeys: String, CodingKey {
		case version
		case networkId = "network_id"
		case startEpochInclusive = "start_epoch_inclusive"
		case endEpochExclusive = "end_epoch_exclusive"
		case nonce
		case publicKey = "notary_public_key"
		case notaryAsSignatory = "notary_as_signatory"
		case costUnitLimit = "cost_unit_limit"
		case tipPercentage = "tip_percentage"
	}

	// MARK: Init
	public init(
		version: TXVersion,
		networkId: NetworkID,
		startEpochInclusive: Epoch,
		endEpochExclusive: Epoch,
		nonce: Nonce,
		publicKey: Engine.PublicKey,
		notaryAsSignatory: Bool,
		costUnitLimit: UInt32,
		tipPercentage: UInt8
	) {
		self.version = version
		self.networkId = networkId
		self.startEpochInclusive = startEpochInclusive
		self.endEpochExclusive = endEpochExclusive
		self.nonce = nonce
		self.publicKey = publicKey
		self.notaryAsSignatory = notaryAsSignatory
		self.costUnitLimit = costUnitLimit
		self.tipPercentage = tipPercentage
	}

	// MARK: Codable
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(String(version), forKey: .version)
		try container.encode(String(networkId), forKey: .networkId)
		try container.encode(String(startEpochInclusive), forKey: .startEpochInclusive)
		try container.encode(String(endEpochExclusive), forKey: .endEpochExclusive)
		try container.encode(String(nonce), forKey: .nonce)
		try container.encode(publicKey, forKey: .publicKey)
		try container.encode(notaryAsSignatory, forKey: .notaryAsSignatory)
		try container.encode(String(costUnitLimit), forKey: .costUnitLimit)
		try container.encode(String(tipPercentage), forKey: .tipPercentage)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		try self.init(
			version: .init(rawValue: decodeAndConvertToNumericType(container: container, key: .version)),
			// TODO: In the future, we should have consistent serialization of the NetworkId on the RET side.
			networkId: NetworkID(decodeAndConvertToNumericType(container: container, key: .networkId)),
			startEpochInclusive: .init(rawValue: decodeAndConvertToNumericType(container: container, key: .startEpochInclusive)),
			endEpochExclusive: .init(rawValue: decodeAndConvertToNumericType(container: container, key: .endEpochExclusive)),
			nonce: .init(rawValue: decodeAndConvertToNumericType(container: container, key: .nonce)),
			publicKey: container.decode(Engine.PublicKey.self, forKey: .publicKey),
			notaryAsSignatory: container.decode(Bool.self, forKey: .notaryAsSignatory),
			costUnitLimit: decodeAndConvertToNumericType(container: container, key: .costUnitLimit),
			tipPercentage: decodeAndConvertToNumericType(container: container, key: .tipPercentage)
		)
	}
}

// TODO: Move to a better place
public func decodeAndConvertToNumericType<Integer: FixedWidthInteger, Key: CodingKey>(
	container: KeyedDecodingContainer<Key>,
	key: Key
) throws -> Integer {
	try Integer(container.decode(String.self, forKey: key)) ?? { throw InternalDecodingFailure.parsingError }()
}
