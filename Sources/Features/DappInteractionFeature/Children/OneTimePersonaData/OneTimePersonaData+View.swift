@_spi(Internals) import ComposableArchitecture
import EditPersonaFeature
import FeaturePrelude
import PersonasClient

// MARK: - Permission.View
extension OneTimePersonaData {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let availablePersonas: IdentifiedArrayOf<PersonaDataPermissionBox.State>
		let selectedPersona: PersonaDataPermissionBox.State?
		let output: IdentifiedArrayOf<Profile.Network.Persona.Field>?

		init(state: OneTimePersonaData.State) {
			title = L10n.DApp.OneTimePersonaData.title
			subtitle = {
				let normalColor = Color.app.gray2
				let highlightColor = Color.app.gray1

				let dappName = AttributedString(state.dappMetadata.name.rawValue, foregroundColor: highlightColor)

				let explanation: AttributedString = {
					let justOneTime = AttributedString(L10n.DApp.OneTimePersonaData.Subtitle.justOneTime, foregroundColor: highlightColor)

					return AttributedString(
						L10n.DApp.OneTimePersonaData.Subtitle.Explanation.first,
						foregroundColor: normalColor
					)
						+ justOneTime
				}()

				return dappName + explanation
			}()
			availablePersonas = state.personas
			selectedPersona = state.selectedPersona
			output = {
				guard let selectedPersona = state.selectedPersona else {
					return nil
				}
				let fields = selectedPersona.persona.fields
					.filter { state.requiredFieldIDs.contains($0.id) }
				guard fields.count == state.requiredFieldIDs.count else {
					return nil
				}
				return fields
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

						Text(L10n.DApp.OneTimePersonaData.chooseDataToProvide)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Header)

						Selection(
							viewStore.binding(
								get: \.selectedPersona,
								send: { .selectedPersonaChanged($0) }
							),
							from: viewStore.availablePersonas
						) { item in
							PersonaDataPermissionBox.View(
								store: store.scope(
									state: { _ in item.value },
									action: { .child(.persona(id: $0.id, action: $1)) }
								),
								action: item.action,
								accessory: {
									RadioButton(
										appearance: .dark,
										state: item.isSelected ? .selected : .unselected
									)
								}
							)
						}
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
				.onAppear { viewStore.send(.appeared) }
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
				) {
					$0.personasClient.getPersonas = { @Sendable in
						[.previewValue0, .previewValue1]
					}
				}
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
