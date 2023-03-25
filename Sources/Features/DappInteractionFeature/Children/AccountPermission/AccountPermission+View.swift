import FeaturePrelude

// MARK: - Permission.View
extension AccountPermission {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let numberOfAccounts: String

		init(state: AccountPermission.State) {
			title = L10n.DApp.AccountPermission.title
			subtitle = {
				let normalColor = Color.app.gray2
				let highlightColor = Color.app.gray1

				let dappName = AttributedString(state.dappMetadata.name.rawValue, foregroundColor: highlightColor)

				let explanation: AttributedString = {
					let always = AttributedString(L10n.DApp.AccountPermission.Subtitle.always, foregroundColor: highlightColor)

					return AttributedString(
						L10n.DApp.AccountPermission.Subtitle.Explanation.first,
						foregroundColor: normalColor
					)
						+ always
						+ AttributedString(
							L10n.DApp.AccountPermission.Subtitle.Explanation.second,
							foregroundColor: normalColor
						)
				}()

				return dappName + explanation
			}()

			numberOfAccounts = "•  " + {
				switch (state.numberOfAccounts.quantifier, state.numberOfAccounts.quantity) {
				case (.atLeast, 0):
					return L10n.DApp.AccountPermission.NumberOfAccounts.atLeastZero
				case let (.atLeast, number):
					return L10n.DApp.AccountPermission.NumberOfAccounts.atLeast(number)
				case (.exactly, 1):
					return L10n.DApp.AccountPermission.NumberOfAccounts.exactlyOne
				case let (.exactly, number):
					return L10n.DApp.AccountPermission.NumberOfAccounts.exactly(number)
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
				ForceFullScreen {
					ScrollView {
						VStack(spacing: .medium2) {
							VStack(spacing: .medium2) {
								dappImage

								Text(viewStore.title)
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)

								Text(viewStore.subtitle)
									.textStyle(.secondaryHeader)
									.multilineTextAlignment(.center)
							}
							.padding(.bottom, .medium2)

							VStack {
								HStack {
									Text(viewStore.numberOfAccounts)
										.foregroundColor(.app.gray1)
										.textStyle(.body1Regular)
										.padding([.horizontal, .vertical], .medium1)

									Spacer()
								}
								.background(Color.app.gray5)
								.cornerRadius(.medium3)

								Spacer()
									.frame(height: .large1 * 1.5)

								Text(L10n.DApp.AccountPermission.updateInSettingsExplanation)
									.foregroundColor(.app.gray2)
									.textStyle(.body1Regular)
									.multilineTextAlignment(.center)
									.padding(.horizontal, .medium3)
							}
							.padding(.horizontal, .medium3)

							Spacer()
								.frame(height: .large1 * 1.5)
						}
						.padding(.horizontal, .medium1)
					}
					.footer {
						Button(L10n.DApp.AccountPermission.Button.continue) {
							viewStore.send(.continueButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
				}
			}
		}

		var dappImage: some SwiftUI.View {
			// NOTE: using placeholder until API is available
			Color.app.gray4
				.frame(.medium)
				.cornerRadius(.medium3)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct AccountPermission_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		AccountPermission.View(
			store: .init(
				initialState: .previewValue,
				reducer: AccountPermission()
			)
		)
	}
}

extension AccountPermission.State {
	static let previewValue: Self = .init(
		dappMetadata: .previewValue,
		numberOfAccounts: .exactly(1)
	)
}
#endif
