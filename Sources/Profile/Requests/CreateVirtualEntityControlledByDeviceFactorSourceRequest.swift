import Cryptography
import EngineToolkitModels
import Prelude

// MARK: - CreateVirtualEntityControlledByDeviceFactorSourceRequest
public struct CreateVirtualEntityControlledByDeviceFactorSourceRequest: Sendable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?
	public let babylonDeviceFactorSource: BabylonDeviceFactorSource
	public let displayName: NonEmptyString
	public let extraProperties: @Sendable (Int) -> EntityExtraProperties

	public init(
		networkID: NetworkID?,
		babylonDeviceFactorSource: BabylonDeviceFactorSource,
		displayName: NonEmpty<String>,
		extraProperties: @escaping @Sendable (Int) -> EntityExtraProperties
	) {
		self.babylonDeviceFactorSource = babylonDeviceFactorSource
		self.networkID = networkID
		self.displayName = displayName
		self.extraProperties = extraProperties
	}
}
