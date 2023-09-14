import FeaturePrelude

// MARK: - Permission.View
extension AccountPermission {
	struct ViewState: Equatable {
		let thumbnail: URL?
		let title: String
		let subtitle: String
		let numberOfAccounts: String

		init(state: AccountPermission.State) {
			self.thumbnail = state.dappMetadata.thumbnail
			self.title = L10n.DAppRequest.AccountPermission.title
			self.subtitle = L10n.DAppRequest.AccountPermission.subtitle(state.dappMetadata.name)

			self.numberOfAccounts = "•  " + {
				switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
				case (.atLeast, 0):
					return L10n.DAppRequest.AccountPermission.numberOfAccountsAtLeastZero
				case let (.atLeast, number):
					return L10n.DAppRequest.AccountPermission.numberOfAccountsAtLeast(number)
				case (.exactly, 1):
					return L10n.DAppRequest.AccountPermission.numberOfAccountsExactlyOne
				case let (.exactly, number):
					return L10n.DAppRequest.AccountPermission.numberOfAccountsExactly(number)
				}
			}()
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<AccountPermission>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: AccountPermission.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							thumbnail: viewStore.thumbnail,
							title: viewStore.title,
							subtitle: viewStore.subtitle
						)

						DappPermissionBox {
							Text(viewStore.numberOfAccounts)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Regular)
								.padding(.medium1)
						}
						.padding(.horizontal, .medium2)

						Text(L10n.DAppRequest.AccountPermission.updateInSettingsExplanation)
							.foregroundColor(.app.gray2)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.padding(.horizontal, .medium2)
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					Button(L10n.DAppRequest.AccountPermission.continue) {
						viewStore.send(.continueButtonTapped)
					}
					.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct AccountPermission_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		NavigationStack {
			AccountPermission.View(
				store: .init(
					initialState: .previewValue,
					reducer: AccountPermission.init
				)
			)
			#if os(iOS)
			.toolbar(.visible, for: .navigationBar)
			#endif // iOS
		}
	}
}

extension AccountPermission.State {
	static let previewValue: Self = .init(
		dappMetadata: .previewValue,
		numberOfAccounts: .exactly(1)
	)
}
#endif
