import Cryptography
import FeaturePrelude
import GatherFactorsFeature
import ProfileClient

// MARK: - CreateAccount
public struct CreateAccount: Sendable, ReducerProtocol {
	@Dependency(\.mainQueue) var mainQueue
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.profileClient) var profileClient

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		EmptyReducer()
			.ifLet(\.gatherFactors, action: /Action.child .. Action.ChildAction.gatherFactors) {
				GatherFactors()
					._printChanges()
			}
		Reduce(self.core)
	}
}

// MARK: Public
public extension CreateAccount {
	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case .internal(.view(.createAccountButtonTapped)):
			guard let factorSources = state.factorSources else {
				assertionFailure("Should not have allowed to tap continue button if factorSources is nil")
				return .none
			}
			assert(!state.isCreatingAccount)
			state.focusedField = nil

			// FIXME: read from profile.
			let accountDerivationPath: AccountHierarchicalDeterministicDerivationPath = try! .init(networkID: .nebunet, index: 1, keyKind: .transactionSigningKey)

			let purpose: GatherFactorPurpose = .derivePublicKey(.createAccount(accountDerivationPath))

			state.gatherFactors = GatherFactors.State(
				purpose: purpose,
				gatherFactors: .init(
					uniqueElements: factorSources.factorSources.map { .init(
						purpose: purpose,
						factorSource: $0
					) }
				)
			)

			if state.shouldCreateProfile {
				return createProfile(state: &state)
			} else {
				return createAccount(state: &state)
			}

		case let .internal(.system(.createdNewAccountResult(.failure(error)))):
			state.gatherFactors = nil
			errorQueue.schedule(error)
			return .none

		case let .internal(.system(.createdNewAccountResult(.success(account)))):
			state.gatherFactors = nil
			return .run { [isFirstAccount = state.isFirstAccount] send in
				await send(.delegate(.createdNewAccount(account: account, isFirstAccount: isFirstAccount)))
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
				await send(.internal(.system(.loadFactorSourcesResult(
					TaskResult {
						try await profileClient.getFactorSources()
					}
				))))
				try await self.mainQueue.sleep(for: .seconds(0.5))
				await send(.internal(.system(.focusTextField(.accountName))))
			}

		case let .internal(.system(.focusTextField(focus))):
			state.focusedField = focus
			return .none

		case let .internal(.system(.loadFactorSourcesResult(.success(factorSources)))):
			state.factorSources = factorSources
			return .none

		case let .internal(.system(.loadFactorSourcesResult(.failure(error)))):
			errorQueue.schedule(error)
			return .none

		case let .child(.gatherFactors(.delegate(.finishedWithResult(result)))):
			loggerGlobal.critical("🔮 \(String(describing: result))")
			return .none

		case .child(.gatherFactors):
			return .none

		case .delegate:
			return .none
		}
	}
}

// MARK: Private
private extension CreateAccount {
	static func networkAndGateway(_ configuredNetworkAndGateway: AppPreferences.NetworkAndGateway?, profileClient: ProfileClient) async -> AppPreferences.NetworkAndGateway {
		if let configuredNetworkAndGateway {
			return configuredNetworkAndGateway
		}

		return await profileClient.getNetworkAndGateway()
	}

	func createAccount(state: inout State) -> EffectTask<Action> {
		/*
		 .run { [accountName = state.sanitizedAccountName, onNetworkWithID = state.onNetworkWithID] send in
		 	await send(.internal(.system(.createdNewAccountResult(
		 		TaskResult {
		 			let request = CreateAccountRequest(
		 				overridingNetworkID: onNetworkWithID, // optional
		 				keychainAccessFactorSourcesAuthPrompt: L10n.CreateAccount.biometricsPrompt,
		 				accountName: accountName
		 			)
		 			let account = try await profileClient.createUnsavedVirtualAccount(request)
		 			try await profileClient.addAccount(account)
		 			return account
		 		}
		 	))))
		 }
		 */
		.none
	}

	func createProfile(state: inout State) -> EffectTask<Action> {
		.run { [nameOfFirstAccount = state.sanitizedAccountName] send in
			await send(.internal(.system(.createdNewAccountResult(
				TaskResult {
					let accountOnCurrentNetwork = try await profileClient.createNewProfile(
						CreateNewProfileRequest(
							nameOfFirstAccount: nameOfFirstAccount
						)
					)
					return accountOnCurrentNetwork
				}
			))))
		}
	}
}
