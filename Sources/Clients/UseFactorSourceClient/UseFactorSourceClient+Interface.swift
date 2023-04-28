import ClientPrelude
import Cryptography
import FactorSourcesClient
import Profile

// MARK: - UseFactorSourceClient
public struct UseFactorSourceClient: Sendable {
	public var publicKeyFromOnDeviceHD: PublicKeyFromOnDeviceHD
	public var signatureFromOnDeviceHD: SignatureFromOnDeviceHD
}

// MARK: UseFactorSourceClient.onDeviceHDPublicKey
extension UseFactorSourceClient {
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
	public let entityKind: EntityKind

	public init(
		hdOnDeviceFactorSource: HDOnDeviceFactorSource,
		derivationPath: DerivationPath,
		curve: SLIP10.Curve,
		creationOfEntity entityKind: EntityKind
	) throws {
		guard hdOnDeviceFactorSource.parameters.supportedCurves.contains(curve) else {
			throw DiscrepancyUnsupportedCurve()
		}
		self.hdOnDeviceFactorSource = hdOnDeviceFactorSource
		self.derivationPath = derivationPath
		self.curve = curve
		self.entityKind = entityKind
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

extension UseFactorSourceClient {
	public func signUsingDeviceFactorSource(
		deviceFactorSource: FactorSource,
		of accounts: Set<Profile.Network.Account>,
		unhashedDataToSign: some DataProtocol
	) async throws -> Set<AccountSignature> {
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		let factorSourceID = deviceFactorSource.id

		guard
			let loadedMnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID, .signTransaction)
		else {
			throw FailedToDeviceFactorSourceForSigning()
		}
		let hdRoot = try loadedMnemonicWithPassphrase.hdRoot()

		var signatures = Set<AccountSignature>()

		loggerGlobal.debug("🔏 Signing data with device factor source label=\(deviceFactorSource.label), description=\(deviceFactorSource.description)")

		for account in accounts {
			switch account.securityState {
			case let .unsecured(unsecuredControl):
				let factorInstance = unsecuredControl.genesisFactorInstance
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

				loggerGlobal.debug("🔏 Signing data with device, with account=\(account.displayName), curve=\(curve)")

				let signatureWithPublicKey = try await self.signatureFromOnDeviceHD(.init(
					hdRoot: hdRoot,
					derivationPath: derivationPath,
					curve: curve,
					unhashedData: Data(unhashedDataToSign)
				))
				let sigatureWithDerivationPath = Signature(signatureWithPublicKey: signatureWithPublicKey, derivationPath: factorInstance.derivationPath)
				let accountSignature = try AccountSignature(entity: account, factorInstance: factorInstance, signature: sigatureWithDerivationPath)
				signatures.insert(accountSignature)
			}
		}

		return signatures
	}
}

// MARK: - FactorInstanceDoesNotHaveADerivationPathUnableToSign
struct FactorInstanceDoesNotHaveADerivationPathUnableToSign: Swift.Error {}
