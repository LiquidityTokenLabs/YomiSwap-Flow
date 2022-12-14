import FungibleToken from 0x01
import NonFungibleToken from 0x02

pub contract YomiSwap {

  pub event StakedNFT(id: UInt64, staker:Address?)
  pub event SwapFTforNFT(id: UInt64, swapper:Address?)
  pub event SwapNFTforFT(id: UInt64, swappper:Address?)


  pub resource interface ITokenPool {
    pub let protocolFeeRatio: UFix64
    pub let royalityRatio: UFix64
    pub fun swapFTforNFT(tokenId: UInt64, kind: Type, vault: @FungibleToken.Vault):@NonFungibleToken.NFT {           
      post {
        result.id == tokenId: "The Id of the withdrawn token must be the same as the requested Id"
        result.isInstance(kind): "The Type of the withdrawn token must be the same as the requested Type"
      }
    }
    //pub fun sell(){}
  }


  pub resource TokenPool {

    //@param collection: capabilitiy of collection
    priv let poolNFTCapability: Capability<&NonFungibleToken.Collection>

    //@param currency: currency of owner's want
    priv let currency: Type

    //@param spotPrice: base price
    priv var spotPrice: UFix64

    //@param delta: price difference
    pub var delta: UFix64

    //@param divergence: divergence of buy and sell
    pub var divergence: UFix64

    //@param isStake of tokenId
    priv let tokenIdToApprove: {UInt64:Bool}

    //@param
    priv let poolFTProviderCapability: Capability<&{FungibleToken.Provider}>

    //@param ownerCapability: capability of token's owner
    priv let poolFTReceiverCapability: Capability<&{FungibleToken.Receiver}>

    //@param protocolCapability: capability of protocol's owner
    priv let protocolCapabitiy: Capability<&{FungibleToken.Receiver}>

    //@param royalityCapability: capability of collection creater
    priv let royalityCapability: Capability<&{FungibleToken.Receiver}>

    //@param protocolFeeRatio: ratio of protocol fee
    pub let protocolFeeRatio: UFix64

    //@param royalityRatio: ratio of royality
    pub let royalityRatio: UFix64

    //@param sellNum
    pub let sellNum: UInt64

    //@param buyNum
    pub let buyNum: UInt64

    init(
      currency: Type,
      spotPrice: UFix64,
      delta: UFix64,
      divergence: UFix64,
      poolNFTCapability: Capability<&NonFungibleToken.Collection>,
      poolFTProviderCapability: Capability<&{FungibleToken.Provider}>,
      poolFTReceiverCapability: Capability<&{FungibleToken.Receiver}>,
      protocolCapabitiy: Capability<&{FungibleToken.Receiver}>,
      royalityCapability: Capability<&{FungibleToken.Receiver}>,
      protocolFeeRatio: UFix64,
      royalityRatio: UFix64
      ){
      self.poolNFTCapability = poolNFTCapability
      self.currency = currency
      self.poolFTProviderCapability = poolFTProviderCapability
      self.poolFTReceiverCapability = poolFTReceiverCapability
      self.protocolCapabitiy = protocolCapabitiy
      self.royalityCapability = royalityCapability
      self.protocolFeeRatio = protocolFeeRatio
      self.royalityRatio = royalityRatio
      self.spotPrice = spotPrice
      self.delta = delta
      self.divergence = divergence
      self.tokenIdToApprove = {}
      self.sellNum = 0
      self.buyNum = 0
    }


//main??????
    pub fun stakeNFT(tokenId: UInt64){
      //owner?????????
      pre {
        self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId) != nil:
          "Token does not exist in the owner's collection!"
      }

      //token?????????
      let token = self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId)
      let uuid = token.uuid

      //stake???????????????
      self.tokenIdToApprove[uuid] = true

      //event??????
      emit StakedNFT(id: token.id, staker: self.owner?.address)
    }

    pub fun swapFTforNFT(tokenId: UInt64, vault: @FungibleToken.Vault): @NonFungibleToken.NFT {
      //owner?????????
      pre {
        self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId) != nil:"No token matching this Id in collection!"
      }

      //token?????????
      let token = self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId)
      let uuid = token.uuid

      //FT???????????????
      self.poolFTReceiverCapability.borrow()!.deposit(from: <-vault)

      //NFT?????????
      return <-self.poolNFTCapability.borrow()!.withdraw(withdrawID: token.id)

      //event??????
      //emit  SwapFTforNFT(id: token.id, swapper: self.owner?.address)
    }

    pub fun swapNFTforFT(tokenId: UInt64, swapCapability: Capability<&NonFungibleToken.Collection>):@FungibleToken.Vault{
      //owner?????????
      pre {
        swapCapability.borrow()!.borrowNFT(id: tokenId) != nil:"No token matching this Id in collection!"
      }

      //token?????????
      let token <- swapCapability.borrow()!.withdraw(withdrawID: tokenId)
      let uuid = token.uuid

      let amount:UFix64 = 0.01

      //NFT???????????????
      self.poolNFTCapability.borrow()!.deposit(token: <- token)

      //FT?????????
      return  <-self.poolFTProviderCapability.borrow()!.withdraw(amount: amount)

      //event?????????
      //emit SwapNFTforFT(id: token.id, swapper: self.owner?.address)
    }

    pub fun cancelStakeNFT(tokenId: UInt64){
      //owner?????????
      pre {
        self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId) != nil:
          "Token does not exist in the owner's collection!"
      }

      //token?????????
      let token = self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId)
      let uuid = token.uuid

      assert(self.tokenIdToApprove[uuid] != nil, message: "No token with this Id on sale!")

      //????????????
      self.tokenIdToApprove.remove(key: uuid)
      self.tokenIdToApprove[uuid] = nil

      //event??????
    }
    
    pub fun cancelStakeFT(tokenId: UInt64){
      
    }


//getter??????
    pub fun getBuyTotalPrice():UFix64{
      return self.spotPrice 
    }

    pub fun getSellTotalPrice():UFix64{
      return self.spotPrice 
    }

//set??????
    pub fun setSpotPrice(_ spotPrice: UFix64){
      self.spotPrice = spotPrice
    }

    pub fun setDelta(_ delta: UFix64){
      self.delta = delta
    }

    pub fun setDivergence(_ divergence: UFix64){
      self.divergence = divergence
    }

//internal??????
    pub fun _calcTotalBuyPrice(_num:UInt64):UFix64{
      let totalFee = UFix64(_num) * self.spotPrice + (UFix64(_num) * (UFix64(_num) - UFix64(1)) * self.delta) / UFix64(2)
      return  totalFee
    }

    pub fun _calcUpdateBuyPrice(_num:UInt64):UFix64{
      let newBuyPrice = self.spotPrice + UFix64(_num) * self.delta
      return  newBuyPrice
    }

    pub fun _calcTotalSellPrice(_num:UInt64):UFix64{
      let totalFee = UFix64(_num) * (self.spotPrice - self.delta * UFix64(2)) - (UFix64(_num) * (UFix64(_num) - UFix64(1)) * self.delta) / UFix64(2)
      return  totalFee
    }

    pub fun _calcUpdateSellPrice(_num:UInt64):UFix64{
      let newBuyPrice = self.spotPrice - UFix64(_num) * self.delta
      return  newBuyPrice
    }
  }
}