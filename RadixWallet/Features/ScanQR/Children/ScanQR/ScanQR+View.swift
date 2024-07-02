import CodeScanner
import ComposableArchitecture
import SwiftUI

extension ScanQR.State {
	var viewState: ScanQR.ViewState {
		.init(state: self)
	}
}

// MARK: - ScanQR.View
extension ScanQR {
	public struct ViewState: Equatable {
		public let scanMode: Mode
		public let disclosure: Disclosure?
		#if targetEnvironment(simulator)
		public var manualQRContent: String
		#endif // sim
		public let instructions: String
		init(state: ScanQR.State) {
			self.scanMode = state.scanMode
			self.instructions = state.scanInstructions
			self.disclosure = state.disclosure
			#if targetEnvironment(simulator)
			self.manualQRContent = state.manualQRContent
			#endif // sim
		}
	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<ScanQR>

		public init(store: StoreOf<ScanQR>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium1) {
					#if !targetEnvironment(simulator)
					scanQRCode(viewStore: viewStore)
					#else
					simulatorInputView(viewStore: viewStore)
					Spacer()
					#endif
				}
				.padding(.horizontal, .large3)
				.padding(.top, .small2)
				.padding(.bottom, .medium3)
			}
		}
	}
}

extension ScanQR.View {
	@ViewBuilder
	private func scanQRCode(
		viewStore: ViewStoreOf<ScanQR>
	) -> some View {
		#if !targetEnvironment(simulator)

		Text(viewStore.instructions)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
			.multilineTextAlignment(.center)

		CodeScannerView(
			codeTypes: [.qr],
			scanMode: viewStore.scanMode.forCodeScannerView()
		) { response in
			switch response {
			case let .failure(error):
				viewStore.send(.scanned(.failure(error)))
			case let .success(result):
				viewStore.send(.scanned(.success(result.string)))
			}
		}
		.aspectRatio(1, contentMode: .fit)
		.cornerRadius(.small2)

		if let disclosure = viewStore.disclosure {
			bottomView(disclosure)
		} else {
			Spacer()
		}

		#else
		EmptyView()
		#endif // !TARGET_OS_SIMULATOR
	}

	private func bottomView(_ disclosure: ScanQR.Disclosure) -> some View {
		VStack(alignment: .leading, spacing: .small1) {
			Text(disclosure.title)
				.font(.app.body2Header)
				.foregroundColor(.app.gray1)
			VStack(alignment: .leading, spacing: .small3) {
				ForEach(Array(disclosure.items.enumerated()), id: \.0) { index, message in
					HStack(alignment: .top, spacing: .small3) {
						Text("\(index + 1).")
						Text(markdown: message, emphasizedColor: .app.gray1)
					}
					.multilineTextAlignment(.leading)
					.font(.app.body2Regular)
					.foregroundColor(.app.gray1)
				}
			}
		}
	}

	@ViewBuilder
	private func simulatorInputView(
		viewStore: ViewStoreOf<ScanQR>
	) -> some View {
		#if targetEnvironment(simulator)
		VStack(alignment: .center) {
			Text("Manually input QR string content")
			TextField(
				"QR String content",
				text: viewStore.binding(
					get: \.manualQRContent,
					send: { .macInputQRContentChanged($0) }
				)
			)
			.textFieldStyle(.roundedBorder)
			Button("Emulate QR scan") {
				viewStore.send(.macConnectButtonTapped)
			}.buttonStyle(.primaryRectangular)
		}
		#else
		EmptyView()
		#endif // sim
	}
}

private extension ScanQR.Mode {
	func forCodeScannerView() -> ScanMode {
		switch self {
		case .continuous: .continuous
		case .manual: .manual
		case .oncePerCode: .oncePerCode
		case .once: .once
		}
	}
}

private extension ScanQR.Disclosure {
	var title: String {
		switch self {
		case .connector:
			"Don't have the Radix Connector browser extension?"
		}
	}

	var items: [String] {
		switch self {
		case .connector:
			[
				"Go to **wallet.radixdlt.com** in your desktop browser.",
				"Follow the instructions there to install the Radix Connector.",
			]
		}
	}
}

#if DEBUG
import ComposableArchitecture
import SwiftUI

struct ScanQR_Preview: PreviewProvider {
	static var previews: some View {
		ScanQR.View(
			store: .init(
				initialState: .previewValue,
				reducer: ScanQR.init
			)
		)
	}
}

extension ScanQR.State {
	public static let previewValue: Self = .init(scanInstructions: "Preview")
}
#endif
