import FeaturePrelude

// MARK: - Permission.View
extension Permission {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let numberOfAccounts: String

		init(state: Permission.State) {
			switch state.permissionKind {
			case .accounts:
				title = L10n.DApp.Permission.Title.accounts
			case .personalData:
				title = L10n.DApp.Permission.Title.personalData
			}

			subtitle = {
				let normalColor = Color.app.gray2
				let highlightColor = Color.app.gray1

				let dappName = AttributedString(state.dappMetadata.name, foregroundColor: highlightColor)

				let explanation: AttributedString = {
					let always = AttributedString(L10n.DApp.Permission.Subtitle.always, foregroundColor: highlightColor)

					switch state.permissionKind {
					case .accounts:
						return AttributedString(
							L10n.DApp.Permission.Subtitle.Explanation.Accounts.first,
							foregroundColor: normalColor
						)
							+ always
							+ AttributedString(
								L10n.DApp.Permission.Subtitle.Explanation.Accounts.second,
								foregroundColor: normalColor
							)
					case .personalData:
						return AttributedString(
							L10n.DApp.Permission.Subtitle.Explanation.PersonalData.first,
							foregroundColor: normalColor
						)
							+ always
							+ AttributedString(
								L10n.DApp.Permission.Subtitle.Explanation.PersonalData.second,
								foregroundColor: normalColor
							)
					}
				}()

				return dappName + explanation
			}()

			numberOfAccounts = {
				let message: String = {
					switch state.permissionKind {
					case let .accounts(numberOfAccounts):
						switch (numberOfAccounts.quantifier, numberOfAccounts.quantity) {
						case (.atLeast, 0):
							return L10n.DApp.Permission.NumberOfAccounts.atLeastZero
						case let (.atLeast, number):
							return L10n.DApp.Permission.NumberOfAccounts.atLeast(number)
						case (.exactly, 1):
							return L10n.DApp.Permission.NumberOfAccounts.exactlyOne
						case let (.exactly, number):
							return L10n.DApp.Permission.NumberOfAccounts.exactly(number)
						}
					case .personalData:
						return ""
					}
				}()

				return "•  " + message
			}()
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<Permission>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: Permission.ViewState.init,
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

								Text(L10n.DApp.Permission.updateInSettingsExplanation)
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
					.safeAreaInset(edge: .bottom) {
						ConfirmationFooter(
							title: L10n.DApp.LoginRequest.continueButtonTitle,
							isEnabled: true,
							action: { viewStore.send(.continueButtonTapped) }
						)
					}
				}
			}
		}
	}
}

private extension Permission.View {
	// NB: will most likely belong in ViewState
	var dappImage: some SwiftUI.View {
		// NOTE: using placeholder until API is available
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct Permission_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		Permission.View(
			store: .init(
				initialState: .previewValue,
				reducer: Permission()
			)
		)
	}
}

extension Permission.State {
	static let previewValue: Self = .init(
		permissionKind: .accounts(.exactly(1)),
		dappMetadata: .previewValue
	)
}
#endif
