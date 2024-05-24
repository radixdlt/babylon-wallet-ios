import ComposableArchitecture
import SwiftUI

// MARK: - AccountDetails
public struct AccountDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, AccountWithInfoHolder {
		public var accountWithInfo: AccountWithInfo
		var assets: AssetsView.State
		var showFiatWorth: Bool

		@PresentationState
		var destination: Destination.State?

		public init(
			accountWithInfo: AccountWithInfo,
			showFiatWorth: Bool
		) {
			self.accountWithInfo = accountWithInfo
			self.showFiatWorth = showFiatWorth
			self.assets = AssetsView.State(
				account: accountWithInfo.account,
				mode: .normal
			)
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case task
		case backButtonTapped
		case preferencesButtonTapped
		case transferButtonTapped
		case historyButtonTapped

		case exportMnemonicButtonTapped
		case importMnemonicButtonTapped

		case showFiatWorthToggled
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case assets(AssetsView.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
		case exportMnemonic(controlling: Account)
		case importMnemonics
	}

	public enum InternalAction: Sendable, Equatable {
		case accountUpdated(Account)
	}

	public struct MnemonicWithPassphraseAndFactorSourceInfo: Sendable, Hashable {
		public let mnemonicWithPassphrase: MnemonicWithPassphrase
		public let factorSourceKind: FactorSourceKind
	}

	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Sendable, Hashable {
			case preferences(AccountPreferences.State)
			case history(TransactionHistory.State)
			case transfer(AssetTransfer.State)
			case fungibleDetails(FungibleTokenDetails.State)
			case nonFungibleDetails(NonFungibleTokenDetails.State)
			case stakeUnitDetails(LSUDetails.State)
			case stakeClaimDetails(NonFungibleTokenDetails.State)
			case poolUnitDetails(PoolUnitDetails.State)
		}

		@CasePathable
		public enum Action: Sendable, Equatable {
			case preferences(AccountPreferences.Action)
			case history(TransactionHistory.Action)
			case transfer(AssetTransfer.Action)
			case fungibleDetails(FungibleTokenDetails.Action)
			case nonFungibleDetails(NonFungibleTokenDetails.Action)
			case stakeUnitDetails(LSUDetails.Action)
			case stakeClaimDetails(NonFungibleTokenDetails.Action)
			case poolUnitDetails(PoolUnitDetails.Action)
		}

		public var body: some Reducer<State, Action> {
			Scope(state: \.preferences, action: \.preferences) {
				AccountPreferences()
			}
			Scope(state: \.history, action: \.history) {
				TransactionHistory()
			}
			Scope(state: \.transfer, action: \.transfer) {
				AssetTransfer()
			}
			Scope(state: /State.fungibleDetails, action: /Action.fungibleDetails) {
				FungibleTokenDetails()
			}
			Scope(state: /State.nonFungibleDetails, action: /Action.nonFungibleDetails) {
				NonFungibleTokenDetails()
			}
			Scope(state: /State.stakeUnitDetails, action: /Action.stakeUnitDetails) {
				LSUDetails()
			}
			Scope(state: /State.stakeClaimDetails, action: /Action.stakeClaimDetails) {
				NonFungibleTokenDetails()
			}
			Scope(state: /State.poolUnitDetails, action: /Action.poolUnitDetails) {
				PoolUnitDetails()
			}
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.openURL) var openURL
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.dappInteractionClient) var dappInteractionClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.assets, action: /Action.child .. ChildAction.assets) {
			AssetsView()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { [state] send in
				for try await accountUpdate in await accountsClient.accountUpdates(state.account.address) {
					guard !Task.isCancelled else { return }
					await send(.internal(.accountUpdated(accountUpdate)))
				}
			}

		case .backButtonTapped:
			return .send(.delegate(.dismiss))

		case .preferencesButtonTapped:
			state.destination = .preferences(.init(account: state.account))
			return .none

		case .transferButtonTapped:
			state.destination = .transfer(.init(
				from: state.account
			))
			return .none

		case .historyButtonTapped:
			do {
				state.destination = try .history(.init(account: state.account))
			} catch {
				errorQueue.schedule(error)
			}

			return .none

		case .exportMnemonicButtonTapped:
			return .send(.delegate(.exportMnemonic(controlling: state.account)))

		case .importMnemonicButtonTapped:
			return .send(.delegate(.importMnemonics))

		case .showFiatWorthToggled:
			return .run { _ in
				try await appPreferencesClient.toggleIsCurrencyAmountVisible()
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountUpdated(account):
			state.account = account
			checkAccountAccessToMnemonic(state: &state)
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .assets(.internal(.portfolioUpdated)):
			checkAccountAccessToMnemonic(state: &state)
			return .none

		case let .assets(.delegate(.selected(selection))):
			switch selection {
			case let .fungible(resource, isXrd):
				state.destination = .fungibleDetails(.init(
					resourceAddress: resource.resourceAddress,
					ownedFungibleResource: resource,
					isXRD: isXrd
				))

			case let .nonFungible(resource, token):
				state.destination = .nonFungibleDetails(.init(
					resourceAddress: resource.resourceAddress,
					ownedResource: resource,
					token: token,
					ledgerState: resource.atLedgerState
				))

			case let .stakeUnit(resource, details):
				state.destination = .stakeUnitDetails(.init(
					validator: details.validator,
					stakeUnitResource: resource,
					xrdRedemptionValue: .init(
						nominalAmount: details.xrdRedemptionValue,
						fiatWorth: resource.amount.fiatWorth
					)
				))

			case let .stakeClaim(resource, claim):
				state.destination = .stakeClaimDetails(.init(
					resourceAddress: resource.resourceAddress,
					resourceDetails: .success(resource),
					token: claim.token,
					ledgerState: resource.atLedgerState,
					stakeClaim: claim
				))

			case let .poolUnit(details):
				state.destination = .poolUnitDetails(.init(resourcesDetails: details))
			}
			return .none

		default:
			return .none
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .transfer(.delegate(.dismissed)):
			state.destination = nil
			return .none

		case .preferences(.delegate(.accountHidden)):
			return .send(.delegate(.dismiss))

		case let .stakeClaimDetails(.delegate(.tappedClaimStake(stakeClaim))):
			state.destination = nil
			return sendStakeClaimTransaction(state.account.address, stakeClaims: [stakeClaim.intoSargon()])

		default:
			return .none
		}
	}

	private func checkAccountAccessToMnemonic(state: inout State) {
		let xrdResource = state.assets.resources.fungibleTokenList?.sections[id: .xrd]?.rows.first?.token
		state.checkAccountAccessToMnemonic(xrdResource: xrdResource)
	}

	private func sendStakeClaimTransaction(
		_ acccountAddress: AccountAddress,
		stakeClaims: [StakeClaim]
	) -> Effect<Action> {
		.run { _ in
			let manifest = TransactionManifest.stakesClaim(
				accountAddress: acccountAddress,
				stakeClaims: stakeClaims
			)
			_ = await dappInteractionClient.addWalletInteraction(
				.transaction(.init(send: .init(transactionManifest: manifest))),
				.accountTransfer
			)
		}
	}
}
