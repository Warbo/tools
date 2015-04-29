{-# LANGUAGE RecordWildCards, OverloadedStrings #-}
module Tip.Pretty where

import Text.PrettyPrint

import Tip.Types

infixl 1 $\

-- | Typeclass for pretty things
class Pretty a where
  pp :: a -> Doc

-- | Pretty to string
ppRender :: Pretty a => a -> String
ppRender = render . pp

-- | Print something pretty
pprint :: Pretty a => a -> IO ()
pprint = putStrLn . ppRender

instance PrettyVar Int where
  varStr = show

-- | Typeclass for variables
class PrettyVar a where
  -- | The string in a variable
  varStr :: a -> String

-- | Variable to 'Doc'
ppVar :: PrettyVar a => a -> Doc
ppVar = text . varStr

-- * Utilities on Docs

-- | Infix 'hang'
($\) :: Doc -> Doc -> Doc
d1 $\ d2 = hang d1 2 d2


-- | Conditional parentheses
parIf :: Bool -> Doc -> Doc
parIf True  = parens
parIf False = id

