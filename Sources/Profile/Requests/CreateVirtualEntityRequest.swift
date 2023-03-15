import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - CreateVirtualEntityRequest
public struct CreateVirtualEntityRequest: Sendable, Hashable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?
	public let factorSource: FactorSource
	public let curve: Slip10Curve
	public let displayName: NonEmptyString

	public init(
		curve: Slip10Curve,
		networkID: NetworkID?,
		factorSource: FactorSource,
		displayName: NonEmpty<String>
	) throws {
		self.factorSource = try factorSource.assertIsHD()
		self.curve = curve
		self.networkID = networkID
		self.displayName = displayName
	}
}
