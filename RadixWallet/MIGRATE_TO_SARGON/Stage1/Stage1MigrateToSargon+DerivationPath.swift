import Foundation
import Sargon

extension DerivationPath {
	var scheme: DerivationPathScheme {
		switch self {
		case .bip44Like: DerivationPathScheme.bip44Olympia
		case .cap26: DerivationPathScheme.cap26
		}
	}
}
