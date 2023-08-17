import Cryptography
@testable import Profile
import TestingPrelude

extension EncryptedProfileSnapshot {
	public static func encrypt(snapshot: ProfileSnapshot, password: String) throws -> Self {
		let snapshotJSON = try JSONEncoder.iso8601.encode(snapshot)
		let kdfScheme = PasswordBasedKeyDerivationScheme.default
		let encryptionKey = kdfScheme.kdf(password: password)
		let encryptionScheme = EncryptionScheme.default
		let cipher = try encryptionScheme.encrypt(data: snapshotJSON, encryptionKey: encryptionKey)
		return Self(encryptedSnapshot: .init(data: cipher), keyDerivationScheme: kdfScheme, encryptionScheme: encryptionScheme)
	}
}

// MARK: - EncryptedProfileTests
final class EncryptedProfileTests: TestCase {
	func test_decode_and_decrypt() throws {
		let encryptedSnapshot = try JSONDecoder().decode(EncryptedProfileSnapshot.self, from: encryptedSnapshotJSON)
		XCTAssertEqual(encryptedSnapshot.encryptionScheme, .version1)
		XCTAssertEqual(encryptedSnapshot.keyDerivationScheme, .version1)
		let decrypted = try encryptedSnapshot.decrypt(password: "foo")
		XCTAssertEqual(decrypted.factorSources.first.kind, .device)
	}

	func test_roundtrip() throws {
		let curve25519FactorSourceMnemonic = try Mnemonic(
			phrase: "bright club bacon dinner achieve pull grid save ramp cereal blush woman humble limb repeat video sudden possible story mask neutral prize goose mandate",
			language: .english
		)
		let profile = try withDependencies {
			$0.date = .constant(stableDate)
			$0.uuid = .constant(stableUUID)
		} operation: {
			let babylonFactorSource = try DeviceFactorSource.babylon(
				mnemonic: curve25519FactorSourceMnemonic,
				model: deviceFactorModel,
				name: deviceFactorName,
				addedOn: stableDate
			)

			let profile = Profile(
				header: snapshotHeader,
				deviceFactorSource: babylonFactorSource,
				appPreferences: .init(gateways: .init(current: .default))
			)

			return profile
		}

		let password = "super secret"
		let encrypted = try EncryptedProfileSnapshot.encrypt(snapshot: profile.snapshot(), password: password)
		let decrypted = try encrypted.decrypt(password: password)
		XCTAssertEqual(decrypted, profile.snapshot())
	}
}

private let deviceFactorModel: DeviceFactorSource.Hint.Model = "computer"
private let deviceFactorName: String = "unit test"
private let creatingDevice: NonEmptyString = "\(deviceFactorModel) \(deviceFactorName)"
private let stableDate = Date(timeIntervalSince1970: 0)
private let stableUUID = UUID(uuidString: "BABE1442-3C98-41FF-AFB0-D0F5829B020D")!
private let device: ProfileSnapshot.Header.UsedDeviceInfo = .init(description: creatingDevice, id: stableUUID, date: stableDate)
private let snapshotHeader = ProfileSnapshot.Header(
	creatingDevice: device,
	lastUsedOnDevice: device,
	id: stableUUID,
	lastModified: stableDate,
	contentHint: .init(
		numberOfAccountsOnAllNetworksInTotal: 6,
		numberOfPersonasOnAllNetworksInTotal: 3,
		numberOfNetworks: 2
	),
	snapshotVersion: .minimum
)

let encryptedSnapshotJSON = """
{"encryptionScheme":{"version":1,"description":"AESGCM-256"},"encryptedSnapshot":"449dccb064852ff611f6c0aac8d5027b0ef8d892d04c61970d76f664a5b8d69c7616e858db628521be345ab66386ca8fdb75a10d524a0891fbb312804835425c9d5d792052aa0118df88233dd6694ca3b05a837f19728ea66bd65c0b52a4ee2db2b8f370ea711e6bbb2b9c1999c5174ef94a8a9d91085b2becd1efd328cb89a46fa7c22e0836cead88e3965f34883371f886075ae389cc66f28fbd707c69cb45c918d26e15d43f78e284ac3d41fa21bfd1e661e298c8c235baf9ca2fed6a473e7957ab2c56ee22acf139a426ea6b4c268083b4f820542dcfcab55fccf9d912b91fb9e4c07efcea8c208f48917542c4febe25153b97d8fe48bab988ae7aa519b863db66de370050b0f845b42d37f21ad408831734d942615dadb4cf43fca85ece78b4cd87787f9b75a5b28a650b3d074bc3ca2c0e998b153a112c7154d834445973cabd7b861ee19260a4cd5f85fab9416c57c0deb02c3161a0a78d2c197ad2d5b8eb8fe2ad32ac17c857dbdc510eb89fbf51899ae516c08f26b89c0aa3e923008436695857eb1ac7046be659c7f5a1b16a3fa167b4b10a2de4339c742e3d7408244bcbb2154baa2cf8a1a7b0730bf56a810824acda2d2daaaadaa126889424aebf9296c2179e215b7886418d93e1bd5a739780e04dd0bf993c377e04c8faa765c9971a4437d4284d6302e39b0b4b3421b7cb1168cd68e3a9d5357a1bd6564db37adc56103ed65c7aad46a72cf86ad6bba9bee3e98f1bf035e708f853e2f1ce5f62897b2a5ebb448e2aedbea75727c42b5fd124d9fa3ade0e0c721e79aebfc9cd04707e5c06201ba3565316733159ae6f87041af06f28d67a28a8df553a968ba521eb164aded672ffac7d08a55d9cc1dd38c44c7734f9824076484923c8ed98132ccd5ea7c98a5a448ecb1869bce4683f1c6a4fdbebbbe99d5ba0f45fcf837d004b1c239504e7817704e6d0d1537d13484d405b954cb0d6da56ce9addfaf31c7517f657400fa1d0746940134aff4b8cbf7d6f68f43f0a6ec37d60279a337842a7bfeaadec097aa9c0f3ae7d0d249e2a796d4ff870a3b09b35726c4a5519f22c82b3dfaad0204529846b7a8c266a8da1e74fc8e83b762565d3288d21f7420efe5ad89f223835440e9e1dea1be419d30d4a38928e44c21619bae18f75c3e7a5ef488a26b6995762032c945373936383997363f260ac88a53aef3258fb514e426fd308d93dc68c55ecdcfa88ccf9ac30e9bdf5e93e8cc960fc294b91a41b98d1564db5dc1b2aca7ed604c35bf99b9e496143788bfc3ba401f7d5b15779231936b2e58a21b592fc7327b92d78283ee943808a1d8088ab7d2e0d416202d433f4af23ce469112727408f163913e7860e4086cf8abd212853117ef959dd79a63af5aaa3bb6af4ae5de6f2ddcab45008d23cfafd89342a44fa5a8345b801866ff68885d8721b1b0209b7a92ed2f1f7ec0fb06ea0414e27e46f5e945d17cb4da9ea1a879af1f30cb74ef13401da8232f4912423a62d7b28b0e93b27ec91d0983035ad303fd07318926f8c9f90bb02de45fec581184ce8b0c5217451e2d2d2d77d924df80bfd6cf65cbf95553cbe26b78370f855067f66cbb557ecac48995e57029c0c7d66de1a3e642fe09588611613b6350dec926dfe0d3525d2a5f077818d9b67b771264944ea74c0c11b9f23ee228f5da7a43b295c14efb1f73f04a6562f0ddc7caf03ddf6194074c8c3d1731af6c821899f26cccd43fe4c605e2bfedbf9bc228fe737f3a32768b5cf76c4e18d1a466684a86ca252395d6e269bd80fdf6d864fa8d474e9bf6f34669f46e874363cfe2f6a91bf8fdd559ae49fbd10cc6fd29de596ef0e6348eb4e4af7229b379292434106967499ff0ee8557f26727f2467d7aa7bcb795d3b2a155775741b20b52b3fb55169eecb8d151bc530bd28c9b17746f6d7c16ba92d6a71f2253b692c19b469131cdbed8860ee59cd27e88e522daf0bf9ab1243ddf68821c7d6f403dc571471b2ec7bedd6adeacdad14b5a46f9484c51e77b5c7c1c323f34b7401cef50fe0355b34cbcee5079c6bb93b59ba0cf0709597a30155808aeb4feaf64081c4dbb827e6c0794836d11194e42ed4f8c916b57930ceb50f331ccedc9aa40071757ead3a9ee72d859c87064b73c44d575c8a00c2fe0865c52abf913ef89517b28f4e0ac9a1da378330d8c3f29917d12e54b2ae1da305fee7580ee1a225e6003301cfdc229e94e15d9b18f5cbb8d0013526884a412b336e05ab1f086078a82cb7558bedef8258f1c262c131066fb0c1ee5a446d0879dc5c318547b31965be7a65c511cd76559b6027f0257eb2def2479fa7f3c1dcf048cd293975727f18428427d74ab7ab02c9aed4ec3bc80d94d064b352b65c98527c305c8b781503974eaac50422e3b099bab5115fb6a5c409464441c5aa98282a2515d094c6d4726098708f350cdfbbdb66ec2dd97651bffc2ced43e54d8baa51217d9797254cb46e4e3a140acb5e44f910e751a7ff4b44f1b75962d4d0af24d95ce0c9a882b444f29622294b7aa3887c2ec0d5d2e59d0c33da520bd464b28f2074cabdee1d101f24819efa5080a97004ccfed037088fb41f2478ca98b245a98d6630c843d03374698205c49269eebbadb5f1496f0e5bc38d61ee1c65a0a8291ee9ce37aa765b666cb3ee592a754e8a503a7725a60546394523a4ab09a7aa9090088b668da7636e36e7357dd162ab360bb9eb29891a31ea07c49db42d2efec65f879f54df17c69539441983368150a91d18c4cb24d4a62186d99fcc2aca335337225f7d81c062598504679ae0985622f92d02a2b5681b8c9a4f2273490b149f1162fef2e794903e42ce7a68886d5cb57d11207b0cfd0b74099f51d00831994d832275c5be6d551ba3b50acc266351eaa398edd5a9197441deb176d2a06cf8655cf3f41acef3fc1d02f93baa736348416cfeb5b2a1a5466b9a34247ee635caa0bd3bb1886c0a66cee1641a71a77fbd2deca10a91f5ad99dcdb6b6f2061fa8bf86331a8622823a2e846873c3953edc859309c1017f096b0737f3ef1143ac5ece0bb0d37516aec77f3ff552d27cd51c6aecdf1f3650f5af860a18592efb3e66cd13be5b464b9a96","keyDerivationScheme":{"version":1,"description":"HKDFSHA256-with-UTF8-encoding-of-password-no-salt-no-info"}}
""".data(using: .utf8)!
