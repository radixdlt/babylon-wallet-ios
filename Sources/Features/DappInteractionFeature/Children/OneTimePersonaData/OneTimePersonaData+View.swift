import EditPersonaFeature
import FeaturePrelude

// MARK: - Permission.View
extension OneTimePersonaData {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let output: IdentifiedArrayOf<Profile.Network.Persona.Field>?

		init(state: OneTimePersonaData.State) {
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
			output = {
//				let fields = state.persona.persona.fields
//					.filter { state.requiredFieldIDs.contains($0.id) }
//				guard fields.count == state.requiredFieldIDs.count else {
//					return nil
//				}
//				return fields
				nil
			}()
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<OneTimePersonaData>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: OneTimePersonaData.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ScrollView {
					VStack(spacing: .medium2) {
						DappHeader(
							icon: nil,
							title: viewStore.title,
							subtitle: viewStore.subtitle
						)

//						PersonaDataPermissionBox.View(
//							store: store.scope(
//								state: \.persona,
//								action: { .child(.persona($0)) }
//							)
//						)

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
					WithControlRequirements(
						viewStore.output,
						forAction: { viewStore.send(.continueButtonTapped($0)) }
					) { action in
						Button(L10n.DApp.PersonaDataPermission.Button.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /OneTimePersonaData.Destinations.State.editPersona,
					action: OneTimePersonaData.Destinations.Action.editPersona,
					content: { EditPersona.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct OneTimePersonaData_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		NavigationStack {
			OneTimePersonaData.View(
				store: Store(
					initialState: .previewValue,
					reducer: OneTimePersonaData()
				)
			)
			.toolbar(.visible, for: .navigationBar)
		}
	}
}

extension OneTimePersonaData.State {
	static let previewValue: Self = .init(
		dappMetadata: .previewValue,
		requiredFieldIDs: [.givenName, .emailAddress]
	)
}
#endif
