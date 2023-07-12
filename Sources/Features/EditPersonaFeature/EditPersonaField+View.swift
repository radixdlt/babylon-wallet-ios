import FeaturePrelude

extension EditPersonaField {
	public struct ViewState: Equatable {
		let primaryHeading: String
		let secondaryHeading: String?
		@Validation<String, String>
		var input: String?
		let inputHint: Hint?
		#if os(iOS)
		let contentType: UITextContentType?
		let keyboardType: UIKeyboardType
		let capitalization: EquatableTextInputCapitalization?
		#endif
		let isDynamic: Bool
		let canBeDeleted: Bool

		init(state: State) {
			fatalError()
			self.primaryHeading = state.id.title
			#if os(iOS)
			self.capitalization = state.id.capitalization
			self.keyboardType = state.id.keyboardType
			self.contentType = state.id.contentType
			#endif
		}
	}

	public struct View: SwiftUI.View {
		private let store: StoreOf<EditPersonaField>

		public init(store: StoreOf<EditPersonaField>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: ViewState.init(state:), send: { .view($0) }) { _ in
				EmptyView()
			}
		}
	}
}
