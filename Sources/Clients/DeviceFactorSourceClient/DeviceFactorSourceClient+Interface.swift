import ClientPrelude
import Cryptography
import FactorSourcesClient
import Profile
import SecureStorageClient

// MARK: - DeviceFactorSourceClient
public struct DeviceFactorSourceClient: Sendable {
	public var publicKeyFromOnDeviceHD: PublicKeyFromOnDeviceHD
	public var signatureFromOnDeviceHD: SignatureFromOnDeviceHD
}

// MARK: DeviceFactorSourceClient.onDeviceHDPublicKey
extension DeviceFactorSourceClient {
	public typealias PublicKeyFromOnDeviceHD = @Sendable (PublicKeyFromOnDeviceHDRequest) async throws -> Engine.PublicKey
	public typealias SignatureFromOnDeviceHD = @Sendable (SignatureFromOnDeviceHDRequest) async throws -> SignatureWithPublicKey
}

// MARK: - DiscrepancyUnsupportedCurve
struct DiscrepancyUnsupportedCurve: Swift.Error {}

// MARK: - PublicKeyFromOnDeviceHDRequest
public struct PublicKeyFromOnDeviceHDRequest: Sendable, Hashable {
	public let hdOnDeviceFactorSource: HDOnDeviceFactorSource
	public let derivationPath: DerivationPath
	public let curve: SLIP10.Curve
	public let loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose

	public init(
		hdOnDeviceFactorSource: HDOnDeviceFactorSource,
		derivationPath: DerivationPath,
		curve: SLIP10.Curve,
		loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose
	) throws {
		guard hdOnDeviceFactorSource.parameters.supportedCurves.contains(curve) else {
			throw DiscrepancyUnsupportedCurve()
		}
		self.hdOnDeviceFactorSource = hdOnDeviceFactorSource
		self.derivationPath = derivationPath
		self.curve = curve
		self.loadMnemonicPurpose = loadMnemonicPurpose
	}
}

// MARK: - SignatureFromOnDeviceHDRequest
public struct SignatureFromOnDeviceHDRequest: Sendable, Hashable {
	public let hdRoot: HD.Root
	public let derivationPath: DerivationPath
	public let curve: SLIP10.Curve

	/// The data to hash and sign
	public let unhashedData: Data

	public init(
		hdRoot: HD.Root,
		derivationPath: DerivationPath,
		curve: SLIP10.Curve,
		unhashedData: Data
	) {
		self.hdRoot = hdRoot
		self.derivationPath = derivationPath
		self.curve = curve
		self.unhashedData = unhashedData
	}
}

// MARK: - FailedToDeviceFactorSourceForSigning
struct FailedToDeviceFactorSourceForSigning: Swift.Error {}

// MARK: - IncorrectSignatureCountExpectedExactlyOne
struct IncorrectSignatureCountExpectedExactlyOne: Swift.Error {}
extension DeviceFactorSourceClient {
	public func signUsingDeviceFactorSource(
		signerEntity: EntityPotentiallyVirtual,
		unhashedDataToSign: some DataProtocol,
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
				let deviceFactorSource = try await factorSourcesClient.getFactorSource(of: factorInstance)
			else {
				throw FailedToDeviceFactorSourceForSigning()
			}

			let signatures = try await signUsingDeviceFactorSource(
				deviceFactorSource: deviceFactorSource,
				signerEntities: [signerEntity],
				unhashedDataToSign: unhashedDataToSign,
				purpose: purpose
			)

			guard let signature = signatures.first, signatures.count == 1 else {
				throw IncorrectSignatureCountExpectedExactlyOne()
			}
			return signature
		}
	}

	public func signUsingDeviceFactorSource(
		deviceFactorSource: FactorSource,
		signerEntities: Set<EntityPotentiallyVirtual>,
		unhashedDataToSign: some DataProtocol,
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

				guard let derivationPath = factorInstance.derivationPath else {
					let errMsg = "Expected derivation path on unsecured factorInstance"
					loggerGlobal.critical(.init(stringLiteral: errMsg))
					assertionFailure(errMsg)
					throw FactorInstanceDoesNotHaveADerivationPathUnableToSign()
				}

				if factorInstance.factorSourceID != factorSourceID {
					let errMsg = "Discrepancy, you specified to use a device factor source you beleived to be the one controlling the entity, but it does not match the genesis factor source id."
					loggerGlobal.critical(.init(stringLiteral: errMsg))
					assertionFailure(errMsg)
				}
				let curve = factorInstance.publicKey.curve

				loggerGlobal.debug("🔏 Signing data with device, with entity=\(entity.displayName), curve=\(curve), factor source label=\(deviceFactorSource.label), description=\(deviceFactorSource.description)")

				let signatureWithPublicKey = try await self.signatureFromOnDeviceHD(.init(
					hdRoot: hdRoot,
					derivationPath: derivationPath,
					curve: curve,
					unhashedData: Data(unhashedDataToSign)
				))
				let sigatureWithDerivationPath = Signature(
					signatureWithPublicKey: signatureWithPublicKey,
					derivationPath: factorInstance.derivationPath
				)

				let entitySignature = try SignatureOfEntity(
					signerEntity: entity,
					factorInstance: factorInstance,
					signature: sigatureWithDerivationPath
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
		}
	}
}

// MARK: - FactorInstanceDoesNotHaveADerivationPathUnableToSign
struct FactorInstanceDoesNotHaveADerivationPathUnableToSign: Swift.Error {}
