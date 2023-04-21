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

// MARK: - CreateVirtualEntityControlledByLedgerFactorSourceRequest
public struct CreateVirtualEntityControlledByLedgerFactorSourceRequest: Sendable {
	// if `nil` we will use current networkID
	public let networkID: NetworkID?
	public let ledger: FactorSource
	public let displayName: NonEmptyString
	public let entityCreatingStorage: FactorSource.Storage.EntityCreating
	public let extraProperties: @Sendable (Int) -> EntityExtraProperties
	public let derivePublicKey: @Sendable (DerivationPath) async throws -> Curve25519.Signing.PublicKey

	public init(
		networkID: NetworkID?,
		ledger: FactorSource,
		displayName: NonEmpty<String>,
		extraProperties: @escaping @Sendable (Int) -> EntityExtraProperties,
		derivePublicKey: @escaping @Sendable (DerivationPath) async throws -> Curve25519.Signing.PublicKey
	) throws {
		guard ledger.kind == .ledgerHQHardwareWallet else {
			throw ExpectedLedgerFactorSource()
		}
		self.derivePublicKey = derivePublicKey
		self.entityCreatingStorage = try ledger.entityCreatingStorage()
		self.ledger = ledger
		self.networkID = networkID
		self.displayName = displayName
		self.extraProperties = extraProperties
	}
}

// MARK: - ExpectedLedgerFactorSource
struct ExpectedLedgerFactorSource: Swift.Error {}
