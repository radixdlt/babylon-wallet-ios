import ComposableArchitecture
import SwiftUI

// MARK: - Persona
public struct PersonaFeature: Sendable, FeatureReducer {
	public struct State: Sendable, Hashable, Identifiable {
		public let id: Persona.ID
		public let thumbnail: URL?
		public let displayName: String
		public var entitySecurityProblems: EntitySecurityProblems.State

		public init(persona: AuthorizedPersonaDetailed) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue,
				identityAddress: persona.identityAddress
			)
		}

		public init(persona: Persona) {
			self.init(
				id: persona.id,
				thumbnail: nil,
				displayName: persona.displayName.rawValue,
				identityAddress: persona.address
			)
		}

		public init(
			id: Persona.ID,
			thumbnail: URL?,
			displayName: String,
			identityAddress: IdentityAddress
		) {
			self.id = id
			self.thumbnail = thumbnail
			self.displayName = displayName
			self.entitySecurityProblems = .init(kind: .persona(identityAddress))
		}
	}

	public enum ViewAction: Sendable, Equatable {
		case tapped
	}

	@CasePathable
	public enum ChildAction: Sendable, Equatable {
		case entitySecurityProblems(EntitySecurityProblems.Action)
	}

	public enum DelegateAction: Sendable, Equatable {
		case openDetails
		case openSecurityCenter
	}

	public init() {}

	public var body: some ReducerOf<Self> {
		Scope(state: \.entitySecurityProblems, action: \.child.entitySecurityProblems) {
			EntitySecurityProblems()
		}
		Reduce(core)
	}

	public func reduce(into state: inout State, viewAction: ViewAction) -> Effect<Action> {
		switch viewAction {
		case .tapped:
			.send(.delegate(.openDetails))
		}
	}

	public func reduce(into state: inout State, childAction: ChildAction) -> Effect<Action> {
		switch childAction {
		case .entitySecurityProblems(.delegate(.openSecurityCenter)):
			.send(.delegate(.openSecurityCenter))
		default:
			.none
		}
	}
}
