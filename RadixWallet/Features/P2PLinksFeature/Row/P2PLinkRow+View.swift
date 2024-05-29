import ComposableArchitecture
import SwiftUI

// MARK: - P2PLink.View
extension P2PLinkRow {
	public struct ViewState: Equatable {
		public let connectionName: String

		init(state: P2PLinkRow.State) {
			connectionName = state.link.displayName
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<P2PLinkRow>

		public init(store: StoreOf<P2PLinkRow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init(state:),
				send: { .view($0) }
			) { viewStore in
				VStack(alignment: .leading, spacing: 2) {
					HStack {
						VStack(alignment: .leading) {
							Text(viewStore.connectionName)
								.foregroundColor(.app.gray1)
								.textStyle(.body1HighImportance)
						}

						Spacer()

						Button(
							action: {
								viewStore.send(.deleteConnectionButtonTapped)
							},
							label: {
								Image(asset: AssetResource.delete)
									.foregroundColor(.app.gray1)
							}
						)
					}
				}
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct P2PLinkRow_Preview: PreviewProvider {
	static var previews: some View {
		P2PLinkRow.View(
			store: .init(
				initialState: .init(link:
					.init(
						connectionPassword: .sample,
						connectionPurpose: .general,
						publicKey: .sample,
						displayName: "Test"
					)
				),
				reducer: P2PLinkRow.init
			)
		)
	}
}
#endif
