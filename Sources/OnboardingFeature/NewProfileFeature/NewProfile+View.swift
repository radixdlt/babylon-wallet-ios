import Common
import ComposableArchitecture
import SwiftUI

// MARK: - NewProfile.View
public extension NewProfile {
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
			send: NewProfile.Action.init
		) { viewStore in
			ForceFullScreen {
				VStack {
					HStack {
						Button(
							action: {
								viewStore.send(.goBackButtonPressed)
							}, label: {
								Image("arrow-back")
							}
						)
						Spacer()
						Text("New Profile")
						Spacer()
						EmptyView()
					}
					Spacer()

					TextField(
						"Name of first acocunt",
						text: viewStore.binding(
							get: \.nameOfFirstAccount,
							send: ViewAction.accountNameChanged
						)
					)

					Button("Create Profle") {
						viewStore.send(.createProfileButtonPressed)
					}
					.buttonStyle(.borderedProminent)
					.disabled(!viewStore.canProceed)

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
		var canProceed: Bool

		init(state: NewProfile.State) {
			nameOfFirstAccount = state.nameOfFirstAccount
			canProceed = state.canProceed
		}
	}
}

// MARK: - NewProfile.View.ViewAction
extension NewProfile.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case accountNameChanged(String)
		case createProfileButtonPressed
		case goBackButtonPressed
	}
}

extension NewProfile.Action {
	init(action: NewProfile.View.ViewAction) {
		switch action {
		case let .accountNameChanged(accountName):
			self = .internal(.user(.accountNameChanged(accountName)))
		case .createProfileButtonPressed:
			self = .internal(.user(.createProfile))
		case .goBackButtonPressed:
			self = .internal(.user(.goBack))
		}
	}
}

// MARK: - NewProfileView_Previews
struct NewProfileView_Previews: PreviewProvider {
	static var previews: some View {
		NewProfile.View(
			store: .init(
				initialState: .init(networkID: .primary),
				reducer: NewProfile()
			)
		)
	}
}
