import ClientPrelude
import Cryptography

// MARK: - CreateNewProfileRequest
public struct CreateNewProfileRequest: Sendable {
	public let nameOfFirstAccount: String?

	public init(
		nameOfFirstAccount: String?
	) {
		self.nameOfFirstAccount = nameOfFirstAccount
	}
}
