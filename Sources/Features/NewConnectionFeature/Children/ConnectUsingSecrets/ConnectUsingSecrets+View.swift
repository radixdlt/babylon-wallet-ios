import ComposableArchitecture
import DesignSystem
import Resources
import SwiftUI

// MARK: - LoadingOverlayView
public struct LoadingOverlayView: View {
	private let text: String?
	public init(_ text: String?) {
		self.text = text
	}

	public var body: some View {
		ZStack {
			Color.app.gray2
				.cornerRadius(.small1)

			VStack {
				LoadingView()
				if let text {
					Text(text)
						.textStyle(.body1Regular)
						.foregroundColor(.app.white)
				}
			}
			.frame(width: 100, height: 100)
		}
		.frame(width: 170, height: 170)
	}
}

#if DEBUG

// MARK: - ConnectUsingPassword_Preview
struct LoadingOverlayView_Preview: PreviewProvider {
	static var previews: some View {
		LoadingOverlayView("Connecting")
	}
}
#endif

// MARK: - ConnectUsingSecrets.View
public extension ConnectUsingSecrets {
	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<ConnectUsingSecrets>

		public init(store: StoreOf<ConnectUsingSecrets>) {
			self.store = store
		}
	}
}

public extension ConnectUsingSecrets.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			LoadingOverlayView(L10n.NewConnection.connecting)
				.onAppear {
					viewStore.send(.appeared)
				}
		}
	}
}

// MARK: - ConnectUsingSecrets.View.ViewState
extension ConnectUsingSecrets.View {
	struct ViewState: Equatable {
		init(state: ConnectUsingSecrets.State) {}
	}
}

#if DEBUG

// MARK: - ConnectUsingPassword_Preview
struct ConnectUsingPassword_Preview: PreviewProvider {
	static var previews: some View {
		ConnectUsingSecrets.View(
			store: .init(
				initialState: .previewValue,
				reducer: ConnectUsingSecrets()
			)
		)
	}
}
#endif
