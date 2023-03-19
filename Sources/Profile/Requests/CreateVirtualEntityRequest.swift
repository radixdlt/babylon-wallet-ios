import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - CreateVirtualEntityRequest
public struct CreateVirtualEntityRequest: Sendable, Hashable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?
	public let hdOnDeviceFactorSource: HDOnDeviceFactorSource
	public let curve: Slip10Curve
	public let displayName: NonEmptyString

	public init(
		curve: Slip10Curve,
		networkID: NetworkID?,
		hdOnDeviceFactorSource: HDOnDeviceFactorSource,
		displayName: NonEmpty<String>
	) {
		self.hdOnDeviceFactorSource = hdOnDeviceFactorSource
		self.curve = curve
		self.networkID = networkID
		self.displayName = displayName
	}
}
