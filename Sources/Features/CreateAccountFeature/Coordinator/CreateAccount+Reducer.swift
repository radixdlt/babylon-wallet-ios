import ComposableArchitecture
import ErrorQueue
import KeychainClientDependency
import Mnemonic
import Profile
import ProfileClient
import Resources

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

#if DEBUG
import Prelude
extension MnemonicGenerator: TestDependencyKey {
	public static let testValue: Self = .init(generate: unimplemented("\(Self.self).generate"))
}
#endif // DEBUG

public extension DependencyValues {
	var mnemonicGenerator: MnemonicGenerator {
		get { self[MnemonicGenerator.self] }
		set { self[MnemonicGenerator.self] = newValue }
	}
}

// MARK: - CreateAccount
public struct CreateAccount: Sendable, ReducerProtocol {
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.mnemonicGenerator) var mnemonicGenerator
	@Dependency(\.keychainClient) var keychainClient
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(self.core)
			.ifLet(\.accountCompletion, action: /Action.child .. Action.ChildAction.accountCompletion) {
				AccountCompletion()
			}
	}
}

public extension CreateAccount {
	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .child(.accountCompletion(_)):
			return .none

		case .internal(.view(.createAccountButtonTapped)):
			precondition(!state.isCreatingAccount)
			state.focusedField = nil
			state.isCreatingAccount = true

			if state.shouldCreateProfile {
				return .run { send in
					await send(.internal(.system(.createProfile)))
				}
			} else {
				return .run { send in
					await send(.internal(.system(.createAccount)))
				}
			}

		case .internal(.system(.createAccount)):
			return .run { [accountName = state.sanitizedAccountName, overridingNetworkID = state.onNetworkWithID] send in
				await send(.internal(.system(.createdNewAccountResult(
					TaskResult {
						let request = CreateAccountRequest(
							overridingNetworkID: overridingNetworkID, // optional
							keychainAccessFactorSourcesAuthPrompt: L10n.CreateAccount.biometricsPrompt,
							accountName: accountName
						)
						return try await profileClient.createVirtualAccount(
							request
						)
					}
				))))
			}

		case .internal(.system(.createProfile)):
			return .run { [nameOfFirstAccount = state.sanitizedAccountName] send in

				await send(.internal(.system(.createdNewProfileResult(
					// FIXME: - mainnet: extract into ProfileCreator client?
					TaskResult {
						let curve25519FactorSourceMnemonic = try mnemonicGenerator.generate(BIP39.WordCount.twentyFour, BIP39.Language.english)

						let networkAndGateway = AppPreferences.NetworkAndGateway.nebunet

						let newProfileRequest = CreateNewProfileRequest(
							networkAndGateway: networkAndGateway,
							curve25519FactorSourceMnemonic: curve25519FactorSourceMnemonic,
							nameOfFirstAccount: nameOfFirstAccount
						)

						let newProfile = try await profileClient.createNewProfile(
							newProfileRequest
						)

						let curve25519FactorSourceReference = newProfile.factorSources.curve25519OnDeviceStoredMnemonicHierarchicalDeterministicSLIP10FactorSources.first.reference

						try await keychainClient.updateFactorSource(
							mnemonic: curve25519FactorSourceMnemonic,
							reference: curve25519FactorSourceReference
						)

						try await keychainClient.updateProfile(profile: newProfile)

						return newProfile
					}
				))))
			}

		case let .internal(.system(.createdNewProfileResult(.success(profile)))):
			state.isCreatingAccount = false
			return .run { send in
				await send(.delegate(.createdNewProfile(profile)))
			}

		case let .internal(.system(.createdNewProfileResult(.failure(error)))):
			state.isCreatingAccount = false
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.createdNewAccountResult(.success(account)))):
			state.isCreatingAccount = false
			return .run { send in
				await send(.delegate(.createdNewAccount(account)))
			}

		case let .internal(.system(.createdNewAccountResult(.failure(error)))):
			state.isCreatingAccount = false
			errorQueue.schedule(error)
			return .run { send in
				await send(.delegate(.failedToCreateNewAccount))
			}

		case .internal(.view(.closeButtonTapped)):
			return .run { send in
				await send(.delegate(.dismissCreateAccount))
			}

		case let .internal(.view(.textFieldChanged(accountName))):
			state.inputtedAccountName = accountName
			return .none

		case let .internal(.view(.textFieldFocused(focus))):
			return .run { send in
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(focus))))
			}

		case .internal(.view(.viewAppeared)):
			return .run { send in
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(.accountName))))
			}

		case let .internal(.system(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case let .delegate(.displayCreateAccountCompletion(account, isFirstAccount, destination)):
			state.accountCompletion = .init(
				account: account,
				isFirstAccount: isFirstAccount,
				destination: destination
			)
			return .none

		case .delegate:
			return .none
		}
	}
}
