import ComposableArchitecture
import SwiftUI

// MARK: - SignalingServerDetails.View
extension SignalingServerDetails {
	@MainActor
	struct View: SwiftUI.View {
		@Perception.Bindable private var store: StoreOf<SignalingServerDetails>
		@FocusState private var focusedField: State.Field?
		@Dependency(\.pasteboardClient) private var pasteboardClient

		init(store: StoreOf<SignalingServerDetails>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithPerceptionTracking {
				ZStack {
					Color.primaryBackground
						.ignoresSafeArea()

					ScrollView {
						VStack(alignment: .leading, spacing: .large2) {
							AppTextField(
								primaryHeading: "Signaling Server Name",
								placeholder: "Profile name",
								text: $store.name.sending(\.view.nameChanged),
								hint: nil,
								focus: .on(
									.name,
									binding: $store.focusedField.sending(\.view.textFieldFocused),
									to: $focusedField
								)
							)
							.disabled(store.isEditMode)

							AppTextField(
								primaryHeading: "Signaling Server URL",
								placeholder: "wss://example-signaling.server",
								text: $store.signalingServer.sending(\.view.signalingServerChanged),
								hint: store.errorHint,
								focus: .on(
									.signalingServer,
									binding: $store.focusedField.sending(\.view.textFieldFocused),
									to: $focusedField
								),
								accessory: {
									if !store.signalingServer.isEmpty {
										Button {
											pasteboardClient.copyString(store.signalingServer)
										} label: {
											Image(asset: AssetResource.copy)
												.frame(.small)
										}
										.accessibilityLabel(L10n.Common.copy)
									}
								}
							)
							.disabled(store.isEditMode)
							.textInputAutocapitalization(.never)
							.keyboardType(.URL)
							.autocorrectionDisabled()

							serverSection(
								title: "STUN Server",
								description: "STUN servers are used to find the public facing IP address of each peer.",
								urls: store.stunURLs,
								onChanged: { id, value in
									store.send(.view(.stunURLChanged(id, value)))
								},
								onDelete: { id in
									store.send(.view(.deleteStunURLTapped(id)))
								},
								onAdd: {
									store.send(.view(.addStunURLTapped))
								},
								canAddMore: store.canAddStunURL
							)

							serverSection(
								title: "TURN Server",
								description: "If STUN servers fail, then a TURN server is used instead as a proxy fallback.",
								urls: store.turnURLs,
								onChanged: { id, value in
									store.send(.view(.turnURLChanged(id, value)))
								},
								onDelete: { id in
									store.send(.view(.deleteTurnURLTapped(id)))
								},
								onAdd: {
									store.send(.view(.addTurnURLTapped))
								},
								canAddMore: store.canAddTurnURL,
								headerFields: {
									AppTextField(
										primaryHeading: "Username",
										placeholder: "TURN username",
										text: $store.turnUsername.sending(\.view.turnUsernameChanged),
										focus: .on(
											.turnUsername,
											binding: $store.focusedField.sending(\.view.textFieldFocused),
											to: $focusedField
										)
									)
									.textInputAutocapitalization(.never)

									AppTextField(
										primaryHeading: "Password",
										placeholder: "TURN password",
										text: $store.turnCredential.sending(\.view.turnCredentialChanged),
										focus: .on(
											.turnCredential,
											binding: $store.focusedField.sending(\.view.textFieldFocused),
											to: $focusedField
										)
									)
									.textInputAutocapitalization(.never)
								}
							)
						}
						.padding(.top, .medium3)
						.padding(.horizontal, .medium3)
						.padding(.bottom, .medium1)
					}
				}
				.radixToolbar(title: "Signaling Server")
				.footer {
					WithPerceptionTracking {
						footer
					}
				}
				.onAppear { store.send(.view(.task)) }
				.alert(store: store.destination.scope(state: \.deleteAlert, action: \.deleteAlert))
			}
		}

		private var footer: some SwiftUI.View {
			VStack(spacing: .small2) {
				Button("Save") {
					store.send(.view(.saveButtonTapped))
				}
				.buttonStyle(.primaryRectangular)
				.controlState(store.saveButtonState)

				if store.isEditMode, !store.isCurrent {
					Button("Change as current") {
						store.send(.view(.changeCurrentTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))

					Button("Delete") {
						store.send(.view(.deleteTapped))
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true, isDestructive: true))
				}
			}
		}

		private func serverSection(
			title: String,
			description: String,
			urls: IdentifiedArrayOf<State.URLFieldState>,
			onChanged: @escaping (UUID, String) -> Void,
			onDelete: @escaping (UUID) -> Void,
			onAdd: @escaping () -> Void,
			canAddMore: Bool,
			@ViewBuilder headerFields: () -> some SwiftUI.View = { EmptyView() }
		) -> some SwiftUI.View {
			VStack(alignment: .leading, spacing: .medium2) {
				Text(title)
					.textStyle(.body1HighImportance)
					.foregroundColor(.primaryText)

				Text(description)
					.textStyle(.body2Regular)
					.foregroundColor(.secondaryText)

				headerFields()

				VStack(alignment: .leading, spacing: .small2) {
					Text("URLs")
						.textStyle(.body2Regular)
						.foregroundColor(.secondaryText)

					ForEach(urls) { field in
						AppTextField(
							placeholder: title == "STUN Server" ? "stun:stun.example.com:19302" : "turn:turn.example.com:80?transport=tcp",
							text: binding(for: field.id, values: urls, onChanged: onChanged),
							accessory: {
								Button {
									onDelete(field.id)
								} label: {
									Image(asset: AssetResource.trash)
										.frame(.small)
								}
							}
						)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					}
				}

				if canAddMore {
					Button("Add URL") {
						onAdd()
					}
					.buttonStyle(.secondaryRectangular(shouldExpand: true))
				}
			}
		}

		private func binding(
			for id: UUID,
			values: IdentifiedArrayOf<State.URLFieldState>,
			onChanged: @escaping (UUID, String) -> Void
		) -> Binding<String> {
			Binding(
				get: { values[id: id]?.value ?? "" },
				set: { onChanged(id, $0) }
			)
		}
	}
}

private extension SignalingServerDetails.State {
	var errorHint: Hint.ViewState? {
		errorText.map(Hint.ViewState.iconError)
	}
}

private extension StoreOf<SignalingServerDetails> {
	var destination: PresentationStoreOf<SignalingServerDetails.Destination> {
		scope(state: \.$destination, action: \.destination)
	}
}
