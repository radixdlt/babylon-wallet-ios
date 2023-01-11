import CustomDump
import Foundation

// MARK: - UnsecuredEntityControl
/// Basic security control of an unsecured entity. When said entity
/// is "securified" it will no longer be controlled by this `UnsecuredEntityControl`
/// but rather by an `AccessControl`. It is a name space holding the
/// single factor instance which was used to create
public struct UnsecuredEntityControl:
	Sendable,
	Hashable,
	Codable,
	CustomStringConvertible,
	CustomDumpReflectable
{
	/// The factor instance which was used to create this unsecured entity.
	public let genesisFactorInstance: FactorInstance
	public init(genesisFactorInstance: FactorInstance) {
		self.genesisFactorInstance = genesisFactorInstance
	}
}

public extension UnsecuredEntityControl {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"genesisFactorInstance": genesisFactorInstance,
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		genesisFactorInstance: \(genesisFactorInstance)
		"""
	}
}
