

// MARK: Public
extension ProfileStore {
	/// The current network if any
	public func network() async throws -> Profile.Network {
		try profile.network(id: profile.networkID)
	}

	public var network: Profile.Network? {
		profile.network
	}

	/// A multicasting replaying async sequence of distinct Profile.
	public func values() async -> AnyAsyncSequence<Profile> {
		_lens { $0 }
	}

	/// A multicasting replaying async sequence of distinct Accounts for the currently selected network.
	public func accountValues() async -> AnyAsyncSequence<Profile.Network.Accounts> {
		_lens {
			$0.network?.accounts
		}
	}

	/// A multicasting replaying async sequence of distinct Personas for the currently selected network.
	public func personaValues() -> AnyAsyncSequence<Profile.Network.Personas> {
		_lens {
			$0.network?.personas
		}
	}

	/// A multicasting replaying async sequence of distinct Gateways
	public func currentGatewayValues() async -> AnyAsyncSequence<Radix.Gateway> {
		_lens {
			$0.appPreferences.gateways.current
		}
	}

	/// A multicasting replaying async sequence of distinct Gateways
	public func gatewaysValues() async -> AnyAsyncSequence<Gateways> {
		_lens {
			$0.appPreferences.gateways
		}
	}

	/// A multicasting replaying async sequence of distinct FactorSources
	public func factorSourcesValues() async -> AnyAsyncSequence<FactorSources> {
		_lens {
			$0.factorSources
		}
	}

	@_disfavoredOverload
	private func lens<Property>(
		_ keyPath: KeyPath<Profile, Property?>
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		_lens { $0[keyPath: keyPath] }
	}

	private func lens<Property>(
		_ keyPath: KeyPath<Profile, Property>
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		_lens { $0[keyPath: keyPath] }
	}
}
