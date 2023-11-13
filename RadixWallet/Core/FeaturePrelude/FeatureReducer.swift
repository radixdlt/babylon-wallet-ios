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
	func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action>
	func reduceDismissedDestination(into state: inout State) -> Effect<Action>

	associatedtype Destination: DestinationReducer = EmptyDestination

	associatedtype ViewState: Equatable = Never
	associatedtype View: SwiftUI.View
}

// MARK: - FeatureAction
public enum FeatureAction<Feature: FeatureReducer>: Sendable, Equatable {
	case destination(PresentationAction<Feature.Destination.Action>)
	case view(Feature.ViewAction)
	case `internal`(Feature.InternalAction)
	case child(Feature.ChildAction)
	case delegate(Feature.DelegateAction)
}

// MARK: - DestinationReducer
public protocol DestinationReducer: Reducer where State: Sendable & Hashable, Action: Sendable & Equatable {}

// MARK: - EmptyDestination
public enum EmptyDestination: DestinationReducer {
	public struct State: Sendable, Hashable {}
	public typealias Action = Never
	public func reduce(into state: inout State, action: Never) -> Effect<Action> {}
	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> { .none }
}

extension Reducer where Self: FeatureReducer {
	public typealias Action = FeatureAction<Self>

	public var body: some ReducerOf<Self> {
		Reduce(core)
	}

	public func core(state: inout State, action: Action) -> Effect<Action> {
		switch action {
		case .destination(.dismiss):
			reduceDismissedDestination(into: &state)
		case let .destination(.presented(presentedAction)):
			reduce(into: &state, presentedAction: presentedAction)
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

	public func reduce(into state: inout State, presentedAction: Destination.Action) -> Effect<Action> {
		.none
	}

	public func reduceDismissedDestination(into state: inout State) -> Effect<Action> {
		.none
	}
}

public typealias PresentationStoreOf<R: Reducer> = Store<PresentationState<R.State>, PresentationAction<R.Action>>

public typealias ViewStoreOf<Feature: FeatureReducer> = ViewStore<Feature.ViewState, Feature.ViewAction>

public typealias StackActionOf<R: Reducer> = StackAction<R.State, R.Action>

// MARK: - FeatureAction + Hashable
extension FeatureAction: Hashable where Feature.Destination.Action: Hashable, Feature.ViewAction: Hashable, Feature.ChildAction: Hashable, Feature.InternalAction: Hashable, Feature.DelegateAction: Hashable {
	public func hash(into hasher: inout Hasher) {
		switch self {
		case let .destination(action):
			hasher.combine(action)
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

extension FeatureReducer {
	func delayedMediumEffect(internal internalAction: InternalAction) -> Effect<Action> {
		self.delayedMediumEffect(for: .internal(internalAction))
	}

	func delayedMediumEffect(
		for action: Action
	) -> Effect<Action> {
		delayedEffect(delay: .seconds(0.6), for: action)
	}

	func delayedShortEffect(
		for action: Action
	) -> Effect<Action> {
		delayedEffect(delay: .seconds(0.3), for: action)
	}

	func delayedEffect(
		delay: Duration,
		for action: Action
	) -> Effect<Action> {
		@Dependency(\.continuousClock) var clock
		return .run { send in
			try await clock.sleep(for: delay)
			await send(action)
		}
	}
}

extension FeatureReducer {
	func exportMnemonic(
		controlling account: Profile.Network.Account,
		notifyIfMissing: Bool = true,
		onSuccess: (SimplePrivateFactorSource) -> Void
	) -> Effect<Action> {
		guard let txSigningFI = account.virtualHierarchicalDeterministicFactorInstances.first(where: { $0.factorSourceID.kind == .device }) else {
			loggerGlobal.notice("Discrepancy, non software account has not mnemonic to export")
			return .none
		}

		return exportMnemonic(
			factorSourceID: txSigningFI.factorSourceID,
			notifyIfMissing: notifyIfMissing,
			onSuccess: onSuccess
		)
	}

	func exportMnemonic(
		factorSourceID: FactorSource.ID.FromHash,
		notifyIfMissing: Bool = true,
		onSuccess: (SimplePrivateFactorSource) -> Void,
		onError: (Swift.Error) -> Void = { error in
			loggerGlobal.error("Failed to load mnemonic to export: \(error)")
		}
	) -> Effect<Action> {
		@Dependency(\.secureStorageClient) var secureStorageClient
		do {
			guard let mnemonicWithPassphrase = try secureStorageClient.loadMnemonic(
				factorSourceID: factorSourceID,
				purpose: .displaySeedPhrase,
				notifyIfMissing: notifyIfMissing
			) else {
				onError(FailedToFindFactorSource())
				return .none
			}

			onSuccess(
				.init(
					mnemonicWithPassphrase: mnemonicWithPassphrase,
					factorSourceID: factorSourceID
				)
			)

		} catch {
			onError(error)
		}
		return .none
	}
}
