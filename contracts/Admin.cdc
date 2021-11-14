import FungibleToken from "./standard/FungibleToken.cdc"
import FUSD from "./standard/FUSD.cdc"
import NonFungibleToken from "./standard/NonFungibleToken.cdc"
import Profile from "./Profile.cdc"
import FIND from "./FIND.cdc"
import Debug from "./Debug.cdc"
import Clock from "./Clock.cdc"
import Artifact from "./Artifact.cdc"
import Art from "./Art.cdc"
import TypedMetadata from "./TypedMetadata.cdc"


pub contract Admin {

	//store the proxy for the admin
	pub let AdminProxyPublicPath: PublicPath
	pub let AdminProxyStoragePath: StoragePath


	/// ===================================================================================
	// Admin things
	/// ===================================================================================

	//Admin client to use for capability receiver pattern
	pub fun createAdminProxyClient() : @AdminProxy {
		return <- create AdminProxy()
	}

	//interface to use for capability receiver pattern
	pub resource interface AdminProxyClient {
		pub fun addCapability(_ cap: Capability<&FIND.Network>)
	}


	//admin proxy with capability receiver 
	pub resource AdminProxy: AdminProxyClient {

		access(self) var capability: Capability<&FIND.Network>?

		pub fun addCapability(_ cap: Capability<&FIND.Network>) {
			pre {
				cap.check() : "Invalid server capablity"
				self.capability == nil : "Server already set"
			}
			self.capability = cap
		}


		pub fun setArtifactTypeConverter(from: Type, converters: [Capability<&{TypedMetadata.TypeConverter}>]) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			Artifact.setTypeConverter(from: from, converters: converters)
		}

		/// Set the wallet used for the network
		/// @param _ The FT receiver to send the money to
		pub fun setWallet(_ wallet: Capability<&{FungibleToken.Receiver}>) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setWallet(wallet)
		}


		/// Enable or disable public registration 
		pub fun setPublicEnabled(_ enabled: Bool) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setPublicEnabled(enabled)
		}


		pub fun setAddonPrice(name: String, price: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setAddonPrice(name: name, price: price)
		}

		pub fun setPrice(default: UFix64, additional : {Int: UFix64}) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}

			self.capability!.borrow()!.setPrice(default: default, additionalPrices: additional)
		}

		pub fun register(name: String, vault: @FUSD.Vault, profile: Capability<&{Profile.Public}>, leases: Capability<&FIND.LeaseCollection{FIND.LeaseCollectionPublic}>){
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
				FIND.validateFindName(name) : "A FIND name has to be lower-cased alphanumeric or dashes and between 3 and 16 characters"
			}

			self.capability!.borrow()!.register(name:name, vault: <- vault, profile: profile, leases: leases)
		}

		pub fun createForge(platform: Artifact.MinterPlatform) : @Artifact.Forge {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			return <- Artifact.createForge(platform:platform)
		}


		//this is used to mock the clock, NB! Should consider removing this before deploying to mainnet?
		pub fun advanceClock(_ time: UFix64) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			Debug.enable(true)
			Clock.enable()
			Clock.tick(time)
		}


		//this is used to mock the clock, NB! Should consider removing this before deploying to mainnet?
		pub fun debug(_ value: Bool) {
			pre {
				self.capability != nil: "Cannot create FIND, capability is not set"
			}
			Debug.enable(value)
		}


		pub fun createVersusArtWithContent(name: String, artist:String, artistAddress:Address, description: String, url: String, type: String, royalty: {String: Art.Royalty}, edition: UInt64, maxEdition: UInt64) : @Art.NFT {
			return <- 	Art.createArtWithContent(name: name, artist: artist, artistAddress: artistAddress, description: description, url: url, type: type, royalty: royalty, edition: edition, maxEdition: maxEdition)
		}
		init() {
			self.capability = nil
		}


	}

	init() {

		self.AdminProxyPublicPath= /public/findAdminProxy
		self.AdminProxyStoragePath=/storage/findAdminProxy
	}

}
