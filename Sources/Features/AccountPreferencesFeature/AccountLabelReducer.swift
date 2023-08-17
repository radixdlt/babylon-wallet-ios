import AccountsClient
import FeaturePrelude
import OverlayWindowClient

// MARK: - UpdateAccountLabel
public struct UpdateAccountLabel: FeatureReducer {
	public struct State: Hashable, Sendable {
		var account: Profile.Network.Account
		var accountLabel: String

		init(account: Profile.Network.Account) {
			self.account = account
			self.accountLabel = account.displayName.rawValue
		}
	}

	public enum ViewAction: Equatable {
		case accountLabelChanged(String)
		case updateTapped(NonEmpty<String>)
	}

	public enum DelegateAction: Equatable {
		case accountLabelUpdated
	}

	@Dependency(\.accountsClient) var accountsClient
	@Dependency(\.errorQueue) var errorQueue
	@Dependency(\.overlayWindowClient) var overlayWindowClient

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .accountLabelChanged(label):
			state.accountLabel = label
			return .none
		case let .updateTapped(newLabel):
			state.account.displayName = newLabel
			return .run { [account = state.account] send in
				do {
					try await accountsClient.updateAccount(account)
					overlayWindowClient.scheduleHUD(.init(kind: .operationSucceeded("Updated")))
					await send(.delegate(.accountLabelUpdated))
				} catch {
					errorQueue.schedule(error)
				}
			}
		}
	}
}

extension UpdateAccountLabel.State {
	var viewState: UpdateAccountLabel.ViewState {
		.init(
			accountLabel: accountLabel,
			updateButtonControlState: accountLabel.isEmpty ? .disabled : .enabled,
			hint: accountLabel.isEmpty ? .error("Account label required") : nil
		)
	}
}

extension UpdateAccountLabel {
	public struct ViewState: Equatable {
		let accountLabel: String
		let updateButtonControlState: ControlState
		let hint: Hint?
	}

	@MainActor
	public struct View: SwiftUI.View {
		let store: StoreOf<UpdateAccountLabel>

		init(store: StoreOf<UpdateAccountLabel>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .center, spacing: .medium1) {
					AppTextField(
						primaryHeading: "Enter a new label for this account",
						placeholder: "Your account label",
						text: viewStore.binding(
							get: \.accountLabel,
							send: { .accountLabelChanged($0) }
						),
						hint: viewStore.hint
					)

					WithControlRequirements(
						NonEmpty(viewStore.accountLabel),
						forAction: { viewStore.send(.updateTapped($0)) }
					) { action in
						Button("Update") {
							action()
						}
						.buttonStyle(.primaryRectangular)
						.controlState(viewStore.updateButtonControlState)
					}

					Spacer()
				}
				.padding(.large3)
				.navigationTitle("Rename Account")
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
				.toolbarBackground(.app.background, for: .navigationBar)
				.toolbarBackground(.visible, for: .navigationBar)
			}
		}
	}
}
