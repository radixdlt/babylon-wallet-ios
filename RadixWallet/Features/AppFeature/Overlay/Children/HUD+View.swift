import ComposableArchitecture
import SwiftUI

extension HUD.State {
	var viewState: HUD.ViewState {
		.init(offset: offset, text: content.text, icon: content.icon)
	}
}

// MARK: - HUD.View
extension HUD {
	struct ViewState: Equatable, Sendable {
		let offset: Double
		let text: String
		let icon: OverlayWindowClient.Item.Icon?
	}

	struct View: SwiftUI.View {
		private let store: StoreOf<HUD>

		init(store: StoreOf<HUD>) {
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
							.foregroundColor(.primaryText)
							.font(.footnote)
					}
					.padding(.vertical, .small1)
					.padding(.horizontal, .medium3)
					.background(
						Capsule()
							.foregroundColor(.primaryBackground)
							.shadow(
								color: .primaryText.opacity(0.16),
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

// MARK: - SwiftUI.Animation + @unchecked Sendable
extension SwiftUI.Animation: @unchecked Sendable {}

extension SwiftUI.Animation {
	static var hudAnimation: SwiftUI.Animation {
		.spring()
	}
}
