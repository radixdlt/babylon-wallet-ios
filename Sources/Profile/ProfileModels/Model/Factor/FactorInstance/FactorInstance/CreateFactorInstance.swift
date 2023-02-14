import Cryptography

// MARK: - CreateFactorInstanceRequest
public enum CreateFactorInstanceRequest {
	case fromNonHardwareHierarchicalDeterministicMnemonicFactorSource(FromNonHardwareHierarchicalDeterministicMnemonicFactorSource)
}

// MARK: CreateFactorInstanceRequest.FromNonHardwareHierarchicalDeterministicMnemonicFactorSource
extension CreateFactorInstanceRequest {
	/// A request that can be used by any Non-Hardware Hierarchical Deterministic Factor Source.
	public struct FromNonHardwareHierarchicalDeterministicMnemonicFactorSource {
		public let reference: FactorSourceReference
		public let derivationPath: DerivationPath

		public init(
			reference: FactorSourceReference,
			derivationPath: DerivationPath
		) {
			self.reference = reference
			self.derivationPath = derivationPath
		}
	}
}

// MARK: - AnyCreateFactorInstanceForResponse
public struct AnyCreateFactorInstanceForResponse: Sendable {
	struct WrongPublicKeyError: Swift.Error {}
	struct NoPrivateKeyError: Swift.Error {}

	public let factorInstance: FactorInstance

	public let privateKey: SLIP10.PrivateKey?
	public func getPrivateKey() throws -> SLIP10.PrivateKey {
		guard let privateKey else {
			throw NoPrivateKeyError()
		}
		return privateKey
	}

	fileprivate init<FI: FactorInstanceProtocol>(_ concrete: CreateFactorInstanceWithKey<FI>) throws {
		try self.init(factorInstance: concrete.factorInstance.wrapAsFactorInstance(), privateKey: concrete.privateKey)
	}

	public init(factorInstance: FactorInstance, privateKey: SLIP10.PrivateKey?) throws {
		if
			let privateKey,
			let hdFactorInstane = factorInstance.any() as? FactorInstanceHierarchicalDeterministicProtocol
		{
			guard hdFactorInstane.publicKey == privateKey.publicKey() else {
				throw WrongPublicKeyError()
			}
		}
		self.factorInstance = factorInstance
		self.privateKey = privateKey
	}
}

// MARK: - CreateFactorInstanceWithKey
public struct CreateFactorInstanceWithKey<Instance: Sendable & FactorInstanceProtocol>: Sendable {
	struct WrongPublicKeyError: Swift.Error {}
	struct NoPrivateKeyError: Swift.Error {}

	public let factorInstance: Instance

	public func eraseToAny() throws -> AnyCreateFactorInstanceForResponse {
		try .init(self)
	}

	public let privateKey: SLIP10.PrivateKey?
	public func getPrivateKey() throws -> SLIP10.PrivateKey {
		guard let privateKey else {
			throw NoPrivateKeyError()
		}
		return privateKey
	}

	public init(factorInstance: Instance, privateKey: SLIP10.PrivateKey?) throws {
		if
			let privateKey,
			let hdFactorInstane = factorInstance as? FactorInstanceHierarchicalDeterministicProtocol
		{
			guard hdFactorInstane.publicKey == privateKey.publicKey() else {
				throw WrongPublicKeyError()
			}
		}
		self.factorInstance = factorInstance
		self.privateKey = privateKey
	}
}

public typealias CreateFactorInstanceForRequest = @Sendable (CreateFactorInstanceRequest) async throws -> AnyCreateFactorInstanceForResponse?
