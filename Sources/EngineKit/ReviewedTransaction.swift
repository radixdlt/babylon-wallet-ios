import EngineToolkit
import Foundation

// MARK: - TransactionKind
public enum TransactionKind: Hashable, Sendable {
	case conforming(TransactionType.GeneralTransaction)
	case nonConforming
}

extension [TransactionType] {
	public func transactionKind() throws -> TransactionKind {
		// Empty array means non conforming transaction. ET was not able to map it to any type
		guard !isEmpty else {
			return .nonConforming
		}

		// First try to get the general transaction, if missing then convert the first transaction to general transaction
		return try firstNonNil(\.generalTransaction).map(TransactionKind.conforming) ?? first!.transactionKind()
	}
}

/// This is kinda temporary conversion of all transaction types into GeneralTransaction, until(not sure if needed) we will want to
/// have specific UI for different transaction types
extension TransactionType {
	public var generalTransaction: GeneralTransaction? {
		if case let .generalTransaction(accountProofs, accountWithdraws, accountDeposits, addressesInManifest, metadataOfNewlyCreatedEntities, dataOfNewlyMintedNonFungibles, addressesOfNewlyCreatedEntities) = self {
			return .init(
				accountProofs: accountProofs,
				accountWithdraws: accountWithdraws,
				accountDeposits: accountDeposits,
				addressesInManifest: addressesInManifest,
				metadataOfNewlyCreatedEntities: metadataOfNewlyCreatedEntities,
				dataOfNewlyMintedNonFungibles: dataOfNewlyMintedNonFungibles,
				addressesOfNewlyCreatedEntities: addressesOfNewlyCreatedEntities
			)
		}

		return nil
	}

	public struct GeneralTransaction: Hashable, Sendable {
		public let accountProofs: [EngineToolkit.Address]
		public let accountWithdraws: [String: [ResourceTracker]]
		public let accountDeposits: [String: [ResourceTracker]]
		public let addressesInManifest: [EngineToolkit.EntityType: [EngineToolkit.Address]]
		public let metadataOfNewlyCreatedEntities: [String: [String: MetadataValue?]]
		public let dataOfNewlyMintedNonFungibles: [String: [NonFungibleLocalId: [UInt8]]]
		public let addressesOfNewlyCreatedEntities: [EngineToolkit.Address]

		public var allAddress: [EngineToolkit.Address] {
			addressesInManifest.flatMap(\.value)
		}
	}

	public func transactionKind() throws -> TransactionKind {
		switch self {
		case let .simpleTransfer(from, to, transferred):
			let addressesInManifest = [
				from,
				to,
				transferred.resourceAddress,
			].reduce(into: [EngineToolkit.EntityType: [EngineToolkit.Address]]()) { partialResult, address in
				partialResult[address.entityType(), default: []].append(address)
			}

			return .conforming(
				.init(
					accountProofs: [],
					accountWithdraws: [from.addressString(): [transferred.toResourceTracker]],
					accountDeposits: [to.addressString(): [transferred.toResourceTracker]],
					addressesInManifest: addressesInManifest,
					metadataOfNewlyCreatedEntities: [:],
					dataOfNewlyMintedNonFungibles: [:],
					addressesOfNewlyCreatedEntities: []
				)
			)

		case let .transfer(from, transfers):
			var withdraws: [String: ResourceTracker] = [:]
			var deposits: [String: [ResourceTracker]] = [:]
			var allAddresses: Set<EngineToolkit.Address> = [from]

			for (address, resouceTransfers) in transfers {
				let accountAddress = try EngineToolkit.Address(address: address)
				allAddresses.insert(accountAddress)

				for (rawResourceAddress, resource) in resouceTransfers {
					let resourceAddress = try EngineToolkit.Address(address: rawResourceAddress)
					allAddresses.insert(resourceAddress)

					let existingResource = withdraws[rawResourceAddress]
					var total: ResourceTracker
					let transfered: ResourceTracker

					switch resource {
					case let .amount(amount):
						transfered = .fungible(
							resourceAddress: resourceAddress,
							amount: .guaranteed(value: amount)
						)
						total = transfered
						if let totalAmount = existingResource?.decimalSource.amount {
							let sum = try totalAmount.add(other: amount)
							total = .fungible(
								resourceAddress: resourceAddress,
								amount: .guaranteed(value: sum)
							)
						}
					case let .ids(ids):
						transfered = try! .nonFungible(
							resourceAddress: resourceAddress,
							amount: .guaranteed(value: .init(value: "\(ids.count)")),
							ids: .guaranteed(value: ids)
						)
						total = transfered
						if let allIds = existingResource?.ids {
							let sum = allIds + ids
							total = try! .nonFungible(
								resourceAddress: resourceAddress,
								amount: .guaranteed(value: .init(value: "\(sum.count)")),
								ids: .guaranteed(value: sum)
							)
						}
					}

					withdraws[rawResourceAddress] = total
					deposits[address, default: []].append(transfered)
				}
			}

			let addressesInManifest = allAddresses.reduce(into: [EngineToolkit.EntityType: [EngineToolkit.Address]]()) { partialResult, address in
				partialResult[address.entityType(), default: []].append(address)
			}

			return .conforming(
				.init(
					accountProofs: [],
					accountWithdraws: [from.addressString(): Array(withdraws.values)],
					accountDeposits: deposits,
					addressesInManifest: addressesInManifest,
					metadataOfNewlyCreatedEntities: [:],
					dataOfNewlyMintedNonFungibles: [:],
					addressesOfNewlyCreatedEntities: []
				)
			)
		case let .generalTransaction(accountProofs, accountWithdraws, accountDeposits, addressesInManifest, metadataOfNewlyCreatedEntities, dataOfNewlyMintedNonFungibles, addressesOfNewlyCreatedEntities):
			return .conforming(
				.init(
					accountProofs: accountProofs,
					accountWithdraws: accountWithdraws,
					accountDeposits: accountDeposits,
					addressesInManifest: addressesInManifest,
					metadataOfNewlyCreatedEntities: metadataOfNewlyCreatedEntities,
					dataOfNewlyMintedNonFungibles: dataOfNewlyMintedNonFungibles,
					addressesOfNewlyCreatedEntities: addressesOfNewlyCreatedEntities
				)
			)
		case .accountDepositSettings:
			return .nonConforming
		}
	}
}

extension ResourceSpecifier {
	public var amount: EngineKit.Decimal? {
		if case let .amount(_, amount) = self {
			return amount
		}

		return nil
	}

	public var ids: [NonFungibleLocalId]? {
		if case let .ids(_, ids) = self {
			return ids
		}
		return nil
	}

	public var resourceAddress: EngineToolkit.Address {
		switch self {
		case let .amount(resourceAddress, _):
			return resourceAddress
		case let .ids(resourceAddress, _):
			return resourceAddress
		}
	}

	public var toResourceTracker: ResourceTracker {
		switch self {
		case let .amount(resourceAddress, amount):
			return .fungible(resourceAddress: resourceAddress, amount: .guaranteed(value: amount))
		case let .ids(resourceAddress, ids):
			return try! .nonFungible(resourceAddress: resourceAddress, amount: .guaranteed(value: .init(value: "\(ids.count)")), ids: .guaranteed(value: ids))
		}
	}
}

extension ResourceTracker {
	public var decimalSource: DecimalSource {
		switch self {
		case let .fungible(_, amount):
			return amount
		case let .nonFungible(_, amount, _):
			return amount
		}
	}

	public var resourceAddress: EngineToolkit.Address {
		switch self {
		case let .fungible(address, _):
			return address
		case let .nonFungible(address, _, _):
			return address
		}
	}

	public var ids: [NonFungibleLocalId]? {
		switch self {
		case .fungible:
			return nil
		case let .nonFungible(_, _, source):
			return source.ids
		}
	}
}

extension NonFungibleLocalIdVecSource {
	public var ids: [NonFungibleLocalId] {
		switch self {
		case let .guaranteed(value):
			return value
		case let .predicted(_, value):
			return value
		}
	}
}

extension MetadataValue {
	public var string: String? {
		if case let .stringValue(value) = self {
			return value
		}
		return nil
	}

	public var stringArray: [String]? {
		if case let .stringArrayValue(value) = self {
			return value
		}
		return nil
	}

	public var url: URL? {
		if case let .urlValue(value) = self {
			return URL(string: value)
		}
		return nil
	}
}

extension DecimalSource {
	public var amount: EngineKit.Decimal {
		switch self {
		case let .guaranteed(value):
			return value
		case let .predicted(_, value):
			return value
		}
	}
}
