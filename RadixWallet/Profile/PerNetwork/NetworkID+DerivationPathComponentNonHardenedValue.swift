import EngineToolkit

extension NetworkID {
	public var derivationPathComponentNonHardenedValue: HD.Path.Component.Child.Value { .init(self.rawValue) }
}
