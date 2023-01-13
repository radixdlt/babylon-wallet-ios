import Cryptography
import EngineToolkitModels
import Prelude

public extension NetworkID {
	var derivationPathComponentNonHardenedValue: HD.Path.Component.Child.Value { .init(self.id) }
}
