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
		case cancelButtonTapped
	}

	@CasePathable
	enum InternalAction: Sendable, Equatable {
		case fetchAccountPortfolioResult(TaskResult<OnLedgerEntity.OnLedgerAccount>)
	}

	@CasePathable
	enum DelegateAction: Sendable, Equatable {
		case canceled
		case chooseRecipientAccount
		case deleteAccount
	}

	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
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
					try await accountPortfoliosClient.fetchAccountPortfolio(address, true).account
				}
				await send(.internal(.fetchAccountPortfolioResult(result)))
			}
		case .cancelButtonTapped:
			return .send(.delegate(.canceled))
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .fetchAccountPortfolioResult(.success(account)):
			state.footerButtonState = .enabled
			return .send(.delegate(account.containsAnyAsset ? .chooseRecipientAccount : .deleteAccount))

		case let .fetchAccountPortfolioResult(.failure(error)):
			state.footerButtonState = .enabled
			errorQueue.schedule(error)
			return .none
		}
	}
}
