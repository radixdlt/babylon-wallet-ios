import FeaturePrelude

extension DebugUserDefaultsContents.State {
	var viewState: DebugUserDefaultsContents.ViewState {
		.init(keyedValues: keyedValues)
	}
}

// MARK: - DebugUserDefaultsContents.View
extension DebugUserDefaultsContents {
	public struct ViewState: Equatable {
		public let keyedValues: IdentifiedArrayOf<DebugUserDefaultsContents.State.KeyValues>
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DebugUserDefaultsContents>

		public init(store: StoreOf<DebugUserDefaultsContents>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				ScrollView {
					Form {
						ForEach(viewStore.keyedValues) { keyValue in
							Section("\(keyValue.key.rawValue)") {
								ForEach(keyValue.values, id: \.self) {
									Text("\($0)")
								}
							}
						}
					}
				}
				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - DebugUserDefaultsContents_Preview
struct DebugUserDefaultsContents_Preview: PreviewProvider {
	static var previews: some View {
		DebugUserDefaultsContents.View(
			store: .init(
				initialState: .previewValue,
				reducer: DebugUserDefaultsContents()
			)
		)
	}
}

extension DebugUserDefaultsContents.State {
	public static let previewValue = Self()
}
#endif
