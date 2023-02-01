import ComposableArchitecture
import SwiftUI

// MARK: - _FeatureReducer
public protocol _FeatureReducer: ReducerProtocol where State: Sendable & Equatable {
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

public typealias ActionOf<F: _FeatureReducer> = FeatureAction<
	F.ViewAction,
	F.InternalAction,
	F.ChildAction,
	F.DelegateAction
>

// MARK: - FeatureReducer
public protocol FeatureReducer: _FeatureReducer where Action == ActionOf<Self> {
	func reduceView(into state: inout State, action: ViewAction) -> EffectTask<Action>
	func reduceInternal(into state: inout State, action: InternalAction) -> EffectTask<Action>
	func reduceChild(into state: inout State, action: ChildAction) -> EffectTask<Action>
}

public extension FeatureReducer {
	typealias Action = ActionOf<Self>

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .view(viewAction):
			return reduceView(into: &state, action: viewAction)
		case let .internal(internalAction):
			return reduceInternal(into: &state, action: internalAction)
		case let .child(childAction):
			return reduceChild(into: &state, action: childAction)
		case .delegate:
			return .none
		}
	}

	func reduceView(into state: inout State, action: ViewAction) -> EffectTask<Action> {
		.none
	}

	func reduceInternal(into state: inout State, action: InternalAction) -> EffectTask<Action> {
		.none
	}

	func reduceChild(into state: inout State, action: ChildAction) -> EffectTask<Action> {
		.none
	}
}

// MARK: - MyView
struct MyView: View {
	var body: some View {
		Text("")
	}
}

// MARK: - MyFeature
struct MyFeature: FeatureReducer {
	typealias View = MyView

	enum ViewAction: Sendable, Equatable {
		case listSelectorTapped
		case fungibleTokenList
		case nonFungibleTokenList
	}

	struct State: Equatable {
		var blabla: String
	}

	func reduceView(into state: inout State, action: ViewAction) -> EffectTask<Action> {
		switch action {
		case .listSelectorTapped:
			return .none
		case .fungibleTokenList:
			return .none
		case .nonFungibleTokenList:
			return .none
		}
	}
}
