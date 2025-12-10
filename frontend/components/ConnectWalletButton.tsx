"use client";

import { useState } from "react";
import { Button, Text, VStack, Box, Spinner } from "@chakra-ui/react";

type EthereumProvider = {
  request: <T = unknown>(args: { method: string; params?: unknown[] }) => Promise<T>;
};

interface ConnectWalletButtonProps {
  onConnect: (address: string) => void;
}

export default function ConnectWalletButton({ onConnect }: ConnectWalletButtonProps) {
  const [account, setAccount] = useState<string | null>(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const getEth = (): EthereumProvider | null => {
    if (typeof window === "undefined") return null;

    const { ethereum } = window as typeof window & {
      ethereum?: EthereumProvider;
    };

    return ethereum ?? null;
  };

  const connect = async () => {
    const eth = getEth();
    if (!eth) {
      setError("MetaMask tidak ditemukan.");
      return;
    }

    setIsConnecting(true);
    setError(null);

    try {
      const accounts = await eth.request<string[]>({ method: "eth_requestAccounts" });
      if (!accounts[0]) throw new Error("MetaMask tidak mengembalikan akun valid");

      setAccount(accounts[0]);
      onConnect(accounts[0]);
    } catch {
      setError("Gagal connect wallet.");
    } finally {
      setIsConnecting(false);
    }
  };

  return (
    <VStack
     align="center"
     gap={3}
     w="100%"
    >
      {!account ? (
        <Button
          onClick={connect}
          disabled={isConnecting}
          colorScheme="teal"
          borderRadius="lg"
          px={5}
          py={3}
          fontSize="sm"
        >
          {isConnecting ? (
            <Box display="flex" alignItems="center" gap={2}>
              <Spinner size="sm" />
              Connecting...
            </Box>
          ) : (
            "Connect Wallet"
          )}
        </Button>
      ) : (
        <Text fontSize="sm" fontWeight="medium">
          Connected: {account.slice(0, 6)}...{account.slice(-4)}
        </Text>
      )}

      {error && (
        <Box
          bg="red.500"
          color="white"
          p={3}
          borderRadius="md"
          w="100%"
        >
          <Text fontSize="sm" fontWeight="medium">
            {error}
          </Text>
        </Box>
      )}
    </VStack>
  );
}
