import AccountsClient
import ClientPrelude
import Cryptography
import EngineToolkit
import FactorSourcesClient
import Profile
import SecureStorageClient
import UseFactorSourceClient

// MARK: - FailedToFindFactorSource
struct FailedToFindFactorSource: Swift.Error {}

// MARK: - UseFactorSourceClient + DependencyKey
extension UseFactorSourceClient: DependencyKey {
	public typealias Value = Self

	public static let liveValue: Self = {
		@Dependency(\.secureStorageClient) var secureStorageClient
		@Dependency(\.factorSourcesClient) var factorSourcesClient

		let publicKeyFromOnDeviceHD: PublicKeyFromOnDeviceHD = { request in
			let factorSourceID = request.hdOnDeviceFactorSource.id

			guard
				let mnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(
					factorSourceID,
					.createEntity(kind: request.entityKind)
				)
			else {
				loggerGlobal.critical("Failed to find factor source with ID: '\(factorSourceID)'")
				throw FailedToFindFactorSource()
			}
			let hdRoot = try mnemonicWithPassphrase.hdRoot()
			let privateKey = try hdRoot.derivePrivateKey(
				path: request.derivationPath,
				curve: request.curve
			)

			return try privateKey.publicKey().intoEngine()
		}

		return Self(
			publicKeyFromOnDeviceHD: publicKeyFromOnDeviceHD,
			signatureFromOnDeviceHD: { request in
				let privateKey = try request.hdRoot.derivePrivateKey(
					path: request.derivationPath,
					curve: request.curve
				)
				let hashedData = try blake2b(data: request.unhashedData)
				return try privateKey.sign(hashOfMessage: hashedData)
			},
			isAccountRecoveryNeeded: {
				@Dependency(\.accountsClient) var accountsClient
				@Dependency(\.factorSourcesClient) var factorSourcesClient

				do {
					// FIXME: figure out a canonocal way to find the expected `device` factor source for this iPhone..?
					let deviceFactorSource: HDOnDeviceFactorSource = try await factorSourcesClient.getFactorSources().hdOnDeviceFactorSource().sorted(by: { $0.lastUsedOn > $1.lastUsedOn }).first!

					let accounts = try await accountsClient.getAccountsOnNetwork(NetworkID.default)

					guard
						let mnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(
							deviceFactorSource.id,
							.checkingAccounts
						)
					else {
						// Failed to find mnemonic for factor source
						return true
					}
					@Sendable func hasControl(of account: Profile.Network.Account) -> Bool {
						do {
							switch account.securityState {
							case let .unsecured(unsecuredEntityControl):
								let factorInstance = unsecuredEntityControl.genesisFactorInstance
								guard let derivationPath = factorInstance.derivationPath else {
									// FIXME: create a new HDFactorInstance type like HDOnDeviceFactorSource where `derivationPath` is not optional?
									loggerGlobal.critical("Factor instance did not contain a derivationPath, this is troublesome.")
									return false
								}
								let hdRoot = try mnemonicWithPassphrase.hdRoot()
								let privateKey = try hdRoot.derivePrivateKey(
									path: derivationPath,
									curve: factorInstance.publicKey.curve.slip10
								)

								return privateKey.publicKey() == factorInstance.publicKey
							}
						} catch {
							return false
						}
					}

					let hasControlOfAllAccounts = accounts.reduce(into: true) { $0 = $0 && hasControl(of: $1) }
					return !hasControlOfAllAccounts

				} catch {
					loggerGlobal.error("Failure during check if wallet needs account recovery: \(String(describing: error))")
					return true
				}
			}
		)
	}()
}

extension ECCurve {
	var slip10: Slip10Curve {
		switch self {
		case .curve25519: return .curve25519
		case .secp256k1: return .secp256k1
		}
	}
}

// MARK: - UseFactorSourceClient.Purpose
extension UseFactorSourceClient {
	public enum Purpose: Sendable, Equatable {
		case signData(Data, isTransaction: Bool)
		case createEntity(kind: EntityKind)
		fileprivate var loadMnemonicPurpose: SecureStorageClient.LoadMnemonicPurpose {
			switch self {
			case let .signData(_, isTransaction): return isTransaction ? .signTransaction : .signAuthChallenge
			case let .createEntity(kind): return .createEntity(kind: kind)
			}
		}
	}
}
