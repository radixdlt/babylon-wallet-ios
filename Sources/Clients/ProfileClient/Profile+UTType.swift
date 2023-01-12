import ClientPrelude
import UniformTypeIdentifiers

public extension UTType {
	// FIXME: should we declare our own file format? For now we use require `.json` file extension.
	static let profile: Self = .json
}
