import ComposableArchitecture
import FeaturePrelude
import OverlayWindowClient
import SwiftUI

// MARK: - OverlayReducer.View
extension OverlayReducer {
	struct View: SwiftUI.View {
		private let store: StoreOf<OverlayReducer>

		public init(store: StoreOf<OverlayReducer>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				IfLetStore(
					store.scope(
						state: \.hud,
						action: { .child(.hud($0)) }
					),
					then: { HUD.View(store: $0) }
				)
				.task { viewStore.send(.task) }
				.alert(store: store.scope(state: \.$alert, action: { .view(.alert($0)) }))
			}
		}
	}
}

// MARK: - HUD
struct HUD: FeatureReducer {
	struct State: Sendable, Hashable {
		static let hiddenOffset: CGFloat = -128.0
		static let autoDismissDelay: Double = 1.0

		let content: OverlayWindowClient.Item.HUD
		var offset = Self.hiddenOffset
	}

	enum ViewAction: Equatable {
		case onAppear
		case dismissCompleted
	}

	enum DelegateAction: Equatable {
		case dismiss
	}

	enum InternalAction: Equatable {
		case autoDimiss
	}

	@Dependency(\.continuousClock) var clock

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .dismissCompleted:
			if state.offset == State.hiddenOffset {
				/// Notify the delegate only after the animation did complete.
				return .send(.delegate(.dismiss))
			} else {
				return .run { send in
					try await clock.sleep(for: .seconds(State.autoDismissDelay))
					await send(.internal(.autoDimiss), animation: .hudAnimation)
				}
			}
		case .onAppear:
			state.offset = 0
			return .none
		}
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		switch internalAction {
		case .autoDimiss:
			state.offset = State.hiddenOffset
			return .none
		}
	}
}

// MARK: HUD.View
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
