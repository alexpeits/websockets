-- | Fast, custom parser for WebSocket data
{-# LANGUAGE OverloadedStrings, PatternGuards #-}
module Network.WebSockets.Decode
    ( request
    , frame
    ) where

import Control.Applicative ((<$>), (<*>), (*>), (<*))
import Data.Attoparsec (Parser, anyWord8, string, takeTill, takeWhile1, word8)
import Data.Attoparsec.Combinator (manyTill)
import Data.ByteString.Char8 ()
import Data.ByteString.Internal (c2w)
import qualified Data.Attoparsec as A

import Network.WebSockets.Types

-- | Parse an initial request
request :: Parser Request
request = Request
    <$> requestLine
    <*> manyTill header newline
    <*> token
  where
    space = word8 (c2w ' ')
    newline = string "\r\n"

    requestLine = string "GET" *> space *> takeWhile1 (/= c2w ' ')
        <* space
        <* string "HTTP/1.1" <* newline

    header = (,)
        <$> takeWhile1 (/= c2w ':') 
        <*  string ": "
        <*> takeWhile1 (/= c2w '\r')
        <*  newline

    token = A.take 8

-- | Parse a frame
frame :: Parser Frame
frame = do
    code <- anyWord8
    case code of
        0 -> Data <$> takeTill (== 0xff) <* word8 0xff
        -- TODO: implement other frame types
        _ -> error "TODO"
