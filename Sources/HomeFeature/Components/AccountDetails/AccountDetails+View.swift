import Common
import ComposableArchitecture
import SwiftUI

public extension Home.AccountDetails {
	struct View: SwiftUI.View {
		public typealias Store = ComposableArchitecture.Store<State, Action>
		private let store: Store

		public init(
			store: Store
		) {
			self.store = store
		}
	}
}

public extension Home.AccountDetails.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: Home.AccountDetails.Action.init
			)
		) { viewStore in
			ForceFullScreen {
				VStack(alignment: .center) {
					HStack {
						Button(
							action: {
								viewStore.send(.dismissAccountDetailsButtonTapped)
							}, label: {
								Image("arrow-back")
							}
						)
						Spacer()
						Text(viewStore.name)
							.foregroundColor(.app.buttonTextBlack)
							.font(.app.buttonTitle)
						Spacer()
						Button(
							action: {
								viewStore.send(.accountPreferencesButtonTapped)
							}, label: {
								Image("ellipsis")
							}
						)
					}

					AddressView(
						address: viewStore.address,
						copyAddressAction: {
							viewStore.send(.copyAddressButtonTapped)
						}
					)

					Home.AggregatedValue.View(
						store: store.scope(
							state: \.aggregatedValue,
							action: Home.AccountDetails.Action.aggregatedValue
						)
					)

					Button(action: {
						viewStore.send(.transferButtonTapped)
					}, label: {
						Text(L10n.Home.AccountDetails.transferButtonTitle)
							.foregroundColor(.app.buttonTextBlack)
							.font(.app.body)
							.padding()
							.background(Color.app.buttonBackgroundLight)
							.cornerRadius(6)
					})

					Spacer()
				}
			}
		}
	}
}

extension Home.AccountDetails.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case dismissAccountDetailsButtonTapped
		case accountPreferencesButtonTapped
		case copyAddressButtonTapped
		case transferButtonTapped
	}
}

extension Home.AccountDetails.Action {
	init(action: Home.AccountDetails.View.ViewAction) {
		switch action {
		case .dismissAccountDetailsButtonTapped:
			self = .internal(.user(.dismissAccountDetails))
		case .accountPreferencesButtonTapped:
			self = .internal(.user(.displayAccountPreferences))
		case .copyAddressButtonTapped:
			self = .internal(.user(.copyAddress))
		case .transferButtonTapped:
			self = .internal(.user(.displayTransfer))
		}
	}
}

extension Home.AccountDetails.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public let address: String
		public var aggregatedValue: Home.AggregatedValue.State
		public let name: String

		init(state: Home.AccountDetails.State) {
			address = state.address
			aggregatedValue = state.aggregatedValue
			name = state.name
		}
	}
}

// MARK: - AccountDetails_Preview
struct AccountDetails_Preview: PreviewProvider {
	static var previews: some View {
		Home.AccountDetails.View(
			store: .init(
				initialState: .init(for: .placeholder),
				reducer: Home.AccountDetails.reducer,
				environment: .init()
			)
		)
	}
}
