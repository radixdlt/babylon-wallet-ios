@_spi(Internals) import ComposableArchitecture

// MARK: - Permission.View
extension OneTimePersonaData {
	struct ViewState: Equatable {
		let thumbnail: URL?
		let title: String
		let subtitle: String
		let shouldShowChooseDataToProvideTitle: Bool
		let availablePersonas: IdentifiedArrayOf<PersonaDataPermissionBox.State>
		let selectedPersona: PersonaDataPermissionBox.State?
		let output: P2P.Dapp.Request.Response?

		init(state: OneTimePersonaData.State) {
			self.thumbnail = state.dappMetadata.thumbnail
			self.title = L10n.DAppRequest.PersonalDataOneTime.title
			self.subtitle = L10n.DAppRequest.PersonalDataOneTime.subtitle(state.dappMetadata.name)
			self.shouldShowChooseDataToProvideTitle = !state.personas.isEmpty
			self.availablePersonas = state.personas
			self.selectedPersona = state.selectedPersona
			self.output = selectedPersona?.responseValidation.response
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
							thumbnail: viewStore.thumbnail,
							title: viewStore.title,
							subtitle: viewStore.subtitle
						)

						if viewStore.shouldShowChooseDataToProvideTitle {
							Text(L10n.DAppRequest.PersonalDataOneTime.chooseDataToProvide)
								.foregroundColor(.app.gray1)
								.textStyle(.body1Header)
						}

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

						Button(L10n.Personas.createNewPersona) {
							viewStore.send(.createNewPersonaButtonTapped)
						}
						.buttonStyle(.secondaryRectangular(shouldExpand: false))
					}
					.padding(.horizontal, .medium1)
					.padding(.bottom, .medium2)
				}
				.footer {
					WithControlRequirements(
						viewStore.output,
						forAction: { viewStore.send(.continueButtonTapped($0)) }
					) { action in
						Button(L10n.DAppRequest.PersonalDataOneTime.continue, action: action)
							.buttonStyle(.primaryRectangular)
					}
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /OneTimePersonaData.Destination.State.editPersona,
					action: OneTimePersonaData.Destination.Action.editPersona,
					content: { EditPersona.View(store: $0) }
				)
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /OneTimePersonaData.Destination.State.createPersona,
					action: OneTimePersonaData.Destination.Action.createPersona,
					content: { CreatePersonaCoordinator.View(store: $0) }
				)
				.onAppear { viewStore.send(.appeared) }
				.task { viewStore.send(.task) }
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - Permission_Preview
// struct OneTimePersonaData_Preview: PreviewProvider {
//	static var previews: some SwiftUI.View {
//		NavigationStack {
//			OneTimePersonaData.View(
//				store: Store(
//					initialState: .previewValue,
//					reducer: OneTimePersonaData.init
//				) {
//					$0.personasClient.getPersonas = { @Sendable in
//						[.previewValue0, .previewValue1]
//					}
//				}
//			)
//			#if os(iOS)
//			.toolbar(.visible, for: .navigationBar)
//			#endif
//		}
//	}
// }
//
// extension OneTimePersonaData.State {
//	static let previewValue: Self = .init(
//		dappMetadata: .previewValue,
//		requiredFieldIDs: [.givenName, .emailAddress]
//	)
// }
// #endif
