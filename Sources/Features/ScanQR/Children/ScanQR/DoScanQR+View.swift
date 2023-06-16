import FeaturePrelude

#if os(iOS)
import CodeScanner
#endif // iOS

extension ScanQR.State {
	var viewState: ScanQR.ViewState {
		.init(state: self)
	}
}

// MARK: - ScanQR.View
extension ScanQR {
	public struct ViewState: Equatable {
		public let scanMode: QRScanMode
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
		public var manualQRContent: String
		#endif // macOS
		public let instructions: String
		init(state: ScanQR.State) {
			self.scanMode = state.scanMode
			self.instructions = state.scanInstructions
			#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
			self.manualQRContent = state.manualQRContent
			#endif // macOS
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
					#if os(iOS) && !targetEnvironment(simulator)
					scanQRCode(viewStore: viewStore)
					#else
					macOSInputView(viewStore: viewStore)
					#endif
					Spacer()
				}
				.padding(.all, .large3)
			}
		}
	}
}

// MARK: - QRScanMode
public enum QRScanMode: Sendable, Hashable {
	/// Scan exactly one code, then stop.
	case once

	/// Scan each code no more than once.
	case oncePerCode

	/// Keep scanning all codes until dismissed.
	case continuous

	/// Scan only when capture button is tapped.
	case manual

	public static let `default`: Self = .oncePerCode

	#if os(iOS)
	func forCodeScannerView() -> ScanMode {
		switch self {
		case .continuous: return .continuous
		case .manual: return .manual
		case .oncePerCode: return .oncePerCode
		case .once: return .once
		}
	}
	#endif
}

extension ScanQR.View {
	@ViewBuilder
	private func scanQRCode(
		viewStore: ViewStoreOf<ScanQR>
	) -> some View {
		#if os(iOS) && !targetEnvironment(simulator)

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

		#else
		EmptyView()
		#endif // os(iOS) && !TARGET_OS_SIMULATOR
	}

	@ViewBuilder
	private func macOSInputView(
		viewStore: ViewStoreOf<ScanQR>
	) -> some View {
		#if os(macOS) || (os(iOS) && targetEnvironment(simulator))
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
		#endif // macOS
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

struct ScanQR_Preview: PreviewProvider {
	static var previews: some View {
		ScanQR.View(
			store: .init(
				initialState: .previewValue,
				reducer: ScanQR()
			)
		)
	}
}

extension ScanQR.State {
	public static let previewValue: Self = .init(scanInstructions: "Preview")
}
#endif
