import Foundation
import Sargon

extension BIP44LikePath {
	public var asGeneral: DerivationPath {
		.bip44Like(value: self)
	}
}
