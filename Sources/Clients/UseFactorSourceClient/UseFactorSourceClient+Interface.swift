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
	public func sign(
		deviceFactorSource: FactorSource? = nil,
		with account: Profile.Network.Account,
		unhashedDataToSign unhashed_: some DataProtocol,
		cache cachedPrivateHDFactorSources: ActorIsolated<IdentifiedArrayOf<PrivateHDFactorSource>> = .init([])
	) async throws -> AccountSignature {
		@Dependency(\.factorSourcesClient) var factorSourcesClient
		@Dependency(\.secureStorageClient) var secureStorageClient
		switch account.securityState {
		case let .unsecured(unsecuredControl):
			let factorInstance = unsecuredControl.genesisFactorInstance
			let factorSources = try await factorSourcesClient.getFactorSources()
			let factorSourceID = deviceFactorSource?.id ?? factorInstance.factorSourceID

			let privateHDFactorSource: PrivateHDFactorSource = try await { @Sendable () async throws -> PrivateHDFactorSource in

				let cache = await cachedPrivateHDFactorSources.value
				if let cached = cache[id: factorSourceID] {
					return cached
				}

				guard
					let factorSource = deviceFactorSource ?? factorSources[id: factorSourceID],
					let loadedMnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(factorSourceID, .signTransaction)
				else {
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

	public func signUsingDeviceFactorSource(
		deviceFactorSource: FactorSource? = nil,
		of accounts: Set<Profile.Network.Account>,
		unhashedDataToSign unhashed_: some DataProtocol,
		cache cachedPrivateHDFactorSources: ActorIsolated<IdentifiedArrayOf<PrivateHDFactorSource>> = .init([])
	) async throws -> Set<AccountSignature> {
		let signatures = try await accounts.asyncMap { account in
			try await sign(
				deviceFactorSource: deviceFactorSource,
				with: account,
				unhashedDataToSign: unhashed_,
				cache: cachedPrivateHDFactorSources
			)
		}
		return Set(signatures)
	}
}
