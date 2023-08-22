import FeaturePrelude
import OverlayWindowClient

extension HUD.State {
	var viewState: HUD.ViewState {
		switch content.kind {
		case .copied:
			return .init(
				offset: offset,
				text: "Copied",
				icon: .init(kind: .system("checkmark.circle.fill"), foregroundColor: .app.green1)
			)
		case let .operationSucceeded(message):
			return .init(
				offset: offset,
				text: message,
				icon: .init(kind: .system("checkmark.circle.fill"), foregroundColor: .app.green1)
			)
		}
	}
}

// MARK: - HUD.View
extension HUD {
	struct ViewState: Equatable, Sendable {
		struct Icon: Equatable {
			enum Kind: Equatable {
				case asset(ImageAsset)
				case system(String)
			}

			let kind: Kind
			let foregroundColor: Color
		}

		let offset: Double
		let text: String
		let icon: Icon?
	}

	struct View: SwiftUI.View {
		private let store: StoreOf<HUD>

		public init(store: StoreOf<HUD>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack {
					HStack {
						if let icon = viewStore.icon {
							Group {
								switch icon.kind {
								case let .system(name):
									Image(systemName: name)
								case let .asset(asset):
									Image(asset: asset)
								}
							}
							.foregroundColor(icon.foregroundColor)
							.frame(.smallest)
						}

						Text(viewStore.text)
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
						viewStore.send(.animationCompletion)
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
