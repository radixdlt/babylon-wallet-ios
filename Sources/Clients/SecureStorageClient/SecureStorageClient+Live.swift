import ClientPrelude
import LocalAuthenticationClient // read LA config to specify max security of new items.
import Profile
import Resources // L10n for auth prompt

// MARK: - KeychainAccess.Accessibility + Sendable
extension KeychainAccess.Accessibility: @unchecked Sendable {}

// MARK: - KeychainAccess.AuthenticationPolicy + Sendable
extension KeychainAccess.AuthenticationPolicy: @unchecked Sendable {}

// MARK: - SecureStorageError
public enum SecureStorageError: Swift.Error, Equatable {
	case evaluateLocalAuthenticationFailed(reason: LocalAuthenticationClient.Error)
	case evaluateLocalAuthenticationFailedUnknown(reason: String)
	case passcodeNotSet
}

// MARK: - SecureStorageClient + DependencyKey
extension SecureStorageClient: DependencyKey {
	public typealias Value = SecureStorageClient

	public static let liveValue: Self = {
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.jsonEncoder) var jsonEncoder
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.localAuthenticationClient) var localAuthenticationClient

		struct AccesibilityAndAuthenticationPolicy: Sendable, Equatable {
			/// The most secure currently available accessibility
			let accessibility: KeychainAccess.Accessibility

			/// The most secure currently available AuthenticationPolicy, if any.
			let authenticationPolicy: AuthenticationPolicy?
		}

		@Sendable func queryMostSecureAccesibilityAndAuthenticationPolicy() async throws -> AccesibilityAndAuthenticationPolicy {
			let config: LocalAuthenticationConfig
			do {
				config = try await localAuthenticationClient.queryConfig()
			} catch let failure as LocalAuthenticationClient.Error {
				throw SecureStorageError.evaluateLocalAuthenticationFailed(reason: failure)
			} catch {
				throw SecureStorageError.evaluateLocalAuthenticationFailedUnknown(reason: String(describing: error))
			}

			guard config.isPasscodeSetUp else {
				throw SecureStorageError.passcodeNotSet
			}

			// we know that user has `passcode` enabled, thus we will use `.whenPasscodeSetThisDeviceOnly`
			// BEWARE! If the user deletes the passcode any item protected by this `accessibility` WILL GET DELETED.
			// We use `userPresence` always, disregardong of biometrics being setup up or not,
			// to allow user to be able to fallback to passcode if biometrics.
			return .init(accessibility: .whenPasscodeSetThisDeviceOnly, authenticationPolicy: .userPresence)
		}

		let loadProfileSnapshotData: LoadProfileSnapshotData = {
			try await keychainClient.getDataWithoutAuthForKey(profileSnapshotKeychainKey)
		}

		let deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID = { factorSourceID in
			let key = key(factorSourceID: factorSourceID)
			try await keychainClient.removeDataForKey(key)
		}

		return Self(
			saveProfileSnapshot: { profileSnapshot in
				let data = try jsonEncoder().encode(profileSnapshot)
				try await keychainClient.setDataWithoutAuthForKey(
					KeychainClient.SetItemWithoutAuthRequest(
						data: data,
						key: profileSnapshotKeychainKey,
						iCloudSyncEnabled: profileSnapshot.appPreferences.security.iCloudProfileSyncEnabled,
						accessibility: .whenUnlocked, // do not delete the Profile if passcode gets deleted.
						label: "Radix Wallet Data",
						comment: "Contains your accounts, personas, authorizedDapps, linked connector extensions and wallet app preferences."
					)
				)
			},
			loadProfileSnapshotData: loadProfileSnapshotData,
			saveMnemonicForFactorSource: { privateFactorSource in
				let factorSource = privateFactorSource.hdOnDeviceFactorSource.factorSource
				let mnemonicWithPassphrase = privateFactorSource.mnemonicWithPassphrase
				let data = try jsonEncoder().encode(mnemonicWithPassphrase)
				let mostSecureAccesibilityAndAuthenticationPolicy = try await queryMostSecureAccesibilityAndAuthenticationPolicy()
				let key = key(factorSourceID: factorSource.id)

				try await keychainClient.setDataWithAuthenticationPolicyIfAble(
					data: data,
					key: key,
					iCloudSyncEnabled: false, // We do NOT want to sync this to iCloud, ever.
					accessibility: mostSecureAccesibilityAndAuthenticationPolicy.accessibility,
					authenticationPolicy: mostSecureAccesibilityAndAuthenticationPolicy.authenticationPolicy, // can be nil
					label: "Radix Wallet Factor Secret",
					comment: .init("Factor hint: \(factorSource.hint)")
				)
			},
			loadMnemonicByFactorSourceID: { factorSourceID, purpose in
				let key = key(factorSourceID: factorSourceID)
				let authPromptValue: String = {
					switch purpose {
					case let .createEntity(kind):
						let entityKindName = kind == .account ? L10n.Common.Account.kind : L10n.Common.Persona.kind
						return L10n.Common.BiometricsPrompt.creationOfEntity(entityKindName)
					case .signTransaction: return L10n.Common.BiometricsPrompt.signTransaction
					case .signAuthChallenge: return L10n.Common.BiometricsPrompt.signAuthChallenge
					#if DEBUG
					case .debugOnlyInspect: return "Auth to inspect mnemonic in ProfileView."
					#endif
					}
				}()
				let authPrompt: KeychainClient.AuthenticationPrompt = NonEmptyString(rawValue: authPromptValue).map { KeychainClient.AuthenticationPrompt($0) } ?? "Authenticate to wallet data secret."
				guard let data = try await keychainClient.getDataWithAuthForKey(key, authPrompt) else {
					return nil
				}
				return try jsonDecoder().decode(MnemonicWithPassphrase.self, from: data)
			},
			deleteMnemonicByFactorSourceID: deleteMnemonicByFactorSourceID,
			deleteProfileAndMnemonicsByFactorSourceIDs: {
				#if DEBUG
				try await keychainClient.removeAllItems()
				#else
				guard let profileSnapshotData = try await loadProfileSnapshotData() else {
					return
				}
				try await keychainClient.removeDataForKey(profileSnapshotKeychainKey)
				guard let profileSnapshot = try? jsonDecoder().decode(ProfileSnapshot.self, from: profileSnapshotData) else {
					return
				}
				for factorSourceID in profileSnapshot.factorSources.map(\.id) {
					try await deleteMnemonicByFactorSourceID(factorSourceID)
				}
				#endif
			}
		)
	}()
}

extension SecureStorageClient {
	public func loadProfileSnapshot() async throws -> ProfileSnapshot? {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard
			let existingSnapshotData = try await loadProfileSnapshotData()
		else {
			return nil
		}
		return try jsonDecoder().decode(ProfileSnapshot.self, from: existingSnapshotData)
	}

	public func loadProfile() async throws -> Profile? {
		@Dependency(\.jsonDecoder) var jsonDecoder
		guard
			let existingSnapshot = try await loadProfileSnapshot()
		else {
			return nil
		}
		return try Profile(snapshot: existingSnapshot)
	}
}

private let profileSnapshotKeychainKey: KeychainClient.Key = "profileSnapshotKeychainKey"
private func key(factorSourceID: FactorSource.ID) -> KeychainClient.Key {
	.init(rawValue: .init(rawValue: factorSourceID.hexCodable.hex())!)
}
