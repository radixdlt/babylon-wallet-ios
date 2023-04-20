import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - CreateVirtualEntityRequest
public struct CreateVirtualEntityRequest: Sendable, Hashable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?
	public let babylonDeviceFactorSource: BabylonDeviceFactorSource
	public let curve: SLIP10.Curve
	public let displayName: NonEmptyString

	public init(
		curve: SLIP10.Curve,
		networkID: NetworkID?,
		babylonDeviceFactorSource: BabylonDeviceFactorSource,
		displayName: NonEmpty<String>
	) {
		self.babylonDeviceFactorSource = babylonDeviceFactorSource
		self.curve = curve
		self.networkID = networkID
		self.displayName = displayName
	}
}
