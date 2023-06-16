import AccountsClient
import ClientPrelude
import EngineToolkit
import Profile
import SecureStorageClient

// MARK: - FailedToFindFactorSource
struct FailedToFindFactorSource: Swift.Error {}

// MARK: - DeviceFactorSourceClient + DependencyKey
extension DeviceFactorSourceClient: DependencyKey {
	public typealias Value = Self

	public static let liveValue: Self = {
		@Dependency(\.secureStorageClient) var secureStorageClient

		return Self(
			publicKeysFromOnDeviceHD: { request in
				let factorSourceID = request.deviceFactorSource.id

				guard
					let mnemonicWithPassphrase = try await secureStorageClient
					.loadMnemonicByFactorSourceID(factorSourceID.embed(), request.loadMnemonicPurpose)
				else {
					loggerGlobal.critical("Failed to find factor source with ID: '\(factorSourceID)'")
					throw FailedToFindFactorSource()
				}
				let hdRoot = try mnemonicWithPassphrase.hdRoot()
				let derivedKeys = try request.derivationPaths.map {
					let key = try hdRoot.derivePrivateKey(
						path: $0,
						curve: $0.curveForScheme
					)
					return HierarchicalDeterministicPublicKey(publicKey: key.publicKey(), derivationPath: $0)
				}
				return OrderedSet(derivedKeys)
			},
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
					let deviceFactorSource = try await factorSourcesClient.getFactorSources().babylonDeviceFactorSources().sorted(by: \.lastUsedOn).first
					let accounts = try await accountsClient.getAccountsOnNetwork(NetworkID.default)

					guard let deviceFactorSource,
					      let mnemonicWithPassphrase = try await secureStorageClient.loadMnemonicByFactorSourceID(
					      	deviceFactorSource.id.embed(),
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
								let factorInstance = unsecuredEntityControl.transactionSigning
								let derivationPath = factorInstance.derivationPath
								let hdRoot = try mnemonicWithPassphrase.hdRoot()
								let privateKey = try hdRoot.derivePrivateKey(
									path: derivationPath,
									curve: factorInstance.publicKey.curve
								)

								return privateKey.publicKey() == factorInstance.publicKey
							}
						} catch {
							return false
						}
					}

					return !accounts.allSatisfy(hasControl)
				} catch {
					loggerGlobal.error("Failure during check if wallet needs account recovery: \(String(describing: error))")
					if error is KeychainAccess.Status {
						throw error
					}
					return true
				}
			}
		)
	}()
}

import Cryptography
