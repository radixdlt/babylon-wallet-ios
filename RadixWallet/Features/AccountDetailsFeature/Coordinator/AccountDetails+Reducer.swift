import ComposableArchitecture
import SwiftUI

// MARK: - AccountDetails
struct AccountDetails: Sendable, FeatureReducer {
	struct State: Sendable, Hashable, AccountWithInfoHolder {
		var accountWithInfo: AccountWithInfo
		var assets: AssetsView.State
		var securityProblemsConfig: EntitySecurityProblemsView.Config
		fileprivate var problems: [SecurityProblem] = []
		var showFiatWorth: Bool
		var accountLockerClaims: [AccountLockerClaimDetails] = []

		@PresentationState
		var destination: Destination.State?

		init(
			accountWithInfo: AccountWithInfo,
			showFiatWorth: Bool
		) {
			self.accountWithInfo = accountWithInfo
			self.showFiatWorth = showFiatWorth
			self.assets = AssetsView.State(
				account: accountWithInfo.account,
				mode: .normal
			)
			self.securityProblemsConfig = .init(kind: .account(accountWithInfo.account.address), problems: problems)
		}
	}

	enum ViewAction: Sendable, Equatable {
		case task
		case backButtonTapped
		case preferencesButtonTapped
		case transferButtonTapped
		case historyButtonTapped
		case showFiatWorthToggled
		case securityProblemsTapped
		case accountLockerClaimTapped(AccountLockerClaimDetails)
	}

	@CasePathable
	enum ChildAction: Sendable, Equatable {
		case assets(AssetsView.Action)
	}

	enum DelegateAction: Sendable, Equatable {
		case dismiss
	}

	enum InternalAction: Sendable, Equatable {
		case accountUpdated(Account)
		case setSecurityProblems([SecurityProblem])
		case setAccountLockerClaims([AccountLockerClaimDetails])
	}

	struct Destination: DestinationReducer {
		@CasePathable
		enum State: Sendable, Hashable {
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
		enum Action: Sendable, Equatable {
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

		var body: some Reducer<State, Action> {
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
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.accountLockersClient) var accountLockersClient

	private let accountPortfolioRefreshIntervalInSeconds = 60

	init() {}

	var body: some ReducerOf<Self> {
		Scope(state: \.assets, action: \.child.assets) {
			AssetsView()
		}
		Reduce(core)
			.ifLet(destinationPath, action: /Action.destination) {
				Destination()
			}
	}

	private let destinationPath: WritableKeyPath<State, PresentationState<Destination.State>> = \.$destination

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .task:
			return .run { [state] send in
				for try await accountUpdate in await accountsClient.accountUpdates(state.account.address) {
					guard !Task.isCancelled else { return }

					if accountUpdate.isDeleted {
						await send(.delegate(.dismiss))
					} else {
						await send(.internal(.accountUpdated(accountUpdate)))
					}
				}
			}
			.merge(with: securityProblemsEffect())
			.merge(with: scheduleFetchAccountPortfolioTimer(state.account.address))
			.merge(with: accountLockerClaimsEffect(state: state))

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

		case let .accountLockerClaimTapped(details):
			return .run { _ in
				try await accountLockersClient.claimContent(details)
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountUpdated(account):
			state.account = account
			return .none
		case let .setSecurityProblems(problems):
			state.problems = problems
			state.securityProblemsConfig.update(problems: problems)
			return .none
		case let .setAccountLockerClaims(claims):
			state.accountLockerClaims = claims
			return .none
		}
	}

	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
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
					details: .token(token),
					ledgerState: resource.atLedgerState
				))

			case let .stakeUnit(resource, details):
				guard let xrdRedemptionValue = details.xrdRedemptionValue.exactAmount else {
					fatalError("Not possible")
				}

				state.destination = .stakeUnitDetails(.init(
					validator: details.validator,
					stakeUnitResource: resource,
					xrdRedemptionValue: .exact(.init(
						nominalAmount: xrdRedemptionValue.nominalAmount,
						fiatWorth: resource.amount.exactAmount?.fiatWorth
					))
				))

			case let .stakeClaim(resource, claim):
				state.destination = .stakeClaimDetails(.init(
					resourceAddress: resource.resourceAddress,
					resourceDetails: .success(resource),
					details: .token(claim.token),
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

	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .transfer(.delegate(.dismissed)):
			state.destination = nil
			return .none

		case .preferences(.delegate(.accountHidden)),
		     .preferences(.delegate(.goHomeAfterAccountDeleted)):
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

	private func scheduleFetchAccountPortfolioTimer(_ address: AccountAddress) -> Effect<Action> {
		.run { _ in
			for await _ in clock.timer(interval: .seconds(accountPortfolioRefreshIntervalInSeconds)) {
				guard !Task.isCancelled else { return }
				_ = try? await accountPortfoliosClient.fetchAccountPortfolio(address, true)
				await accountPortfoliosClient.syncAccountsDeletedOnLedger()
			}
		}
	}

	private func accountLockerClaimsEffect(state: State) -> Effect<Action> {
		.run { send in
			for try await claims in await accountLockersClient.accountClaims(state.account.address) {
				guard !Task.isCancelled else { return }
				await send(.internal(.setAccountLockerClaims(claims)))
			}
		}
	}
}
