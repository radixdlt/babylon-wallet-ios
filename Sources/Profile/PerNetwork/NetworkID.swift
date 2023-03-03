import Cryptography
import EngineToolkitModels
import Prelude

extension NetworkID {
	public var derivationPathComponentNonHardenedValue: HD.Path.Component.Child.Value { .init(self.rawValue) }
}
