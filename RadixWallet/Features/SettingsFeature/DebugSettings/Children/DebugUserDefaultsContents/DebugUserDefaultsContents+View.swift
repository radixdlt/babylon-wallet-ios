import ComposableArchitecture
import SwiftUI
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
				VStack(alignment: .leading) {
					Form {
						ForEach(viewStore.keyedValues) { keyValue in
							VStack(alignment: .leading) {
								Text("`\(keyValue.key.rawValue)`")
									.textStyle(.body1Header)

								if keyValue.values.isEmpty {
									Text("NO VALUES FOR KEY")
								} else {
									VStack(alignment: .leading) {
										ForEach(keyValue.values, id: \.self) { value in

											HStack(spacing: .small1) {
												Text("*")
												Text("`\"\(value)\"`")
												Spacer(minLength: 0)
											}
											.multilineTextAlignment(.leading)
											.textStyle(.body2Regular)
											.frame(maxWidth: .infinity)
										}
									}
								}
							}
							.frame(maxWidth: .infinity)
						}
					}

					Button("Delete All but Profile.ID") {
						viewStore.send(.removeAllButtonTapped)
					}
					.padding()
					.buttonStyle(.primaryRectangular(isDestructive: true))
				}

				.onAppear {
					viewStore.send(.appeared)
				}
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - DebugUserDefaultsContents_Preview
struct DebugUserDefaultsContents_Preview: PreviewProvider {
	static var previews: some View {
		DebugUserDefaultsContents.View(
			store: .init(
				initialState: .previewValue,
				reducer: DebugUserDefaultsContents.init
			)
		)
	}
}

extension DebugUserDefaultsContents.State {
	public static let previewValue = Self()
}
#endif
