import ComposableArchitecture
import DesignSystem
import Resources
import SwiftUI

// MARK: - ConnectUsingSecrets.View
public extension ConnectUsingSecrets {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ConnectUsingSecrets>

		public init(store: StoreOf<ConnectUsingSecrets>) {
			self.store = store
		}
	}
}

public extension ConnectUsingSecrets.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(alignment: .leading) {
				if viewStore.isConnecting {
					LoadingOverlayView(L10n.NewConnection.connecting)
				} else if viewStore.isPromptingForName {
					Group {
						Text(L10n.NewConnection.nameConnectionInstruction)
							.textStyle(.body1HighImportance)

						TextField(
							L10n.NewConnection.nameConnectionTextFieldHint,
							text: viewStore.binding(
								get: \.nameOfConnection,
								send: { .nameOfConnectionChanged($0) }
							)
						)
						.textFieldStyle(.roundedBorder)

						Button(L10n.NewConnection.saveNamedConnectionButton) {
							viewStore.send(.confirmNameButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
				}
			}
			.padding()
			.onAppear {
				viewStore.send(.appeared)
			}
		}
	}
}

// MARK: - ConnectUsingSecrets.View.ViewState
extension ConnectUsingSecrets.View {
	struct ViewState: Equatable {
		public var isConnecting: Bool
		public var isPromptingForName: Bool
		public var nameOfConnection: String

		init(state: ConnectUsingSecrets.State) {
			nameOfConnection = state.nameOfConnection
			isPromptingForName = state.isPromptingForName
			isConnecting = state.isConnecting
		}
	}
}

#if DEBUG

// MARK: - ConnectUsingPassword_Preview
struct ConnectUsingPassword_Preview: PreviewProvider {
	static var previews: some View {
		ConnectUsingSecrets.View(
			store: .init(
				initialState: .previewValue,
				reducer: ConnectUsingSecrets()
			)
		)
	}
}
#endif
