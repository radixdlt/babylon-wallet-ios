import FeaturePrelude

// MARK: - Permission.View
extension PersonaDataPermission {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString

		init(state: PersonaDataPermission.State) {
			title = L10n.DApp.PersonaDataPermission.title
			subtitle = {
				let normalColor = Color.app.gray2
				let highlightColor = Color.app.gray1

				let dappName = AttributedString(state.dappMetadata.name.rawValue, foregroundColor: highlightColor)

				let explanation: AttributedString = {
					let always = AttributedString(L10n.DApp.PersonaDataPermission.Subtitle.always, foregroundColor: highlightColor)

					return AttributedString(
						L10n.DApp.PersonaDataPermission.Subtitle.Explanation.first,
						foregroundColor: normalColor
					)
						+ always
						+ AttributedString(
							L10n.DApp.PersonaDataPermission.Subtitle.Explanation.second,
							foregroundColor: normalColor
						)
				}()

				return dappName + explanation
			}()
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PersonaDataPermission>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: PersonaDataPermission.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ForceFullScreen {
					ScrollView {
						VStack(spacing: .medium2) {
							DappHeader(
								icon: nil,
								title: viewStore.title,
								subtitle: viewStore.subtitle
							)

							DappEntityBox {
								Text("s")
							} content: {
								Text("s")
							}

							Text(L10n.DApp.AccountPermission.updateInSettingsExplanation)
								.foregroundColor(.app.gray2)
								.textStyle(.body1Regular)
								.multilineTextAlignment(.center)
								.padding(.horizontal, .medium2)
						}
						.padding(.horizontal, .medium1)
						.padding(.bottom, .medium2)
					}
					.footer {
						Button(L10n.DApp.PersonaDataPermission.Button.continue) {
							viewStore.send(.continueButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct PersonaDataPermission_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		PersonaDataPermission.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonaDataPermission()
			)
		)
	}
}

extension PersonaDataPermission.State {
	static let previewValue: Self = .init(
		dappMetadata: .previewValue,
		numberOfAccounts: .exactly(1)
	)
}
#endif
