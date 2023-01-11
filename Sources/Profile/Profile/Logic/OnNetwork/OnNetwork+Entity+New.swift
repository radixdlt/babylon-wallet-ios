import Collections
import EngineToolkit
import Foundation
import Mnemonic
import NonEmpty
import SLIP10

// MARK: - AnyCreateFactorInstanceForResponse
public struct AnyCreateFactorInstanceForResponse: Sendable {
	struct WrongPublicKeyError: Swift.Error {}
	struct NoPrivateKeyError: Swift.Error {}

	public let factorInstance: FactorInstance

	public let privateKey: PrivateKey?
	public func getPrivateKey() throws -> PrivateKey {
		guard let privateKey else {
			throw NoPrivateKeyError()
		}
		return privateKey
	}

	fileprivate init<FI: FactorInstanceProtocol>(_ concrete: CreateFactorInstanceWithKey<FI>) throws {
		try self.init(factorInstance: concrete.factorInstance.wrapAsFactorInstance(), privateKey: concrete.privateKey)
	}

	public init(factorInstance: FactorInstance, privateKey: PrivateKey?) throws {
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

	public let privateKey: PrivateKey?
	public func getPrivateKey() throws -> PrivateKey {
		guard let privateKey else {
			throw NoPrivateKeyError()
		}
		return privateKey
	}

	public init(factorInstance: Instance, privateKey: PrivateKey?) throws {
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

internal extension OnNetwork {
	/// Creates a new, non saved, **Virtual** `Entity` of type `Entity.Type`
	static func createNewVirtualEntity<Entity: EntityProtocol>(
		factorSources: FactorSources,
		index: Int,
		networkID: NetworkID,
		displayName: String?,
		createFactorInstance: @escaping CreateFactorInstanceForRequest,
		makeEntity: (
			_ address: Entity.EntityAddress,
			_ securityState: EntitySecurityState,
			_ index: Int,
			_ derivationPath: Entity.EntityDerivationPath,
			_ displayName: String?
		) throws -> Entity
	) async throws -> Entity {
		let derivationPath = try Entity.EntityDerivationPath(
			networkID: networkID,
			index: index,
			keyKind: .virtualEntity
		)

		let nonHWHDSource = try factorSources.anyNonHardwareHierarchicalDeterministicFactorSource()
		let request = CreateFactorInstanceRequest.fromNonHardwareHierarchicalDeterministicMnemonicFactorSource(
			.init(
				reference: nonHWHDSource.reference,
				derivationPath: derivationPath.wrapAsDerivationPath()
			))

		guard
			let genesisFactorInstanceSome = try await createFactorInstance(request),
			let genesisFactorInstance = genesisFactorInstanceSome.factorInstance.any() as? (any FactorInstanceHierarchicalDeterministicProtocol)
		else {
			throw NoInstance()
		}

		let address = try Entity.deriveAddress(
			networkID: networkID,
			publicKey: genesisFactorInstance.publicKey
		)

		let unsecuredControl = UnsecuredEntityControl(
			genesisFactorInstance: genesisFactorInstance.wrapAsFactorInstance()
		)

		return try makeEntity(
			address,
			.unsecured(unsecuredControl),
			index,
			derivationPath,
			displayName
		)
	}
}

// MARK: - AccountIndexOutOfBounds
struct AccountIndexOutOfBounds: Swift.Error {}

// MARK: - PersonaIndexOutOfBounds
struct PersonaIndexOutOfBounds: Swift.Error {}

// MARK: - NoEntityFoundMatchingCriteria
struct NoEntityFoundMatchingCriteria: Swift.Error {}

public extension Profile {
	func entity(
		networkID: NetworkID,
		kind: EntityKind,
		entityIndex: Int
	) throws -> any EntityProtocol {
		let onNetwork = try onNetwork(id: networkID)
		switch kind {
		case .account:
			guard entityIndex < onNetwork.accounts.count else {
				throw AccountIndexOutOfBounds()
			}
			return onNetwork.accounts[entityIndex]
		case .identity:
			guard entityIndex < onNetwork.personas.count else {
				throw PersonaIndexOutOfBounds()
			}
			return onNetwork.personas[entityIndex]
		}
	}

	func entity<Entity: EntityProtocol>(
		networkID: NetworkID,
		entityType: Entity.Type,
		entityIndex: Int
	) throws -> Entity {
		guard let entity = try entity(networkID: networkID, kind: entityType.entityKind, entityIndex: entityIndex) as? Entity else {
			throw IncorrectEntityType()
		}
		return entity
	}

	struct IncorrectEntityType: Swift.Error {}

	func entity(
		networkID: NetworkID,
		address: AddressProtocol
	) throws -> any EntityProtocol {
		let onNetwork = try onNetwork(id: networkID)
		if let account = onNetwork.accounts.first(where: { $0.address.address == address.address }) {
			return account
		} else if let persona = onNetwork.personas.first(where: { $0.address.address == address.address }) {
			return persona
		} else {
			throw NoEntityFoundMatchingCriteria()
		}
	}

	func signers<Entity>(
		networkID: NetworkID,
		address: AddressProtocol,
		mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) async throws -> NonEmpty<OrderedSet<SignersOf<Entity>>> where Entity: EntityProtocol & Sendable & Hashable {
		let someEntity = try entity(networkID: networkID, address: address)
		guard let entity = someEntity as? Entity else {
			throw IncorrectEntityType()
		}
		return try await signers(
			of: entity,
			mnemonicForFactorSourceByReference: mnemonicForFactorSourceByReference
		)
	}

	func signers<Entity>(
		networkID: NetworkID,
		entityType: Entity.Type,
		entityIndex: Int,
		mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) async throws -> NonEmpty<OrderedSet<SignersOf<Entity>>> where Entity: EntityProtocol & Sendable & Hashable {
		try await signers(
			of: entity(networkID: networkID, entityType: entityType, entityIndex: entityIndex),
			mnemonicForFactorSourceByReference: mnemonicForFactorSourceByReference
		)
	}

	func signers<Entity>(
		of entity: Entity,
		mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) async throws -> NonEmpty<OrderedSet<SignersOf<Entity>>> where Entity: EntityProtocol & Sendable & Hashable {
		try await signers(ofEntities: [entity], mnemonicForFactorSourceByReference: mnemonicForFactorSourceByReference)
	}

	/// Makes sure to only read mnemonic for factor source from keychain once
	/// Makes sure to only read mnemonic for factor source from keychain once
	func signers<Entity>(
		ofEntities entities: some Collection<Entity>,
		mnemonicForFactorSourceByReference: @escaping MnemonicForFactorSourceByReference
	) async throws -> NonEmpty<OrderedSet<SignersOf<Entity>>> where Entity: EntityProtocol & Sendable & Hashable {
		guard !entities.isEmpty else {
			throw NoInstance()
		}

		let factorSource = factorSources.notaryFactorSource
		let factorSourceRef = factorSource.reference

		guard let mnemonic = try await mnemonicForFactorSourceByReference(factorSourceRef) else {
			throw CreateAccountError.noMnemonicFoundInKeychainForReference(factorSourceRef)
		}

		var orderedSet = OrderedSet<SignersOf<Entity>>()

		for entity in entities {
			let notaryFactorInstance = try await factorSource.createAnyFactorInstanceForResponse(
				input: CreateHierarchicalDeterministicFactorInstanceWithMnemonicInput(
					mnemonic: mnemonic,
					derivationPath: entity.derivationPath.wrapAsDerivationPath(),
					includePrivateKey: true
				)
			)

			let notaryPrivateKey = try notaryFactorInstance.getPrivateKey()
			let signers = SignersOf<Entity>(entity: entity, notaryPrivateKey: notaryPrivateKey)
			orderedSet.append(signers)
		}

		return NonEmpty(rawValue: orderedSet)!
	}
}

// MARK: - SignersOf
public struct SignersOf<Entity: EntityProtocol & Sendable & Hashable>: Sendable, Hashable {
	public let entity: Entity
	public let notaryPublicKey: PublicKey
	public let notarySigner: Signer
	public let signers: [Signer]

	// FIXME: mainnet - add other signers here, probably as type: `@Sendable (any DataProtocol) async throws -> ((Prompt) async throws -> SignatureWithPublicKey)`, where `Prompt` is a type which can inform caller that user needs to do something, e.g. input answers to security questions inside the prompt, or asked to connect a Ledger Nano S to the computer etc.
	public init(
		entity: Entity,
		notaryPublicKey: PublicKey,
		notarySigner: @escaping Signer
	) {
		self.entity = entity
		self.notaryPublicKey = notaryPublicKey
		self.notarySigner = notarySigner

		self.signers = [notarySigner]
	}
}

public extension SignersOf {
	func hash(into hasher: inout Hasher) {
		hasher.combine(entity)
	}

	static func == (lhs: Self, rhs: Self) -> Bool {
		lhs.entity == rhs.entity
	}

	typealias Signer = @Sendable (any DataProtocol) async throws -> SignatureWithPublicKey

	init(entity: Entity, notaryPrivateKey: PrivateKey) {
		self.init(
			entity: entity,
			notaryPublicKey: notaryPrivateKey.publicKey(),
			notarySigner: { @Sendable dataToSign in
				try notaryPrivateKey.sign(data: dataToSign)
			}
		)
	}
}
