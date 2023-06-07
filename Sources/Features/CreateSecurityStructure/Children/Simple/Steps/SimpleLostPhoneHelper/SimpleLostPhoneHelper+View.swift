import AddTrustedContactFactorSourceFeature
import FeaturePrelude

// MARK: - SimpleLostPhoneHelper.View
extension SimpleLostPhoneHelper {
	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<SimpleLostPhoneHelper>

		public init(store: StoreOf<SimpleLostPhoneHelper>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			Color.white
				.sheet(
					store: store.scope(
						state: \.$addTrustedContactFactorSource,
						action: { .child(.addTrustedContactFactorSource($0)) }
					),
					content: { AddTrustedContactFactorSource.View(store: $0) }
				)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - SimpleLostPhoneHelper_Preview
struct SimpleLostPhoneHelper_Preview: PreviewProvider {
	static var previews: some View {
		SimpleLostPhoneHelper.View(
			store: .init(
				initialState: .previewValue,
				reducer: SimpleLostPhoneHelper()
			)
		)
	}
}

extension SimpleLostPhoneHelper.State {
	public static let previewValue = Self()
}
#endif
