import ComposableArchitecture
import SwiftUI

// MARK: - AccountPreferences
public struct AccountPreferences: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable {
		public var account: Profile.Network.Account

		@PresentationState
		var destination: Destination.State? = nil

		public init(account: Profile.Network.Account) {
			self.account = account
		}
	}

	// MARK: - Action

	public enum ViewAction: Sendable, Equatable {
		case task
		case qrCodeButtonTapped
		case rowTapped(AccountPreferences.Section.SectionRow)
		case hideAccountTapped
	}

	public enum InternalAction: Sendable, Equatable {
		case accountUpdated(Profile.Network.Account)
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
		}
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		switch internalAction {
		case let .accountUpdated(updated):
			state.account = updated
			return .none
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
