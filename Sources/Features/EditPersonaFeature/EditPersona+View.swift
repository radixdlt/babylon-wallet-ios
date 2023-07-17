import FeaturePrelude
import Profile

extension EditPersona.State {
	var viewState: EditPersona.ViewState {
		.init(
			personaLabel: persona.displayName.rawValue,
			avatarURL: URL(string: "something")!,
			addAFieldButtonState: {
				if dynamicFields.count < DynamicFieldID.supportedKinds.count {
					return .enabled
				} else {
					return .disabled
				}
			}(),
			output: { () -> EditPersona.Output? in
				guard
					let personaLabelInput = labelField.input,
					let personaLabelOutput = NonEmptyString(rawValue: personaLabelInput.trimmingWhitespace()),
					let fieldsOutput = fieldsOutput(dynamicFields: dynamicFields)
				else {
					return nil
				}
				return EditPersona.Output(
					personaLabel: personaLabelOutput,
					fields: fieldsOutput
				)
			}()
		)
	}

	func fieldsOutput(
		dynamicFields: IdentifiedArrayOf<EditPersonaDynamicField.State>
	) -> IdentifiedArrayOf<Identified<EditPersonaDynamicField.State.ID, String>>? {
		var fieldsOutput: IdentifiedArrayOf<Identified<EditPersonaDynamicField.State.ID, String>> = []
		for field in dynamicFields {
			guard let fieldInput = field.input else {
				if field.kind == .dynamic(isRequiredByDapp: true) {
					return nil
				} else {
					continue
				}
			}
			let fieldOutput = fieldInput.trimmingWhitespace()
			fieldsOutput[id: field.id] = .init(fieldOutput, id: field.id)
		}

		return fieldsOutput
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

							EditPersonaStaticField.View(
								store: store.scope(
									state: \.labelField,
									action: (/Action.child
										.. EditPersona.ChildAction.labelField
									).embed
								)
							)

							Separator()

							ForEachStore(
								store.scope(
									state: \.dynamicFields,
									action: (/Action.child
										.. EditPersona.ChildAction.dynamicField
									).embed
								),
								content: EditPersonaDynamicField.View.init
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
					#if os(iOS)
					.navigationTitle(viewStore.personaLabel)
					.navigationBarTitleDisplayMode(.inline)
					.toolbar {
						ToolbarItem(placement: .primaryAction) {
							CloseButton { viewStore.send(.closeButtonTapped) }
						}
					}
					#endif
				}
				.sheet(
					store: store.scope(state: \.$destination, action: { .child(.destination($0)) }),
					state: /EditPersona.Destinations.State.addFields,
					action: EditPersona.Destinations.Action.addFields,
					content: { EditPersonaAddFields.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - EditPersonaDetails_Preview
struct EditPersona_Preview: PreviewProvider {
	static var previews: some View {
		EditPersona.View(
			store: .init(
				initialState: .previewValue(
					mode: .edit
				),
				reducer: EditPersona()
			)
		)
		.previewDisplayName("dApp Mode")

		EditPersona.View(
			store: .init(
				initialState: .previewValue(mode: .edit),
				reducer: EditPersona()
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

extension EditPersona.State.DynamicFieldID {
	static var supportedKinds: [Self.Kind] {
		[
			.name,
			.phoneNumber,
			.emailAddress,
		]
	}
}
