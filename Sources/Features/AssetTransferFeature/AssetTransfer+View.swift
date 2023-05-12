import FeaturePrelude

// MARK: - AssetTransfer.View
// extension AssetTransfer.State {
//	var viewState: AssetTransfer.ViewState {
//		.init()
//	}
// }

extension AssetTransfer {
//	public struct ViewState: Equatable {
//		// TODO: Add
//	}

	@MainActor
	public struct View: SwiftUI.View {
		private let store: StoreOf<AssetTransfer>

		public init(store: StoreOf<AssetTransfer>) {
			self.store = store
		}
	}
}

extension AssetTransfer.View {
	public var body: some View {
		WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
			VStack {
				HStack {
					Text("Transfer").textStyle(.sheetTitle)
					Spacer()
					if viewStore.message == nil {
						Button("Add Message", asset: AssetResource.addMessage) {
							viewStore.send(.addMessageTapped)
						}
						.textStyle(.button)
						.foregroundColor(.app.blue2)
					}
				}
				IfLetStore(
					store.scope(state: \.message, action: { .child(.message($0)) }),
					then: {
						AssetTransferMessage.View(store: $0)
					}
				)
				Spacer()
			}.padding(.horizontal, .medium3)
		}
	}
}

// MARK: - RoundedCorners
public struct RoundedCorners: Shape {
	let radius: CGFloat
	let corners: UIRectCorner

	public init(radius: CGFloat, corners: UIRectCorner = .allCorners) {
		self.radius = radius
		self.corners = corners
	}

	public func path(in rect: CGRect) -> SwiftUI.Path {
		.init(
			UIBezierPath(
				roundedRect: rect,
				byRoundingCorners: corners,
				cornerRadii: .init(width: radius, height: radius)
			).cgPath
		)
	}
}

// extension View {
//        public func bottomRoundedCorners(_ radius: CGFloat) -> some View {
//                clipShape(RoundedCorners(radius: radius, corners: [.bottomLeft, .bottomRight]).stro)
//        }
// }
