import ComposableArchitecture
import SwiftUI

// MARK: - FeatureReducer
public protocol FeatureReducer: ReducerProtocol where State: Sendable & Hashable, Action == FeatureAction<Self> {
	associatedtype ViewAction: Sendable & Equatable = Never
	associatedtype InternalAction: Sendable & Equatable = Never
	associatedtype ChildAction: Sendable & Equatable = Never
	associatedtype DelegateAction: Sendable & Equatable = Never

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action>
	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action>
	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action>

	associatedtype ViewState: Equatable = Never
	associatedtype View: SwiftUI.View
}

// MARK: - FeatureAction
public enum FeatureAction<Feature: FeatureReducer>: Sendable, Equatable {
	case view(Feature.ViewAction)
	case `internal`(Feature.InternalAction)
	case child(Feature.ChildAction)
	case delegate(Feature.DelegateAction)
}

extension ReducerProtocol where Self: FeatureReducer {
	public typealias Action = FeatureAction<Self>

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	public func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .view(viewAction):
			return reduce(into: &state, viewAction: viewAction)
		case let .internal(internalAction):
			return reduce(into: &state, internalAction: internalAction)
		case let .child(childAction):
			return reduce(into: &state, childAction: childAction)
		case .delegate:
			return .none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		.none
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		.none
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
		.none
	}
}

public typealias PresentationStoreOf<R: ReducerProtocol> = Store<PresentationStateOf<R>, PresentationActionOf<R>>

// MARK: - FeatureViewState
public protocol FeatureViewState<State>: Equatable {
	associatedtype State
	init(state: State)
}

extension FeatureViewState where Self == State {
	public init(state: State) {
		self = state
	}
}

public typealias ViewStoreOf<Feature: FeatureReducer> = ViewStore<Feature.ViewState, Feature.ViewAction>

extension WithViewStore where Content: View {
	public init<Feature: FeatureReducer>(
		_ store: StoreOf<Feature>,
		content: @escaping (ViewStoreOf<Feature>) -> Content
	) where Feature.ViewState: FeatureViewState<Feature.State>, ViewState == Feature.ViewState, ViewAction == Feature.ViewAction {
		self.init(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) },
			content: content
		)
	}
}
