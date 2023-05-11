import FeaturePrelude

// MARK: - Permission.View
extension AccountPermission {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let numberOfAccounts: String

		init(state: AccountPermission.State) {
			self.title = L10n.DappRequest.AccountPermission.title
			self.subtitle = {
				let normalColor = Color.app.gray2
				let highlightColor = Color.app.gray1

				let dappName = AttributedString(state.dappMetadata.name.rawValue, foregroundColor: highlightColor)
				let explanation1 = AttributedString(L10n.DappRequest.AccountPermission.subtitlePart1, foregroundColor: normalColor)
				let explanation2 = AttributedString(L10n.DappRequest.AccountPermission.subtitlePart2, foregroundColor: highlightColor)
				let explanation3 = AttributedString(L10n.DappRequest.AccountPermission.subtitlePart3, foregroundColor: normalColor)

				return dappName + explanation1 + explanation2 + explanation3
			}()

			self.numberOfAccounts = "•  " + {
				switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
				case (.atLeast, 0):
					return L10n.DappRequest.AccountPermission.numberOfAccountsAtLeastZero
				case let (.atLeast, number):
					return L10n.DappRequest.AccountPermission.numberOfAccountsAtLeast(number)
				case (.exactly, 1):
					return L10n.DappRequest.AccountPermission.numberOfAccountsExactlyOne
				case let (.exactly, number):
					return L10n.DappRequest.AccountPermission.numberOfAccountsExactly(number)
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
							icon: nil,
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

						Text(L10n.DappRequest.AccountPermission.updateInSettingsExplanation)
							.foregroundColor(.app.gray2)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)
							.padding(.horizontal, .medium2)
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					Button(L10n.Common.continue) {
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
					reducer: AccountPermission()
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
