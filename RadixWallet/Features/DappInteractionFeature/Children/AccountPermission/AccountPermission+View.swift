import ComposableArchitecture
import SwiftUI

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

			// Need to disable, since broken in swiftformat 0.52.7
			// swiftformat:disable redundantClosure
			self.numberOfAccounts = "•  " + {
				switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
				case (.atLeast, 0):
					L10n.DAppRequest.AccountPermission.numberOfAccountsAtLeastZero
				case let (.atLeast, number):
					L10n.DAppRequest.AccountPermission.numberOfAccountsAtLeast(Int(number))
				case (.exactly, 1):
					L10n.DAppRequest.AccountPermission.numberOfAccountsExactlyOne
				case let (.exactly, number):
					L10n.DAppRequest.AccountPermission.numberOfAccountsExactly(Int(number))
				}
			}()
			// swiftformat:enable redundantClosure
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
				GeometryReader { geometry in
					ScrollView {
						VStack(spacing: .zero) {
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
							.padding(.top, .large1)

							Text(L10n.DAppRequest.AccountPermission.updateInSettingsExplanation)
								.foregroundColor(.app.gray2)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.center)
								.padding(.horizontal, .medium2)
								.padding(.top, .medium1)

							Spacer()
						}
						.padding(.horizontal, .medium1)
						.padding(.bottom, .medium2)
						.frame(minHeight: geometry.size.height)
					}
					.frame(width: geometry.size.width)
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
import ComposableArchitecture
import SwiftUI

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
			.toolbar(.visible, for: .navigationBar)
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
