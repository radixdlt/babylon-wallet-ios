import Foundation
import Sargon

// MARK: - Sargon.Persona + EntityBaseProtocol
extension Sargon.Persona: EntityBaseProtocol {}

extension PersonaData.Entry.Kind {
	public var title: String {
		switch self {
		case .fullName:
			L10n.AuthorizedDapps.PersonaDetails.fullName
		case .emailAddress:
			"Email Address"
		case .phoneNumber:
			"Phone Number"
		}
	}
}
