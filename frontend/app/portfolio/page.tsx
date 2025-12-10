"use client";

import React, { useEffect, useState, useCallback } from "react";
import {
  Box,
  Button,
  Grid,
  Heading,
  HStack,
  Stack,
  Text,
  useDisclosure,
} from "@chakra-ui/react";

import DepositModal from "@/components/vault/DepositModal";
import { formatTokenAmount } from "../../utils/formatToken";

/* ================= TYPES ================= */

type EthereumProvider = {
  request: (args: { method: string; params?: unknown[] }) => Promise<unknown>;
};

type SpotBalance = {
  asset: string;
  balance: string;
  locked: number;
};

type FuturesBalance = {
  asset: string;
  collateral: string;
  pnl: number;
};

type SpotVaultApiItem = {
  asset: string;
  balance: string;
  locked: string;
};

type FuturesApiItem = {
  asset: string;
  collateral: number | string | null;
  pnl: number | string | null;
};

/* ================= COMPONENT ================= */

export default function PortfolioPage() {
  const [userAddress, setUserAddress] = useState<string | null>(null);
  const [prices, setPrices] = useState<Record<string, string>>({});
  const [spotBalances, setSpotBalances] = useState<SpotBalance[]>([]);
  const [futuresBalances, setFuturesBalances] = useState<FuturesBalance[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const { open, onOpen, onClose } = useDisclosure();

  const apiBase = (process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001").replace(
    /\/$/,
    "",
  );

  /* ================= INIT USER (MetaMask) ================= */
  useEffect(() => {
    async function initAddress() {
      if (typeof window === "undefined") return;

      const ethereum = (window as unknown as { ethereum?: EthereumProvider })
        .ethereum;

      if (!ethereum) {
        setUserAddress(process.env.NEXT_PUBLIC_USER_ADDRESS ?? null);
        return;
      }

      try {
        const accounts = (await ethereum.request({
          method: "eth_requestAccounts",
        })) as string[];

        if (accounts?.length) {
          setUserAddress(accounts[0]);
        }
      } catch {
        setUserAddress(process.env.NEXT_PUBLIC_USER_ADDRESS ?? null);
      }
    }

    initAddress();
  }, []);

  /* ================= FETCH PRICES ================= */
  useEffect(() => {
    const fetchPrices = async () => {
      const assets = ["BTC", "ETH", "USDT", "SOL", "ADA"];
      const fetched: Record<string, string> = {};

      await Promise.all(
        assets.map(async (asset) => {
          try {
            const res = await fetch(`${apiBase}/mock-oracle/price?asset=${asset}`);
            if (!res.ok) throw new Error();
            const data = await res.json();
            fetched[asset] = formatTokenAmount(data.price, asset);
          } catch {
            fetched[asset] = "-";
          }
        }),
      );

      setPrices(fetched);
    };

    fetchPrices();
  }, [apiBase]);

  /* ================= LOAD VAULTS ================= */
  const loadVaults = useCallback(async () => {
    if (!userAddress) return;

    try {
      setLoading(true);
      setError(null);

      // ---------- SPOT ----------
      const spotRes = await fetch(`${apiBase}/spot/vaults/${userAddress}`);
      if (!spotRes.ok) throw new Error("Failed to load spot vaults");

      const rawSpot = await spotRes.json();
      const spotArray: SpotVaultApiItem[] = Array.isArray(rawSpot)
        ? rawSpot
        : rawSpot.spot ?? [];

      setSpotBalances(
        spotArray.map((i) => ({
          asset: i.asset,
          balance: formatTokenAmount(Number(i.balance || 0), i.asset),
          locked: Number(i.locked || 0),
        })),
      );

      // ---------- FUTURES ----------
      const futuresRes = await fetch(`${apiBase}/futures/vaults/${userAddress}`);
      if (!futuresRes.ok) throw new Error("Failed to load futures vaults");

      const futuresJson = (await futuresRes.json()) as {
        futures?: FuturesApiItem[];
      };

      setFuturesBalances(
        (futuresJson.futures ?? []).map((i) => ({
          asset: i.asset,
          collateral: formatTokenAmount(Number(i.collateral || 0), i.asset),
          pnl: Number(i.pnl || 0),
        })),
      );
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setLoading(false);
    }
  }, [userAddress, apiBase]);

  useEffect(() => {
    loadVaults();
  }, [loadVaults]);

  if (!userAddress) return <Text>Loading wallet...</Text>;

  /* ================= UI ================= */
  return (
    <Stack p={6} bg="gray.100" borderRadius="xl" gap={6}>
      <HStack justify="space-between">
        <HStack gap={3}>
          <Button size="sm" colorScheme="teal" onClick={onOpen}>
            Deposit
          </Button>
          <Button size="sm" colorScheme="red" variant="outline">
            Withdraw
          </Button>
        </HStack>

        <HStack gap={4} fontSize="sm">
          {["BTC", "ETH", "USDT", "SOL", "ADA"].map((a) => (
            <HStack key={a} gap={1}>
              <Text fontWeight="semibold">{a}</Text>
              <Text fontFamily="mono">{prices[a] ?? "-"}</Text>
            </HStack>
          ))}
        </HStack>
      </HStack>

      <DepositModal
        isOpen={open}
        onClose={onClose}
        onSuccess={loadVaults}
        userAddress={userAddress}
      />

      <Grid templateColumns={{ base: "1fr", md: "1fr 1fr" }} gap={6}>
        <Box bg="white" p={5} borderRadius="lg">
          <Heading size="md" mb={3}>
            Spot Vault
          </Heading>

          <Stack gap={3}>
            {loading && <Text>Loading...</Text>}
            {error && <Text color="red.400">{error}</Text>}

            {!loading &&
              !error &&
              spotBalances.map((b) => (
                <HStack
                  key={b.asset}
                  justify="space-between"
                  px={3}
                  py={2}
                  borderWidth="1px"
                  borderRadius="md"
                >
                  <Text fontWeight="semibold">{b.asset}</Text>
                  <Text fontFamily="mono">
                    {b.balance}{" "}
                    <Text as="span" color="gray.500">
                      ({b.locked})
                    </Text>
                  </Text>
                </HStack>
              ))}
          </Stack>
        </Box>

        <Box bg="white" p={5} borderRadius="lg">
          <Heading size="md" mb={3}>
            Futures Vault
          </Heading>

          <Stack gap={3}>
            {futuresBalances.map((f) => (
              <HStack key={f.asset} justify="space-between">
                <Text fontWeight="semibold">{f.asset}</Text>
                <Text fontFamily="mono">{f.collateral}</Text>
              </HStack>
            ))}
          </Stack>
        </Box>
      </Grid>
    </Stack>
  );
}
