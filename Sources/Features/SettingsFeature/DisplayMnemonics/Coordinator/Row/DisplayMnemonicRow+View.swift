import FeaturePrelude

extension DisplayMnemonicRow.State {
	var viewState: DisplayMnemonicRow.ViewState {
		.init(
			factorSourceID: deviceFactorSource.factorSource.id,
			supportsOlympia: deviceFactorSource.supportsOlympia,
			addedOn: deviceFactorSource
				.addedOn
				.ISO8601Format(.iso8601Date(timeZone: .current))
		)
	}
}

// MARK: - DisplayMnemonicRow.View
extension DisplayMnemonicRow {
	public struct ViewState: Equatable {
		let factorSourceID: FactorSourceID
		let supportsOlympia: Bool
		let addedOn: String
		var olympiaLabelOrEmpty: String {
			guard supportsOlympia else { return "Main seed phrase" }
			return "Legacy seed phrase"
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<DisplayMnemonicRow>

		public init(store: StoreOf<DisplayMnemonicRow>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				Card {
					viewStore.send(.tapped)
				} contents: {
					PlainListRow(title: "\(viewStore.olympiaLabelOrEmpty) added: \(viewStore.addedOn)") {
						EmptyView()
					}
				}
			}
		}
	}
}

// #if DEBUG
// import SwiftUI // NB: necessary for previews to appear
//
//// MARK: - DisplayMnemonicRow_Preview
// struct DisplayMnemonicRow_Preview: PreviewProvider {
//	static var previews: some View {
//		DisplayMnemonicRow.View(
//			store: .init(
//				initialState: .previewValue,
//				reducer: DisplayMnemonicRow()
//			)
//		)
//	}
// }
//
// extension DisplayMnemonicRow.State {
//    public static let previewValue = Self(deviceFactorSource: )
// }
// #endif
