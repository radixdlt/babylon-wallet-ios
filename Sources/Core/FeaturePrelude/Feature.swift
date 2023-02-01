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
