import FeaturePrelude
import ScanQRFeature

extension ScanMultipleOlympiaQRCodes.State {
	var viewState: ScanMultipleOlympiaQRCodes.ViewState {
		.init()
	}
}

// MARK: - ScanMultipleOlympiaQRCodes.View
extension ScanMultipleOlympiaQRCodes {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ScanMultipleOlympiaQRCodes>

		public init(store: StoreOf<ScanMultipleOlympiaQRCodes>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store.scope(state: \.step)) {
				CaseLet(
					state: /ScanMultipleOlympiaQRCodes.State.Step.scanQR,
					action: { ScanMultipleOlympiaQRCodes.Action.child(.scanQR($0)) },
					then: { ScanQRCoordinator.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ScanMultipleOlympiaQRCodes_Preview
struct ScanMultipleOlympiaQRCodes_Preview: PreviewProvider {
	static var previews: some View {
		ScanMultipleOlympiaQRCodes.View(
			store: .init(
				initialState: .previewValue,
				reducer: ScanMultipleOlympiaQRCodes()
			)
		)
	}
}

extension ScanMultipleOlympiaQRCodes.State {
	public static let previewValue: Self = .init()
}
#endif
