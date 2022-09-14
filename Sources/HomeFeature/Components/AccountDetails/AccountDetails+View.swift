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
				VStack {
					header(with: viewStore)
						.padding([.leading, .trailing, .top], 24)

					ScrollView {
						VStack(spacing: 16) {
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

							transferButton(with: viewStore)
								.padding(.bottom, 20)

							Home.AssetList.View(
								store: store.scope(
									state: \.assetList,
									action: Home.AccountDetails.Action.assetList
								)
							)
						}
						.padding(.bottom, 24)
					}
				}
				.background(Color.app.backgroundLightGray.opacity(0.15))
			}
		}
	}
}

// MARK: - Private Typealias
private extension Home.AccountDetails.View {
	typealias AccountDetailsViewStore = ViewStore<Home.AccountDetails.View.ViewState, Home.AccountDetails.View.ViewAction>
}

// MARK: - Private Methods
private extension Home.AccountDetails.View {
	func header(with viewStore: AccountDetailsViewStore) -> some View {
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
					// TODO: uncomment
//					viewStore.send(.accountPreferencesButtonTapped)
					// TODO: temp implementation just for testing pull to refresh
					viewStore.send(.refreshTapped)
				}, label: {
					Image("ellipsis")
				}
			)
		}
	}

	func transferButton(with viewStore: AccountDetailsViewStore) -> some View {
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
	}
}

extension Home.AccountDetails.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case dismissAccountDetailsButtonTapped
		case accountPreferencesButtonTapped
		case copyAddressButtonTapped
		case transferButtonTapped
		case refreshTapped
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
		case .refreshTapped:
			self = .internal(.user(.refresh))
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
