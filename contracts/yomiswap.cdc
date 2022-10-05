import FungibleToken from 0x01
import NonFungibleToken from 0x02

pub contract YomiSwap {

  pub event StakedNFT(id: UInt64, staker:Address?)
  pub event SwapFTforNFT(id: UInt64, swapper:Address?)


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
    priv let spotPrice: UFix64

    //@param delta: price difference
    pub let delta: UFix64

    //@param divergence: divergence of buy and sell
    pub let divergence: UFix64

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


//main関数
    pub fun stakeNFT(tokenId: UInt64){
      //ownerの確認
      pre {
        self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId) != nil:
          "Token does not exist in the owner's collection!"
      }

      //tokenを取得
      let token = self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId)
      let uuid = token.uuid

      //stake状態を変更
      self.tokenIdToApprove[uuid] = true

      //event発行
      emit StakedNFT(id: token.id, staker: self.owner?.address)
    }

    pub fun swapFTforNFT(tokenId: UInt64, vault: @FungibleToken.Vault): @NonFungibleToken.NFT {
      //ownerの確認
      pre {
        self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId) != nil:"No token matching this Id in collection!"
      }

      //tokenを取得
      let token = self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId)
      let uuid = token.uuid

      //FTを受け取る
      self.poolFTReceiverCapability.borrow()!.deposit(from: <-vault)

      //NFTを渡す
      return <-self.poolNFTCapability.borrow()!.withdraw(withdrawID: token.id)

      //event発行
      //emit  SwapFTforNFT(id: token.id, swapper: self.owner?.address)
    }

    pub fun swapNFTforFT(tokenId: UInt64, swapCapability: Capability<&NonFungibleToken.Collection>){
      //ownerの確認
      pre {
        swapCapability.borrow()!.borrowNFT(id: tokenId) != nil:"No token matching this Id in collection!"
      }

      //tokenを取得
      let token <- swapCapability.borrow()!.withdraw(withdrawID: tokenId)
      let uuid = token.uuid

      //NFTを受け取る
      self.poolNFTCapability.borrow()!.deposit(token: <- token)

      //FTを渡す

      //eventの発行
    }

    pub fun cancelStakeNFT(tokenId: UInt64){
      //ownerの確認
      pre {
        self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId) != nil:
          "Token does not exist in the owner's collection!"
      }

      //tokenの取得
      let token = self.poolNFTCapability.borrow()!.borrowNFT(id: tokenId)
      let uuid = token.uuid

      assert(self.tokenIdToApprove[uuid] != nil, message: "No token with this Id on sale!")

      //状態変更
      self.tokenIdToApprove.remove(key: uuid)
      self.tokenIdToApprove[uuid] = nil

      //event発行
    }
    
    pub fun cancelStakeFT(tokenId: UInt64){
      
    }


//getter関数
    pub fun getBuyTotalPrice():UFix64{
      return self.spotPrice 
    }

    pub fun getSellTotalPrice():UFix64{
      return self.spotPrice 
    }

//set関数
    pub fun setSpotPrice(){}

    pub fun setDelta(){}

    pub fun setDivergence(){}

//internal関数
    pub fun _calcBuyPrice(num:UInt64):UFix64{
      return  UFix64(num) * self.spotPrice
    }

    pub fun _calcSellPrice(num:UInt64):UFix64{
      return  UFix64(num) * self.spotPrice
    }
  }
}