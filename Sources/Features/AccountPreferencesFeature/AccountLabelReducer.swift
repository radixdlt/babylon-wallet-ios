import FeaturePrelude

// MARK: - UpdateAccountLabel
public struct UpdateAccountLabel: FeatureReducer {
	public struct State: Hashable, Sendable {
		var accountLabel: String
	}

	public enum ViewAction: Equatable {
		case accountLabelChanged(String)
		case updateTapped
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case let .accountLabelChanged(label):
			state.accountLabel = label
			return .none
		case .updateTapped:
			return .none
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

					Button("Update") {
						viewStore.send(.updateTapped)
					}
					.buttonStyle(.primaryRectangular)
					.controlState(viewStore.updateButtonControlState)

					Spacer()
				}
				.padding(.large1)
				.navigationTitle("Rename Account")
			}
		}
	}
}
