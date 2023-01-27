import FeaturePrelude

// MARK: - Personas.View
public extension Personas {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<Personas>

		public init(store: StoreOf<Personas>) {
			self.store = store
		}
	}
}

public extension Personas.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack(spacing: .zero) {
					NavigationBar(
						// TODO: implement
						titleText: "Personas",
						leadingItem: BackButton {
							viewStore.send(.dismissButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding([.horizontal, .top], .medium3)

					Separator()

					ScrollView {
						HStack {
							// TODO: implement
							Text("Personas description text")
								.foregroundColor(.app.gray2)
								.textStyle(.body1HighImportance)
								.padding([.horizontal, .top], .medium3)
								.padding(.bottom, .small2)

							Spacer()
						}

						Separator()

						// TODO: implement
						/*
						 VStack(alignment: .leading) {
						 	ForEachStore(
						 		store.scope(
						 			state: \.clients,
						 			action: { .child(.connection(id: $0, action: $1)) }
						 		),
						 		content: {
						 			ManageP2PClient.View(store: $0)
						 				.padding(.medium3)

						 			Separator()
						 		}
						 	)
						 }
						 */

						Button("Create new persona") {
							// TODO: implement
						}
						/*
						 .controlState(viewStore.canAddMoreConnections ? .enabled : .disabled)
						 .buttonStyle(.secondaryRectangular(
						 	shouldExpand: true,
						 	image: .init(asset: AssetResource.qrCodeScanner)
						 ))
						 */
						.padding(.horizontal, .medium3)
						.padding(.vertical, .large1)
					}
				}
			}
		}
	}
}

// MARK: - Personas.View.ViewState
extension Personas.View {
	struct ViewState: Equatable {
		init(state: Personas.State) {
			// TODO: implement
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Personas_Preview
struct Personas_Preview: PreviewProvider {
	static var previews: some View {
		Personas.View(
			store: .init(
				initialState: .previewValue,
				reducer: Personas()
			)
		)
	}
}
#endif
