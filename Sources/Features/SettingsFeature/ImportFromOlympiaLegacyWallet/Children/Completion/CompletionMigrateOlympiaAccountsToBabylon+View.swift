import AccountsClient
import FeaturePrelude

extension CompletionMigrateOlympiaAccountsToBabylon.State {
	var viewState: CompletionMigrateOlympiaAccountsToBabylon.ViewState {
		.init()
	}
}

// MARK: - CompletionMigrateOlympiaAccountsToBabylon.View
extension CompletionMigrateOlympiaAccountsToBabylon {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<CompletionMigrateOlympiaAccountsToBabylon>

		public init(store: StoreOf<CompletionMigrateOlympiaAccountsToBabylon>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				// TODO: implement
				Text("Implement: CompletionMigrateOlympiaAccountsToBabylon")
					.background(Color.yellow)
					.foregroundColor(.red)
					.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - CompletionMigrateOlympiaAccountsToBabylon_Preview
struct CompletionMigrateOlympiaAccountsToBabylon_Preview: PreviewProvider {
	static var previews: some View {
		CompletionMigrateOlympiaAccountsToBabylon.View(
			store: .init(
				initialState: .previewValue,
				reducer: CompletionMigrateOlympiaAccountsToBabylon()
			)
		)
	}
}

extension CompletionMigrateOlympiaAccountsToBabylon.State {
	public static let previewValue = Self(migratedAccounts: .previewValue)
}

extension MigratedAccounts {
	public static let previewValue: Self = {
		fatalError()
	}()
}
#endif
