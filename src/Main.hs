{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE LambdaCase #-}
module Main where

import Control.Concurrent.Async
import Control.Exception
import Control.Monad
import Data.Binary.Get
import qualified Data.ByteString as B
import Data.ByteString.Lazy
import Data.Word
import Data.FileEmbed
import Network.Wai.Handler.WebSockets
import Network.WebSockets
import System.Environment
import System.Exit
import System.Posix.Pty
import System.Process (ProcessHandle, terminateProcess)
import Network.Wai.Application.Static
import Network.Wai.Handler.Warp
import Network.Wai

staticContent :: [(FilePath, B.ByteString)]
staticContent = $(embedDir "static")

staticServe :: Application
staticServe = staticApp $ embeddedSettings staticContent

serve :: String -> [String] -> Application
serve prog args = websocketsOr defaultConnectionOptions (application prog args) staticServe

usage :: IO ()
usage = Prelude.putStrLn "usage: wshterm [-p PORT | --] command [args..]"

main :: IO ()
main = do
    args <- getArgs
    case args of
        [] -> usage >> exitFailure
        (first:rest) -> do
            let
                (port, prog:args) = case first of
                    "-p" -> let (p:command) = rest in (read p, command)
                    "--" -> (8899, rest)
                    _    -> (8899, first : rest)
            Prelude.putStrLn $ "Listening on port " ++ show port
            run port $ serve prog args

data InMessage
    = Input ByteString
    | Resize Word16 Word16

instance WebSocketsData InMessage where
    fromDataMessage (Text bs _) = fromLazyByteString bs
    fromDataMessage (Binary bs) = fromLazyByteString bs

    fromLazyByteString = runGet $ do
        getWord8 >>= \case
            0 -> Resize <$> getWord16be <*> getWord16be
            1 -> Input <$> getRemainingLazyByteString

    toLazyByteString = error "toLazyByteString undefined because we don't need it"

application :: String -> [String] -> ServerApp
application prog args pending = do
    conn <- acceptRequest pending
    forkPingThread conn 30
    bracket
        (spawnWithPty Nothing True prog args (80, 80))
        (\(pty,ph) -> closePty pty >> terminateProcess ph)
        (\(pty,ph) -> dealWith conn pty ph)

dealWith :: Connection -> Pty -> ProcessHandle -> IO ()
dealWith c pty ph = void $ doIO
    where
        doIO = race doIn doOut

        doIn = forever $ do
            receiveData c >>= \case
                Input s -> mapM_ (writePty pty) $ toChunks s
                Resize w h -> resizePty pty (fromIntegral w,fromIntegral h)

        doOut = forever $ readPty pty >>= sendTextData c
