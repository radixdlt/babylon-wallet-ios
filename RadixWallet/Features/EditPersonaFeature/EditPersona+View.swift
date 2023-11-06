import ComposableArchitecture
import SwiftUI
extension EditPersona.State {
	var viewState: EditPersona.ViewState {
		.init(
			personaLabel: persona.displayName.rawValue,
			avatarURL: URL(string: "something")!,
			// Need to disable, since broken in swiftformat 0.52.7
			// swiftformat:disable redundantClosure
			addAFieldButtonState: {
				if alreadyAddedEntryKinds.count < EntryKind.supportedKinds.count {
					.enabled
				} else {
					.disabled
				}
			}(),
			// swiftformat:enable redundantClosure
			output: { () -> EditPersona.Output? in
				guard
					let personaLabelInput = labelField.input,
					let personaLabelOutput = NonEmptyString(rawValue: personaLabelInput.trimmingWhitespace())
				else {
					return nil
				}

				return EditPersona.Output(
					personaLabel: personaLabelOutput,
					name: entries.name?.content,
					emailAddress: entries.emailAddress?.content,
					phoneNumber: entries.phoneNumber?.content
				)
			}()
		)
	}
}

// MARK: - EditPersonaDetails.View
extension EditPersona {
	public struct ViewState: Equatable {
		let personaLabel: String
		let avatarURL: URL
		let addAFieldButtonState: ControlState
		let output: Output?
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersona>

		public init(store: StoreOf<EditPersona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			NavigationStack {
				WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
					ScrollView(showsIndicators: false) {
						VStack(spacing: .medium1) {
							PersonaThumbnail(viewStore.avatarURL, size: .veryLarge)

							EditPersonaField.View(store: store.labelField)

							Separator()

							// FIXME: Strings
							Text("dApps can request permission from you to share the following fields of information.")
								.multilineTextAlignment(.leading)
								.textStyle(.body1HighImportance)
								.foregroundColor(.app.gray2)

							Separator()

							EditPersonaEntries.View(
								store: store.scope(
									state: \.entries,
									action: (/Action.child .. EditPersona.ChildAction.personaData).embed
								)
							)

							Button(action: { viewStore.send(.addAFieldButtonTapped) }) {
								Text(L10n.EditPersona.addAField).padding(.horizontal, .medium2)
							}
							.buttonStyle(.secondaryRectangular)
							.controlState(viewStore.addAFieldButtonState)
							.padding(.top, .medium2)
						}
						.padding(.horizontal, .medium1)
						.padding(.bottom, .medium1)
					}
					.scrollDismissesKeyboard(.interactively)
					.footer {
						WithControlRequirements(
							viewStore.output,
							forAction: { viewStore.send(.saveButtonTapped($0)) }
						) { action in
							Button(L10n.Common.save, action: action)
								.buttonStyle(.primaryRectangular)
						}
					}
					.navigationTitle(viewStore.personaLabel)
					.navigationBarTitleDisplayMode(.inline)
					.toolbar {
						ToolbarItem(placement: .primaryAction) {
							CloseButton { viewStore.send(.closeButtonTapped) }
						}
					}
				}
				.confirmationDialog(
					store: store.destination,
					state: /EditPersona.Destinations.State.closeConfirmationDialog,
					action: EditPersona.Destinations.Action.closeConfirmationDialog
				)
				.sheet(
					store: store.destination,
					state: /EditPersona.Destinations.State.addFields,
					action: EditPersona.Destinations.Action.addFields,
					content: { EditPersonaAddEntryKinds.View(store: $0) }
				)
			}
		}
	}
}

private extension StoreOf<EditPersona> {
	var destination: PresentationStoreOf<EditPersona.Destinations> {
		scope(state: \.$destination) { .child(.destination($0)) }
	}

	var labelField: StoreOf<EditPersonaStaticField> {
		scope(state: \.labelField) { .child(.labelField($0)) }
	}

	var personaEntries: StoreOf<EditPersonaEntries> {
		scope(state: \.entries) { .child(.entries($0)) }
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - EditPersonaDetails_Preview
struct EditPersona_Preview: PreviewProvider {
	static var previews: some View {
		EditPersona.View(
			store: .init(
				initialState: .previewValue(
					mode: .edit
				),
				reducer: EditPersona.init
			)
		)
		.previewDisplayName("dApp Mode")

		EditPersona.View(
			store: .init(
				initialState: .previewValue(mode: .edit),
				reducer: EditPersona.init
			)
		)
		.previewDisplayName("Edit Mode")
	}
}

extension EditPersona.State {
	public static func previewValue(mode: EditPersona.State.Mode) -> Self {
		.init(
			mode: mode,
			persona: .previewValue0
		)
	}
}
#endif
