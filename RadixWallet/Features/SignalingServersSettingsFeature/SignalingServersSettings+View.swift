import ComposableArchitecture
import SwiftUI

extension SignalingServersSettings.State.Row {
	var rowCoreViewState: PlainListRowCore.ViewState {
		.init(
			title: profile.name,
			detail: profile.signalingServer
		)
	}
}

// MARK: - SignalingServersSettings.View
extension SignalingServersSettings {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<SignalingServersSettings>

		init(store: StoreOf<SignalingServersSettings>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ScrollView {
					coreView()
						.padding(.bottom, .medium1)
						.radixToolbar(title: "Signaling Servers")
				}
				.background(Color.secondaryBackground)
				.task { @MainActor in await store.send(.view(.task)).finish() }
				.destinations(with: store)
			}
		}

		private func coreView() -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .zero) {
				Text("Choose and manage signaling server profiles used for WalletConnect P2P.")
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

				Button("Add New Signaling Server") {
					store.send(.view(.addProfileButtonTapped))
				}
				.buttonStyle(.secondaryRectangular(shouldExpand: true))
				.padding(.horizontal, .medium3)
				.padding(.top, .large1)
			}
		}
	}
}

private extension StoreOf<SignalingServersSettings> {
	var destination: PresentationStoreOf<SignalingServersSettings.Destination> {
		func scopeState(state: SignalingServersSettings.State) -> PresentationState<SignalingServersSettings.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: SignalingServersSettings.Action.destination)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<SignalingServersSettings>) -> some View {
		let destinationStore = store.destination
		return self
			.sheet(store: destinationStore.scope(state: \.addNewProfile, action: \.addNewProfile)) {
				AddNewSignalingServer.View(store: $0)
			}
			.alert(store: destinationStore.scope(state: \.removeProfile, action: \.removeProfile))
	}
}

extension AddNewSignalingServer.State {
	var nameHint: Hint.ViewState? {
		nil
	}

	var signalingHint: Hint.ViewState? {
		errorText.map(Hint.ViewState.iconError)
	}
}

// MARK: - AddNewSignalingServer.View
extension AddNewSignalingServer {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable private var store: StoreOf<AddNewSignalingServer>
		@FocusState private var focusedField: State.Field?
		@Environment(\.dismiss) var dismiss

		init(store: StoreOf<AddNewSignalingServer>) {
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
						Text("Add signaling server")
							.foregroundColor(.primaryText)
							.textStyle(.sheetTitle)
							.multilineTextAlignment(.center)

						Text("Provide a profile name, signaling server URL, and optional ICE server configuration.")
							.foregroundColor(.primaryText)
							.textStyle(.body1Regular)
							.multilineTextAlignment(.center)

						AppTextField(
							placeholder: "Profile name",
							text: $store.name.sending(\.view.nameChanged),
							hint: store.nameHint,
							focus: .on(
								.name,
								binding: $store.focusedField.sending(\.view.textFieldFocused),
								to: $focusedField
							)
						)

						AppTextField(
							placeholder: "wss://example-signaling.server",
							text: $store.signalingURL.sending(\.view.signalingURLChanged),
							hint: store.signalingHint,
							focus: .on(
								.signalingURL,
								binding: $store.focusedField.sending(\.view.textFieldFocused),
								to: $focusedField
							)
						)
						.textInputAutocapitalization(.never)
						.keyboardType(.URL)
						.autocorrectionDisabled()

						AppTextField(
							placeholder: "ICE URLs (comma or newline separated)",
							text: $store.iceServerURLs.sending(\.view.iceServerURLsChanged),
							focus: .on(
								.iceServerURLs,
								binding: $store.focusedField.sending(\.view.textFieldFocused),
								to: $focusedField
							)
						)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()

						AppTextField(
							placeholder: "ICE username (optional)",
							text: $store.username.sending(\.view.usernameChanged),
							focus: .on(
								.username,
								binding: $store.focusedField.sending(\.view.textFieldFocused),
								to: $focusedField
							)
						)
						.textInputAutocapitalization(.never)

						AppTextField(
							placeholder: "ICE credential (optional)",
							text: $store.credential.sending(\.view.credentialChanged),
							focus: .on(
								.credential,
								binding: $store.focusedField.sending(\.view.textFieldFocused),
								to: $focusedField
							)
						)
						.textInputAutocapitalization(.never)
					}
					.padding(.top, .medium3)
					.padding(.horizontal, .large2)
					.padding(.bottom, .medium1)
				}
				.footer {
					Button("Add signaling server") {
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
