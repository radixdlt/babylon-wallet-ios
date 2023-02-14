import ClientPrelude
import UniformTypeIdentifiers

extension UTType {
	// FIXME: should we declare our own file format? For now we use require `.json` file extension.
	public static let profile: Self = .json
}
