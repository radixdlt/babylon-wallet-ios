import ComposableArchitecture
import SwiftUI

// MARK: - FeatureView
public protocol FeatureView: SwiftUI.View where Feature.View == Self {
	associatedtype Feature: FeatureReducer

	@MainActor
	init(store: StoreOf<Feature>)
}

// MARK: - EmptyInitializable
public protocol EmptyInitializable {
	init()
}

// MARK: - FeatureReducer
public protocol FeatureReducer: Reducer where State: Sendable & Hashable, Action == FeatureAction<Self> {
	associatedtype ViewAction: Sendable & Equatable = Never
	associatedtype InternalAction: Sendable & Equatable = Never
	associatedtype ChildAction: Sendable & Equatable = Never
	associatedtype DelegateAction: Sendable & Equatable = Never

	func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action>
	func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action>
	func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action>

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

extension Reducer where Self: FeatureReducer {
	public typealias Action = FeatureAction<Self>

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func core(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case let .view(viewAction):
			reduce(into: &state, viewAction: viewAction)
		case let .internal(internalAction):
			reduce(into: &state, internalAction: internalAction)
		case let .child(childAction):
			reduce(into: &state, childAction: childAction)
		case .delegate:
			.none
		}
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		.none
	}

	public func reduce(into state: inout State, internalAction: InternalAction) -> Effect<Action> {
		.none
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		.none
	}
}

public typealias AlertPresentationStore<AlertAction> = Store<PresentationState<AlertState<AlertAction>>, PresentationAction<AlertAction>>
public typealias PresentationStoreOf<R: Reducer> = Store<PresentationState<R.State>, PresentationAction<R.Action>>

public typealias ViewStoreOf<Feature: FeatureReducer> = ViewStore<Feature.ViewState, Feature.ViewAction>

public typealias StackActionOf<R: Reducer> = StackAction<R.State, R.Action>

// MARK: - FeatureAction + Hashable
extension FeatureAction: Hashable where Feature.ViewAction: Hashable, Feature.ChildAction: Hashable, Feature.InternalAction: Hashable, Feature.DelegateAction: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .view(action):
			hasher.combine(action)
		case let .internal(action):
			hasher.combine(action)
		case let .child(action):
			hasher.combine(action)
		case let .delegate(action):
			hasher.combine(action)
		}
	}
}

/// For scoping to an actionless childstore
public func actionless<T>(never: Never) -> T {}
