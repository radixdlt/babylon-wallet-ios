import FeaturePrelude

extension UpdateAccountLabel.State {
	var viewState: UpdateAccountLabel.ViewState {
		.init(
			accountLabel: accountLabel,
			updateButtonControlState: accountLabel.isEmpty ? .disabled : .enabled,
			hint: accountLabel.isEmpty ? .error("Account label required") : nil // FIXME: strings
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
					VStack {
						AppTextField(
							primaryHeading: "Enter a new label for this account", // FIXME: strings
							placeholder: "Your account label", // FIXME: strings
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
							Button("Update") { // FIXME: strings
								action()
							}
							.buttonStyle(.primaryRectangular)
							.controlState(viewStore.updateButtonControlState)
						}
					}.background(.app.background)

					Spacer()
				}
				.padding(.large3)
				.background(.app.gray2)
				.navigationTitle("Rename Account") // FIXME: strings
				.navigationBarTitleColor(.app.gray1)
				.navigationBarTitleDisplayMode(.inline)
				.navigationBarInlineTitleFont(.app.secondaryHeader)
				.toolbarBackground(.app.background, for: .navigationBar)
				.toolbarBackground(.visible, for: .navigationBar)
			}
		}
	}
}
