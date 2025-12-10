"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import {
  Button,
  Box,
  Text,
  Spinner,
  VStack,
} from "@chakra-ui/react";

type EthereumProvider = {
  request: <T = unknown>(args: { method: string; params?: unknown[] }) => Promise<T>;
};

interface LoginButtonProps {
  ethAddress: string;
}

const LoginButton: React.FC<LoginButtonProps> = ({ ethAddress }) => {
  const [isLoggingIn, setIsLoggingIn] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const router = useRouter();

  const getEth = (): EthereumProvider | null => {
    if (typeof window === "undefined") return null;
    const { ethereum } = window as typeof window & { ethereum?: EthereumProvider };
    return ethereum ?? null;
  };

  const login = async () => {
    setIsLoggingIn(true);
    setError(null);

    try {
      // STEP 1 — Fetch nonce
      const nonceFetch = await fetch("http://localhost:3001/auth/nonce", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ eth_address: ethAddress }),
      });

      if (!nonceFetch.ok) {
        let message = "";
        const ct = nonceFetch.headers.get("content-type");
        if (ct?.includes("application/json")) {
          const body = (await nonceFetch.json().catch(() => null)) as { message?: string } | null;
          message = body?.message ?? "";
        }
        setError(message || `Gagal mengambil nonce dari server (status ${nonceFetch.status})`);
        setIsLoggingIn(false);
        return;
      }

      const nonceRes = await nonceFetch.json();
      const rawNonce = nonceRes?.nonce ?? nonceRes?.data?.nonce;

      if (rawNonce == null) throw new Error("Nonce tidak ditemukan");
      const nonce = Number(rawNonce);
      if (Number.isNaN(nonce)) throw new Error("Nonce tidak valid");

      // STEP 2 — Signature via MetaMask
      const eth = getEth();
      if (!eth) throw new Error("MetaMask tidak ditemukan.");

      const message = `Login nonce: ${nonce}`;
      const signature = await eth.request<string>({
        method: "personal_sign",
        params: [message, ethAddress],
      });

      // STEP 3 — Verify signature
      const verifyFetch = await fetch("http://localhost:3001/auth/verify", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ eth_address: ethAddress, signature }),
      });

      if (!verifyFetch.ok) {
        let message = "";
        const ct = verifyFetch.headers.get("content-type");
        if (ct?.includes("application/json")) {
          const body = (await verifyFetch.json().catch(() => null)) as { message?: string } | null;
          message = body?.message ?? "";
        }
        setError(message || `Verifikasi signature gagal (status ${verifyFetch.status})`);
        setIsLoggingIn(false);
        return;
      }

      const verifyRes = await verifyFetch.json();
      if (!verifyRes?.success || !verifyRes?.token) throw new Error("Verifikasi gagal.");

      // Save token
      localStorage.setItem("ethAddress", ethAddress);
      localStorage.setItem("token", verifyRes.token);

      router.push("/portfolio");
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Gagal login via signature";
      setError(msg);
    } finally {
      setIsLoggingIn(false);
    }
  };

  return (
    <VStack align="start" gap={3} w="100%">
      <Button
        onClick={login}
        disabled={isLoggingIn}
        colorScheme="blue"
        borderRadius="lg"
        px={5}
        py={3}
        fontSize="sm"
        w="100%"
      >
        {isLoggingIn ? (
          <Box display="flex" alignItems="center" gap={2}>
            <Spinner size="sm" /> Logging in...
          </Box>
        ) : (
          "Login / Sign Message"
        )}
      </Button>

      {error && (
        <Box
          bg="red.500"
          color="white"
          p={3}
          rounded="md"
          w="100%"
        >
          <Text fontSize="sm">{error}</Text>
        </Box>
      )}
    </VStack>
  );
};

export default LoginButton;
