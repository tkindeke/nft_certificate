{-# LANGUAGE NoImplicitPrelude #-}

module Utilities
  ( wrapValidator
  , wrapPolicy
  , writeJSON
  , serialisedValidator
  , serialisedPolicy
  ) where

import           Cardano.Api           (PlutusScript, PlutusScriptV2,
                                        writeFileTextEnvelope)
import           Cardano.Api.Shelley   (PlutusScript (..),
                                        ScriptDataJsonSchema (ScriptDataJsonDetailedSchema),
                                        fromPlutusData, scriptDataToJson)
import           Codec.Serialise       (serialise)
import           Data.Aeson            as A
import qualified Data.ByteString.Lazy  as LBS
import qualified Data.ByteString.Short as SBS
import           Data.Functor          (void)
import           Plutus.V2.Ledger.Api  (MintingPolicy, ScriptContext,
                                        UnsafeFromData, Validator, toData,
                                        unsafeFromBuiltinData)
import           PlutusTx
import           PlutusTx.Prelude      (Bool, BuiltinData, Maybe (Nothing),
                                        check, ($), (.))
import           Prelude               as P (FilePath, IO)


{-# INLINABLE wrapValidator #-}
wrapValidator :: ( UnsafeFromData a
                 , UnsafeFromData b
                 )
              => (a -> b -> ScriptContext -> Bool)
              -> (BuiltinData -> BuiltinData -> BuiltinData -> ())
wrapValidator f a b ctx =
  check $ f
      (unsafeFromBuiltinData a)
      (unsafeFromBuiltinData b)
      (unsafeFromBuiltinData ctx)

{-# INLINABLE wrapPolicy #-}
wrapPolicy :: UnsafeFromData a
           => (a -> ScriptContext -> Bool)
           -> (BuiltinData -> BuiltinData -> ())
wrapPolicy f a ctx =
  check $ f
      (unsafeFromBuiltinData a)
      (unsafeFromBuiltinData ctx)

writeJSON :: PlutusTx.ToData a => FilePath -> a -> IO ()
writeJSON file = LBS.writeFile file . A.encode . scriptDataToJson ScriptDataJsonDetailedSchema . fromPlutusData . toData

serialisedValidator :: Validator -> PlutusScript PlutusScriptV2
serialisedValidator claimValidator = PlutusScriptSerialised $ SBS.toShort . LBS.toStrict $ serialise claimValidator

serialisedPolicy :: MintingPolicy -> PlutusScript PlutusScriptV2
serialisedPolicy mintPolicy = PlutusScriptSerialised $ SBS.toShort . LBS.toStrict $ serialise mintPolicy
