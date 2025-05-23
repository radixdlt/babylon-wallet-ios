// MARK: - DAppsDirectoryClient + DependencyKey
extension DAppsDirectoryClient: DependencyKey {
	public typealias Value = DAppsDirectoryClient
	static let endpoint = URL(string: "https://dapps-list.radixdlt.com/list")!

	public static let liveValue = {
		@Dependency(\.httpClient) var httpClient
		@Dependency(\.cacheClient) var cacheClient

		@Sendable
		func fetchDAppsFromRemote() async throws -> CategorizedDApps {
			let request = URLRequest(url: endpoint)
			let data = try await httpClient.executeRequest(request)
			return try JSONDecoder().decode(CategorizedDApps.self, from: data)
		}

		@Sendable
		func fetchdDApps() async throws -> DApps {
			try await cacheClient.withCaching(cacheEntry: .dAppsDirectory, request: fetchDAppsFromRemote).allDApps
		}

		return Self(fetchDApps: fetchdDApps)
	}()
}

extension DAppsDirectoryClient.CategorizedDApps {
	var allDApps: DAppsDirectoryClient.DApps {
		highlighted.shuffled() + others
	}
}

// extension DAppsDirectoryClient {
//	static let mockDApps: IdentifiedArrayOf<DApp> =
//		[
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12yrjl8m5a4cn9aap2ez2lmvw6g64zgyqnlj4gvugzstye4gnj6assc"),
//				tags: [.defi, .dex, .token, .trade]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12x2ecj3kp4mhq9u34xrdh7njzyz0ewcz4szv0jw5jksxxssnjh7z6z"),
//				tags: [.defi, .dex]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx128s5u7yqc7p5rw6k7xcq2ug9vz0k2zc94zytaw9s67hxre34e2k5sk"),
//				tags: [.marketplace, .nfts, .trade]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12ykkpf2v0f3hdqtez9yjhyt04u5ct455aqkq5scd5hlecwf20hcvd2"),
//				tags: [.lending]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx16x9mmsy3gasxrn7d2jey6cnzflk8a5w24fghjg082xqa3ncgxjqct3"),
//				tags: [.tools]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12yn43ckkkre9un54424nvck48vf70cgyq8np4ajsrwkc9q3m20ndmd"),
//				tags: [.defi, .dex]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx128ku70k3nxy9q0ekcwtwucdwm5jt80xsmxnqm5pfqj2dyjswgh3rm3"),
//				tags: [.lending]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12yctqxnlfqjyn68hrtnxjxkqcvs6hcg4sa6fnst9gfkpruzfeanjke"),
//				tags: [.marketplace, .tools]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx1280jw5unz0w3ktmrfpenym6fjxfs7gqedf2rsyqnsgc888ue66ktwl"),
//				tags: [.token]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12xtayjlrzs0d9rga27w48256d98ycgrpde6yrqpmavmyrr0e4svsqy"),
//				tags: [.defi, .tools]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx129f39fsvwt07jlwqhc0pyew8vnh4xxtpxdgz0t9vcyfn07j0jdulrc"),
//				tags: [.defi, .lending]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx129vf97vuy4lwcz23gezjhvcflsx5mvfcaqqgy8keunfmfj3kkhhk2f"),
//				tags: [.marketplace]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12xx94vq4egddx308gg4tkd793yhcsruxyfwrdnxthkt0qfmt6lqhju"),
//				tags: [.defi, .dex]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12yx3x8fh577ua33hve4r8mw94k6f6chh2mkgfjypm4yht986ns0xep"),
//				tags: [.marketplace, .nfts]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx128y905cfjwhah5nm8mpx5jnlkshmlamfdd92qnqpy6pgk428qlqxcf"),
//				tags: [.defi, .dex, .token]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx16x5l69u3cpuy59g8n0g7xpv3u3dfmxcgvj8t7y2ukvkjn8pjz2v492"),
//				tags: [.dashboard, .tools]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx129jet2tlflnxh2l4dhuusdq43s2lmarznw7392rh3dud4560qg6jc2"),
//				tags: [.marketplace, .nfts]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12840cvuphs90sfzapuuxsu45qx5nalv9p5m43u6nsu4nwwtlvk7r9t"),
//				tags: [.dashboard, .tools]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx128m799c5dketq0v07kqukamuxy6zfca0vqttyjj5av6gcdhlkwpy2r"),
//				tags: [.defi]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx16xz467phhcv969yutwqxv7acy9n2q5ml7hdngfwa5f3vtnldclz49d"),
//				tags: [.tools]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx168qrzyngejus9nazhp7rw9z3qn2r7uk3ny89m5lwvl299ayv87vpn5"),
//				tags: [.defi, .dex]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12x2a5dft0gszufcce98ersqvsd8qr5kzku968jd50n8w4qyl9awecr"),
//				tags: [.defi, .dex]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx168r05zkmtvruvqfm4rfmgnpvhw8a47h6ln7vl3rgmyrlzmfvdlfgcg"),
//				tags: [.defi, .lending]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12xgr6cx4w85nc7655p6mcgtu8h03qukyz8gymlhe8vg9zddf52y5qp"),
//				tags: [.tools]
//			),
//			DApp(
//				address: try! .init(validatingAddress: "account_rdx12xkthp8p9k4v3ew0hg8d7v3afr3w3a5wllx29u98nsgz3jwt08u2y6"),
//				tags: [.token]
//			),
//		]
//		.asIdentified()
// }
