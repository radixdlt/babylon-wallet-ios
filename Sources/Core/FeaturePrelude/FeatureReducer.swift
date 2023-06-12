import ComposableArchitecture
import SwiftUI

// MARK: - FeatureView
public protocol FeatureView: SwiftUI.View where Feature.View == Self {
	associatedtype Feature: FeatureReducer

	@MainActor
	init(store: StoreOf<Feature>)
}

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

public typealias AlertPresentationStore<AlertAction> = Store<PresentationState<AlertState<AlertAction>>, PresentationAction<AlertAction>>
public typealias PresentationStoreOf<R: ReducerProtocol> = Store<PresentationState<R.State>, PresentationAction<R.Action>>

public typealias ViewStoreOf<Feature: FeatureReducer> = ViewStore<Feature.ViewState, Feature.ViewAction>
