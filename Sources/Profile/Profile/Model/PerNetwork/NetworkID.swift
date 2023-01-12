import Cryptography
import struct EngineToolkit.NetworkID
import Prelude

public extension NetworkID {
	var derivationPathComponentNonHardenedValue: HD.Path.Component.Child.Value { .init(self.id) }
}
