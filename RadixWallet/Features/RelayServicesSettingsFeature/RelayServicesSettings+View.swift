import ComposableArchitecture
import SwiftUI

extension RelayServicesSettings.State.Row {
	var rowCoreViewState: PlainListRowCore.ViewState {
		.init(
			title: service.name,
			detail: service.url.absoluteString
		)
	}
}

// MARK: - RelayServicesSettings.View
extension RelayServicesSettings {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<RelayServicesSettings>

		init(store: StoreOf<RelayServicesSettings>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView()
						.padding(.bottom, .medium1)
						.radixToolbar(title: "Relay Services")
				}
				.background(Color.secondaryBackground)
				.task { @MainActor in await store.send(.view(.task)).finish() }
				.destinations(with: store)
			}
		}

		private func coreView() -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .zero) {
				Text("Choose and manage relay service endpoints used for Radix Connect Mobile responses.")
					.foregroundColor(.secondaryText)
					.textStyle(.body1HighImportance)
					.padding(.top, .medium3)
					.padding(.horizontal, .medium3)
					.padding(.bottom, .large2)

				LazyVStack(spacing: .zero) {
					ForEach(store.rows) { row in
						VStack(spacing: .zero) {
							Button {
								store.send(.view(.rowTapped(row.id)))
							} label: {
								PlainListRow(viewState: .init(
									rowCoreViewState: row.rowCoreViewState,
									accessory: {
										if row.canBeDeleted {
											Button(asset: AssetResource.trash) {
												store.send(.view(.rowRemoveTapped(row.id)))
											}
										}
									},
									icon: {
										Image(.check)
											.opacity(row.isSelected ? 1 : 0)
									}
								))
							}

							Separator()
								.padding(.horizontal, row.id == store.rows.last?.id ? 0 : .medium3)
						}
						.background(Color.secondaryBackground)
					}
				}
				.buttonStyle(.tappableRowStyle)
				.padding(.bottom, .small3)

				Button("Add New Relay Service") {
					store.send(.view(.addServiceButtonTapped))
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
				.padding(.horizontal, .medium3)
				.padding(.top, .large1)
			}
		}
	}
}

private extension StoreOf<RelayServicesSettings> {
	var destination: PresentationStoreOf<RelayServicesSettings.Destination> {
		func scopeState(state: RelayServicesSettings.State) -> PresentationState<RelayServicesSettings.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: RelayServicesSettings.Action.destination)
	}
}

@MainActor
private extension RelayServicesSettings.View {
	func destinations(with store: StoreOf<RelayServicesSettings>) -> some View {
		let destinationStore = store.destination
		return addRelayService(with: destinationStore)
			.removeRelayService(with: destinationStore)
	}

	private func addRelayService(with destinationStore: PresentationStoreOf<RelayServicesSettings.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addNewService, action: \.addNewService)) {
			AddNewRelayService.View(store: $0)
		}
	}

	private func removeRelayService(with destinationStore: PresentationStoreOf<RelayServicesSettings.Destination>) -> some View {
		alert(store: destinationStore.scope(state: \.removeService, action: \.removeService))
	}
}

extension AddNewRelayService.State {
	var nameHint: Hint.ViewState? {
		nil
	}

	var relayHint: Hint.ViewState? {
		errorText.map(Hint.ViewState.iconError)
	}
}

// MARK: - AddNewRelayService.View
extension AddNewRelayService {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable private var store: StoreOf<AddNewRelayService>
		@FocusState private var focusedField: State.Field?
		@Environment(\.dismiss) var dismiss

		init(store: StoreOf<AddNewRelayService>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			content
				.withNavigationBar {
					dismiss()
				}
				.presentationDragIndicator(.visible)
				.presentationBackground(.blur)
		}

		private var content: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					VStack(spacing: .medium2) {
						Text("Add relay service")
							.foregroundColor(.primaryText)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text("Provide a service name and relay endpoint URL.")
							.foregroundColor(.primaryText)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						AppTextField(
							placeholder: "Service name",
							text: $store.name.sending(\.view.nameChanged),
							hint: store.nameHint,
							focus: .on(
								.name,
								binding: $store.focusedField.sending(\.view.textFieldFocused),
								to: $focusedField
							)
						)

						AppTextField(
							placeholder: "https://relay.example/api/v1",
							text: $store.relayURL.sending(\.view.relayURLChanged),
							hint: store.relayHint,
							focus: .on(
								.relayURL,
								binding: $store.focusedField.sending(\.view.textFieldFocused),
								to: $focusedField
							)
						)
						.textInputAutocapitalization(.never)
						.keyboardType(.URL)
						.autocorrectionDisabled()
					}
					.padding(.top, .medium3)
					.padding(.horizontal, .large2)
					.padding(.bottom, .medium1)
				}
				.footer {
					Button("Add relay service") {
						store.send(.view(.addButtonTapped))
					}
					.buttonStyle(.primaryRectangular)
					.controlState(store.addButtonState)
				}
				.onAppear { store.send(.view(.appeared)) }
			}
		}
	}
}
