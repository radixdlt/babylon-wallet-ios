import ComposableArchitecture
import Sargon
import SwiftUI

// MARK: - DeleteAccountConfirmation
struct DeleteAccountConfirmation: Sendable, FeatureReducer {
	struct State: Sendable, Hashable {
		let account: Account
		var footerButtonState: ControlState = .enabled
	}

	@CasePathable
	enum ViewAction: Sendable, Equatable {
		case continueButtonTapped
	}

	@CasePathable
	enum InternalAction: Sendable, Equatable {
		case fetchAccountPortfolioResult(TaskResult<AccountPortfoliosClient.AccountPortfolio>)
		case fetchReceivingAccounts
		case fetchReceivingAccountsResult(TaskResult<[State.ReceivingAccountCandidate]>)
	}

	@CasePathable
	enum DelegateAction: Sendable, Equatable {
		case chooseReceivingAccount(accounts: [State.ReceivingAccountCandidate], disabledAccounts: [AccountAddress])
		case deleteAccount
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.onLedgerEntitiesClient) var onLedgerEntitiesClient
	@Dependency(\.errorQueue) var errorQueue

	init() {}

	var body: some ReducerOf<Self> {
		Reduce(core)
	}

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .continueButtonTapped:
			state.footerButtonState = .loading(.local)
			return .run { [address = state.account.address] send in
				let result = await TaskResult {
					try await accountPortfoliosClient.fetchAccountPortfolio(address, true)
				}
				await send(.internal(.fetchAccountPortfolioResult(result)))
			}
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .fetchAccountPortfolioResult(.success(portfolio)):
			state.footerButtonState = .enabled
			return portfolio.containsAnyAsset ? .send(.internal(.fetchReceivingAccounts)) : .send(.delegate(.deleteAccount))

		case .fetchReceivingAccounts:
			return .run { send in
				let result = await TaskResult {
					let accounts = try await accountsClient.getAccountsOnCurrentNetwork()
					let entities = try await onLedgerEntitiesClient.getAccounts(accounts.map(\.address), cachingStrategy: .forceUpdate)
					return accounts.compactMap { account -> State.ReceivingAccountCandidate? in
						guard let entity = entities.first(where: { $0.address == account.address }) else {
							assertionFailure("Failed to find account, this should never happen.")
							return nil
						}

						let xrdBalance = entity.fungibleResources.xrdResource?.amount.exactAmount?.nominalAmount ?? 0
						let hasEnoughXRD = xrdBalance >= State.ReceivingAccountCandidate.minimumRequiredXRD

						return .init(account: account, hasEnoughXRD: hasEnoughXRD)
					}
					.sorted { $0.hasEnoughXRD && !$1.hasEnoughXRD }
				}

				await send(.internal(.fetchReceivingAccountsResult(result)))
			}

		case let .fetchReceivingAccountsResult(.success(accounts)):
			return .send(.delegate(.chooseReceivingAccount(
				accounts: accounts,
				disabledAccounts: accounts.filter { !$0.hasEnoughXRD }.map(\.account.address)
			)))

		case let .fetchAccountPortfolioResult(.failure(error)),
		     let .fetchReceivingAccountsResult(.failure(error)):
			state.footerButtonState = .enabled
			errorQueue.schedule(error)
			return .none
		}
	}
}

// MARK: - DeleteAccountConfirmation.State.ReceivingAccountCandidate
extension DeleteAccountConfirmation.State {
	struct ReceivingAccountCandidate: Sendable, Hashable {
		let account: Account
		let hasEnoughXRD: Bool

		static let minimumRequiredXRD: Decimal192 = 4
	}
}
