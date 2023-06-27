import FeaturePrelude
import ScanQRFeature

extension ScanMultipleOlympiaQRCodes.State {
	var viewState: ScanMultipleOlympiaQRCodes.ViewState {
		.init(
			numberOfPayloadsToScan: numberOfPayloadsToScan,
			numberOfPayloadsScanned: scannedPayloads.count
		)
	}
}

// MARK: - ScanMultipleOlympiaQRCodes.View
extension ScanMultipleOlympiaQRCodes {
	public struct ViewState: Equatable {
		public let numberOfPayloadsToScan: Int?
		public let numberOfPayloadsScanned: Int
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ScanMultipleOlympiaQRCodes>

		public init(store: StoreOf<ScanMultipleOlympiaQRCodes>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			VStack {
				WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
					if let numberOfPayloadsToScan = viewStore.numberOfPayloadsToScan {
						Text(L10n.ImportLegacyWallet.scannedLabel(viewStore.numberOfPayloadsScanned, numberOfPayloadsToScan))
					}
				}
				let scanStore = store.scope(state: \.scanQR, action: { .child(.scanQR($0)) })
				ScanQRCoordinator.View(store: scanStore)
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
