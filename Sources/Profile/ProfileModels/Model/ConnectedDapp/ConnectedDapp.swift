import Prelude

// MARK: - OnNetwork.ConnectedDapp
public extension OnNetwork {
	/// A connection made between a Radix Dapp and the user.
	struct ConnectedDapp:
		Sendable,
		Hashable,
		Codable,
		Identifiable,
		CustomStringConvertible,
		CustomDumpReflectable
	{
		/// Dapp component address
		public let address: String
		public let name: String?
	}
}

public extension OnNetwork.ConnectedDapp {
	var id: String {
		address
	}
}

public extension OnNetwork.ConnectedDapp {
	var customDumpMirror: Mirror {
		.init(
			self,
			children: [
				"address": address,
				"name": String(describing: name),
			],
			displayStyle: .struct
		)
	}

	var description: String {
		"""
		address: \(address),
		name: \(String(describing: name)),
		"""
	}
}
