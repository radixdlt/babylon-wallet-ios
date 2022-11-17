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
				VStack(spacing: .zero) {
					header(with: viewStore)
						.padding([.horizontal, .top], .medium3)

					AddressView(
						address: viewStore.address.wrapAsAddress(),
						copyAddressAction: {
							viewStore.send(.copyAddressButtonTapped)
						}
					)
					.frame(maxWidth: 140)
					.foregroundColor(.app.whiteTransparent)
					.padding(.bottom, .medium1)

					ScrollView {
						VStack(spacing: .medium3) {
							AssetsView.View(
								store: store.scope(
									state: \.assets,
									action: { .child(.assets($0)) }
								)
							)
						}
						.padding(.bottom, .medium1)
					}
					.background(Color.app.gray5)
					.padding(.bottom, .medium2)
					.cornerRadius(.medium2)
					.padding(.bottom, .medium2 * -2)
				}
				.background(Color.app.blue2)
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
				.textStyle(.secondaryHeader)

			Spacer()

			// TODO: remove when account preferences screen is implemented
			Spacer()
				.frame(.small)

			// TODO: uncomment when account preferences screen is implemented
			/*
			 accountPreferencesButton(with: viewStore)
			 */
		}
		.foregroundColor(.app.white)
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
				.cornerRadius(.small2)
		})
	}

	func accountPreferencesButton(with viewStore: AccountDetailsViewStore) -> some View {
		Button(
			action: {
				viewStore.send(.displayAccountPreferencesButtonTapped)
			}, label: {
				Image(asset: AssetResource.ellipsis)
			}
		)
		.frame(.small)
	}
}

// MARK: - AccountDetails.View.ViewState
extension AccountDetails.View {
	// MARK: ViewState
	struct ViewState: Equatable {
		public let address: AccountAddress
		public let displayName: String

		init(state: AccountDetails.State) {
			address = state.address
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
