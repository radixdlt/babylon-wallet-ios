import ComposableArchitecture
import SwiftUI

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
	struct ViewState: Equatable {
		let numberOfPayloadsToScan: Int?
		let numberOfPayloadsScanned: Int
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ScanMultipleOlympiaQRCodes>

		init(store: StoreOf<ScanMultipleOlympiaQRCodes>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			VStack(spacing: 0) {
				Text(L10n.ImportOlympiaAccounts.ScanQR.title)
					.textStyle(.sheetTitle)
					.foregroundColor(.primaryText)
					.multilineTextAlignment(.center)
					.padding(.horizontal, .large2)

				WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
					if let numberOfPayloadsToScan = viewStore.numberOfPayloadsToScan, numberOfPayloadsToScan > 1 {
						Text(L10n.ImportOlympiaAccounts.ScanQR.scannedLabel(viewStore.numberOfPayloadsScanned, numberOfPayloadsToScan))
							.padding(.top, .medium1)
					}
				}

				let scanStore = store.scope(state: \.scanQR, action: { .child(.scanQR($0)) })
				ScanQRCoordinator.View(store: scanStore)

				Spacer(minLength: 0)
			}
			.onAppear {
				store.send(.view(.appeared))
			}
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

// MARK: - ScanMultipleOlympiaQRCodes_Preview
struct ScanMultipleOlympiaQRCodes_Preview: PreviewProvider {
	static var previews: some View {
		ScanMultipleOlympiaQRCodes.View(
			store: .init(
				initialState: .previewValue,
				reducer: ScanMultipleOlympiaQRCodes.init
			)
		)
	}
}

extension ScanMultipleOlympiaQRCodes.State {
	static let previewValue: Self = .init()
}
#endif
