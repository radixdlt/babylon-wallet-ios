import EngineToolkit
import Prelude

extension Profile {
	internal mutating func updateOnNetwork(_ onNetwork: OnNetwork) throws {
		try perNetwork.update(onNetwork)
	}
}

extension Profile {
	/// The current network with a non empty set of accounts.
	public var network: OnNetwork {
		do {
			return try onNetwork(id: self.appPreferences.gateways.current.network.id)
		} catch {
			let errorMsg = "Critical error, `self.appPreferences.gateways.current.network.id` not found in `self.perNetwork`, indication of incorrect implementation of Profile. We have probably forgot to add the network that was added to `appPreferences.gateways` into `perNetwork`. Failure: \(String(describing: error))"
			loggerGlobal.critical(.init(stringLiteral: errorMsg))
			fatalError(errorMsg)
		}
	}

	public func onNetwork(id needle: NetworkID) throws -> OnNetwork {
		try perNetwork.onNetwork(id: needle)
	}

	public func containsNetwork(withID networkID: NetworkID) -> Bool {
		(try? onNetwork(id: networkID)) != nil
	}
}
