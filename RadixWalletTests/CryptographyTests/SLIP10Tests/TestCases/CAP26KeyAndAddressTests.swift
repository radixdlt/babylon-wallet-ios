import EngineToolkit
import Foundation
@testable import Radix_Wallet_Dev
import XCTest

final class CAP26KeyAndAddressTests: TestCase {
	// PLEASE do clean this up... sorry. Adding it to assert a Rust lib.
	func test() throws {
		var mnemonic = try Mnemonic(phrase: "zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo zoo vote", language: .english)
		XCTAssertEqual(try FactorSource.id(fromRoot: mnemonic.hdRoot(), factorSourceKind: .device).description, "device:3bf4636876a9c795486194d2eaff32790961ed9005e18a7ebe677f0947b54087")
		XCTAssertEqual(try FactorSource.id(fromRoot: mnemonic.hdRoot(passphrase: "foo"), factorSourceKind: .device).description, "device:883882e1d9d47b98090163bb4b369ae00349507693d856b1854de103dfe52793")

		var hdRoot = try mnemonic.hdRoot(passphrase: "foo")
		var fsid = try FactorSource.id(fromRoot: hdRoot, factorSourceKind: .device)

		if true {
			let path = try AccountBabylonDerivationPath(networkID: .mainnet, index: 0, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "37947aece03dfbbe89672cb5b1caba88629625739750db7b8b0d8cb4bd5631f8")
			XCTAssertEqual(publicKey.hex, "111ae3183e7b93c0f751bbfbc8aba6888434d889e3805f8941669e3194721290")

			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: .mainnet, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_rdx12xg8ncs6xd8fr9t3gzx3sv3k8nmu8q4ekgxaahdlnxhn2rfrh04k2w")
		}

		if true {
			let path = try AccountBabylonDerivationPath(networkID: .mainnet, index: 1, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "431fc569aac0a7fe55c7537b9c46977c66eb50cd6383795ecef64a6fb2aa39aa")
			XCTAssertEqual(publicKey.hex, "e24df52deaa191fd247d1f0c10d55ff9251c1b7b50e61125bb419bd28e76b4c2")
			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: .mainnet, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_rdx12ydzkre4ujmn5mz2rddqt5mytl7ek52c7fgks48fusj32rfs0ns40n")
		}

		if true {
			let networkID = NetworkID.stokenet
			let path = try AccountBabylonDerivationPath(networkID: networkID, index: 0, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "a5f1c8d8433416b147c09ce6a5dd83bb77cab9d344ea9ea458d4a0c45b30ec7a")
			XCTAssertEqual(publicKey.hex, "810b03bf9c767f66e0e8caca015873c96bf7df0c5a28884f30a9a2837386cb7b")
			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: networkID, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_tdx_2_129kc6c9fhmsgstj4kv8ycc76z7nf36j46saav84lwt6ttdpeq44w6l")
		}

		if true {
			let networkID = NetworkID.stokenet
			let path = try AccountBabylonDerivationPath(networkID: networkID, index: 1, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "df60dafc61032f3bb0bd48ef6ba4bed03b93f5f87277d47456655736f4be709f")
			XCTAssertEqual(publicKey.hex, "eb04aaa6721c86fd71f9e7e5173f7a176a11c9e9407f39bbe998bc3bb12f03e5")
			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: networkID, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_tdx_2_129peacgfcj99m8ty9s2z09u7n3dhf6ps0n6mlz5ttex7mnfrzyjtt5")
		}

		hdRoot = try mnemonic.hdRoot(passphrase: "")
		fsid = try FactorSource.id(fromRoot: hdRoot, factorSourceKind: .device)
		XCTAssertEqual(fsid.description, "device:3bf4636876a9c795486194d2eaff32790961ed9005e18a7ebe677f0947b54087")

		if true {
			let networkID = NetworkID.stokenet
			let path = try AccountBabylonDerivationPath(networkID: networkID, index: 0, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "b5ecb0b6b928a198cb1a6bb87b0b67a5ae675961ea4b835e9aad8629828600ab")
			XCTAssertEqual(publicKey.hex, "12d9d790ef471e11738ff7ba3f99d1ddc58d969c9a796848f8e4af01d294c263")
			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: networkID, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_tdx_2_129t4rk8hyu9ekz9jgxcveprkm40dly5f4tc426sdqz7fa7mtgkmmff")
		}

		if true {
			let networkID = NetworkID.stokenet
			let path = try AccountBabylonDerivationPath(networkID: networkID, index: 1, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "2b2e6ce6abe0ab7ac7eb15d0809f4a44809ef979449bdd3550a5791a86e927ca")
			XCTAssertEqual(publicKey.hex, "2b1414b927a03ade597127bdaa90db93f60518795141ab5c451649f4997acddb")
			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: networkID, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_tdx_2_128cplhpppm0295zxf9507tlng8zf539jv9rc2pmaymkft36qpt7slj")
		}

		mnemonic = try Mnemonic(phrase: "bright club bacon dinner achieve pull grid save ramp cereal blush woman humble limb repeat video sudden possible story mask neutral prize goose mandate", language: .english)
		hdRoot = try mnemonic.hdRoot(passphrase: "")
		fsid = try FactorSource.id(fromRoot: hdRoot, factorSourceKind: .device)
		XCTAssertEqual(fsid.description, "device:6facb00a836864511fdf8f181382209e64e83ad462288ea1bc7868f236fb8033")

		if true {
			let networkID = NetworkID.mainnet
			let path = try AccountBabylonDerivationPath(networkID: networkID, index: 0, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "7b21b62816c6349293abc3a8c37470f917ae621ada2eb8d5124250e83b78f7ef")
			XCTAssertEqual(publicKey.hex, "6224937b15ec4017a036c0bd6999b7fa2b9c2f9452286542fd56f6a3fb6d33ed")
			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: networkID, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_rdx128vge9xzep4hsn4pns8qch5uqld2yvx6f3gfff786du7vlk6w6e6k4")
		}

		if true {
			let networkID = NetworkID.mainnet
			let path = try AccountBabylonDerivationPath(networkID: networkID, index: 1, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "e153431a8e55f8fde4d6c5377ea4f749fd28a6f196c7735ce153bd16bcbfcd6e")
			XCTAssertEqual(publicKey.hex, "a8d6fb3b7f3627b4589c2b663e8cc9b4d49df7013220ac0edd7e22e6cc608fa6")
			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: networkID, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_rdx129xapgx582768wrkd54mq0a8lhp8aqp5vkkc8u2jfavujktl0tatcs")
		}

		if true {
			let networkID = NetworkID.stokenet
			let path = try AccountBabylonDerivationPath(networkID: networkID, index: 0, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "2e7def75661fcd8a8916866546a7713bc10fea728d46487f33e3fa09f538038c")
			XCTAssertEqual(publicKey.hex, "5fdfa89b784cc63fc90f67bd3481f6611a798a9581b414bf627f758075e95ca1")
			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: networkID, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_tdx_2_12x4rz8yh6t2qtpwdmzc2fvz9xvr00rvv37v7lk3eyh8re7z6r0xyw8")
		}

		if true {
			let networkID = NetworkID.stokenet
			let path = try AccountBabylonDerivationPath(networkID: networkID, index: 1, keyKind: .transactionSigning)

			let keyPair = try hdRoot.derivePrivateKey(path: path.fullPath, curve: Curve25519.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey
			XCTAssertEqual(privateKey.hex, "c24fe54ad3cff0ba2627935e11f75fae12c477828d96fdfe3a707defa1d5db57")
			XCTAssertEqual(publicKey.hex, "0c6cf91e9b669bf09aeff687c86f6158f8fdfb23d0034bd3cb3f95c4443e9324")
			let add = try Profile.Network.Account.deriveVirtualAddress(networkID: networkID, factorInstance: HierarchicalDeterministicFactorInstance(id: fsid, publicKey: SLIP10.PublicKey.eddsaEd25519(publicKey), derivationPath: path.wrapAsDerivationPath()))
			XCTAssertEqual(add.address, "account_tdx_2_12xwkvs77drhw7lxnw2aewrs264yhhkln7zzpejye66q6gt5mc2kphn")
		}
	}
}
