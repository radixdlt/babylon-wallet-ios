import FeaturePrelude

// MARK: - IsFirstPersona
public enum IsFirstPersona: Sendable, Hashable {
	case no
	case yes(FirstPersona)

	public enum FirstPersona: Sendable, Hashable {
		case onAnyNetwork
		case justOnCurrentNetwork
	}

	public init(firstOnAnyNetwork: Bool, firstOnCurrent: Bool) {
		switch (firstOnAnyNetwork, firstOnCurrent) {
		case (true, false):
			assertionFailure("Discrepancy")
			fallthrough
		case (true, true):
			self = .yes(.onAnyNetwork)
		case (false, false):
			self = .no
		case (false, true):
			self = .yes(.justOnCurrentNetwork)
		}
	}

	public var firstPersonaOnCurrentNetwork: Bool {
		switch self {
		case .no: return false
		case .yes: return true
		}
	}

	public var isFirstEver: Bool {
		switch self {
		case .yes(.onAnyNetwork): return true
		default: return false
		}
	}
}

// MARK: - CreatePersonaConfig
public struct CreatePersonaConfig: Sendable, Hashable {
	public let isFirstPersona: IsFirstPersona

	public let navigationButtonCTA: CreatePersonaNavigationButtonCTA

	public init(
		isFirstPersona: IsFirstPersona,
		navigationButtonCTA: CreatePersonaNavigationButtonCTA
	) {
		self.isFirstPersona = isFirstPersona
		self.navigationButtonCTA = navigationButtonCTA
	}
}

// MARK: - CreatePersonaNavigationButtonCTA
public enum CreatePersonaNavigationButtonCTA: Sendable, Equatable {
	case goBackToPersonaListInSettings
	case goBackToChoosePersonas
}
