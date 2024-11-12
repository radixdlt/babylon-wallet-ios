import ComposableArchitecture
import SwiftUI

extension DebugUserDefaultsContents.State {
	var viewState: DebugUserDefaultsContents.ViewState {
		.init(keyedValues: keyedValues, stringValuesOverTime: stringValuesOverTime)
	}
}

// MARK: - DebugUserDefaultsContents.View
extension DebugUserDefaultsContents {
	struct ViewState: Equatable {
		let keyedValues: IdentifiedArrayOf<DebugUserDefaultsContents.State.KeyValues>
		let stringValuesOverTime: [String]
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<DebugUserDefaultsContents>

		init(store: StoreOf<DebugUserDefaultsContents>) {
			self.store = store
		}

		var body: some SwiftUI.View {
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
					Text("String values over time: #\(viewStore.stringValuesOverTime.count)")
					Button("Delete All but Profile.ID") {
						viewStore.send(.removeAllButtonTapped)
					}
					.padding()
					.buttonStyle(.primaryRectangular(isDestructive: true))
				}
				.task { @MainActor in
					await viewStore.send(.task).finish()
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
	static let previewValue = Self()
}
#endif
