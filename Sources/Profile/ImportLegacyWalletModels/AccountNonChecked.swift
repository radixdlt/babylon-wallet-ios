import Prelude

// MARK: - AccountNonChecked
public struct AccountNonChecked: Sendable, Hashable {
	public let accountType: String
	public let pk: String
	public let path: String
	public let name: String?

	public init(accountType: String, pk: String, path: String, name: String?) {
		self.accountType = accountType
		self.pk = pk
		self.path = path
		self.name = name
	}
}
