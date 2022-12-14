import ComposableArchitecture
import Resources
import SwiftUI

#if os(iOS)
import CodeScanner
#endif // iOS

// MARK: - ScanQR.View
public extension ScanQR {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ScanQR>

		public init(store: StoreOf<ScanQR>) {
			self.store = store
		}
	}
}

public extension ScanQR.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			VStack(alignment: .center, spacing: .large3) {
				contentView(viewStore: viewStore)
				Spacer()
			}
			.padding(.all, .large3)
		}
	}
}

// MARK: Private Views

private extension ScanQR.View {
	@ViewBuilder
	func contentView(
		viewStore: ViewStore<ViewState, ScanQR.Action.ViewAction>
	) -> some View {
		#if os(iOS) && !targetEnvironment(simulator)
		scanQRCode(viewStore: viewStore)
		#else
		macOSInputView(viewStore: viewStore)
		#endif
	}

	@ViewBuilder
	func scanQRCode(
		viewStore: ViewStore<ViewState, ScanQR.Action.ViewAction>
	) -> some View {
		#if os(iOS) && !targetEnvironment(simulator)

		Text(L10n.NewConnection.subtitle)
			.foregroundColor(.app.gray1)
			.textStyle(.body1Regular)

		CodeScannerView(
			codeTypes: [.qr]
		) { response in
			switch response {
			case let .failure(error):
				viewStore.send(.scanResult(.failure(error)))
			case let .success(result):
				viewStore.send(.scanResult(.success(result.string)))
			}
		}
		.aspectRatio(1, contentMode: .fit)
		.cornerRadius(.small2)

		#else
		EmptyView()
		#endif // os(iOS) && !TARGET_OS_SIMULATOR
	}

	@ViewBuilder
	func macOSInputView(viewStore: ViewStore<ViewState, ScanQR.Action.ViewAction>) -> some View {
		#if os(macOS)
		VStack(alignment: .center) {
			Text("Manually input connection password which you can see if you right click and inspect the browser window.")
			TextField(
				"Connection password",
				text: viewStore.binding(
					get: \.connectionPassword,
					send: { .macInputConnectionPasswordChanged($0) }
				)
			)
			.textFieldStyle(.roundedBorder)
			Button("Connect") {
				viewStore.send(.macConnectButtonTapped)
			}
		}
		#else
		EmptyView()
		#endif // macOS
	}
}

// MARK: - ScanQR.View.ViewState
extension ScanQR.View {
	struct ViewState: Equatable {
		#if os(macOS)
		public var connectionPassword: String
		#endif // macOS
		init(state: ScanQR.State) {
			#if os(macOS)
			connectionPassword = state.connectionPassword
			#endif // macOS
		}
	}
}

#if DEBUG

// MARK: - ScanQR_Preview
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
#endif
