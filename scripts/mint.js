const NFT = artifacts.require("NFT");

module.exports = async function(callback) {
  try {
    const nft = await NFT.deployed()

    console.log('Minting token...')
    await nft.mint()
    .on('receipt', async function(receipt) {
      console.log('Token address: ', receipt.logs[0].address)
      console.log('Token owner: ', receipt.logs[0].args.to)
      console.log('Token ID: ', Number(receipt.logs[0].args.tokenId))
    })
  } catch(error) {
    console.log(error)
  }
  callback()
}
