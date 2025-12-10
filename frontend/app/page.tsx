"use client";

import { useState } from "react";
import { Center, VStack, Heading, Box } from "@chakra-ui/react";
import ConnectWalletButton from "@/components/ConnectWalletButton";
import LoginButton from "@/components/LoginButton";

export default function HomePage() {
  const [ethAddress, setEthAddress] = useState<string>("");

  return (
    <Center w="100%" h="100vh" p={6}>
       <Box
        bg="white"
        p={8}
        rounded="xl"
        shadow="xl"
        w="100%"
        maxW="420px"
        border="1px solid"
        borderColor="gray.200"
      >
      <VStack gap={6} align="center" w="100%" maxW="400px">
        <Heading size="lg">Trading Bot MVP</Heading>

        <ConnectWalletButton onConnect={(addr) => setEthAddress(addr)} />

        {ethAddress && (
          <Box w="100%">
            <LoginButton ethAddress={ethAddress} />
          </Box>
        )}
      </VStack>
      </Box>
    </Center>
  );
}
