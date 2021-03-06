{-# LANGUAGE CPP, TemplateHaskell #-}
module Main where

import Tip.GHC
import Tip.GHC.Params

import System.Environment
import Data.Ord

import Control.Monad

import Tip.Core
import Tip.Fresh
import Tip.Simplify
import Tip.Lint
import Tip.Passes

import Tip.Utils.Rename

import Tip.Pretty
import Tip.Pretty.SMT as SMT

import Options.Applicative
import System.Environment
import Language.Haskell.TH.Syntax(qRunIO, lift)
import System.Process

main :: IO ()
main = do
#ifdef STACK
    let pkgdb = $(qRunIO (readProcess "stack" ["exec", "--", "sh", "-c", "echo $GHC_PACKAGE_PATH"] "") >>= lift)

    setEnv "GHC_PACKAGE_PATH" (head (lines pkgdb))
#endif
    (file, params) <-
      execParser $
        info (helper <*>
                ((,) <$> strArgument (metavar "FILENAME" <> help "Haskell file to process")
                     <*> parseParams))
          (fullDesc <>
           progDesc "Translate Haskell to TIP" <>
           header "tip-ghc - translate Haskell to TIP")
    mthy <- readHaskellFile params file
    case mthy of
      Left s -> error s
      Right thy -> do
        when (PrintInitialTheory `elem` param_debug_flags params) $ putStrLn (ppRender thy)
        let pipeline =
              freshPass $
                runPasses
                  [ SimplifyGently
                  , RemoveNewtype
                  , UncurryTheory
                  , CommuteMatch
                  , SimplifyGently
                  , IfToBoolOp
                  , RemoveAliases, CollapseEqual
                  , CommuteMatch
                  , SimplifyGently
                  , CSEMatch
                  , EliminateDeadCode
                  ]
        case pipeline thy of
          [thy] -> print (SMT.ppTheory thy)
          _     -> error "tip-ghc: not one theory!"
