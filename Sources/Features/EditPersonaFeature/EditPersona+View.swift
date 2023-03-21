import FeaturePrelude

extension EditPersona.State {
	var viewState: EditPersona.ViewState {
		.init(
			isSaveButtonDisabled: {
				var allErrors: [String] = []
				if let labelErrors = labelField.$input.errors {
					allErrors.append(contentsOf: labelErrors)
				}
				let dynamicErrors = dynamicFields.compactMap(\.$input.errors).flatMap { $0 }
				allErrors.append(contentsOf: dynamicErrors)
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
							EditPersonaStaticField.View(
								store: store.scope(
									state: \.labelField,
									action: { .child(.labelField($0)) }
								)
							)

							Separator()

							ForEachStore(
								store.scope(
									state: \.dynamicFields,
									action: { .child(.dynamicField(id: $0, action: $1)) }
								),
								content: { EditPersonaDynamicField.View(store: $0) }
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
				initialState: .previewValue(mode: .edit),
				reducer: EditPersona()
			)
		)
		.previewDisplayName("Edit Mode")

		EditPersona.View(
			store: .init(
				initialState: .previewValue(
					mode: .dapp(
						requiredFields: [
							.givenName,
							.emailAddress,
						]
					)
				),
				reducer: EditPersona()
			)
		)
		.previewDisplayName("dApp Mode")
	}
}

extension EditPersona.State {
	public static func previewValue(mode: EditPersona.State.Mode) -> Self {
		.init(
			mode: mode,
			personaLabel: NonEmptyString(rawValue: "RadIpsum")!,
			existingFields: [
				//                .init(kind: .givenName, value: "Lorem"),
				//                .init(kind: .familyName, value: "Ipsum"),
				//                .init(kind: .emailAddress, value: "lorem.ipsum@example.com"),
				//                .init(kind: .phoneNumber, value: "555-5555"),
			]
		)
	}
}
#endif
