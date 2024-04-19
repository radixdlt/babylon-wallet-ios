import Foundation
import Sargon

extension FactorSourceCryptoParameters {
	public var supportsOlympia: Bool {
		supportedCurves.contains(.secp256k1) &&
			supportedDerivationPathSchemes.contains(.bip44Olympia)
	}

	public var supportsBabylon: Bool {
		supportedCurves.contains(.curve25519) &&
			supportedDerivationPathSchemes.contains(.cap26)
	}
}
