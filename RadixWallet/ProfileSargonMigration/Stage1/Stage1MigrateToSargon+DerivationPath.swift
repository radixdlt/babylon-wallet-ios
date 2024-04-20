import Foundation
import Sargon

extension DerivationPath {
	public init(string: String) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public var curveForScheme: SLIP10Curve {
		switch self {
		case .bip44Like: .secp256k1
		case .cap26: .curve25519
		}
	}

	public var path: HDPath {
		switch self {
		case let .bip44Like(value): value.path
		case let .cap26(value): value.path
		}
	}

	public static func forEntity(
		kind: EntityKind,
		networkID: NetworkID,
		index: HDPathValue
	) throws -> Self {
		switch kind {
		case .account:
			AccountPath(networkID: networkID, keyKind: .transactionSigning, index: index).asDerivationPath
		case .persona:
			IdentityPath(networkID: networkID, keyKind: .transactionSigning, index: index).asDerivationPath
		}
	}
}
