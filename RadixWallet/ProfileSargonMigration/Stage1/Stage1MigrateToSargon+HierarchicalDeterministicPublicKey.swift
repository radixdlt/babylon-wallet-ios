import Foundation
import Sargon

extension HierarchicalDeterministicPublicKey {
	public var curve: SLIP10Curve {
		derivationPath.curveForScheme
	}

	init(
		curve curveString: String,
		key keyData: Data,
		path: String
	) throws {
		guard let curve = SLIP10Curve(rawValue: curveString) else {
			struct BadCurve: Swift.Error {}
			loggerGlobal.error("Bad curve")
			throw BadCurve()
		}
		let publicKey = try Sargon.PublicKey(bytes: keyData)
		let derivationPath = try DerivationPath(string: path)
		assert(publicKey.curve == curve)
		assert(derivationPath.curveForScheme == curve)
		self.init(publicKey: publicKey, derivationPath: derivationPath)
	}
}
