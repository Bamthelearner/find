import NonFungibleToken from "../contracts/standard/NonFungibleToken.cdc"
import CharityNFT from "../contracts/CharityNFT.cdc"
import Admin from "../contracts/Admin.cdc"

//mint an art and add it to a users collection
transaction(
	name: String,
	image: String,
	thumbnail: String,
	originUrl: String,
	description: String,
	recipients: [Address]
) {

	prepare(account: AuthAccount) {
		let  client= account.borrow<&Admin.AdminProxy>(from: Admin.AdminProxyStoragePath)!

		let maxEdition=recipients.length

		var i=1
		for recipient in recipients {
			let metadata = {"name" : name.concat("#").concat(i.toString()).concat("/").concat(maxEdition.toString()), "image" : image, "thumbnail": thumbnail, "originUrl": originUrl, "description":description, "edition": i.toString(), "maxEdition" :  maxEdition.toString() }

			let receiverCap= getAccount(recipient).getCapability<&{NonFungibleToken.CollectionPublic}>(CharityNFT.CollectionPublicPath)
			client.mintCharity(metadata: metadata, recipient: receiverCap)

			i=i+1
		}
	}
}

