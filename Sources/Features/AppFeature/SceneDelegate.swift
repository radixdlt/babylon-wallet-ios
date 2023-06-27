import UIKit
import FeaturePrelude

public final class SceneDelegate: NSObject, UIWindowSceneDelegate, ObservableObject {
	public weak var windowScene: UIWindowScene?
        public var overlayWindow: UIWindow?

	public func scene(
		_ scene: UIScene,
		willConnectTo session: UISceneSession,
		options connectionOptions: UIScene.ConnectionOptions
	) {
		windowScene = scene as? UIWindowScene
                if let windowScene {
                        overlayWindow(in: windowScene)
                }
	}

        func overlayWindow(in scene: UIWindowScene) {
                let overlayWindow = UIWindow(windowScene: scene)
                overlayWindow.rootViewController = UIHostingController(rootView: OverlayReducer.View(store: .init(initialState: .init(window: overlayWindow), reducer: OverlayReducer())))
                overlayWindow.rootViewController?.view.backgroundColor = .clear
                overlayWindow.windowLevel = .normal + 1
                overlayWindow.isUserInteractionEnabled = false
                overlayWindow.makeKeyAndVisible()

                self.overlayWindow = overlayWindow
        }
}

import SwiftUI

@MainActor
struct OverlayReducer: FeatureReducer {
        struct State: Hashable, Sendable {
                var requestQueue: OrderedSet<BannerClient.Banner> = []

                var isPresenting: Bool {
                        alert != nil || toast != nil
                }

                @PresentationState
                public var alert: Alerts.State?

                public var toast: HUD.State?

                let window: UIWindow

        }

        public struct Alerts: Sendable, ReducerProtocol {
                public typealias State = BannerClient.Banner.AlertState
                public typealias Action = BannerClient.Banner.AlertAction

                public var body: some ReducerProtocolOf<Self> {
                        EmptyReducer()
                }
        }

        enum ViewAction: Equatable {
                case task
                case alert(PresentationAction<Alerts.Action>)
        }

        enum InternalAction: Equatable {
                case scheduleEvent(BannerClient.Banner)
                case showNextEvent
        }

        enum ChildAction: Equatable {
                case hud(HUD.Action)
        }

        @Dependency(\.bannerClient) var bannerClient

        public var body: some ReducerProtocolOf<Self> {
                Reduce(core)
                        .ifLet(\.$alert, action: /Action.view .. ViewAction.alert) {
                                Alerts()
                        }
                        .ifLet(\.toast, action: /Action.child .. ChildAction.hud) {
                                HUD()
                        }
        }


        func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
                switch viewAction {
                case .task:
                        return .run { send in
                                for try await event in await bannerClient.events() {
                                        await send(.internal(.scheduleEvent(event)))
                                }
                        }
                case .alert(.dismiss):
                        state.requestQueue.removeFirst()
                        return setIsUserInteraction(&state, isEnabled: false)
                                .concatenate(with: showEventIfPossible(state: &state))
                case .alert:
                        return .none
                }
        }

        func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
                switch internalAction {
                case let .scheduleEvent(event):
                        state.requestQueue.append(event)
                        return showEventIfPossible(state: &state)
                case .showNextEvent:
                        return showEventIfPossible(state: &state)
                }
        }

        private func showEventIfPossible(state: inout State) -> EffectTask<Action> {
                guard !state.isPresenting, !state.requestQueue.isEmpty else {
                        return .none
                }

                let event = state.requestQueue[0]

                switch event {
                case let .hud(hud):
                        state.toast = .init(content: hud)
                        return .none
                case let .alert(alert):
                        state.alert = alert

                        return setIsUserInteraction(&state, isEnabled: true)
                }
        }

        func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
                switch childAction {
                case .hud(.delegate(.dismiss)):
                        state.toast = nil
                        state.requestQueue.removeFirst()
                        print("toast dismissed")
                        return .run { send in
                               // try await Task.sleep(for: .milliseconds(10))
                                await send(.internal(.showNextEvent))
                        }
                default:
                        return .none
                }
        }

        private func setIsUserInteraction(_ state: inout State, isEnabled: Bool) -> EffectTask<Action> {
                state.window.isUserInteractionEnabled = isEnabled
                return .none
        }
}

extension OverlayReducer {
        struct View: SwiftUI.View {
                private let store: StoreOf<OverlayReducer>

                public init(store: StoreOf<OverlayReducer>) {
                        self.store = store
                }

                var body: some SwiftUI.View {
                        WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
                                IfLetStore(store.scope(
                                        state: \.toast,
                                        action: { .child(.hud($0)) }),
                                           then: {
                                        HUD.View(store: $0)
                                })
                                .task {
                                        viewStore.send(.task)
                                }
                                .alert(
                                        store: store.scope(state: \.$alert, action: { .view(.alert($0))})
                                )
                        }
                }
        }
}

struct HUD: FeatureReducer {
        struct State: Sendable, Hashable {
                let content: BannerClient.Banner.HUD
                var offset: CGFloat = -128.0
                var isPresented: Bool = true
        }

        enum ViewAction: Equatable {
                case tapped
                case onAppear
                case dismissCompleted
        }

        enum DelegateAction: Equatable {
                case dismiss
        }

        enum InternalAction: Equatable {
                case autoDimiss
        }


        func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
                switch viewAction {
                case .tapped:
                        return dismissCapsule(&state)
                case .dismissCompleted:
                        if state.offset == -128 {
                                return .send(.delegate(.dismiss))
                        } else {
                                return scheduleAutoDismiss()
                        }
                case .onAppear:
                        state.offset = 0
                        return .none
                }
        }

        func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
                switch internalAction {
                case .autoDimiss:
                        return dismissCapsule(&state)
                }
        }

        private func scheduleAutoDismiss() -> EffectTask<Action> {
                return .run { send in
                        try await Task.sleep(for: .seconds(1))
                        await send(.internal(.autoDimiss), animation: .spring())
                }
        }

        private func dismissCapsule(_ state: inout State) -> EffectTask<Action> {
                state.offset = -128
                return .none
        }
}

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
                                                        .foregroundColor(.green)
                                                        .frame(.smallest)
                                                Text(viewStore.content.text)
                                                        .foregroundColor(.app.gray1)
                                                        .font(.footnote)
                                        }
                                        .padding(.vertical, .small1)
                                        .padding(.horizontal, .medium3)
                                        .background(
                                                Capsule()
                                                        .foregroundColor(Color.white)
                                                        .shadow(color: Color(.black).opacity(0.16), radius: 12, x: 0, y: 5)
                                        )
                                        .onTapGesture {
                                                viewStore.send(.tapped, animation: .spring())
                                        }
                                        .offset(y: viewStore.offset)
                                        .onAppear {
                                                viewStore.send(.onAppear, animation: .spring())
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


/// An animatable modifier that is used for observing animations for a given animatable value.
struct AnimationCompletionObserverModifier<Value>: AnimatableModifier where Value: VectorArithmetic {

    /// While animating, SwiftUI changes the old input value to the new target value using this property. This value is set to the old value until the animation completes.
    var animatableData: Value {
        didSet {
            notifyCompletionIfFinished()
        }
    }

    /// The target value for which we're observing. This value is directly set once the animation starts. During animation, `animatableData` will hold the oldValue and is only updated to the target value once the animation completes.
    private var targetValue: Value

    /// The completion callback which is called once the animation completes.
    private var completion: () -> Void

    init(observedValue: Value, completion: @escaping () -> Void) {
        self.completion = completion
        self.animatableData = observedValue
        targetValue = observedValue
    }

    /// Verifies whether the current animation is finished and calls the completion callback if true.
    private func notifyCompletionIfFinished() {
        guard animatableData == targetValue else { return }

        /// Dispatching is needed to take the next runloop for the completion callback.
        /// This prevents errors like "Modifying state during view update, this will cause undefined behavior."
        DispatchQueue.main.async {
            self.completion()
        }
    }

    func body(content: Content) -> some View {
        /// We're not really modifying the view so we can directly return the original input value.
        return content
    }
}

extension View {

    /// Calls the completion handler whenever an animation on the given value completes.
    /// - Parameters:
    ///   - value: The value to observe for animations.
    ///   - completion: The completion callback to call once the animation completes.
    /// - Returns: A modified `View` instance with the observer attached.
    func onAnimationCompleted<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) -> ModifiedContent<Self, AnimationCompletionObserverModifier<Value>> {
        return modifier(AnimationCompletionObserverModifier(observedValue: value, completion: completion))
    }
}

