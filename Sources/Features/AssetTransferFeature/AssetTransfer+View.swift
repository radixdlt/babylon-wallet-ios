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
			ScrollView {
				VStack(spacing: .medium3) {
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

					VStack(alignment: .trailing, spacing: .zero) {
						VStack(spacing: .small2) {
							Text("From")
								.sectionHeading
								.textCase(.uppercase)
								.flushedLeft(padding: .medium3)
							SmallAccountCard(
								viewStore.fromAccount.displayName.rawValue,
								identifiable: .address(.account(viewStore.fromAccount.address)),
								gradient: .init(viewStore.fromAccount.appearanceID)
							)
							.cornerRadius(.small1)
						}

						Text("To")
							.sectionHeading
							.textCase(.uppercase)
							.flushedLeft(padding: .medium3)
							.padding(.bottom, .small2)
							.frame(height: 64, alignment: .bottom)
							.background(alignment: .trailing) {
								VLine()
									.stroke(.app.gray3, style: .transactionReview)
									.frame(width: 1)
									.padding(.trailing, SpeechbubbleShape.triangleInset)
							}
						VStack(spacing: .medium3) {
							ForEachStore(
								store.scope(state: \.toAccounts, action: { .child(.toAccountTransfer(id: $0, action: $1)) }),
								content: { ToAccountTransfer.View(store: $0) }
							)
						}
					}
					Button("Add Account", asset: AssetResource.addAccount) {
						viewStore.send(.addAccountTapped)
					}
					.textStyle(.button)
					.foregroundColor(.app.blue2)
					.flushedRight
					Spacer()
				}.padding(.horizontal, .medium3)
			}
		}
	}
}

// MARK: - VLine
struct VLine: Shape {
	func path(in rect: CGRect) -> SwiftUI.Path {
		SwiftUI.Path { path in
			path.move(to: .init(x: rect.midX, y: rect.minY))
			path.addLine(to: .init(x: rect.midX, y: rect.maxY))
		}
	}
}

// MARK: - FixedSpacer
public struct FixedSpacer: View {
	let width: CGFloat
	let height: CGFloat

	public init(width: CGFloat = 1, height: CGFloat = 1) {
		self.width = width
		self.height = height
	}

	public var body: some View {
		Rectangle()
			.fill(.clear)
			.frame(width: width, height: height)
	}
}

extension StrokeStyle {
	static let transactionReview = StrokeStyle(lineWidth: 2, dash: [5, 5])
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
