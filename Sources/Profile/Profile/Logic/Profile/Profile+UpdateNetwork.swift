import EngineToolkit
import Prelude
import ProfileModels

extension Profile {
	internal mutating func updateOnNetwork(_ onNetwork: OnNetwork) throws {
		try perNetwork.update(onNetwork)
	}
}

extension Profile {
	public func onNetwork(id needle: NetworkID) throws -> OnNetwork {
		try perNetwork.onNetwork(id: needle)
	}

	public func containsNetwork(withID networkID: NetworkID) -> Bool {
		(try? onNetwork(id: networkID)) != nil
	}
}
