import ComposableArchitecture
import ErrorQueue
import KeychainClient
import Mnemonic
import Profile
import ProfileClient
import TransactionClient

// MARK: - MnemonicGenerator
public struct MnemonicGenerator: Sendable, DependencyKey {
	public var generate: Generate
}

// MARK: MnemonicGenerator.Generate
public extension MnemonicGenerator {
	typealias Generate = @Sendable (BIP39.WordCount, BIP39.Language) throws -> Mnemonic
}

// = @Sendable (BIP39.WordCount, BIP39.Language) throws -> Mnemonic

// MARK: - MnemonicGeneratorKey
public extension MnemonicGenerator {
	static let liveValue: Self = .init(generate: { try Mnemonic(wordCount: $0, language: $1) })
}

public extension DependencyValues {
	var mnemonicGenerator: MnemonicGenerator {
		get { self[MnemonicGenerator.self] }
		set { self[MnemonicGenerator.self] = newValue }
	}
}

// MARK: - NewProfile
public struct NewProfile: ReducerProtocol {
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicGenerator) var mnemonicGenerator
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient
	@Dependency(\.transactionClient) var transactionClient
}

public extension NewProfile {
	func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.backButtonPressed)):
			return .run { send in
				await send(.delegate(.goBack))
			}

		case .internal(.view(.createProfileButtonPressed)):
			return .run { send in
				await send(.internal(.system(.createProfile)))
			}

		case .internal(.system(.createProfile)):
			precondition(state.canProceed)
			precondition(!state.isCreatingProfile)
			state.isCreatingProfile = true
			return .run { [mnemonicGenerator, transactionClient, nameOfFirstAccount = state.nameOfFirstAccount] send in

				await send(.internal(.system(.createdProfileResult(
					// FIXME: - mainnet: extract into ProfileCreator client?
					TaskResult {
						let curve25519FactorSourceMnemonic = try mnemonicGenerator.generate(BIP39.WordCount.twentyFour, BIP39.Language.english)

						// FIXME: betanet: stop using `.primary` use explicit version!
						let networkAndGateway = AppPreferences.NetworkAndGateway.primary

						let newProfileRequest = CreateNewProfileRequest(
							networkAndGateway: networkAndGateway,
							curve25519FactorSourceMnemonic: curve25519FactorSourceMnemonic,
							nameOfFirstAccount: nameOfFirstAccount
						) {
							try await transactionClient.makeAccountNonVirtual(networkAndGateway.network.id)
						}

						let newProfile = try await profileClient.createNewProfileWithOnLedgerAccount(
							newProfileRequest
						)

						let curve25519FactorSourceReference = newProfile.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first.reference

						try keychainClient.setFactorSource(
							mnemonic: curve25519FactorSourceMnemonic,
							reference: curve25519FactorSourceReference
						)

						try keychainClient.setProfile(profile: newProfile)

						return newProfile
					}
				))))
			}

		case let .internal(.system(.createdProfileResult(.success(profile)))):
			state.isCreatingProfile = false
			return .run { send in
				await send(.delegate(.finishedCreatingNewProfile(profile)))
			}

		case let .internal(.system(.createdProfileResult(.failure(error)))):
			state.isCreatingProfile = false
			errorQueue.schedule(error)
			return .none

		case let .internal(.view(.accountNameTextFieldChanged(accountName))):
			state.nameOfFirstAccount = accountName
			state.canProceed = !state.nameOfFirstAccount.isEmpty
			return .none

		case .delegate:
			return .none
		}
	}
}
