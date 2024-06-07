import ComposableArchitecture
import SwiftUI

// MARK: - AccountDetails
public struct AccountDetails: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, AccountWithInfoHolder {
		public var accountWithInfo: AccountWithInfo
		var assets: AssetsView.State
		var problems: [SecurityProblem] = []
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
		case showFiatWorthToggled
		case securityProblemsTapped
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case assets(AssetsView.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	public enum InternalAction: Sendable, Equatable {
		case accountUpdated(Account)
		case setSecurityProblems([SecurityProblem])
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
			case securityCenter(SecurityCenter.State)
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
			case securityCenter(SecurityCenter.Action)
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
			Scope(state: \.fungibleDetails, action: \.fungibleDetails) {
				FungibleTokenDetails()
			}
			Scope(state: \.nonFungibleDetails, action: \.nonFungibleDetails) {
				NonFungibleTokenDetails()
			}
			Scope(state: \.stakeUnitDetails, action: \.stakeUnitDetails) {
				LSUDetails()
			}
			Scope(state: \.stakeClaimDetails, action: \.stakeClaimDetails) {
				NonFungibleTokenDetails()
			}
			Scope(state: \.poolUnitDetails, action: \.poolUnitDetails) {
				PoolUnitDetails()
			}
			Scope(state: \.securityCenter, action: \.securityCenter) {
				SecurityCenter()
			}
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.continuousClock) var clock
	@Dependency(\.openURL) var openURL
	@Dependency(\.appPreferencesClient) var appPreferencesClient
	@Dependency(\.dappInteractionClient) var dappInteractionClient
	@Dependency(\.securityCenterClient) var securityCenterClient

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.assets, action: \.child.assets) {
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
			.merge(with: securityProblemsEffect())

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

		case .showFiatWorthToggled:
			return .run { _ in
				try await appPreferencesClient.toggleIsCurrencyAmountVisible()
			}

		case .securityProblemsTapped:
			state.destination = .securityCenter(.init())
			return .none
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountUpdated(account):
			state.account = account
			return .none
		case let .setSecurityProblems(problems):
			state.problems = problems
			return .none
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
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

	private func securityProblemsEffect() -> Effect<Action> {
		.run { send in
			for try await problems in await securityCenterClient.problems() {
				guard !Task.isCancelled else { return }
				await send(.internal(.setSecurityProblems(problems)))
			}
		}
	}
}
