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

	public init(
		publicKeysFromOnDeviceHD: @escaping PublicKeysFromOnDeviceHD,
		signatureFromOnDeviceHD: @escaping SignatureFromOnDeviceHD,
		isAccountRecoveryNeeded: @escaping IsAccountRecoveryNeeded
	) {
		self.publicKeysFromOnDeviceHD = publicKeysFromOnDeviceHD
		self.signatureFromOnDeviceHD = signatureFromOnDeviceHD
		self.isAccountRecoveryNeeded = isAccountRecoveryNeeded
	}
}

// MARK: DeviceFactorSourceClient.onDeviceHDPublicKey
extension DeviceFactorSourceClient {
	public typealias PublicKeysFromOnDeviceHD = @Sendable (PublicKeysFromOnDeviceHDRequest) async throws -> OrderedSet<HierarchicalDeterministicPublicKey>
	public typealias SignatureFromOnDeviceHD = @Sendable (SignatureFromOnDeviceHDRequest) async throws -> SignatureWithPublicKey
	public typealias IsAccountRecoveryNeeded = @Sendable () async throws -> Bool
}

// MARK: - DiscrepancyUnsupportedCurve
struct DiscrepancyUnsupportedCurve: Swift.Error {}

// MARK: - PublicKeysFromOnDeviceHDRequest
public struct PublicKeysFromOnDeviceHDRequest: Sendable, Hashable {
	public let deviceFactorSource: DeviceFactorSource
	public let derivationPaths: OrderedSet<DerivationPath>
	public let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose

	public init(
		deviceFactorSource: DeviceFactorSource,
		derivationPaths: OrderedSet<DerivationPath>,
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

func extractPrimaryRoleSuperAdminDeviceFactorInstance(from securified: Securified) throws -> HierarchicalDeterministicFactorInstance {
	guard let factor = try? securified.transactionSigningStructure.primaryRole.superAdminFactors.first(where: { $0.factorSourceKind == .device })?.virtualHierarchicalDeterministic() else {
		throw ExpectedToSignTransactionWithEntityWhichIsSecurifiedButPrimaryRoleContainsNoSuperAdminFactorOfKindDevice()
	}
	return factor
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

		let factorInstance = try {
			switch signerEntity.securityState {
			case let .unsecured(control):
				switch purpose {
				case .signAuth:
					return control.authenticationSigning ?? control.transactionSigning
				case .signTransaction:
					return control.transactionSigning
				}
			case let .securified(securified):
				switch purpose {
				case .signAuth:
					return securified.authenticationSigning
				case .signTransaction:
					return try extractPrimaryRoleSuperAdminDeviceFactorInstance(from: securified)
				}
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
			let loadedMnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID.embed(), purpose.loadMnemonicPurpose)
		else {
			throw FailedToDeviceFactorSourceForSigning()
		}
		let hdRoot = try loadedMnemonicWithPassphrase.hdRoot()

		var signatures = Set<SignatureOfEntity>()

		for entity in signerEntities {
			let factorInstance = try {
				switch entity.securityState {
				case let .unsecured(unsecuredControl):

					switch purpose {
					case .signAuth:
						return unsecuredControl.authenticationSigning ?? unsecuredControl.transactionSigning
					case .signTransaction:
						return unsecuredControl.transactionSigning
					}
				case let .securified(securified):
					switch purpose {
					case .signAuth:
						return securified.authenticationSigning
					case .signTransaction:
						return try extractPrimaryRoleSuperAdminDeviceFactorInstance(from: securified)
					}
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

// MARK: - ExpectedToSignTransactionWithEntityWhichIsSecurifiedButPrimaryRoleContainsNoSuperAdminFactorOfKindDevice
struct ExpectedToSignTransactionWithEntityWhichIsSecurifiedButPrimaryRoleContainsNoSuperAdminFactorOfKindDevice: Swift.Error {}
