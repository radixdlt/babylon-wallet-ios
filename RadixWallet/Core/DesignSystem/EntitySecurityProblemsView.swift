// MARK: - EntitySecurityProblemsView
public struct EntitySecurityProblemsView: SwiftUI.View {
	let config: Config
	let action: () -> Void

	public var body: some View {
		if !config.problems.isEmpty {
			VStack(alignment: .leading, spacing: .small2) {
				ForEach(config.problems) { problem in
					Button(action: action) {
						switch config.kind {
						case .account:
							AccountBannerView(kind: .securityProblem(message: problem.accountCard))
						case .persona:
							WarningErrorView(text: problem.personas, type: .warning, useNarrowSpacing: true)
								.frame(maxWidth: .infinity, alignment: .leading)
								.padding(.bottom, .small3)
						}
					}
				}
			}
		}
	}
}

// MARK: EntitySecurityProblemsView.Config
extension EntitySecurityProblemsView {
	public struct Config: Sendable, Hashable {
		public enum Kind: Sendable, Hashable {
			case account(AccountAddress)
			case persona(IdentityAddress)
		}

		let kind: Kind
		fileprivate(set) var problems: [SecurityProblem] = []

		public init(kind: Kind, problems: [SecurityProblem]) {
			self.kind = kind
			self.problems = problems.filter(kind: kind)
		}

		public mutating func update(problems: [SecurityProblem]) {
			let filtered = problems.filter(kind: kind)
			if self.problems != filtered {
				self.problems = filtered
			}
		}
	}
}

private extension [SecurityProblem] {
	func filter(kind: EntitySecurityProblemsView.Config.Kind) -> Self {
		filter {
			switch $0 {
			case .problem5, .problem6, .problem7:
				true
			case let .problem3(addresses), let .problem9(addresses):
				switch kind {
				case let .account(address):
					addresses.accounts.contains(address) || addresses.hiddenAccounts.contains(address)
				case let .persona(address):
					addresses.personas.contains(address) || addresses.hiddenPersonas.contains(address)
				}
			}
		}
	}
}
