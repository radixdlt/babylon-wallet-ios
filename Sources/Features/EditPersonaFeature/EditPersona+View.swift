import FeaturePrelude

extension EditPersona.State {
	var viewState: EditPersona.ViewState {
		.init(
			isSaveButtonDisabled: {
				var allErrors: [String] = []
				if let labelErrors = labelField.$input.errors {
					allErrors.append(contentsOf: labelErrors)
				}
				let otherErrors = fields.compactMap(\.$input.errors).flatMap { $0 }
				allErrors.append(contentsOf: otherErrors)
				return !allErrors.isEmpty
			}()
		)
	}
}

// MARK: - EditPersonaDetails.View
extension EditPersona {
	public struct ViewState: Equatable {
		let isSaveButtonDisabled: Bool
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersona>

		public init(store: StoreOf<EditPersona>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				NavigationStack {
					ScrollView {
						VStack(alignment: .leading, spacing: .medium1) {
							EditPersonaField.View(
								store: store.scope(
									state: \.labelField,
									action: { .child(.labelField($0)) }
								)
							)

							Separator()

							ForEachStore(
								store.scope(
									state: \.fields,
									action: { .child(.field(id: $0, action: $1)) }
								),
								content: { EditPersonaField.View(store: $0) }
							)
						}
						.padding(.horizontal, .medium1)
						.padding(.vertical, .medium1)
					}
					#if os(iOS)
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							Button("Cancel", action: { viewStore.send(.cancelButtonTapped) })
								.textStyle(.body1Link)
								.foregroundColor(.app.blue2)
						}
						ToolbarItem(placement: .navigationBarTrailing) {
							Button("Save", action: { viewStore.send(.saveButtonTapped) })
								.textStyle(.body1Link)
								.foregroundColor(.app.blue2)
								.disabled(viewStore.isSaveButtonDisabled)
								.opacity(viewStore.isSaveButtonDisabled ? 0.3 : 1)
						}
					}
					#endif
				}
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
				initialState: .previewValue,
				reducer: EditPersona()
			)
		)
	}
}

extension EditPersona.State {
	public static let previewValue = Self(
		mode: .edit,
		personaLabel: NonEmptyString("RadIpsum"),
		existingFields: [
			.init(kind: .givenName, value: "Lorem"),
			.init(kind: .familyName, value: "Ipsum"),
			.init(kind: .emailAddress, value: "lorem.ipsum@example.com"),
			.init(kind: .phoneNumber, value: "555-5555"),
		]
	)
}
#endif
