import Foundation
import Sargon

extension DerivationPath {
	public init(string: String) throws {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public var curveForScheme: SLIP10Curve {
		sargonProfileFinishMigrateAtEndOfStage1()
	}

	public var path: HDPath {
		switch self {
		case let .bip44Like(value): value.path
		case let .cap26(value): value.path
		}
	}
}
