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
		of accounts: Set<Profile.Network.Account>,
		unhashedDataToSign unhashed_: some DataProtocol,
		cache cachedPrivateHDFactorSources: ActorIsolated<IdentifiedArrayOf<PrivateHDFactorSource>> = .init([])
	) async throws -> Set<AccountSignature> {
		// Enables us to only read from keychain once per mnemonic
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.secureStorageClient) var secureStorageClient

		@Sendable func sign(
			with account: Profile.Network.Account
		) async throws -> AccountSignature {
			switch account.securityState {
			case let .unsecured(unsecuredControl):
				let factorInstance = unsecuredControl.genesisFactorInstance
				let factorSources = try await factorSourcesClient.getFactorSources()

				let privateHDFactorSource: PrivateHDFactorSource = try await { @Sendable () async throws -> PrivateHDFactorSource in

					let cache = await cachedPrivateHDFactorSources.value
					if let cached = cache[id: factorInstance.factorSourceID] {
						return cached
					}

					guard
						let factorSource = factorSources[id: factorInstance.factorSourceID],
						let loadedMnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorInstance.factorSourceID, .signTransaction)
					else {
						//                        throw TransactionFailure.failedToCompileOrSign(.failedToLoadFactorSourceForSigning)
						throw FailedToDeviceFactorSourceForSigning()
					}

					let privateHDFactorSource = try PrivateHDFactorSource(
						mnemonicWithPassphrase: loadedMnemonicWithPassphrase,
						hdOnDeviceFactorSource: .init(factorSource: factorSource)
					)

					await cachedPrivateHDFactorSources.setValue(cache.appending(privateHDFactorSource))

					return privateHDFactorSource
				}()

				let hdRoot = try privateHDFactorSource.mnemonicWithPassphrase.hdRoot()
				let curve = privateHDFactorSource.hdOnDeviceFactorSource.parameters.supportedCurves.last
				let unhashedData = Data(unhashed_)

				loggerGlobal.debug("🔏 Signing data, with account=\(account.displayName), curve=\(curve), factorSourceKind=\(privateHDFactorSource.hdOnDeviceFactorSource.kind), factorSourceLabel=\(privateHDFactorSource.hdOnDeviceFactorSource.label), factorSourceDescription=\(privateHDFactorSource.hdOnDeviceFactorSource.description)")

				let signatureWithPublicKey = try await self.signatureFromOnDeviceHD(.init(
					hdRoot: hdRoot,
					derivationPath: factorInstance.derivationPath!,
					curve: curve,
					unhashedData: unhashedData
				))

				let sig = Signature(signatureWithPublicKey: signatureWithPublicKey, derivationPath: factorInstance.derivationPath)
				return try AccountSignature(entity: account, factorInstance: factorInstance, signature: sig)
			}
		}

		let signatures = try await accounts.asyncMap(sign)
		return Set(signatures)
	}
}
