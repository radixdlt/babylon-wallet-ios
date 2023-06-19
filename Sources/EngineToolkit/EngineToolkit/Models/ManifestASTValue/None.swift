import CasePaths

// MARK: - None
public struct None: ValueProtocol, Sendable, Codable, Hashable {
	public static let kind: ManifestASTValueKind = .none
	public static var casePath: CasePath<ManifestASTValue, None> = .init(
		embed: { _ in .none },
		extract: {
			if case .none = $0 { return None() }
			return nil
		}
	)
}
