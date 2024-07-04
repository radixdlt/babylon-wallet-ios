import CodeScanner
import ComposableArchitecture
import SwiftUI

// MARK: - ScanQR.View
extension ScanQR {
	@MainActor
	public struct View: SwiftUI.View {
		@Perception.Bindable var store: StoreOf<ScanQR>

		public init(store: StoreOf<ScanQR>) {
			self.store = store
		}

		public var body: some SwiftUI.View {
			WithPerceptionTracking {
				VStack(spacing: .medium1) {
					#if !targetEnvironment(simulator)
					scanQRCode
					#else
					simulatorInputView
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
	private var scanQRCode: some View {
		#if !targetEnvironment(simulator)

		Text(store.kind.instructions)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)
			.multilineTextAlignment(.center)

		CodeScannerView(
			codeTypes: [.qr],
			scanMode: store.kind.scanMode
		) { response in
			switch response {
			case let .failure(error):
				store.send(.view(.scanned(.failure(error))))
			case let .success(result):
				store.send(.view(.scanned(.success(result.string))))
			}
		}
		.aspectRatio(1, contentMode: .fit)
		.cornerRadius(.small2)

		if let disclosure = store.kind.disclosure {
			bottomView(disclosure)
		} else {
			Spacer()
		}

		#else
		EmptyView()
		#endif // !TARGET_OS_SIMULATOR
	}

	private func bottomView(_ disclosure: ScanQR.Kind.Disclosure) -> some View {
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
	private var simulatorInputView: some View {
		#if targetEnvironment(simulator)
		VStack(alignment: .center) {
			Text("Manually input QR string content")
			TextField(
				"QR String content",
				text: $store.manualQRContent.sending(\.view.manualQRContentChanged)
			)
			.textFieldStyle(.roundedBorder)
			Button("Emulate QR scan") {
				store.send(.view(.macConnectButtonTapped))
			}.buttonStyle(.primaryRectangular)
		}
		#else
		EmptyView()
		#endif // sim
	}
}

private extension ScanQR.Kind {
	var instructions: String {
		switch self {
		case .connectorExtension: L10n.ScanQR.ConnectorExtension.instructions
		case .account: L10n.ScanQR.Account.instructions
		case .importOlympia: L10n.ScanQR.ImportOlympia.instructions
		}
	}

	var scanMode: ScanMode {
		switch self {
		case .connectorExtension, .account, .importOlympia:
			.oncePerCode
		}
	}

	var disclosure: Disclosure? {
		switch self {
		case .account, .importOlympia:
			nil
		case .connectorExtension:
			.init(
				title: L10n.ScanQR.ConnectorExtension.disclosureTitle,
				items: [
					L10n.ScanQR.ConnectorExtension.disclosureItem1,
					L10n.ScanQR.ConnectorExtension.disclosureItem2,
				]
			)
		}
	}

	struct Disclosure {
		let title: String
		let items: [String]
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
	public static let previewValue: Self = .init(kind: .account)
}
#endif
