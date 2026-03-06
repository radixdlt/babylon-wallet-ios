import ComposableArchitecture
import SwiftUI

// MARK: - PersonaPrimacy
enum PersonaPrimacy: Hashable {
	case first(First)
	case notFirst

	enum First: Hashable {
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
struct CreatePersonaConfig: Hashable {
	let personaPrimacy: PersonaPrimacy

	let navigationButtonCTA: CreatePersonaNavigationButtonCTA
}

// MARK: - CreatePersonaNavigationButtonCTA
enum CreatePersonaNavigationButtonCTA: Equatable {
	case goBackToPersonaListInSettings
	case goBackToChoosePersonas
}
