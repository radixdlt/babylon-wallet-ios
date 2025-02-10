import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - DevAccountPreferences
struct DevAccountPreferences: Sendable, FeatureReducer {
	// MARK: - State

	struct State: Sendable, Hashable {
		let account: Account
		var address: AccountAddress { account.address }

		@PresentationState
		var destination: Destination.State? = nil

		#if DEBUG
		var canCreateAuthSigningKey: Bool
		var canTurnIntoDappDefinitionAccountType: Bool
		var createFungibleTokenButtonState: ControlState
		var createNonFungibleTokenButtonState: ControlState
		var createMultipleFungibleTokenButtonState: ControlState
		var createMultipleNonFungibleTokenButtonState: ControlState
		#endif

		init(account: Account) {
			self.account = account

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

	enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case closeTransactionButtonTapped

		#if DEBUG
		case turnIntoDappDefinitionAccountTypeButtonTapped
		case createFungibleTokenButtonTapped
		case createNonFungibleTokenButtonTapped
		case createMultipleFungibleTokenButtonTapped
		case createMultipleNonFungibleTokenButtonTapped
		#endif // DEBUG
	}

	enum InternalAction: Sendable, Equatable {
		#if DEBUG
		case reviewTransaction(TransactionManifest)
		case canCreateAuthSigningKey(Bool)
		case canTurnIntoDappDefAccountType(Bool)
		#endif // DEBUG
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	// MARK: - Destination

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Hashable, Sendable {
			#if DEBUG
			case reviewTransaction(TransactionReview.State)
			#endif // DEBUG
		}

		@CasePathable
		enum Action: Equatable, Sendable {
			#if DEBUG
			case reviewTransaction(TransactionReview.Action)
			#endif // DEBUG
		}

		var body: some ReducerOf<Self> {
			#if DEBUG
			Scope(state: /State.reviewTransaction, action: /Action.reviewTransaction) {
				TransactionReview()
			}
			#endif // DEBUG
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue

	#if DEBUG
	@Dependency(\.gatewayAPIClient) var gatewayAPIClient
	#endif // DEBUG

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .appeared:
			return .none

		case .closeButtonTapped:
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case .closeTransactionButtonTapped:
			state.destination = nil
			return .none

		#if DEBUG
		case .turnIntoDappDefinitionAccountTypeButtonTapped:
			return .run { [accountAddress = state.address] send in

				let manifest = TransactionManifest.markingAccountAsDappDefinitionType(
					accountAddress: accountAddress
				)

				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}

		case .createFungibleTokenButtonTapped:
			return .run { [accountAddress = state.address] send in

				let manifest = TransactionManifest.createFungibleToken(
					addressOfOwner: accountAddress
				)

				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}

		case .createNonFungibleTokenButtonTapped:
			return .run { [accountAddress = state.address] send in

				let manifest = TransactionManifest.createNonFungibleToken(
					addressOfOwner: accountAddress,
					nftsPerCollection: 10
				)

				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}
		case .createMultipleFungibleTokenButtonTapped:
			return .run { [accountAddress = state.address] send in

				let manifest = TransactionManifest.createMultipleFungibleTokens(
					addressOfOwner: accountAddress,
					count: 10
				)

				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}
		case .createMultipleNonFungibleTokenButtonTapped:
			return .run { [accountAddress = state.address] send in

				let manifest = TransactionManifest.createMultipleNonFungibleTokens(
					addressOfOwner: accountAddress,
					collectionCount: 1,
					nftsPerCollection: 120
				)

				await send(.internal(.reviewTransaction(manifest)))
			} catch: { error, _ in
				loggerGlobal.warning("Failed to create manifest which turns account into dapp definition account type, error: \(error)")
			}

		#endif
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		#if DEBUG
		switch internalAction {
		case let .reviewTransaction(manifest):
			state.destination = .reviewTransaction(.init(
				unvalidatedManifest: try! .init(manifest: manifest),
				nonce: .secureRandom(),
				signTransactionPurpose: .internalManifest(.debugModifyAccount),
				message: .none,
				interactionId: .walletInteractionID(for: .accountTransfer),
				proposingDappMetadata: nil,
				p2pRoute: .wallet
			))
			return .none

		case let .canCreateAuthSigningKey(canCreateAuthSigningKey):
			state.canCreateAuthSigningKey = canCreateAuthSigningKey
			return .none

		case let .canTurnIntoDappDefAccountType(canTurnIntoDappDefAccountType):
			state.canTurnIntoDappDefinitionAccountType = canTurnIntoDappDefAccountType
			return .none
		}
		#endif
	}

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
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
}

extension DevAccountPreferences {
	#if DEBUG
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
