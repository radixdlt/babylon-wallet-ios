import ClientPrelude
import LocalAuthenticationClient // read LA config to specify max security of new items.
import Profile
import Resources // L10n for auth prompt

// MARK: - Accessibility + Sendable
extension Accessibility: @unchecked Sendable {}

// MARK: - AuthenticationPolicy + Sendable
extension AuthenticationPolicy: @unchecked Sendable {}

// MARK: - SecretStorageClient + DependencyKey
extension SecretStorageClient: DependencyKey {
	public typealias Value = SecretStorageClient

	public static let liveValue: Self = {
		@Dependency(\.keychainClient) var keychainClient
		@Dependency(\.jsonEncoder) var jsonEncoder
		@Dependency(\.jsonDecoder) var jsonDecoder
		@Dependency(\.localAuthenticationClient) var localAuthenticationClient

		struct AccesibilityAndAuthenticationPolicy: Sendable, Equatable {
			/// The most secure currently available accessibility
			let accessibility: Accessibility

			/// The most secure currently available AuthenticationPolicy, if any.
			let authenticationPolicy: AuthenticationPolicy?
		}

		@Sendable func queryMostSecureAccesibilityAndAuthenticationPolicy() async throws -> AccesibilityAndAuthenticationPolicy {
			let config = try await localAuthenticationClient.queryConfig()

			guard config.isPasscodeSetUp else {
				return .init(accessibility: .whenUnlocked, authenticationPolicy: nil)
			}

			// we know that user has `passcode` enabled, thus we will use `.whenPasscodeSetThisDeviceOnly`
			// BEWARE! If the user deletes the passcode any item protected by this `accessibility` WILL GET DELETED.
			let mostSecureAccessibility: Accessibility = .whenPasscodeSetThisDeviceOnly

			guard config.isBiometricsSetUp == true else {
				// We use `userPresence` instead of explictly using `.devicePasscode` to enabled user to "upgrade" to
				// biometrics in the future (`.userPresence` "includes" `.devicePasscode`).
				return .init(accessibility: mostSecureAccessibility, authenticationPolicy: .userPresence)
			}

			// We use `biometryAny` to allow user to delete/update biometry.
			return .init(accessibility: mostSecureAccessibility, authenticationPolicy: .biometryAny)
		}

		let loadProfileSnapshotData: LoadProfileSnapshotData = {
			try await keychainClient.getDataWithoutAuthForKey(profileSnapshotKeychainKey)
		}

		let deleteMnemonicByFactorSourceID: DeleteMnemonicByFactorSourceID = { factorSourceID in
			let key = key(factorSourceID: factorSourceID)
			try await keychainClient.removeDataForKey(key)
		}

		return Self(
			addNewProfileSnapshot: { profileSnapshot in
				let data = try jsonEncoder().encode(profileSnapshot)
				try await keychainClient.addDataWithoutAuthForKey(
					KeychainClient.AddItemWithoutAuthRequest(
						data: data,
						key: profileSnapshotKeychainKey,
						iCloudSyncEnabled: true,
						accessibility: Accessibility.whenUnlocked,
						label: "Radix Wallet Data",
						comment: "Contains your accounts, personas, authorizedDapps, linked connector extensions and wallet app preferences."
					)
				)
			},
			updateProfileSnapshot: { profileSnapshot in
				guard try await loadProfileSnapshotData() != nil else {
					struct NoProfileSnapshotExistsCallAddNewInstead: Swift.Error {}
					throw NoProfileSnapshotExistsCallAddNewInstead()
				}
				let data = try jsonEncoder().encode(profileSnapshot)
				try await keychainClient.updateDataWithoutAuthForKey(data, profileSnapshotKeychainKey)
			},
			loadProfileSnapshotData: loadProfileSnapshotData,
			addNewMnemonicForFactorSource: { privateFactorSource in
				let factorSource = privateFactorSource.factorSource
				let mnemonicWithPassphrase = privateFactorSource.mnemonicWithPassphrase
				let data = try jsonEncoder().encode(mnemonicWithPassphrase)
				let mostSecureAccesibilityAndAuthenticationPolicy = try await queryMostSecureAccesibilityAndAuthenticationPolicy()
				let key = key(factorSourceID: factorSource.id)

				try await keychainClient.addDataWithAuthenticationPolicyIfAble(
					data: data,
					key: key,
					iCloudSyncEnabled: false, // We do NOT want to sync this to iCloud, ever.
					accessibility: mostSecureAccesibilityAndAuthenticationPolicy.accessibility,
					authenticationPolicy: mostSecureAccesibilityAndAuthenticationPolicy.authenticationPolicy, // can be nil
					label: "Radix Wallet Factor Secret",
					comment: .init(factorSource.hint)
				)
			},
			loadMnemonicByFactorSourceID: { factorSourceID, purpose in
				let key = key(factorSourceID: factorSourceID)
				let authPrompt: KeychainClient.AuthenticationPrompt = {
					switch purpose {
					case .deleteSingleMnemonic: fatalError()
					case .deleteProfileAndAllMnemonics: fatalError()
					case .createPersona: fatalError()
					case .createAccount: fatalError()
					case .signTransaction: fatalError()
					case .signAuthChallenge: fatalError()
					}
				}()
				guard let data = try await keychainClient.getDataWithAuthForKey(key, authPrompt) else {
					return nil
				}
				return try jsonDecoder().decode(MnemonicWithPassphrase.self, from: data)
			},
			deleteMnemonicByFactorSourceID: deleteMnemonicByFactorSourceID,
			deleteProfileAndMnemonicsByFactorSourceIDs: {
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
			}
		)
	}()
}

private let profileSnapshotKeychainKey: KeychainClient.Key = "profileSnapshotKeychainKey"
private func key(factorSourceID: FactorSource.ID) -> KeychainClient.Key {
	.init(rawValue: .init(rawValue: factorSourceID.hexCodable.hex())!)
}
