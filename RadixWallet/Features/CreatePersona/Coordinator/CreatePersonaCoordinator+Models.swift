import ComposableArchitecture
import SwiftUI

// MARK: - PersonaPrimacy
public enum PersonaPrimacy: Sendable, Hashable {
	case first(First)
	case notFirst

	public enum First: Sendable, Hashable {
		case onAnyNetwork
		case justOnCurrentNetwork
	}

	public init(firstOnAnyNetwork: Bool, firstOnCurrent: Bool) {
		switch (firstOnAnyNetwork, firstOnCurrent) {
		case (true, false):
			assertionFailure("Discrepancy")
			fallthrough
		case (true, true):
			self = .first(.onAnyNetwork)
		case (false, false):
			self = .notFirst
		case (false, true):
			self = .first(.justOnCurrentNetwork)
		}
	}

	public var firstPersonaOnCurrentNetwork: Bool {
		switch self {
		case .notFirst: false
		case .first: true
		}
	}

	public var isFirstEver: Bool {
		switch self {
		case .first(.onAnyNetwork): true
		default: false
		}
	}
}

// MARK: - CreatePersonaConfig
public struct CreatePersonaConfig: Sendable, Hashable {
	public let personaPrimacy: PersonaPrimacy

	public let navigationButtonCTA: CreatePersonaNavigationButtonCTA

	public init(
		personaPrimacy: PersonaPrimacy,
		navigationButtonCTA: CreatePersonaNavigationButtonCTA
	) {
		self.personaPrimacy = personaPrimacy
		self.navigationButtonCTA = navigationButtonCTA
	}
}

// MARK: - CreatePersonaNavigationButtonCTA
public enum CreatePersonaNavigationButtonCTA: Sendable, Equatable {
	case goBackToPersonaListInSettings
	case goBackToChoosePersonas
}
