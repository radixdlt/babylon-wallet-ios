import Foundation

typealias DepositStatus = DepositStatusPerResource.DepositStatus
typealias DepositStatusPerResources = IdentifiedArrayOf<DepositStatusPerResource>

// MARK: - DepositStatusPerResource
struct DepositStatusPerResource: Sendable, Hashable, Identifiable {
	let resourceAddress: ResourceAddress
	let depositStatus: DepositStatus

	var id: ResourceAddress { resourceAddress }

	enum DepositStatus: Sendable, Hashable {
		/// The deposit of this asset is allowed.
		case allowed

		/// The user needs to provide an additional signature to deposit this asset.
		case additionalSignatureRequired

		/// The user cannot deposit this asset since the receiving acccount has disallowed it.
		case denied
	}
}
