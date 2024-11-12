import Foundation
import Sargon

extension DerivationPath {
	var scheme: DerivationPathScheme {
		switch self {
		case .bip44Like: DerivationPathScheme.bip44Olympia
		case .account, .identity: .cap26
		}
	}
}
