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
			WithViewStore(store, observe: { ViewState(state: $0) }, send: { .view($0) }) { viewStore in
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

						selection(viewStore: viewStore)

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
			}
			.destinations(with: store)
			.onAppear { store.send(.view(.appeared)) }
			.task { store.send(.view(.task)) }
		}

		private func selection(viewStore: ViewStoreOf<OneTimePersonaData>) -> some SwiftUI.View {
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
	}
}

// MARK: - Extensions

private extension StoreOf<OneTimePersonaData> {
	var destination: PresentationStoreOf<OneTimePersonaData.Destination_> {
		scope(state: \.$destination) { .destination($0) }
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<OneTimePersonaData>) -> some View {
		let destinationStore = store.destination
		return editPersona(with: destinationStore)
			.createPersona(with: destinationStore)
	}

	private func editPersona(with destinationStore: PresentationStoreOf<OneTimePersonaData.Destination_>) -> some View {
		sheet(
			store: destinationStore,
			state: /OneTimePersonaData.Destination_.State.editPersona,
			action: OneTimePersonaData.Destination_.Action.editPersona,
			content: { EditPersona.View(store: $0) }
		)
	}

	private func createPersona(with destinationStore: PresentationStoreOf<OneTimePersonaData.Destination_>) -> some View {
		sheet(
			store: destinationStore,
			state: /OneTimePersonaData.Destination_.State.createPersona,
			action: OneTimePersonaData.Destination_.Action.createPersona,
			content: { CreatePersonaCoordinator.View(store: $0) }
		)
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
