import EngineToolkitimport EngineToolkit

// MARK: - PersonaDataEntryProtocol
public protocol PersonaDataEntryProtocol: BasePersonaDataEntryProtocol {
	static var casePath: CasePath<PersonaData.Entry, Self> { get }
	static var kind: PersonaData.Entry.Kind { get }
}

extension PersonaDataEntryProtocol {
	public var kind: PersonaData.Entry.Kind { Self.kind }
	public var casePath: CasePath<PersonaData.Entry, Self> { Self.casePath }

	public func embed() -> PersonaData.Entry {
		casePath.embed(self)
	}

	public static func extract(from fieldValue: PersonaData.Entry) -> Self? {
		casePath.extract(from: fieldValue)
	}
}
