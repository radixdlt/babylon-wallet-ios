import ComposableArchitecture
import SwiftUI

// MARK: - AccountPreferences
public struct AccountPreferences: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var account: Profile.Network.Account
		public var faucetButtonState: ControlState
		public var address: AccountAddress { account.address }
		public var isOnMainnet: Bool { account.networkID == .mainnet }

		@PresentationState
		var destination: Destination.State? = nil

		public init(
			account: Profile.Network.Account,
			faucetButtonState: ControlState = .enabled
		) {
			self.account = account
			self.faucetButtonState = faucetButtonState
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case task
		case qrCodeButtonTapped
		case rowTapped(AccountPreferences.Section.SectionRow)
		case hideAccountTapped
		case faucetButtonTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case accountUpdated(Profile.Network.Account)
		case isAllowedToUseFaucet(TaskResult<Bool>)
		case callDone(updateControlState: WritableKeyPath<State, ControlState>, changeTo: ControlState = .enabled)
		case refreshAccountCompleted(TaskResult<OnLedgerEntity.Account>)
		case hideLoader(updateControlState: WritableKeyPath<State, ControlState>)
	}

	public enum DelegateAction: Sendable, Equatable {
		case accountHidden
	}

	// MARK: - Destination
	public struct Destination: DestinationReducer {
		@CasePathable
		public enum State: Hashable, Sendable {
			case showQR(ShowQR.State)
			case updateAccountLabel(UpdateAccountLabel.State)
			case thirdPartyDeposits(ManageThirdPartyDeposits.State)
			case devPreferences(DevAccountPreferences.State)
			case confirmHideAccount(AlertState<Action.ConfirmHideAccountAlert>)
		}

		@CasePathable
		public enum Action: Equatable, Sendable {
			case showQR(ShowQR.Action)
			case updateAccountLabel(UpdateAccountLabel.Action)
			case thirdPartyDeposits(ManageThirdPartyDeposits.Action)
			case devPreferences(DevAccountPreferences.Action)
			case confirmHideAccount(ConfirmHideAccountAlert)

			public enum ConfirmHideAccountAlert: Hashable, Sendable {
				case confirmTapped
				case cancelTapped
			}
		}

		public var body: some ReducerOf<Self> {
			Scope(state: /State.showQR, action: /Action.showQR) {
				ShowQR()
			}
			Scope(state: /State.updateAccountLabel, action: /Action.updateAccountLabel) {
				UpdateAccountLabel()
			}
			Scope(state: /State.thirdPartyDeposits, action: /Action.thirdPartyDeposits) {
				ManageThirdPartyDeposits()
			}
			Scope(state: /State.devPreferences, action: /Action.devPreferences) {
				DevAccountPreferences()
			}
		}
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.entitiesVisibilityClient) var entitiesVisibilityClient
	@Dependency(\.overlayWindowClient) var overlayWindowClient
	@Dependency(\.faucetClient) var faucetClient
	@Dependency(\.accountPortfoliosClient) var accountPortfoliosClient
	@Dependency(\.gatewaysClient) var gatewaysClient
	@Dependency(\.errorQueue) var errorQueue

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
		case .task:
			return .run { [address = state.account.address] send in
				for try await accountUpdate in await accountsClient.accountUpdates(address) {
					guard !Task.isCancelled else { return }
					await send(.internal(.accountUpdated(accountUpdate)))
				}
			}
			.merge(with: state.isOnMainnet ? .none : loadIsAllowedToUseFaucet(&state))

		case .qrCodeButtonTapped:
			state.destination = .showQR(.init(accountAddress: state.account.address))
			return .none

		case let .rowTapped(row):
			return destination(for: row, &state)

		case .hideAccountTapped:
			state.destination = .confirmHideAccount(.init(
				title: .init(L10n.AccountSettings.hideThisAccount),
				message: .init(L10n.AccountSettings.hideAccountConfirmation),
				buttons: [
					.default(.init(L10n.Common.continue), action: .send(.confirmTapped)),
					.cancel(.init(L10n.Common.cancel), action: .send(.cancelTapped)),
				]
			))
			return .none

		case .faucetButtonTapped:
			return call(buttonState: \.faucetButtonState, into: &state) {
				try await faucetClient.getFreeXRD(.init(recipientAccountAddress: $0))
			}
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountUpdated(updated):
			state.account = updated
			return .none

		case let .isAllowedToUseFaucet(.success(value)):
			state.faucetButtonState = value ? .enabled : .disabled
			return .none

		case let .isAllowedToUseFaucet(.failure(error)):
			state.faucetButtonState = .disabled
			errorQueue.schedule(error)
			return .none

		case let .hideLoader(controlStateKeyPath):
			state[keyPath: controlStateKeyPath] = .enabled
			return .none

		case .refreshAccountCompleted:
			state.faucetButtonState = .disabled
			return .none

		case let .callDone(controlStateKeyPath, changeTo):
			if controlStateKeyPath == \State.faucetButtonState {
				// NB: This call to update might be superfluous, since after any transaction we fetch all accounts
				return updateAccountPortfolio(state).concatenate(with: loadIsAllowedToUseFaucet(&state))
			} else {
				state[keyPath: controlStateKeyPath] = changeTo
				return .none
			}
		}
	}

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		switch presentedAction {
		case .showQR(.delegate(.dismiss)):
			if case .showQR = state.destination {
				state.destination = nil
			}
			return .none
		case .showQR:
			return .none
		case .updateAccountLabel(.delegate(.accountLabelUpdated)),
		     .thirdPartyDeposits(.delegate(.accountUpdated)):
			state.destination = nil
			return .none
		case .updateAccountLabel:
			return .none
		case .thirdPartyDeposits:
			return .none
		#if DEBUG
		case .devPreferences(DevAccountPreferences.Action.delegate(.debugOnlyAccountWasDeleted)):
			return .send(.delegate(.accountHidden))
		#endif
		case .devPreferences:
			return .none
		case let .confirmHideAccount(action):
			switch action {
			case .confirmTapped:
				return .run { [account = state.account] send in
					try await entitiesVisibilityClient.hide(account: account)
					overlayWindowClient.scheduleHUD(.accountHidden)
					await send(.delegate(.accountHidden))
				} catch: { error, _ in
					errorQueue.schedule(error)
				}
			case .cancelTapped:
				break
			}
			return .none
		}
	}
}

extension AccountPreferences {
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

	private func updateAccountPortfolio(_ state: State) -> Effect<Action> {
		.run { [address = state.address] send in
			await send(.internal(.refreshAccountCompleted(
				TaskResult { try await accountPortfoliosClient.fetchAccountPortfolio(address, true).account }
			)))
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
}

extension OverlayWindowClient.Item.HUD {
	static let accountHidden = Self(text: L10n.AccountSettings.accountHidden)
}

extension AccountPreferences {
	func destination(for row: AccountPreferences.Section.SectionRow, _ state: inout State) -> Effect<Action> {
		switch row {
		case .personalize(.accountLabel):
			state.destination = .updateAccountLabel(.init(account: state.account))
			return .none

		case .personalize(.accountColor):
			return .none

		case .personalize(.tags):
			return .none

		case .onLedger(.thirdPartyDeposits):
			state.destination = .thirdPartyDeposits(.init(account: state.account))
			return .none

		case .onLedger(.accountSecurity):
			return .none

		case .dev(.devPreferences):
			state.destination = .devPreferences(.init(account: state.account))
			return .none
		}
	}
}
