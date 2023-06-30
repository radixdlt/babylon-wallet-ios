import Prelude

// MARK: - AccessController
public struct AccessController: Sendable, Hashable, Codable {
	public struct Address: Sendable, Hashable, Codable {}

	/// On ledger component address
	public let address: Address

	/// Time factor, used e.g. by recovery role, as a countdown until recovery automaticall
	/// goes through.
	public let time: Duration

	public let securityStructure: ProfileSnapshot.AppliedSecurityStructure
}

public typealias AppliedSecurityStructure = AbstractSecurityStructure<FactorInstance>

// MARK: - ProfileSnapshot.AppliedSecurityStructure
extension ProfileSnapshot {
	/// A version of `AppliedSecurityStructure` which only contains IDs of factor sources, suitable for storage in Profile Snapshot.
	public typealias AppliedSecurityStructure = AbstractSecurityStructure<FactorInstance.ID>
}
