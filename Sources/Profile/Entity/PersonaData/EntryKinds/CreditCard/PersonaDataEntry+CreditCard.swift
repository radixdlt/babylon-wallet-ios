import CasePaths
import Prelude

extension PersonaDataEntry {
	public struct CreditCard: Sendable, Hashable, Codable, PersonaFieldValueProtocol {
		public static var casePath: CasePath<PersonaDataEntry, Self> = /PersonaDataEntry.creditCard
		public static var kind = PersonaFieldKind.creditCard

		public struct Expiry: Sendable, Hashable, Codable {
			public let year: Int
			public let month: Int
		}

		/// Year/Month when card expires
		public let expiry: Expiry

		/// Name of card holder
		public let holder: String

		/// The credit card number
		public let number: String

		/// CVV / CSC
		public let cvc: Int

		public init(expiry: Expiry, holder: String, number: String, cvc: Int) {
			self.expiry = expiry
			self.holder = holder
			self.number = number
			self.cvc = cvc
		}
	}
}
