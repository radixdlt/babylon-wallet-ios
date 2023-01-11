import CustomDump
@_exported import struct EngineToolkit.NetworkID
import Foundation
import SLIP10

public extension NetworkID {
	var derivationPathComponentNonHardenedValue: HD.Path.Component.Child.Value { .init(self.id) }
}
