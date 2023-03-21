import FeaturePrelude
import ScanQRFeature

extension ImportFromOlympiaLegacyWallet.State {
	var viewState: ImportFromOlympiaLegacyWallet.ViewState {
		.init()
	}
}

// MARK: - ImportFromOlympiaLegacyWallet.View
extension ImportFromOlympiaLegacyWallet {
	public struct ViewState: Equatable {
		// TODO: declare some properties
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ImportFromOlympiaLegacyWallet>

		public init(store: StoreOf<ImportFromOlympiaLegacyWallet>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			SwitchStore(store) {
				CaseLet(
					state: /ImportFromOlympiaLegacyWallet.State.scanQR,
					action: { ImportFromOlympiaLegacyWallet.Action.child(.scanQR($0)) },
					then: { ScanQR.View(store: $0) }
				)
			}
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - ImportFromOlympiaLegacyWallet_Preview
struct ImportFromOlympiaLegacyWallet_Preview: PreviewProvider {
	static var previews: some View {
		ImportFromOlympiaLegacyWallet.View(
			store: .init(
				initialState: .previewValue,
				reducer: ImportFromOlympiaLegacyWallet()
			)
		)
	}
}

extension ImportFromOlympiaLegacyWallet.State {
	public static let previewValue: Self = .scanQR(.init())
}
#endif
