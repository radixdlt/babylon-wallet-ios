import FeaturePrelude

// MARK: - HUD.View
extension HUD {
	struct View: SwiftUI.View {
		private let store: StoreOf<HUD>

		public init(store: StoreOf<HUD>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack {
					HStack {
						Image(systemName: "checkmark.circle.fill")
							.foregroundColor(.app.green1)
							.frame(.smallest)

						Text(viewStore.content.text)
							.foregroundColor(.app.gray1)
							.font(.footnote)
					}
					.padding(.vertical, .small1)
					.padding(.horizontal, .medium3)
					.background(
						Capsule()
							.foregroundColor(.app.background)
							.shadow(
								color: .app.gray1.opacity(0.16),
								radius: 12,
								x: 0,
								y: 5
							)
					)
					.offset(y: viewStore.offset)
					.onAppear {
						viewStore.send(.onAppear, animation: .hudAnimation)
					}
					.onAnimationCompleted(for: viewStore.offset) {
						viewStore.send(.dismissCompleted)
					}

					Spacer()
				}
			}
		}
	}
}

// MARK: - SwiftUI.Animation + Sendable
extension SwiftUI.Animation: @unchecked Sendable {}

extension SwiftUI.Animation {
	static var hudAnimation: SwiftUI.Animation {
		.spring()
	}
}
