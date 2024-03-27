import ComposableArchitecture
import SwiftUI

// MARK: - DevAccountPreferences
public struct DevAccountPreferences: Sendable, FeatureReducer {
	// MARK: - State

	public struct State: Sendable, Hashable {
		public let account: Profile.Network.Account
		public var address: AccountAddress { account.address }

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

		public init(account: Profile.Network.Account) {
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

	public enum ViewAction: Sendable, Equatable {
		case appeared
		case closeButtonTapped
		case closeTransactionButtonTapped

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
		@CasePathable
		public enum State: Hashable, Sendable {
			#if DEBUG
			case reviewTransaction(TransactionReview.State)
			#endif // DEBUG
		}

		@CasePathable
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
	@Dependency(\.errorQueue) var errorQueue

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
			#if DEBUG
			return loadCanCreateAuthSigningKey(state)
				.concatenate(with: loadCanTurnIntoDappDefAccountType(state))
			#else
			return .none
			#endif

		case .closeButtonTapped:
			return .run { send in
				await send(.delegate(.dismiss))
			}

		case .closeTransactionButtonTapped:
			state.destination = nil
			return .none

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
		#if DEBUG
		switch internalAction {
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
		}
		#endif
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
}

extension DevAccountPreferences {
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
