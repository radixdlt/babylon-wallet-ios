import Foundation
import Sargon

extension CAP26Path {
	public var asGeneral: DerivationPath {
		.cap26(value: self)
	}

	public var path: HDPath {
		switch self {
		case let .account(value): value.path
		case let .identity(value): value.path
		case let .getId(value): value.path
		}
	}
}
