// import Cryptography
// import EngineToolkitModels
// import Prelude
//
//// MARK: - CreateVirtualEntityRequest
// public struct CreateVirtualEntityRequest: Sendable {
//	// if `nil` we will use current networkID
//	public let networkID: NetworkID?
//	public let factorSource: EntityCreatingFactorSource
//	public let displayName: NonEmptyString
//	public let extraProperties: @Sendable (Int) -> EntityExtraProperties
//
//	public init(
//		networkID: NetworkID?,
//        factorSource: EntityCreatingFactorSource,
//		displayName: NonEmpty<String>,
//		extraProperties: @escaping @Sendable (Int) -> EntityExtraProperties
//	) {
//		self.factorSource = factorSource
//		self.networkID = networkID
//		self.displayName = displayName
//		self.extraProperties = extraProperties
//	}
// }
//
