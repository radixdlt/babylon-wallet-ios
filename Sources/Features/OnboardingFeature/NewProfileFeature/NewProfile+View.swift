import Common
import ComposableArchitecture
import DesignSystem
import SwiftUI

// MARK: - NewProfile.View
public extension NewProfile {
	@MainActor
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(store: Store) {
			self.store = store
		}
	}
}

public extension NewProfile.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack {
					NavigationBar(
						titleText: "New Profile",
						leadingButton: {
							BackButton {
								viewStore.send(.backButtonPressed)
							}
						}
					)

					Spacer()

					TextField(
						"Name of first acocunt",
						text: viewStore.binding(
							get: \.nameOfFirstAccount,
							send: { .accountNameTextFieldChanged($0) }
						)
					)

					if viewStore.isLoaderVisible {
						LoadingView()
					}

					Button("Create Profle") {
						viewStore.send(.createProfileButtonPressed)
					}
					.buttonStyle(.borderedProminent)
					.enabled(viewStore.isCreateProfileButtonEnabled)

					Spacer()
				}
				.padding()
				.textFieldStyle(.roundedBorder)
			}
		}
	}
}

// MARK: - NewProfile.View.ViewState
extension NewProfile.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		var nameOfFirstAccount: String
		var isLoaderVisible: Bool
		var isCreateProfileButtonEnabled: Bool

		init(state: NewProfile.State) {
			nameOfFirstAccount = state.nameOfFirstAccount
			isLoaderVisible = state.isCreatingProfile
			isCreateProfileButtonEnabled = state.canProceed && !state.isCreatingProfile
		}
	}
}

// MARK: - NewProfileView_Previews
struct NewProfileView_Previews: PreviewProvider {
	static var previews: some View {
		NewProfile.View(
			store: .init(
				initialState: .init(),
				reducer: NewProfile()
			)
		)
	}
}
