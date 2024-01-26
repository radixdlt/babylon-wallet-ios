import ComposableArchitecture
import SwiftUI

// MARK: - DevAccountPreferences
public struct DevAccountPreferences: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public var isOnMainnet: Bool
		public let account: Profile.Network.Account
		public var address: AccountAddress { account.address }
		public var faucetButtonState: ControlState

		@PresentationState
		var destination: Destination.State? = nil

		#if DEBUG
		public var canCreateAuthSigningKey: Bool
		public var canTurnIntoDappDefinitionAccountType: Bool
		public var createFungibleTokenButtonState: ControlState
		public var createNonFungibleTokenButtonState: ControlState
		public var createMultipleFungibleTokenButtonState: ControlState
		public var createMultipleNonFungibleTokenButtonState: ControlState
		#endif

		public init(
			isOnMainnet: Bool = true, // safest to default to true and change to false, we REALLY do not wanna display the faucet button for mainnet
			account: Profile.Network.Account,
			faucetButtonState: ControlState = .enabled
		) {
			self.isOnMainnet = isOnMainnet
			self.account = account
			self.faucetButtonState = faucetButtonState

			#if DEBUG
			self.canCreateAuthSigningKey = false
			self.canTurnIntoDappDefinitionAccountType = false
			self.createFungibleTokenButtonState = .enabled
			self.createNonFungibleTokenButtonState = .enabled
			self.createMultipleFungibleTokenButtonState = .enabled
			self.createMultipleNonFungibleTokenButtonState = .enabled
			#endif
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case closeTransactionButtonTapped
		case faucetButtonTapped

		#if DEBUG
		case turnIntoDappDefinitionAccountTypeButtonTapped
		case createFungibleTokenButtonTapped
		case createNonFungibleTokenButtonTapped
		case createMultipleFungibleTokenButtonTapped
		case createMultipleNonFungibleTokenButtonTapped
		case deleteAccountButtonTapped
		#endif // DEBUG
	}

	public enum InternalAction: Sendable, Equatable {
		case currentNetwork(Radix.Network)
		case isAllowedToUseFaucet(TaskResult<Bool>)
		case callDone(updateControlState: WritableKeyPath<State, ControlState>, changeTo: ControlState = .enabled)
		case refreshAccountCompleted(TaskResult<OnLedgerEntity.Account>)
		case hideLoader(updateControlState: WritableKeyPath<State, ControlState>)
		#if DEBUG
		case reviewTransaction(TransactionManifest)
		case canCreateAuthSigningKey(Bool)
		case canTurnIntoDappDefAccountType(Bool)
		#endif // DEBUG
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		#if DEBUG
		case debugOnlyAccountWasDeleted
		#endif
	}

	// MARK: - Destination

	public struct Destination: DestinationReducer {
		public enum State: Hashable, Sendable {
			#if DEBUG
			case reviewTransaction(TransactionReview.State)
			#endif // DEBUG
		}

		public enum Action: Equatable, Sendable {
			#if DEBUG
			case reviewTransaction(TransactionReview.Action)
			#endif // DEBUG
		}

		public var body: some ReducerOf<Self> {
			#if DEBUG
			Scope(state: /State.reviewTransaction, action: /Action.reviewTransaction) {
				TransactionReview()
			}
			#endif // DEBUG
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.faucetClient) var faucetClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.gatewaysClient) var gatewaysClient

	#if DEBUG
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	#endif // DEBUG

	public init() {}

	public var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return loadCurrentNetwork()
				.concatenate(with: loadIsAllowedToUseFaucet(&state))
			#if DEBUG
				.concatenate(with: loadCanCreateAuthSigningKey(state))
				.concatenate(with: loadCanTurnIntoDappDefAccountType(state))
			#endif

		case .closeButtonTapped:
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case .closeTransactionButtonTapped:
			state.destination = nil
			return .none

		case .faucetButtonTapped:
			return call(buttonState: \.faucetButtonState, into: &state) {
				try await faucetClient.getFreeXRD(.init(recipientAccountAddress: $0))
			}
		#if DEBUG
		case .deleteAccountButtonTapped:
			return .run { [account = state.account] send in
				try await accountsClient.debugOnlyDeleteAccount(account)
				await send(.delegate(.debugOnlyAccountWasDeleted))
			}
		case .turnIntoDappDefinitionAccountTypeButtonTapped:
			return .run { [accountAddress = state.address] send in
				let accountAddress = try await accountsClient.getAccountByAddress(accountAddress)
				let manifest = try TransactionManifest.manifestMarkingAccountAsDappDefinitionType(accountAddress: accountAddress)
				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}

		case .createFungibleTokenButtonTapped:
			return .run { [accountAddress = state.address] send in
				let accountAddress = try await accountsClient.getAccountByAddress(accountAddress)
				let manifest = try ManifestBuilder.manifestForCreateFungibleToken(account: accountAddress.address, networkID: accountAddress.networkID)
				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}

		case .createNonFungibleTokenButtonTapped:
			return .run { [accountAddress = state.address] send in
				let accountAddress = try await accountsClient.getAccountByAddress(accountAddress)
				let manifest = try ManifestBuilder.manifestForCreateNonFungibleToken(account: accountAddress.address, networkID: accountAddress.networkID)
				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}
		case .createMultipleFungibleTokenButtonTapped:
			return .run { [accountAddress = state.address] send in
				let accountAddress = try await accountsClient.getAccountByAddress(accountAddress)
				let manifest = try ManifestBuilder.manifestForCreateMultipleFungibleTokens(account: accountAddress.address, networkID: accountAddress.networkID)
				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}
		case .createMultipleNonFungibleTokenButtonTapped:
			return .run { [accountAddress = state.address] send in
				let accountAddress = try await accountsClient.getAccountByAddress(accountAddress)
				let manifest = try ManifestBuilder.manifestForCreateMultipleNonFungibleTokens(account: accountAddress.address, networkID: accountAddress.networkID)
				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}
		#endif
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .currentNetwork(currentNetwork):
			state.isOnMainnet = currentNetwork == .mainnet
			return .none

		case let .isAllowedToUseFaucet(.success(value)):
			state.faucetButtonState = value ? .enabled : .disabled
			return .none

		case let .isAllowedToUseFaucet(.failure(error)):
			state.faucetButtonState = .disabled
			errorQueue.schedule(error)
			return .none

		case .refreshAccountCompleted:
			state.faucetButtonState = .disabled
			return .none

		case let .hideLoader(controlStateKeyPath):
			state[keyPath: controlStateKeyPath] = .enabled
			return .none

		case let .callDone(controlStateKeyPath, changeTo):
			if controlStateKeyPath == \State.faucetButtonState {
				// NB: This call to update might be superfluous, since after any transaction we fetch all accounts
				return updateAccountPortfolio(state).concatenate(with: loadIsAllowedToUseFaucet(&state))
			} else {
				state[keyPath: controlStateKeyPath] = changeTo
				return .none
			}

		#if DEBUG
		case let .reviewTransaction(manifest):
			state.destination = .reviewTransaction(.init(
				unvalidatedManifest: try! .init(manifest: manifest),
				nonce: .secureRandom(),
				signTransactionPurpose: .internalManifest(.debugModifyAccount),
				message: .none,
				isWalletTransaction: true,
				proposingDappMetadata: nil
			))
			return .none

		case let .canCreateAuthSigningKey(canCreateAuthSigningKey):
			state.canCreateAuthSigningKey = canCreateAuthSigningKey
			return .none
		case let .canTurnIntoDappDefAccountType(canTurnIntoDappDefAccountType):
			state.canTurnIntoDappDefinitionAccountType = canTurnIntoDappDefAccountType
			return .none
		#endif
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		#if DEBUG
		switch presentedAction {
		case .reviewTransaction(.delegate(.transactionCompleted)), .reviewTransaction(.delegate(.failed)):
			if case .reviewTransaction = state.destination {
				state.destination = nil
			}
			return .none

		default:
			return .none
		}
		#endif
	}

	private func call(
		buttonState: WritableKeyPath<State, ControlState>,
		into state: inout State,
		onSuccess: ControlState = .enabled,
		call: @escaping @Sendable (AccountAddress) async throws -> Void
	) -> Effect<Action> {
		state[keyPath: buttonState] = .loading(.local)
		return .run { [address = state.address] send in
			try await call(address)
			await send(.internal(.callDone(updateControlState: buttonState, changeTo: onSuccess)))
		} catch: { error, send in
			await send(.internal(.hideLoader(updateControlState: buttonState)))
			if !Task.isCancelled {
				errorQueue.schedule(error)
			}
		}
	}
}

extension DevAccountPreferences {
	private func updateAccountPortfolio(_ state: State) -> Effect<Action> {
		.run { [address = state.address] send in
			await send(.internal(.refreshAccountCompleted(
				TaskResult { try await accountPortfoliosClient.fetchAccountPortfolio(address, true) }
			)))
		}
	}

	private func loadCurrentNetwork() -> Effect<Action> {
		.run { send in
			let currentGateway = await gatewaysClient.getCurrentGateway()
			await send(.internal(.currentNetwork(currentGateway.network)))
		}
	}

	private func loadIsAllowedToUseFaucet(_ state: inout State) -> Effect<Action> {
		state.faucetButtonState = .loading(.local)
		return .run { [address = state.address] send in
			await send(.internal(.isAllowedToUseFaucet(
				TaskResult {
					await faucetClient.isAllowedToUseFaucet(address)
				}
			)))
		}
	}

	#if DEBUG
	private func loadCanCreateAuthSigningKey(_ state: State) -> Effect<Action> {
		.run { [address = state.address] send in
			let accountAddress = try await accountsClient.getAccountByAddress(address)

			await send(.internal(.canCreateAuthSigningKey(!accountAddress.hasAuthenticationSigningKey)))
		}
	}

	private func loadCanTurnIntoDappDefAccountType(_ state: State) -> Effect<Action> {
		.run { [address = state.address] send in

			do {
				let isDappDefinitionAccount: Bool = try await gatewayAPIClient
					.getEntityMetadata(address.address, [.accountType])
					.accountType == .dappDefinition

				await send(.internal(.canTurnIntoDappDefAccountType(!isDappDefinitionAccount)))
			} catch {}
		}
	}
	#endif
}

#if DEBUG
extension TransactionManifest {
	fileprivate static func manifestMarkingAccountAsDappDefinitionType(
		accountAddress: Profile.Network.Account
	) throws -> TransactionManifest {
		try ManifestBuilder()
			.setAccountType(from: accountAddress.address.asGeneral, type: "dapp definition")
			.build(networkId: accountAddress.networkID.rawValue)
	}
}
#endif
