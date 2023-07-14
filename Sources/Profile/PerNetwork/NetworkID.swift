import Cryptography
import EngineKit
import Prelude

extension NetworkID {
	public var derivationPathComponentNonHardenedValue: HD.Path.Component.Child.Value { .init(self.rawValue) }
}
