import CasePaths
import Prelude

extension PersonaData {
	public struct CreditCard: Sendable, Hashable, Codable, PersonaDataEntryProtocol {
		public static var casePath: CasePath<PersonaData.Entry, Self> = /PersonaData.Entry.creditCard
		public static var kind = PersonaData.Entry.Kind.creditCard

		public struct Expiry: Sendable, Hashable, Codable {
			public let year: Int
			public let month: Int
			public init(year: Int, month: Int) {
				self.year = year
				self.month = month
			}
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
