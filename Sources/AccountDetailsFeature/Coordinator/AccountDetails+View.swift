import AggregatedValueFeature
import Common
import ComposableArchitecture
import SwiftUI

public extension AccountDetails {
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

public extension AccountDetails.View {
	var body: some View {
		WithViewStore(
			store.scope(
				state: ViewState.init,
				action: AccountDetails.Action.init
			)
		) { viewStore in
			ForceFullScreen {
				VStack {
					header(with: viewStore)
						.padding([.leading, .trailing, .top], 24)

					ScrollView {
						VStack(spacing: 16) {
							/*
							 AccountDetails.AddressView(
							 	address: viewStore.address,
							 	copyAddressAction: {
							 		viewStore.send(.copyAddressButtonTapped)
							 	}
							 )
							 */

							AggregatedValue.View(
								store: store.scope(
									state: \.aggregatedValue,
									action: AccountDetails.Action.aggregatedValue
								)
							)

							transferButton(with: viewStore)
								.padding(.bottom, 20)

							AccountDetails.AssetList.View(
								store: store.scope(
									state: \.assetList,
									action: AccountDetails.Action.assetList
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
private extension AccountDetails.View {
	typealias AccountDetailsViewStore = ViewStore<AccountDetails.View.ViewState, AccountDetails.View.ViewAction>
}

// MARK: - Private Methods
private extension AccountDetails.View {
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

// MARK: - AddressView
struct AddressView: SwiftUI.View {
	let address: String
	let copyAddressAction: () -> Void

	var body: some View {
		HStack(spacing: 5) {
			Text(address)
				.lineLimit(1)
				.truncationMode(.middle)
				.foregroundColor(.app.buttonTextBlackTransparent)
				.font(.app.caption2)

			Button(
				action: copyAddressAction,
				label: {
					Text(L10n.Home.AccountRow.copyTitle)
						.foregroundColor(.app.buttonTextBlack)
						.font(.app.caption2)
						.underline()
						.padding(12)
						.fixedSize()
				}
			)
		}
	}
}

extension AccountDetails.View {
	// MARK: ViewAction
	enum ViewAction: Equatable {
		case dismissAccountDetailsButtonTapped
		case accountPreferencesButtonTapped
		case copyAddressButtonTapped
		case transferButtonTapped
		case refreshTapped
	}
}

extension AccountDetails.Action {
	init(action: AccountDetails.View.ViewAction) {
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

extension AccountDetails.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public let address: String
		public var aggregatedValue: AggregatedValue.State
		public let name: String

		init(state: AccountDetails.State) {
			address = state.address
			aggregatedValue = state.aggregatedValue
			name = state.name
		}
	}
}

// MARK: - AccountDetails_Preview
struct AccountDetails_Preview: PreviewProvider {
	static var previews: some View {
		AccountDetails.View(
			store: .init(
				initialState: .init(for: .placeholder),
				reducer: AccountDetails.reducer,
				environment: .init()
			)
		)
	}
}
