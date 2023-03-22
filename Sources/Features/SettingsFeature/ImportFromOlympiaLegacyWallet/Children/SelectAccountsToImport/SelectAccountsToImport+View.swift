import FeaturePrelude

extension SelectAccountsToImport.State {
	var viewState: SelectAccountsToImport.ViewState {
		.init()
	}
}

// MARK: - SelectAccountsToImport.View
extension SelectAccountsToImport {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SelectAccountsToImport>

		public init(store: StoreOf<SelectAccountsToImport>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: SelectAccountsToImport")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SelectAccountsToImport_Preview
struct SelectAccountsToImport_Preview: PreviewProvider {
	static var previews: some View {
		SelectAccountsToImport.View(
			store: .init(
				initialState: .previewValue,
				reducer: SelectAccountsToImport()
			)
		)
	}
}

extension SelectAccountsToImport.State {
	public static let previewValue = Self(scannedAccounts: .init(rawValue: .init(uncheckedUniqueElements: [.previewValue]))!)
}
#endif
