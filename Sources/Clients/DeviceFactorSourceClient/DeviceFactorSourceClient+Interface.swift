import ClientPrelude
import Cryptography
import FactorSourcesClient
import Profile
import SecureStorageClient

// MARK: - DeviceFactorSourceClient
public struct DeviceFactorSourceClient: Sendable {
	public var publicKeysFromOnDeviceHD: PublicKeysFromOnDeviceHD
	public var signatureFromOnDeviceHD: SignatureFromOnDeviceHD
	public var isAccountRecoveryNeeded: IsAccountRecoveryNeeded

	// FIXME: Find a better home for this...

	public var entitiesControlledByFactorSource: GetEntitiesControlledByFactorSource

	/// Fetched accounts and personas on current network that are controlled by a device factor source, for every factor source in current profile
	public var controlledEntities: GetControlledEntities

	public init(
		publicKeysFromOnDeviceHD: @escaping PublicKeysFromOnDeviceHD,
		signatureFromOnDeviceHD: @escaping SignatureFromOnDeviceHD,
		isAccountRecoveryNeeded: @escaping IsAccountRecoveryNeeded,
		entitiesControlledByFactorSource: @escaping GetEntitiesControlledByFactorSource,
		controlledEntities: @escaping GetControlledEntities
	) {
		self.publicKeysFromOnDeviceHD = publicKeysFromOnDeviceHD
		self.signatureFromOnDeviceHD = signatureFromOnDeviceHD
		self.isAccountRecoveryNeeded = isAccountRecoveryNeeded

		self.entitiesControlledByFactorSource = entitiesControlledByFactorSource
		self.controlledEntities = controlledEntities
	}
}

// MARK: DeviceFactorSourceClient.onDeviceHDPublicKey
extension DeviceFactorSourceClient {
	public typealias GetEntitiesControlledByFactorSource = @Sendable (DeviceFactorSource, ProfileSnapshot?) async throws -> EntitiesControlledByFactorSource
	public typealias GetControlledEntities = @Sendable (ProfileSnapshot?) async throws -> IdentifiedArrayOf<EntitiesControlledByFactorSource>

	public typealias PublicKeysFromOnDeviceHD = @Sendable (PublicKeysFromOnDeviceHDRequest) async throws -> [HierarchicalDeterministicPublicKey]
	public typealias SignatureFromOnDeviceHD = @Sendable (SignatureFromOnDeviceHDRequest) async throws -> Cryptography.SignatureWithPublicKey
	public typealias IsAccountRecoveryNeeded = @Sendable () async throws -> Bool
}

// MARK: - DiscrepancyUnsupportedCurve
struct DiscrepancyUnsupportedCurve: Swift.Error {}

// MARK: - PublicKeysFromOnDeviceHDRequest
public struct PublicKeysFromOnDeviceHDRequest: Sendable, Hashable {
	public let deviceFactorSource: DeviceFactorSource
	public let derivationPaths: [DerivationPath]
	public let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose

	public init(
		deviceFactorSource: DeviceFactorSource,
		derivationPaths: [DerivationPath],
		loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose
	) throws {
		for derivationPath in derivationPaths {
			guard deviceFactorSource.cryptoParameters.supportedCurves.contains(derivationPath.curveForScheme) else {
				throw DiscrepancyUnsupportedCurve()
			}
		}
		self.deviceFactorSource = deviceFactorSource
		self.derivationPaths = derivationPaths
		self.loadMnemonicPurpose = loadMnemonicPurpose
	}
}

// MARK: - SignatureFromOnDeviceHDRequest
public struct SignatureFromOnDeviceHDRequest: Sendable, Hashable {
	public let hdRoot: HD.Root
	public let derivationPath: DerivationPath
	public let curve: SLIP10.Curve

	/// The data to sign
	public let hashedData: Data

	public init(
		hdRoot: HD.Root,
		derivationPath: DerivationPath,
		curve: SLIP10.Curve,
		hashedData: Data
	) {
		self.hdRoot = hdRoot
		self.derivationPath = derivationPath
		self.curve = curve
		self.hashedData = hashedData
	}
}

// MARK: - FailedToDeviceFactorSourceForSigning
struct FailedToDeviceFactorSourceForSigning: Swift.Error {}

// MARK: - IncorrectSignatureCountExpectedExactlyOne
struct IncorrectSignatureCountExpectedExactlyOne: Swift.Error {}
extension DeviceFactorSourceClient {
	public func signUsingDeviceFactorSource(
		signerEntity: EntityPotentiallyVirtual,
		hashedDataToSign: some DataProtocol,
		purpose: SigningPurpose
	) async throws -> SignatureOfEntity {
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		switch signerEntity.securityState {
		case let .unsecured(control):
			let factorInstance = {
				switch purpose {
				case .signAuth:
					return control.authenticationSigning ?? control.transactionSigning
				case .signTransaction:
					return control.transactionSigning
				}
			}()

			guard
				let deviceFactorSource = try await factorSourcesClient.getDeviceFactorSource(of: factorInstance)
			else {
				throw FailedToDeviceFactorSourceForSigning()
			}

			let signatures = try await signUsingDeviceFactorSource(
				deviceFactorSource: deviceFactorSource,
				signerEntities: [signerEntity],
				hashedDataToSign: hashedDataToSign,
				purpose: purpose
			)

			guard let signature = signatures.first, signatures.count == 1 else {
				throw IncorrectSignatureCountExpectedExactlyOne()
			}
			return signature
		}
	}

	public func signUsingDeviceFactorSource(
		deviceFactorSource: DeviceFactorSource,
		signerEntities: Set<EntityPotentiallyVirtual>,
		hashedDataToSign: some DataProtocol,
		purpose: SigningPurpose
	) async throws -> Set<SignatureOfEntity> {
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		let factorSourceID = deviceFactorSource.id

		guard
			let loadedMnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID, purpose.loadMnemonicPurpose)
		else {
			throw FailedToDeviceFactorSourceForSigning()
		}
		let hdRoot = try loadedMnemonicWithPassphrase.hdRoot()

		var signatures = Set<SignatureOfEntity>()

		for entity in signerEntities {
			switch entity.securityState {
			case let .unsecured(unsecuredControl):

				let factorInstance = {
					switch purpose {
					case .signAuth:
						return unsecuredControl.authenticationSigning ?? unsecuredControl.transactionSigning
					case .signTransaction:
						return unsecuredControl.transactionSigning
					}
				}()

				let derivationPath = factorInstance.derivationPath

				if factorInstance.factorSourceID != factorSourceID {
					let errMsg = "Discrepancy, you specified to use a device factor source you beleived to be the one controlling the entity, but it does not match the genesis factor source id."
					loggerGlobal.critical(.init(stringLiteral: errMsg))
					assertionFailure(errMsg)
				}
				let curve = factorInstance.publicKey.curve

				loggerGlobal.debug("🔏 Signing data with device, with entity=\(entity.displayName), curve=\(curve), factor source hint.name=\(deviceFactorSource.hint.name), hint.model=\(deviceFactorSource.hint.model)")

				let signatureWithPublicKey = try await self.signatureFromOnDeviceHD(.init(
					hdRoot: hdRoot,
					derivationPath: derivationPath,
					curve: curve,
					hashedData: Data(hashedDataToSign)
				))

				let entitySignature = SignatureOfEntity(
					signerEntity: entity,
					derivationPath: derivationPath,
					factorSourceID: factorSourceID.embed(),
					signatureWithPublicKey: signatureWithPublicKey
				)

				signatures.insert(entitySignature)
			}
		}

		return signatures
	}
}

extension SigningPurpose {
	public var loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose {
		switch self {
		case .signAuth: return .signAuthChallenge
		case .signTransaction(.manifestFromDapp):
			return .signTransaction
		case .signTransaction(.internalManifest(.transfer)):
			return .signTransaction
		case .signTransaction(.internalManifest(.uploadAuthKey)):
			return .createSignAuthKey
		#if DEBUG
		case .signTransaction(.internalManifest(.debugModifyAccount)):
			return .updateAccountMetadata
		#endif // DEBUG
		}
	}
}

// MARK: - FactorInstanceDoesNotHaveADerivationPathUnableToSign
struct FactorInstanceDoesNotHaveADerivationPathUnableToSign: Swift.Error {}
