import AccountPortfoliosClient
import AccountsClient
import CreateAuthKeyFeature
import FaucetClient
import FeaturePrelude
import GatewayAPI
import ShowQRFeature

#if DEBUG
// Manifest turning account into Dapp Definition type, debug action...
import TransactionReviewFeature
#endif // DEBUG

// MARK: - AccountPreferences
public struct AccountPreferences: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public let address: AccountAddress
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
			address: AccountAddress,
			faucetButtonState: ControlState = .enabled
		) {
			self.address = address
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
		case faucetButtonTapped

		#if DEBUG
		case turnIntoDappDefinitionAccountTypeButtonTapped
		case createAndUploadAuthKeyButtonTapped
		case createFungibleTokenButtonTapped
		case createNonFungibleTokenButtonTapped
		case createMultipleFungibleTokenButtonTapped
		case createMultipleNonFungibleTokenButtonTapped
		#endif // DEBUG

		case qrCodeButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case isAllowedToUseFaucet(TaskResult<Bool>)
		case callDone(updateControlState: WritableKeyPath<State, ControlState>, changeTo: ControlState = .enabled)
		case refreshAccountCompleted(TaskResult<AccountPortfolio>)
		case hideLoader(updateControlState: WritableKeyPath<State, ControlState>)
		#if DEBUG
		case createAuthKeyWithAccount(Profile.Network.Account)
		case turnIntoDappDefAccountType(TransactionManifest)
		case canCreateAuthSigningKey(Bool)
		case canTurnIntoDappDefAccountType(Bool)
		#endif // DEBUG
	}

	public enum ChildAction: Sendable, Equatable {
		case destination(PresentationAction<Destination.Action>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	// MARK: - Destination

	public struct Destination: ReducerProtocol {
		public enum State: Equatable, Hashable {
			case showQR(ShowQR.State)
			#if DEBUG
			case createAuthKey(CreateAuthKey.State)
			case reviewTransactionTurningAccountIntoDappDefType(TransactionReview.State)
			#endif // DEBUG
		}

		public enum Action: Equatable {
			case showQR(ShowQR.Action)
			#if DEBUG
			case createAuthKey(CreateAuthKey.Action)
			case reviewTransactionTurningAccountIntoDappDefType(TransactionReview.Action)
			#endif // DEBUG
		}

		public var body: some ReducerProtocolOf<Self> {
			Scope(state: /State.showQR, action: /Action.showQR) {
				ShowQR()
			}
			#if DEBUG
			Scope(state: /State.createAuthKey, action: /Action.createAuthKey) {
				CreateAuthKey()
			}
			Scope(state: /State.reviewTransactionTurningAccountIntoDappDefType, action: /Action.reviewTransactionTurningAccountIntoDappDefType) {
				TransactionReview()
			}
			#endif // DEBUG
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.faucetClient) var faucetClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient

	#if DEBUG
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	#endif // DEBUG

	public init() {}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
			.ifLet(\.$destination, action: /Action.child .. ChildAction.destination) {
				Destination()
			}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .appeared:
			return loadIsAllowedToUseFaucet(&state)
			#if DEBUG
				.concatenate(with: loadCanCreateAuthSigningKey(state))
				.concatenate(with: loadCanTurnIntoDappDefAccountType(state))
			#endif

		case .closeButtonTapped:
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case .faucetButtonTapped:
			return call(buttonState: \.faucetButtonState, into: &state) {
				try await faucetClient.getFreeXRD(.init(recipientAccountAddress: $0))
			}
		#if DEBUG
		case .createAndUploadAuthKeyButtonTapped:
			return .run { [accountAddress = state.address] send in
				let account = try await accountsClient.getAccountByAddress(accountAddress)
				await send(.internal(.createAuthKeyWithAccount(account)))
			}

		case .turnIntoDappDefinitionAccountTypeButtonTapped:
			return .run { [accountAddress = state.address] send in
				let account = try await accountsClient.getAccountByAddress(accountAddress)
				let manifest = try TransactionManifest.manifestMarkingAccountAsDappDefinitionType(account: account)
				await send(.internal(.turnIntoDappDefAccountType(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}

		case .createFungibleTokenButtonTapped:
			return call(buttonState: \.createFungibleTokenButtonState, into: &state) {
				try await faucetClient.createFungibleToken(.init(
					recipientAccountAddress: $0
				))
			}

		case .createNonFungibleTokenButtonTapped:
			return call(buttonState: \.createNonFungibleTokenButtonState, into: &state) {
				try await faucetClient.createNonFungibleToken(.init(
					recipientAccountAddress: $0
				))
			}
		case .createMultipleFungibleTokenButtonTapped:
			return call(buttonState: \.createMultipleFungibleTokenButtonState, into: &state) {
				try await faucetClient.createFungibleToken(.init(
					recipientAccountAddress: $0,
					numberOfTokens: 50
				))
			}
		case .createMultipleNonFungibleTokenButtonTapped:
			return call(buttonState: \.createMultipleNonFungibleTokenButtonState, into: &state) {
				try await faucetClient.createNonFungibleToken(.init(
					recipientAccountAddress: $0,
					numberOfTokens: 10,
					numberOfIds: 100
				))
			}
		#endif

		case .qrCodeButtonTapped:
			state.destination = .showQR(.init(accountAddress: state.address))
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		switch childAction {
		case let .destination(.presented(action)):
			switch action {
			#if DEBUG
			case let .createAuthKey(.delegate(.done(wasSuccessful))):
				if case .createAuthKey = state.destination {
					state.destination = nil
				}
				if wasSuccessful {
					state.canCreateAuthSigningKey = false
				}
				return .none

			case .reviewTransactionTurningAccountIntoDappDefType(.delegate(.transactionCompleted)), .reviewTransactionTurningAccountIntoDappDefType(.delegate(.failed)):
				if case .reviewTransactionTurningAccountIntoDappDefType = state.destination {
					state.destination = nil
				}
				state.canTurnIntoDappDefinitionAccountType = false
				return .none
			#endif

			case .showQR(.delegate(.dismiss)):
				if case .showQR = state.destination {
					state.destination = nil
				}
				return .none

			default:
				return .none
			}

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
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
				return updateAccountPortfolio(state).concatenate(with: loadIsAllowedToUseFaucet(&state))
			} else {
				state[keyPath: controlStateKeyPath] = changeTo
				return .none
			}

		#if DEBUG
		case let .createAuthKeyWithAccount(account):
			guard !account.hasAuthenticationSigningKey else {
				return .none
			}
			state.destination = .createAuthKey(.init(entity: .account(account)))
			return .none

		case let .turnIntoDappDefAccountType(manifest):
			state.destination = .reviewTransactionTurningAccountIntoDappDefType(.init(
				transactionManifest: manifest,
				nonce: .secureRandom(),
				signTransactionPurpose: .internalManifest(.debugModifyAccount),
				message: nil
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

	private func call(
		buttonState: WritableKeyPath<State, ControlState>,
		into state: inout State,
		onSuccess: ControlState = .enabled,
		call: @escaping @Sendable (AccountAddress) async throws -> Void
	) -> EffectTask<Action> {
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

extension AccountPreferences {
	private func updateAccountPortfolio(_ state: State) -> EffectTask<Action> {
		.run { [address = state.address] send in
			await send(.internal(.refreshAccountCompleted(
				TaskResult { try await accountPortfoliosClient.fetchAccountPortfolio(address, true) }
			)))
		}
	}

	private func loadIsAllowedToUseFaucet(_ state: inout State) -> EffectTask<Action> {
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
	private func loadCanCreateAuthSigningKey(_ state: State) -> EffectTask<Action> {
		.run { [address = state.address] send in
			let account = try await accountsClient.getAccountByAddress(address)

			await send(.internal(.canCreateAuthSigningKey(!account.hasAuthenticationSigningKey)))
		}
	}

	private func loadCanTurnIntoDappDefAccountType(_ state: State) -> EffectTask<Action> {
		.run { [address = state.address] send in

			do {
				let isDappDefinitionAccount: Bool = try await gatewayAPIClient
					.getEntityMetadata(address.address)
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
		account: Profile.Network.Account
	) throws -> TransactionManifest {
		let raw = """
		SET_METADATA
		            Address("\(account.address.address)")
		            "account_type"
		            Enum<Metadata::String>("dapp definition");
		"""
		return try .init(instructions: .fromString(string: raw, blobs: [], networkId: account.networkID.rawValue), blobs: [])
	}
}
#endif
