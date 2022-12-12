import Common
import ComposableArchitecture
import DesignSystem
import Resources
import SwiftUI

// MARK: - ConnectUsingSecrets.State.Field
public extension ConnectUsingSecrets.State {
	enum Field: String, Sendable, Hashable {
		case connectionName
	}
}

// MARK: - ConnectUsingSecrets.View
public extension ConnectUsingSecrets {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ConnectUsingSecrets>
		@FocusState private var focusedField: ConnectUsingSecrets.State.Field?
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
				if viewStore.isPromptingForName {
					AppTextField(
						placeholder: L10n.NewConnection.textFieldPlaceholder,
						text: viewStore.binding(
							get: \.nameOfConnection,
							send: { .nameOfConnectionChanged($0) }
						),
						hint: L10n.NewConnection.textFieldHint,
						binding: $focusedField,
						equals: .connectionName,
						first: viewStore.binding(
							get: \.focusedField,
							send: { .textFieldFocused($0) }
						)
					)
					.padding(.medium3)

					Spacer()

					Button(L10n.NewConnection.saveNamedConnectionButton) {
						viewStore.send(.confirmNameButtonTapped)
					}
					.controlState(viewStore.isSaveConnectionButtonEnabled ? .enabled : .disabled)
					.buttonStyle(.primaryRectangular)
					.padding(.medium3)
				}
			}
			.isLoading(viewStore.isConnecting, context: .global(text: L10n.NewConnection.connecting))
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
		public var isSaveConnectionButtonEnabled: Bool
		@BindableState public var focusedField: ConnectUsingSecrets.State.Field?

		init(state: ConnectUsingSecrets.State) {
			nameOfConnection = state.nameOfConnection
			isPromptingForName = state.isPromptingForName
			isConnecting = state.isConnecting
			focusedField = state.focusedField
			isSaveConnectionButtonEnabled = state.isNameValid
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
