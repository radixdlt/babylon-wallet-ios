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

public extension ReducerProtocol where Self: FeatureReducer {
	typealias Action = ActionOf<Self>

	var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func core(state: inout State, action: Action) -> EffectTask<Action> {
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

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		.none
	}

	func reduce(into state: inout State, internalAction: InternalAction) -> EffectTask<Action> {
		.none
	}

	func reduce(into state: inout State, childAction: ChildAction) -> EffectTask<Action> {
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

	func reduce(into state: inout State, viewAction: ViewAction) -> EffectTask<Action> {
		switch viewAction {
		case .listSelectorTapped:
			return .none
		case .fungibleTokenList:
			return .none
		case .nonFungibleTokenList:
			return .none
		}
	}
}
