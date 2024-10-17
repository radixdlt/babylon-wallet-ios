import ComposableArchitecture
import SwiftUI

// MARK: - PersonaPrimacy
enum PersonaPrimacy: Sendable, Hashable {
	case first(First)
	case notFirst

	enum First: Sendable, Hashable {
		case onAnyNetwork
		case justOnCurrentNetwork
	}

	init(firstOnAnyNetwork: Bool, firstOnCurrent: Bool) {
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

	var firstPersonaOnCurrentNetwork: Bool {
		switch self {
		case .notFirst: false
		case .first: true
		}
	}

	var isFirstEver: Bool {
		switch self {
		case .first(.onAnyNetwork): true
		default: false
		}
	}
}

extension PersonaPrimacy {
	static let firstOnAnyNetwork = Self(firstOnAnyNetwork: true, firstOnCurrent: true)
	static let notFirstOnCurrentNetwork = Self(firstOnAnyNetwork: false, firstOnCurrent: false)
}

// MARK: - CreatePersonaConfig
struct CreatePersonaConfig: Sendable, Hashable {
	let personaPrimacy: PersonaPrimacy

	let navigationButtonCTA: CreatePersonaNavigationButtonCTA

	init(
		personaPrimacy: PersonaPrimacy,
		navigationButtonCTA: CreatePersonaNavigationButtonCTA
	) {
		self.personaPrimacy = personaPrimacy
		self.navigationButtonCTA = navigationButtonCTA
	}
}

// MARK: - CreatePersonaNavigationButtonCTA
enum CreatePersonaNavigationButtonCTA: Sendable, Equatable {
	case goBackToPersonaListInSettings
	case goBackToChoosePersonas
}
