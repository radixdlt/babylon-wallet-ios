import ComposableArchitecture
import SwiftUI

// MARK: - Feature
public protocol Feature: ReducerProtocol where State: Sendable & Equatable {
	associatedtype ViewAction: Sendable, Equatable
	associatedtype InternalAction: Sendable, Equatable
	associatedtype ChildAction: Sendable, Equatable
	associatedtype DelegateAction: Sendable, Equatable

	associatedtype View: SwiftUI.View
}

// MARK: - AutoFeature
public protocol AutoFeature: Feature where Action == ActionOf<Self> {
	func viewReduce(state: inout State, action: ViewAction) -> EffectTask<Action>
	func internalReduce(state: inout State, action: InternalAction) -> EffectTask<Action>
	func childReduce(state: inout State, action: ChildAction) -> EffectTask<Action>
	func delegateReduce(state: inout State, action: DelegateAction) -> EffectTask<Action>
}

public extension AutoFeature {
	func core(state: inout State, action: Action) -> EffectTask<Action> {
		switch action {
		case let .view(viewAction):
			return viewReduce(state: &state, action: viewAction)
		case let .internal(internalAction):
			return internalReduce(state: &state, action: internalAction)
		case let .child(childAction):
			return childReduce(state: &state, action: childAction)
		case let .delegate(delegateAction):
			return delegateReduce(state: &state, action: delegateAction)
		}
	}

	func viewReduce(state: inout State, action: ViewAction) -> EffectTask<Action> {
		.none
	}

	func internalReduce(state: inout State, action: InternalAction) -> EffectTask<Action> {
		.none
	}

	func childReduce(state: inout State, action: ChildAction) -> EffectTask<Action> {
		.none
	}

	func delegateReduce(state: inout State, action: DelegateAction) -> EffectTask<Action> {
		.none
	}
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

public typealias ActionOf<F: Feature> = FeatureAction<
	F.ViewAction,
	F.InternalAction,
	F.ChildAction,
	F.DelegateAction
>

// MARK: - MyView
struct MyView: View {
	var body: some View {
		Text("")
	}
}

// MARK: - MyFeature
struct MyFeature: AutoFeature {
	typealias View = MyView

	typealias Action = ActionOf<Self>

	enum ViewAction: Sendable, Equatable {
		case listSelectorTapped
		case fungibleTokenList
		case nonFungibleTokenList
	}

	typealias InternalAction = Never
	typealias ChildAction = Never
	typealias DelegateAction = Never

	struct State: Equatable {
		var blabla: String
	}

	public var body: some ReducerProtocolOf<Self> {
		Reduce(core)
	}

	func viewReduce(state: inout State, action: ViewAction) -> EffectTask<Action> {
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
