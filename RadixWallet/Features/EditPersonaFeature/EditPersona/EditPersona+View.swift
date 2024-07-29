import ComposableArchitecture
import SwiftUI

extension EditPersona.State {
	var title: String {
		switch mode {
		case .create:
			L10n.CreatePersona.Introduction.title
		case let .edit(persona), let .dapp(persona, _):
			persona.displayName.value
		}
	}

	var saveButtonTitle: String {
		switch mode {
		case .create:
			L10n.CreatePersona.saveAndContinueButtonTitle
		case .edit, .dapp:
			L10n.Common.save
		}
	}

	var description: String {
		switch mode {
		case .create:
			L10n.CreatePersona.Explanation.someDappsMayRequest
		case .edit, .dapp:
			L10n.EditPersona.sharedInformationHeading
		}
	}

	// FIXME: Implement avatar change functionality
	var avatarURL: URL? { nil }

	var addAFieldButtonState: ControlState {
		if alreadyAddedEntryKinds.count < EntryKind.supportedKinds.count {
			.enabled
		} else {
			.disabled
		}
	}

	var output: EditPersona.Output? {
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
	}
}

// MARK: - EditPersona.View
extension EditPersona {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersona>

		public init(store: StoreOf<EditPersona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				switch viewStore.mode {
				case .create:
					content(viewStore)

				case .edit, .dapp:
					NavigationStack {
						content(viewStore)
							.radixToolbar(title: viewStore.title) {
								viewStore.send(.view(.closeButtonTapped))
							}
					}
				}
			}
			.destinations(with: store)
		}

		private func content(_ viewStore: ViewStore<EditPersona.State, EditPersona.Action>) -> some SwiftUI.View {
			ScrollView(showsIndicators: false) {
				VStack(spacing: .large2) {
					if viewStore.mode == .create {
						Text(viewStore.title)
							.foregroundColor(.app.gray1)
							.textStyle(.sheetTitle)
					}

					Thumbnail(.persona, url: viewStore.avatarURL, size: .veryLarge)

					EditPersonaField.View(store: store.labelField)

					VStack(spacing: .medium1) {
						Separator()

						Text(viewStore.description)
							.multilineTextAlignment(.leading)
							.textStyle(.body1HighImportance)
							.foregroundColor(.app.gray2)
							.flushedLeft

						if !viewStore.entries.isEmpty {
							Separator()
							EditPersonaEntries.View(store: store.personaEntries)
								.padding(.top, .medium3)
						}
					}

					Button {
						viewStore.send(.view(.addAFieldButtonTapped))
					} label: {
						Text(L10n.EditPersona.addAField)
							.padding(.horizontal, .medium2)
					}
					.buttonStyle(.secondaryRectangular)
					.controlState(viewStore.addAFieldButtonState)
				}
				.padding(.horizontal, .medium1)
				.padding(.vertical, .medium1)
			}
			.scrollDismissesKeyboard(.interactively)
			.footer {
				WithControlRequirements(
					viewStore.output,
					forAction: { viewStore.send(.view(.saveButtonTapped($0))) }
				) { action in
					Button(viewStore.saveButtonTitle, action: action)
						.buttonStyle(.primaryRectangular)
				}
			}
		}
	}
}

private extension StoreOf<EditPersona> {
	var destination: PresentationStoreOf<EditPersona.Destination> {
		func scopeState(state: State) -> PresentationState<EditPersona.Destination.State> {
			state.$destination
		}
		return scope(state: scopeState, action: Action.destination)
	}

	var labelField: StoreOf<EditPersonaStaticField> {
		scope(state: \.labelField, action: \.child.labelField)
	}

	var personaEntries: StoreOf<EditPersonaEntries> {
		scope(state: \.entries, action: \.child.entries)
	}
}

@MainActor
private extension View {
	func destinations(with store: StoreOf<EditPersona>) -> some View {
		let destinationStore = store.destination
		return closeConfirmationDialog(with: destinationStore)
			.addFields(with: destinationStore)
	}

	private func closeConfirmationDialog(with destinationStore: PresentationStoreOf<EditPersona.Destination>) -> some View {
		confirmationDialog(store: destinationStore.scope(state: \.closeConfirmationDialog, action: \.closeConfirmationDialog))
	}

	private func addFields(with destinationStore: PresentationStoreOf<EditPersona.Destination>) -> some View {
		sheet(store: destinationStore.scope(state: \.addFields, action: \.addFields)) {
			EditPersonaAddEntryKinds.View(store: $0)
		}
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
					mode: .edit(.sample)
				),
				reducer: EditPersona.init
			)
		)
		.previewDisplayName("dApp Mode")

		EditPersona.View(
			store: .init(
				initialState: .previewValue(mode: .edit(.sample)),
				reducer: EditPersona.init
			)
		)
		.previewDisplayName("Edit Mode")
	}
}

extension EditPersona.State {
	public static func previewValue(mode: EditPersona.State.Mode) -> Self {
		.init(mode: mode)
	}
}
#endif
