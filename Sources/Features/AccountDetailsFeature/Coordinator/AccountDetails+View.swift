import AggregatedValueFeature
import AssetsViewFeature
import Common
import ComposableArchitecture
import DesignSystem
import Profile
import SwiftUI

// MARK: - AccountDetails.View
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
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack {
					header(with: viewStore)
						.padding([.leading, .trailing, .top], 24)

					ScrollView {
						VStack(spacing: 16) {
							AddressView(
								address: viewStore.address.wrapAsAddress(),
								copyAddressAction: {
									viewStore.send(.copyAddressButtonTapped)
								}
							)

							AggregatedValue.View(
								store: store.scope(
									state: \.aggregatedValue,
									action: { .child(.aggregatedValue($0)) }
								)
							)

							transferButton(with: viewStore)
								.padding(.bottom, 20)

							AssetsView.View(
								store: store.scope(
									state: \.assets,
									action: { .child(.assets($0)) }
								)
							)
						}
						.padding(.bottom, 24)
					}
				}
				.background(Color.app.gray2.opacity(0.15))
			}
		}
	}
}

// MARK: - AccountDetails.View.AccountDetailsViewStore
private extension AccountDetails.View {
	typealias AccountDetailsViewStore = ViewStore<AccountDetails.View.ViewState, AccountDetails.Action.ViewAction>
}

// MARK: - Private Methods
private extension AccountDetails.View {
	func header(with viewStore: AccountDetailsViewStore) -> some View {
		HStack {
			BackButton {
				viewStore.send(.dismissAccountDetailsButtonTapped)
			}

			Spacer()

			Text(viewStore.displayName)
				.foregroundColor(.app.buttonTextBlack)
				.textStyle(.secondaryHeader)

			Spacer()
			Button(
				action: {
					// TODO: uncomment
//					viewStore.send(.accountPreferencesButtonTapped)
					// TODO: temp implementation just for testing pull to refresh
					viewStore.send(.refreshButtonTapped)
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
			Text(L10n.AccountDetails.transferButtonTitle)
				.foregroundColor(.app.buttonTextBlack)
				.textStyle(.body1Regular)
				.padding()
				.background(Color.app.gray4)
				.cornerRadius(6)
		})
	}
}

// MARK: - AccountDetails.View.ViewState
extension AccountDetails.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public let address: AccountAddress
		public var aggregatedValue: AggregatedValue.State
		public let displayName: String

		init(state: AccountDetails.State) {
			address = state.address
			aggregatedValue = state.aggregatedValue
			displayName = state.displayName
		}
	}
}

#if DEBUG

// MARK: - AccountDetails_Preview
struct AccountDetails_Preview: PreviewProvider {
	static var previews: some View {
		AccountDetails.View(
			store: .init(
				initialState: .init(for: .placeholder),
				reducer: AccountDetails()
			)
		)
	}
}
#endif // DEBUG
