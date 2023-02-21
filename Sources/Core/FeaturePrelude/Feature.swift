import ComposableArchitecture
import SwiftUI

// MARK: - _FeatureReducer
public protocol _FeatureReducer: ReducerProtocol where State: Sendable & Hashable {
	associatedtype ViewAction: Sendable & Equatable = Never
	associatedtype InternalAction: Sendable & Equatable = Never
	associatedtype ChildAction: Sendable & Equatable = Never
	associatedtype DelegateAction: Sendable & Equatable = Never

	associatedtype View: SwiftUI.View
}

// MARK: - FeatureAction
public enum FeatureAction<
	ViewAction: Sendable & Equatable,
	InternalAction: Sendable & Equatable,
	ChildAction: Sendable & Equatable,
	DelegateAction: Sendable & Equatable
>: Sendable, Equatable {
	case view(ViewAction)
	case `internal`(InternalAction)
	case child(ChildAction)
	case delegate(DelegateAction)
}

public typealias ActionOf<Feature: _FeatureReducer> = FeatureAction<
	Feature.ViewAction,
	Feature.InternalAction,
	Feature.ChildAction,
	Feature.DelegateAction
>

// MARK: - FeatureReducer
public protocol FeatureReducer: _FeatureReducer where Action == ActionOf<Self> {
	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action>
	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action>
	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action>
}

extension ReducerProtocol where Self: FeatureReducer {
	public typealias Action = ActionOf<Self>

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
